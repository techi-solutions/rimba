import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_app/services/config/config.dart';
import 'package:pay_app/services/preferences/preferences.dart';
import 'package:pay_app/services/secure/secure.dart';
import 'package:pay_app/services/wallet/wallet.dart';
import 'package:pay_app/services/monerium/monerium_auth_service.dart';
import 'package:pay_app/utils/currency.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class WalletState with ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();
  final SecureService _secureService = SecureService();
  final MoneriumAuthService moneriumAuthService = MoneriumAuthService();

  final Config _config;
  Config get config => _config;

  late EthereumAddress? _address;
  EthereumAddress? get address => _address;

  // Token balances management
  Map<String, String> tokenBalances = {};

  Map<String, bool> tokenLoadingStates = {};

  bool _loadingTokenBalances = false;
  bool get loadingTokenBalances => _loadingTokenBalances;

  bool loading = false;
  bool error = false;

  bool credentialsExpired = false;

  Timer? _pollingTimer;
  bool _mounted = true;

  // Monerium auth state
  String? _moneriumCodeVerifier;
  void safeNotifyListeners() {
    if (_mounted) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  WalletState(this._config) {
    _address = _preferencesService.lastAccount != null
        ? EthereumAddress.fromHex(_preferencesService.lastAccount!)
        : null;
    init();
  }

  Future<void> init() async {
    try {
      loading = true;
      safeNotifyListeners();

      if (_address == null) {
        loading = false;
        safeNotifyListeners();
        return;
      }

      tokenBalances = _preferencesService.tokenBalances(_address!.hexEip55);
      updateBalance();
      loadTokenBalances();

      safeNotifyListeners();

      final credentials = _secureService.getCredentials();

      if (credentials == null) {
        throw Exception('Credentials not found');
      }

      final (account, key) = credentials;

      final expired = await _config.sessionManagerModuleContract.isExpired(
        account,
        key.address,
      );

      if (expired) {
        await _secureService.clearCredentials();
        loading = false;
        credentialsExpired = true;
        safeNotifyListeners();
        return;
      }

      loading = false;
      safeNotifyListeners();

      return;
    } catch (e, s) {
      debugPrint('error: $e');
      debugPrint('stack trace: $s');
      error = true;
      safeNotifyListeners();
    }
  }

  void switchAccount(String account) {
    _address = EthereumAddress.fromHex(account);
    _preferencesService.setLastAccount(account);
    init();
  }

  Future<void> startBalancePolling() async {
    stopBalancePolling();

    _pollingTimer = Timer.periodic(
      Duration(seconds: 1),
      (_) {
        updateBalance();
        updateTokenBalances();
      },
    );
  }

  Future<void> stopBalancePolling() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> updateBalance() async {
    tokenBalances = _preferencesService.tokenBalances(_address!.hexEip55);
    safeNotifyListeners();

    final tokenConfig = config.getToken(
      _preferencesService.tokenAddress ?? config.getPrimaryToken().address,
    );

    final balance = await getBalance(
      _config,
      _address!,
      tokenAddress: tokenConfig.address,
    );

    final token = _config.getToken(tokenConfig.address);

    tokenBalances[tokenConfig.address] =
        formatCurrency(balance, token.decimals);
    safeNotifyListeners();

    await _preferencesService.setTokenBalances(
        _address!.hexEip55, tokenBalances);
  }

  Future<void> loadTokenBalances() async {
    if (_address == null || _config.tokens.isEmpty) {
      return;
    }

    try {
      tokenBalances = _preferencesService.tokenBalances(_address!.hexEip55);
      _loadingTokenBalances = true;
      safeNotifyListeners();

      // Initialize loading states for all tokens
      for (final tokenEntry in _config.tokens.entries) {
        tokenLoadingStates[tokenEntry.key] = true;
      }
      safeNotifyListeners();

      final balances = <String, String>{};

      for (final tokenEntry in _config.tokens.entries) {
        final tokenAddress = tokenEntry.value.address;
        try {
          final balance = await getBalance(
            _config,
            _address!,
            tokenAddress: tokenAddress,
          );

          balances[tokenAddress] =
              formatCurrency(balance, tokenEntry.value.decimals);
        } catch (e) {
          debugPrint('Error loading balance for token $tokenAddress: $e');
          balances[tokenAddress] = '0';
        } finally {
          tokenLoadingStates[tokenAddress] = false;
          safeNotifyListeners();
        }
      }

      tokenBalances = balances;
      safeNotifyListeners();

      await _preferencesService.setTokenBalances(
        _address!.hexEip55,
        tokenBalances,
      );
    } catch (e) {
      debugPrint('Error loading token balances: $e');
    } finally {
      _loadingTokenBalances = false;
      safeNotifyListeners();
    }
  }

  Future<void> updateTokenBalances() async {
    if (_address == null || _config.tokens.isEmpty) {
      return;
    }

    try {
      tokenBalances = _preferencesService.tokenBalances(_address!.hexEip55);
      safeNotifyListeners();

      final balances = <String, String>{};

      for (final tokenEntry in _config.tokens.entries) {
        final tokenKey = tokenEntry.key;
        final tokenAddress = tokenEntry.value.address;
        try {
          final balance = await getBalance(
            _config,
            _address!,
            tokenAddress: tokenAddress,
          );
          balances[tokenAddress] = formatCurrency(
            balance,
            tokenEntry.value.decimals,
          );
        } catch (e) {
          debugPrint('Error updating balance for token $tokenKey: $e');
          balances[tokenKey] = tokenBalances[tokenKey] ?? '0';
        }
      }

      tokenBalances = balances;
      await _preferencesService.setTokenBalances(
        _address!.hexEip55,
        tokenBalances,
      );
      safeNotifyListeners();
    } catch (e) {
      debugPrint('Error updating token balances: $e');
    }
  }

  String getTokenBalance(String tokenAddress) {
    return tokenBalances[tokenAddress] ?? '0';
  }

  bool isTokenLoading(String tokenAddress) {
    return tokenLoadingStates[tokenAddress] ?? false;
  }

  void setLastAccount(String account) {
    _preferencesService.setLastAccount(account);
  }

  void clear() {
    _address = null;
    tokenBalances = {};
    _preferencesService.setToken(null);
    safeNotifyListeners();
  }

  /// Generates PKCE values and builds the Monerium authorization URL
  /// Returns a map with 'authUrl' and 'redirectUri' keys
  Future<Map<String, String>> buildMoneriumAuthUrl() async {
    try {
      final clientId = dotenv.env['MONERIUM_CLIENT_ID'];
      final redirectUri =
          dotenv.env['MONERIUM_REDIRECT_URI'] ?? 'rimba://monerium';

      if (clientId == null || clientId.isEmpty) {
        throw Exception('MONERIUM_CLIENT_ID not configured');
      }

      // Generate PKCE values
      _moneriumCodeVerifier = moneriumAuthService.generateCodeVerifier();
      final codeChallenge =
          moneriumAuthService.generateCodeChallenge(_moneriumCodeVerifier!);

      final credentials = _secureService.getCredentials();

      if (credentials == null) {
        throw Exception('Credentials not found');
      }

      final (account, key) = credentials;

      final simpleAccount = await _config.getSimpleAccount(account.hexEip55);

      final message =
          utf8.encode('I hereby declare that I am the address owner.');

      // Get message hash for Safe - pass messageBytes directly (not preMessage)
      // to match what Safe will do internally
      final messageHash = await simpleAccount.getMessageHashForSafe(message);

      // Build authorization URL
      // Sign the messageHash with personal sign and adjust v for eth_sign flow
      final signature = moneriumAuthService.signOwnershipMessage(
        privateKey: key,
        message: messageHash,
      );

      print('ADDRESS: ${account.hexEip55}');
      print('KEY ADDRESS: ${key.address.hexEip55}');
      print('KEY: ${bytesToHex(key.privateKey, include0x: true)}');
      print('SIG RESULT: ${bytesToHex(signature, include0x: true)}');
      print('v ${signature[64]}');

      // Verify signature against Safe using isValidSignature
      // Pass keccak256(message) as _dataHash (bytes32)
      final result =
          await simpleAccount.isValidSignature(keccak256(message), signature);
      print('RESULT: ${bytesToHex(result, include0x: true)}');

      final authUrl = moneriumAuthService.buildAuthorizationUrl(
        clientId: clientId,
        redirectUri: redirectUri,
        codeChallenge: codeChallenge,
        address: account.hexEip55,
        // address: key.address.hexEip55,
        signature: bytesToHex(signature, include0x: true),
      );

      return {
        'authUrl': authUrl,
        'redirectUri': redirectUri,
      };
    } catch (e, s) {
      debugPrint('Error building Monerium auth URL: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Exchanges the authorization code for an access token
  /// [authorizationCode] - The code received from the OAuth redirect
  Future<Map<String, dynamic>> exchangeMoneriumCode(
      String authorizationCode) async {
    try {
      if (_moneriumCodeVerifier == null) {
        throw Exception(
            'Code verifier not found. Please start auth flow again.');
      }

      final clientId = dotenv.env['MONERIUM_CLIENT_ID'];
      final redirectUri =
          dotenv.env['MONERIUM_REDIRECT_URI'] ?? 'rimba://monerium';

      if (clientId == null || clientId.isEmpty) {
        throw Exception('MONERIUM_CLIENT_ID not configured');
      }

      final tokenResponse = await moneriumAuthService.exchangeCodeForToken(
        authorizationCode: authorizationCode,
        codeVerifier: _moneriumCodeVerifier!,
        clientId: clientId,
        redirectUri: redirectUri,
      );

      // Clear the code verifier after successful exchange
      _moneriumCodeVerifier = null;

      return tokenResponse;
    } catch (e, s) {
      debugPrint('Error exchanging Monerium code: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }
}

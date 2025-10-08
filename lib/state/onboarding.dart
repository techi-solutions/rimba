import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:pay_app/services/config/config.dart';
import 'package:pay_app/services/preferences/preferences.dart';
import 'package:pay_app/services/secure/secure.dart';
import 'package:pay_app/services/session/session.dart';
import 'package:pay_app/services/wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

enum SessionRequestStatus {
  none,
  pending,
  challenge,
  confirming,
  confirmed,
  failed,
  confirmFailed,
}

class OnboardingState with ChangeNotifier {
  // instantiate services here
  final PreferencesService _preferencesService = PreferencesService();
  final SecureService _secureService = SecureService();
  late SessionService _sessionService;
  final Config _config;

  // private variables here
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _challengeController = TextEditingController();

  TextEditingController get emailController => _emailController;
  TextEditingController get challengeController => _challengeController;

  EthPrivateKey? _sessionRequestPrivateKey;
  Uint8List? _sessionRequestHash;

  // constructor here
  OnboardingState(this._config) {
    connectedAccountAddress = getAccountAddress();
    init();
  }

  Future<void> init() async {
    _sessionService = SessionService(_config);
  }

  bool _mounted = true;
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

  // state variables here
  EthereumAddress? connectedAccountAddress;

  bool touched = false;
  bool isValidEmail = false;
  bool challengeTouched = false;
  String? challenge;

  SessionRequestStatus sessionRequestStatus = SessionRequestStatus.none;

  void reset() {
    sessionRequestStatus = SessionRequestStatus.none;
    _sessionRequestHash = null;
    _sessionRequestPrivateKey = null;

    touched = false;
    isValidEmail = false;
    challengeTouched = false;
    challenge = null;

    emailController.clear();
    challengeController.clear();
  }

  void clearConnectedAccountAddress() {
    connectedAccountAddress = null;
    _preferencesService.clear();
    safeNotifyListeners();
  }

  void retry() {
    sessionRequestStatus = SessionRequestStatus.none;
    _sessionRequestHash = null;
    _sessionRequestPrivateKey = null;

    challenge = null;
    challengeTouched = false;

    challengeController.clear();

    safeNotifyListeners();
  }

  EthereumAddress? getAccountAddress() {
    final lastAccount = _preferencesService.lastAccount;
    if (lastAccount != null) {
      return EthereumAddress.fromHex(lastAccount);
    }

    final credentials = _secureService.getCredentials();
    if (credentials == null) {
      return null;
    }

    final (account, _) = credentials;

    return account;
  }

  Future<EthereumAddress?> isSessionExpired() async {
    final credentials = _secureService.getCredentials();
    if (credentials == null) {
      return null;
    }

    final (account, privateKey) = credentials;

    final isExpired = await _config.sessionManagerModuleContract.isExpired(
      account,
      privateKey.address,
    );

    if (isExpired) {
      return null;
    }

    return account;
  }

  // state methods here
  Future<void> requestSession(String source) async {
    try {
      sessionRequestStatus = SessionRequestStatus.pending;
      _sessionRequestHash = null;
      safeNotifyListeners();

      String? parsedSource;
      // Validate email format
      if (!_isValidEmail(source)) {
        throw Exception('Invalid email address');
      }
      parsedSource = source;

      final random = Random.secure();
      _sessionRequestPrivateKey = EthPrivateKey.createRandom(random);

      final response = await _sessionService.request(
          _sessionRequestPrivateKey!, parsedSource);

      if (response == null) {
        throw Exception('Failed to request session');
      }

      final sessionRequestTxHash = response.$1;
      _sessionRequestHash = response.$2;

      final salt = generateSessionSalt(parsedSource, 'email');

      final provider = EthereumAddress.fromHex(
        _config.getPrimarySessionManager().providerAddress,
      );

      final twoFAAddress = await _config.twoFAFactoryContract.getAddress(
        provider,
        salt,
      );

      await _secureService.setCredentials(
        twoFAAddress,
        _sessionRequestPrivateKey!,
      );

      sessionRequestStatus = SessionRequestStatus.challenge;
      safeNotifyListeners();
    } catch (e, s) {
      debugPrint('error: $e');
      debugPrint('stack trace: $s');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Error requesting session',
      );
      sessionRequestStatus = SessionRequestStatus.failed;
      safeNotifyListeners();
    }
  }

  Future<EthereumAddress?> confirmSession(String challenge) async {
    try {
      if (_sessionRequestPrivateKey == null) {
        throw Exception('Session request private key not found');
      }

      if (_sessionRequestHash == null) {
        throw Exception('Session request hash not found');
      }

      sessionRequestStatus = SessionRequestStatus.confirming;
      safeNotifyListeners();

      final parsedChallenge = int.parse(challenge);

      final sessionConfirmRequestTxHash = await _sessionService.confirm(
        _sessionRequestPrivateKey!,
        _sessionRequestHash!,
        parsedChallenge,
      );
      if (sessionConfirmRequestTxHash == null) {
        throw Exception('Failed to confirm session');
      }

      sessionRequestStatus = SessionRequestStatus.confirmed;
      safeNotifyListeners();

      _sessionRequestPrivateKey = null;

      final credentials = _secureService.getCredentials();
      if (credentials == null) {
        throw Exception('No credentials found');
      }

      final (account, _) = credentials;

      connectedAccountAddress = account;

      return account;
    } catch (e, s) {
      debugPrint('error: $e');
      debugPrint('stack trace: $s');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Error confirming session',
      );
      sessionRequestStatus = SessionRequestStatus.confirmFailed;
      safeNotifyListeners();

      return null;
    }
  }

  void formatEmail(String email) {
    isValidEmail = _isValidEmail(email);
    touched = true;
    safeNotifyListeners();
  }

  bool _isValidEmail(String email) {
    // Email validation regex
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9]([a-zA-Z0-9._+-]*[a-zA-Z0-9])?@[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?\.[a-zA-Z]{2,}$');

    if (email.isEmpty || email.length > 254) return false;
    if (email.startsWith('.') || email.endsWith('.')) return false;
    if (email.contains('..')) return false;
    if (email.split('@').length != 2) return false;

    final parts = email.split('@');
    if (parts.length != 2) return false;

    final localPart = parts[0];
    final domainPart = parts[1];

    if (localPart.isEmpty) return false;
    if (localPart.startsWith('.') || localPart.endsWith('.')) return false;
    if (localPart.startsWith('-') || localPart.endsWith('-')) return false;
    if (localPart.startsWith('_') || localPart.endsWith('_')) return false;
    if (localPart.startsWith('+') || localPart.endsWith('+')) return false;

    if (domainPart.isEmpty) return false;

    return emailRegex.hasMatch(email);
  }

  void updateChallenge(String? challenge) {
    this.challenge = challenge;
    challengeTouched = true;
    safeNotifyListeners();
  }
}

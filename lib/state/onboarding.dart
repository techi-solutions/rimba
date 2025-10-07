import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:rimba/services/config/config.dart';
import 'package:rimba/services/preferences/preferences.dart';
import 'package:rimba/services/secure/secure.dart';
import 'package:rimba/services/session/email_session_service.dart';
import 'package:rimba/utils/validation.dart';
import 'package:rimba/utils/session_crypto.dart';
import 'package:rimba/services/wallet/wallet.dart';
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
  late EmailSessionService _emailSessionService;
  final Config _config;

  // private variables here
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  TextEditingController get emailController => _emailController;
  TextEditingController get otpController => _otpController;

  EthPrivateKey? _sessionRequestPrivateKey;
  Uint8List? _sessionRequestHash;
  String? _currentEmail;

  // constructor here
  OnboardingState(this._config) {
    connectedAccountAddress = getAccountAddress();
    init();
  }

  Future<void> init() async {
    _emailSessionService = EmailSessionService(_config);
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

  bool emailTouched = false;
  bool otpTouched = false;
  String? otp;
  bool isValidEmail = false;

  SessionRequestStatus sessionRequestStatus = SessionRequestStatus.none;

  void reset() {
    sessionRequestStatus = SessionRequestStatus.none;
    _sessionRequestHash = null;
    _sessionRequestPrivateKey = null;
    _currentEmail = null;

    emailTouched = false;
    isValidEmail = false;
    otpTouched = false;
    otp = null;

    emailController.clear();
    otpController.clear();
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
    _currentEmail = null;

    otp = null;
    otpTouched = false;

    otpController.clear();

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
  Future<void> requestSession(String email) async {
    try {
      sessionRequestStatus = SessionRequestStatus.pending;
      _sessionRequestHash = null;
      safeNotifyListeners();

      // Validate email format
      if (!ValidationUtils.isValidEmail(email)) {
        throw Exception('Invalid email address');
      }

      final random = Random.secure();
      _sessionRequestPrivateKey = EthPrivateKey.createRandom(random);

      final response = await _emailSessionService.request(
          _sessionRequestPrivateKey!, email);

      if (response == null) {
        throw Exception('Failed to request session');
      }

      final sessionRequestTxHash = response.sessionRequestTxHash;
      _sessionRequestHash = response.hash;
      _currentEmail = response.email;

      // Skip blockchain transaction waiting for development mode (mock tx hash)
      bool success = true;
      if (ValidationUtils.isMockTxHash(sessionRequestTxHash)) {
        // This is a mock transaction hash from development mode
        debugPrint('Skipping blockchain transaction waiting for mock tx hash: $sessionRequestTxHash');
      } else {
        // Real transaction hash - wait for it to be mined
        success = await waitForTxSuccess(_config, sessionRequestTxHash);
        if (!success) {
          throw Exception('Failed to wait for session request tx to be mined');
        }
      }

      final salt = SessionCryptoUtils.generateEmailSessionSalt(email, 'email');

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
        reason: 'Error requesting email session',
      );
      sessionRequestStatus = SessionRequestStatus.failed;
      safeNotifyListeners();
    }
  }

  Future<EthereumAddress?> confirmSession(String otp) async {
    try {
      if (_sessionRequestPrivateKey == null) {
        throw Exception('Session request private key not found');
      }

      if (_sessionRequestHash == null) {
        throw Exception('Session request hash not found');
      }

      if (_currentEmail == null) {
        throw Exception('Current email not found');
      }

      sessionRequestStatus = SessionRequestStatus.confirming;
      safeNotifyListeners();

      final sessionConfirmRequestTxHash = await _emailSessionService.confirm(
        _sessionRequestPrivateKey!,
        _sessionRequestHash!,
        _currentEmail!,
        otp,
      );
      
      if (sessionConfirmRequestTxHash == null) {
        throw Exception('Failed to confirm session');
      }

      // Skip blockchain transaction waiting for development mode (mock tx hash)
      bool success = true;
      if (ValidationUtils.isMockTxHash(sessionConfirmRequestTxHash)) {
        // This is a mock transaction hash from development mode
        debugPrint('Skipping blockchain transaction waiting for mock confirm tx hash: $sessionConfirmRequestTxHash');
      } else {
        // Real transaction hash - wait for it to be mined
        success = await waitForTxSuccess(_config, sessionConfirmRequestTxHash);
        if (!success) {
          throw Exception('Failed to wait for session request tx to be mined');
        }
      }

      sessionRequestStatus = SessionRequestStatus.confirmed;
      safeNotifyListeners();

      _sessionRequestPrivateKey = null;
      _currentEmail = null;

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
        reason: 'Error confirming email session',
      );
      sessionRequestStatus = SessionRequestStatus.confirmFailed;
      safeNotifyListeners();

      return null;
    }
  }

  void validateEmail(String email) {
    emailTouched = true;
    isValidEmail = ValidationUtils.isValidEmail(email);
    safeNotifyListeners();
  }

  void updateOTP(String? otp) {
    otpTouched = true;
    this.otp = otp;
    safeNotifyListeners();
  }
}

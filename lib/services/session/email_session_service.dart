import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import 'package:rimba/services/api/api.dart';
import 'package:rimba/services/config/config.dart';
import 'package:rimba/services/otp/otp_service.dart';
import 'package:rimba/services/session/config/session_config.dart';
import 'package:rimba/services/session/exceptions/session_exceptions.dart';
import 'package:rimba/models/session_request.dart';
import 'package:rimba/utils/session_crypto.dart';
import 'package:rimba/utils/validation.dart';

/// Service for managing email-based session authentication
class EmailSessionService {
  final EthereumAddress _provider;
  final OTPService _otpService;
  final APIService _apiService;

  EmailSessionService(Config config)
      : _provider = EthereumAddress.fromHex(
          config.getPrimarySessionManager().providerAddress,
        ),
        _otpService = OTPService(),
        _apiService = APIService(baseURL: SessionConfig.dashboardApiBaseUrl);

  /// Validate email format
  bool isValidEmail(String email) => ValidationUtils.isValidEmail(email);

  /// Creates a session request and sends OTP via email
  Future<SessionResponse?> request(
    EthPrivateKey privateKey,
    String email,
  ) async {
    try {
      if (!isValidEmail(email)) {
        throw SessionRequestException('Invalid email address format');
      }

      final sessionOwner = privateKey.address.hexEip55;
      final expiry = SessionCryptoUtils.generateSessionExpiry();
      final salt = SessionCryptoUtils.generateEmailSessionSalt(
        email,
        SessionConfig.emailSessionType,
      );
      final hash = SessionCryptoUtils.generateEmailSessionRequestHash(
        _provider.hexEip55,
        sessionOwner,
        salt,
        expiry,
      );

      // Try backend API first, fallback to mock if it fails
      final sessionRequestTxHash = await _requestSessionFromBackend(
        privateKey,
        email,
        hash,
        expiry,
      );

      // Send OTP email
      final otpSent = await _otpService.sendOTPAction(email: email);
      if (!otpSent) {
        throw SessionRequestException('Failed to send OTP email');
      }

      return SessionResponse(
        sessionRequestTxHash: sessionRequestTxHash,
        hash: hash,
        email: email,
      );
    } on SessionRequestException {
      rethrow;
    } catch (e, s) {
      debugPrint('Failed to create email session request: $e');
      debugPrint('Stack trace: $s');
      return null;
    }
  }

  /// Confirms a session with email OTP
  Future<String?> confirm(
    EthPrivateKey privateKey,
    Uint8List sessionRequestHash,
    String email,
    String otp,
  ) async {
    try {
      // Verify OTP first
      final isValidOTP = await _otpService.verifyOTP(source: email, code: otp);
      if (!isValidOTP) {
        throw InvalidChallengeException('Invalid or expired OTP');
      }

      final sessionOwner = privateKey.address.hexEip55;
      final challenge = SessionCryptoUtils.generateChallengeFromOTP(otp);
      final confirmationHash = SessionCryptoUtils.generateConfirmationHash(
        sessionRequestHash,
        challenge,
      );

      // Sign the confirmation hash
      final signature = privateKey.signPersonalMessageToUint8List(confirmationHash);
      final signatureHex = bytesToHex(signature, include0x: true);

      // Try backend API first, fallback to mock if it fails
      final sessionConfirmTxHash = await _confirmSessionWithBackend(
        sessionOwner,
        sessionRequestHash,
        challenge,
        signatureHex,
      );

      // Delete the OTP after successful confirmation
      await _otpService.deleteOTP(email);
      debugPrint('OTP deleted after successful confirmation for: $email');

      return sessionConfirmTxHash;
    } on InvalidChallengeException {
      rethrow;
    } catch (e, s) {
      debugPrint('Failed to confirm email session: $e');
      debugPrint('Stack trace: $s');
      return null;
    }
  }

  /// Request session from backend API with fallback to mock
  Future<String> _requestSessionFromBackend(
    EthPrivateKey privateKey,
    String email,
    Uint8List hash,
    int expiry,
  ) async {
    if (!SessionConfig.hasBackendApi) {
      final mockTxHash = SessionCryptoUtils.generateMockTxHash();
      debugPrint('Using mock sessionRequestTxHash (no backend configured): $mockTxHash');
      return mockTxHash;
    }

    debugPrint('DASHBOARD_API_BASE_URL_BREVO: "${SessionConfig.dashboardApiBaseUrl}"');
    debugPrint('Using backend API for session request: ${SessionConfig.dashboardApiBaseUrl}${SessionConfig.sessionRequestEndpoint}');

    try {
      final signature = privateKey.signPersonalMessageToUint8List(hash);
      final signatureHex = bytesToHex(signature, include0x: true);

      final requestData = EmailSessionRequest(
        provider: _provider.hexEip55,
        owner: privateKey.address.hexEip55,
        source: email,
        type: SessionConfig.emailSessionType,
        expiry: expiry,
        signature: signatureHex,
      );

      debugPrint('Making API call to: ${_apiService.baseURL}${SessionConfig.sessionRequestEndpoint}');
      debugPrint('Request body: ${jsonEncode(requestData.toJson())}');

      final response = await _apiService.post(
        url: SessionConfig.sessionRequestEndpoint,
        body: requestData.toJson(),
      );

      debugPrint('API Response: $response');
      final apiTxHash = response['sessionRequestTxHash'] as String?;
      
      if (!ValidationUtils.isValidTxHash(apiTxHash)) {
        throw InvalidApiResponseException(
          'Invalid sessionRequestTxHash in API response',
          response,
        );
      }

      debugPrint('Received sessionRequestTxHash from backend: $apiTxHash');
      return apiTxHash!;
    } catch (e) {
      debugPrint('Backend API call failed: $e');
      debugPrint('Falling back to development mode');
      
      final fallbackTxHash = SessionCryptoUtils.generateMockTxHash();
      debugPrint('Using fallback mock sessionRequestTxHash: $fallbackTxHash');
      return fallbackTxHash;
    }
  }

  /// Confirm session with backend API with fallback to mock
  Future<String> _confirmSessionWithBackend(
    String sessionOwner,
    Uint8List sessionRequestHash,
    int challenge,
    String signatureHex,
  ) async {
    if (!SessionConfig.hasBackendApi) {
      final mockTxHash = SessionCryptoUtils.generateMockTxHash(offset: 1);
      debugPrint('Using mock sessionConfirmTxHash (no backend configured): $mockTxHash');
      return mockTxHash;
    }

    debugPrint('DASHBOARD_API_BASE_URL_BREVO: "${SessionConfig.dashboardApiBaseUrl}"');
    debugPrint('Using backend API for session confirmation: ${SessionConfig.dashboardApiBaseUrl}${SessionConfig.sessionConfirmEndpoint}');

    try {
      final confirmationData = EmailSessionConfirmation(
        provider: _provider.hexEip55,
        owner: sessionOwner,
        hash: bytesToHex(sessionRequestHash, include0x: true),
        challenge: challenge,
        signature: signatureHex,
      );

      final response = await _apiService.post(
        url: SessionConfig.sessionConfirmEndpoint,
        body: confirmationData.toJson(),
      );

      final apiConfirmTxHash = response['sessionConfirmTxHash'] as String?;
      
      if (!ValidationUtils.isValidTxHash(apiConfirmTxHash)) {
        throw InvalidApiResponseException(
          'Invalid sessionConfirmTxHash in API response',
          response,
        );
      }

      debugPrint('Received sessionConfirmTxHash from backend: $apiConfirmTxHash');
      return apiConfirmTxHash!;
    } catch (e) {
      debugPrint('Backend API confirmation failed: $e');
      debugPrint('Falling back to development mode');
      
      final fallbackTxHash = SessionCryptoUtils.generateMockTxHash(offset: 1);
      debugPrint('Using fallback mock sessionConfirmTxHash: $fallbackTxHash');
      return fallbackTxHash;
    }
  }
}

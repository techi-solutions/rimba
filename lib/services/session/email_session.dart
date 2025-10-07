import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rimba/services/api/api.dart';
import 'package:rimba/services/config/config.dart';
import 'package:rimba/services/otp/otp_service.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

/// Generate salt for session based on email and type
Uint8List generateEmailSessionSalt(String email, String sessionType) {
  final combined = '$email:$sessionType';
  return keccak256(Uint8List.fromList(combined.codeUnits));
}

/// Generate hash for session request
Uint8List generateEmailSessionRequestHash(
  String provider,
  String sessionOwner,
  Uint8List salt,
  int expiry,
) {
  final providerBytes = hexToBytes(provider.replaceFirst('0x', ''));
  final sessionOwnerBytes = hexToBytes(sessionOwner.replaceFirst('0x', ''));
  final expiryBytes = BigInt.from(expiry).toRadixString(16).padLeft(64, '0');
  final expiryByteArray = hexToBytes(expiryBytes);

  final packed = <int>[];
  packed.addAll(providerBytes);
  packed.addAll(sessionOwnerBytes);
  packed.addAll(salt);
  packed.addAll(expiryByteArray);

  return keccak256(Uint8List.fromList(packed));
}

class EmailSessionService {
  final EthereumAddress _provider;
  final OTPService _otpService = OTPService();

  EmailSessionService(Config config)
      : _provider = EthereumAddress.fromHex(
          config.getPrimarySessionManager().providerAddress,
        );

  final APIService _apiService = APIService(
    baseURL: dotenv.env['DASHBOARD_API_BASE_URL'] ?? '',
  );

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Creates a session request and sends OTP via email
  Future<(String, Uint8List, String)?> request(
    EthPrivateKey privateKey,
    String email,
  ) async {
    try {
      final sessionOwner = privateKey.address.hexEip55;
      final sessionType = 'email';

      // Generate expiry timestamp (current time + 365 days in seconds)
      final expiry = (DateTime.now().millisecondsSinceEpoch ~/ 1000) +
          (60 * 60 * 24 * 365); // 365 days

      // Generate salt
      final salt = generateEmailSessionSalt(email, sessionType);

      // Generate hash
      final hash = generateEmailSessionRequestHash(
        _provider.hexEip55,
        sessionOwner,
        salt,
        expiry,
      );

      // Sign the hash
      final signature = privateKey.signPersonalMessageToUint8List(hash);
      final signatureHex = bytesToHex(signature, include0x: true);

      // Create request body
      final requestBody = {
        'provider': _provider.hexEip55,
        'owner': sessionOwner,
        'source': email,
        'type': sessionType,
        'expiry': expiry,
        'signature': signatureHex,
      };

      // Send POST request to create session
      final response = await _apiService.post(
        url: '/app/session',
        body: requestBody,
      );

      final sessionRequestTxHash = response['sessionRequestTxHash'] as String;

      final otpSent = await _otpService.sendOTPAction(email: email);
      if (!otpSent) {
        throw Exception('Failed to send OTP email');
      }

      return (sessionRequestTxHash, hash, email);
    } on BadRequestException {
      throw InvalidChallengeException();
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
      final isValidOTP = await _otpService.verifyOTP(source: email, code: otp);
      if (!isValidOTP) {
        throw Exception('Invalid or expired OTP');
      }

      final sessionOwner = privateKey.address.hexEip55;

      // Generate challenge hash from OTP (similar to SMS challenge)
      final challengeHash = keccak256(
        Uint8List.fromList(otp.codeUnits),
      );
      final challenge = BigInt.parse(
        bytesToHex(challengeHash.take(4).toList(), include0x: false),
        radix: 16,
      ).toInt();

      // Create confirmation hash
      final challengeBytes = Uint8List.fromList(
          BigInt.from(challenge).toRadixString(16).padLeft(64, '0').codeUnits);
      final confirmationHash = keccak256(Uint8List.fromList([
        ...sessionRequestHash,
        ...challengeBytes,
      ]));

      // Sign the confirmation hash
      final signature =
          privateKey.signPersonalMessageToUint8List(confirmationHash);
      final signatureHex = bytesToHex(signature, include0x: true);

      // Create confirmation request body
      final requestBody = {
        'provider': _provider.hexEip55,
        'owner': sessionOwner,
        'hash': bytesToHex(sessionRequestHash, include0x: true),
        'challenge': challenge,
        'signature': signatureHex,
      };

      // Send POST request to confirm session
      final response = await _apiService.post(
        url: '/app/session/confirm',
        body: requestBody,
      );

      return response['sessionConfirmTxHash'] as String;
    } on BadRequestException {
      throw InvalidChallengeException();
    } catch (e, s) {
      debugPrint('Failed to confirm email session: $e');
      debugPrint('Stack trace: $s');
      return null;
    }
  }
}

class InvalidChallengeException implements Exception {
  @override
  String toString() => 'Invalid challenge provided';
}

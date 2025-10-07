import 'dart:typed_data';
import 'package:web3dart/crypto.dart';

/// Utility functions for session cryptographic operations
class SessionCryptoUtils {
  /// Generate salt for session based on email and type
  static Uint8List generateEmailSessionSalt(String email, String sessionType) {
    final combined = '$email:$sessionType';
    return keccak256(Uint8List.fromList(combined.codeUnits));
  }

  /// Generate hash for session request
  static Uint8List generateEmailSessionRequestHash(
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

  /// Generate challenge hash from OTP
  static int generateChallengeFromOTP(String otp) {
    final challengeHash = keccak256(Uint8List.fromList(otp.codeUnits));
    return BigInt.parse(
      bytesToHex(challengeHash.take(4).toList(), include0x: false),
      radix: 16,
    ).toInt();
  }

  /// Generate confirmation hash from session request hash and challenge
  static Uint8List generateConfirmationHash(
    Uint8List sessionRequestHash,
    int challenge,
  ) {
    final challengeBytes = Uint8List.fromList(
      BigInt.from(challenge).toRadixString(16).padLeft(64, '0').codeUnits,
    );
    
    return keccak256(Uint8List.fromList([
      ...sessionRequestHash,
      ...challengeBytes,
    ]));
  }

  /// Generate session expiry timestamp (365 days from now)
  static int generateSessionExpiry() {
    return (DateTime.now().millisecondsSinceEpoch ~/ 1000) +
        (60 * 60 * 24 * 365); // 365 days
  }

  /// Generate mock transaction hash for development
  static String generateMockTxHash({int offset = 0}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch + offset;
    return '0x${timestamp.toRadixString(16).padLeft(64, '0')}';
  }
}


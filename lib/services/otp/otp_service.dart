import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:rimba/models/otp.dart';
import 'package:rimba/services/db/app/otps.dart';
import 'package:rimba/services/db/app/db.dart';
import 'package:rimba/services/brevo/brevo.dart';

class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  final AppDBService _appDBService = AppDBService();
  final BrevoEmailService _brevoService = BrevoEmailService();

  OTPsTable get _otpTable => _appDBService.otps;

  String generateOTP() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Save OTP to database
  Future<void> saveOTP({
    required String source,
    required String sourceType,
    required String code,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(
      const Duration(minutes: 30),
    );

    await _otpTable.saveOTP(
      source: source,
      sourceType: sourceType,
      code: code,
      createdAt: now,
      expiresAt: expiresAt,
    );

    debugPrint('OTP saved for $sourceType: $source');
  }

  // Verify OTP from database
  Future<bool> verifyOTP({
    required String source,
    required String code,
  }) async {
    return await _otpTable.verifyOTP(source, code);
  }

  // Send OTP via email using Brevo and save to database
  Future<bool> sendOTPAction({required String email}) async {
    try {
      final otp = generateOTP();

      // Send email via Brevo
      final emailSent = await _brevoService.sendOtpEmailWithCode(
        email: email,
        otp: otp,
      );

      if (!emailSent) {
        throw Exception('Failed to send OTP email');
      }

      // Save to database
      await saveOTP(
        source: email,
        sourceType: 'email',
        code: otp,
      );

      debugPrint('OTP sent and saved successfully for email: $email');
      return true;
    } catch (e, s) {
      debugPrint('Error in sendOTPAction: $e');
      debugPrint('Stack trace: $s');
      return false;
    }
  }

  // Clean up expired OTPs
  Future<void> cleanupExpiredOTPs() async {
    await _otpTable.cleanupExpiredOTPs();
  }

  // Get OTP for debugging purposes
  Future<OTP?> getOTP(String source) async {
    return await _otpTable.getOTP(source);
  }

  // Delete specific OTP
  Future<void> deleteOTP(String source) async {
    await _otpTable.deleteOTP(source);
  }
}

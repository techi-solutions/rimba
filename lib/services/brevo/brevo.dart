import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BrevoEmailService {
  static final BrevoEmailService _instance = BrevoEmailService._internal();
  factory BrevoEmailService() => _instance;
  BrevoEmailService._internal();

  // Store OTPs temporarily (in production, use secure storage or backend)
  final Map<String, String> _otpStorage = {};
  final Map<String, DateTime> _otpExpiry = {};

  String get _apiKey => dotenv.env['BREVO_API_KEY'] ?? '';
  String get _senderEmail => dotenv.env['BREVO_SENDER_EMAIL'] ?? '';
  String get _senderName => dotenv.env['BREVO_SENDER_NAME'] ?? 'Your App';
  String get _appUrl => dotenv.env['APP_URL'] ?? '';

  void _validateEnvironmentVariables() {
    if (_apiKey.isEmpty || _senderEmail.isEmpty || _senderName.isEmpty) {
      throw Exception(
          'Cannot send email: Missing required environment variables (BREVO_API_KEY, BREVO_SENDER_EMAIL, BREVO_SENDER_NAME)');
    }
  }

  /// Generate a random 6-digit OTP
  String _generateOTP() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<bool> sendOtpEmail({required String email}) async {
    try {
      _validateEnvironmentVariables();

      final otp = _generateOTP();

      _otpStorage[email] = otp;
      _otpExpiry[email] = DateTime.now().add(const Duration(minutes: 5));

      return await _sendTemplateEmail(
        email: email,
        templateId: 1,
        subject: 'Dashboard - Login Code',
        params: {'OTP': otp},
      );
    } catch (e, s) {
      debugPrint('Error sending OTP email: $e');
      debugPrint('Stack trace: $s');
      return false;
    }
  }

  Future<bool> sendOtpEmailWithCode({
    required String email,
    required String otp,
  }) async {
    try {
      _validateEnvironmentVariables();

      return await _sendTemplateEmail(
        email: email,
        templateId: 1,
        subject: 'Dashboard - Login Code',
        params: {'OTP': otp},
      );
    } catch (e, s) {
      debugPrint('Error sending OTP email with code: $e');
      debugPrint('Stack trace: $s');
      return false;
    }
  }

  Future<bool> sendOTP(String email) async {
    return await sendOtpEmail(email: email);
  }

  Future<bool> sendCommunityInvitationEmail({
    required String email,
    required String communityAlias,
    required String communityName,
  }) async {
    try {
      _validateEnvironmentVariables();

      if (_appUrl.isEmpty) {
        throw Exception(
            'Cannot send community invitation: Missing APP_URL environment variable');
      }

      final otp = _generateOTP();

      _otpStorage[email] = otp;
      _otpExpiry[email] = DateTime.now().add(const Duration(minutes: 5));

      final loginLink =
          '$_appUrl/login?auto_signin=true&email=$email&code=$otp&alias=$communityAlias';

      return await _sendTemplateEmail(
        email: email,
        templateId: 2,
        subject: '$communityName - Invitation to join',
        params: {
          'COMMUNITY_NAME': communityName,
          'LOGIN_LINK': loginLink,
        },
      );
    } catch (e, s) {
      debugPrint('Error sending community invitation email: $e');
      debugPrint('Stack trace: $s');
      return false;
    }
  }

  Future<bool> _sendTemplateEmail({
    required String email,
    required int templateId,
    required String subject,
    required Map<String, String> params,
  }) async {
    try {
      final url = Uri.parse('https://api.brevo.com/v3/smtp/email');

      final payload = {
        'sender': {
          'email': _senderEmail,
          'name': _senderName,
        },
        'templateId': templateId,
        'subject': subject,
        'params': params,
        'messageVersions': [
          {
            'to': [
              {'email': email}
            ]
          }
        ]
      };

      final response = await http.post(
        url,
        headers: {
          'api-key': _apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        debugPrint(
            'Template email sent successfully to $email (Template ID: $templateId)');
        return true;
      } else {
        debugPrint(
            'Failed to send template email: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, s) {
      debugPrint('Error sending template email: $e');
      debugPrint('Stack trace: $s');
      return false;
    }
  }

  bool verifyOTP(String email, String enteredOTP) {
    try {
      final storedOTP = _otpStorage[email];
      final expiry = _otpExpiry[email];

      if (storedOTP == null || expiry == null) {
        return false;
      }

      if (DateTime.now().isAfter(expiry)) {
        _cleanupOTP(email);
        return false;
      }

      final isValid = storedOTP == enteredOTP;

      if (isValid) {
        _cleanupOTP(email);
      } else {
        debugPrint('Invalid OTP for email: $email');
      }

      return isValid;
    } catch (e, s) {
      debugPrint('Error verifying OTP: $e');
      debugPrint('Stack trace: $s');
      return false;
    }
  }

  /// Clean up stored OTP data
  void _cleanupOTP(String email) {
    _otpStorage.remove(email);
    _otpExpiry.remove(email);
  }

  void cleanupExpiredOTPs() {
    final now = DateTime.now();
    final expiredEmails = <String>[];

    for (final entry in _otpExpiry.entries) {
      if (now.isAfter(entry.value)) {
        expiredEmails.add(entry.key);
      }
    }

    for (final email in expiredEmails) {
      _cleanupOTP(email);
    }
  }
}

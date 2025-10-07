import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration class for session management
class SessionConfig {
  /// Get the dashboard API base URL from environment
  static String get dashboardApiBaseUrl => 
      dotenv.env['DASHBOARD_API_BASE_URL_BREVO'] ?? '';

  /// Get the app alias from environment (fallback to 'rimba')
  static String get appAlias => 
      dotenv.env['APP_ALIAS'] ?? 'rimba';

  /// Check if backend API is configured
  static bool get hasBackendApi => dashboardApiBaseUrl.isNotEmpty;

  /// Get session request endpoint
  static String get sessionRequestEndpoint => '/app/$appAlias/session';

  /// Get session confirmation endpoint  
  static String get sessionConfirmEndpoint => '/app/$appAlias/session/confirm';

  /// Session type for email sessions
  static const String emailSessionType = 'email';

  /// Default session expiry duration (365 days in seconds)
  static const int sessionExpiryDuration = 60 * 60 * 24 * 365;
}


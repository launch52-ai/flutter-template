// Template: App Constants
//
// Location: lib/core/constants/app_constants.dart
//
// Usage:
// 1. Copy to target location
// 2. Replace placeholders with values from /init

/// App-wide constants.
/// Populated from /init skill configuration.
abstract final class AppConstants {
  // App info
  static const String appName = '{APP_NAME}';
  static const String appDescription = '{APP_DESCRIPTION}';
  static const String bundleId = '{BUNDLE_ID}';

  // API
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Pagination
  static const int defaultPageSize = 20;

  // Cache
  static const Duration cacheExpiry = Duration(hours: 1);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int otpLength = 6;
  static const Duration otpExpiry = Duration(minutes: 5);

  // Rate limiting
  static const Duration otpResendCooldown = Duration(seconds: 60);
  static const int maxOtpAttempts = 5;
}

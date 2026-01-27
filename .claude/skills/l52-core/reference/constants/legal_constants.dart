// Template: Legal URLs Constants
//
// Location: lib/core/constants/legal_constants.dart
//
// Usage:
// 1. Copy to target location
// 2. Replace placeholder URLs with actual URLs before release
// 3. /release check will fail if URLs contain 'example.com' or 'yourapp.com'

/// Legal document URLs.
///
/// IMPORTANT: Update these URLs before app store submission.
/// The release check script will verify these are not placeholders.
abstract final class LegalConstants {
  /// Privacy Policy URL.
  ///
  /// Required for App Store and Play Store submission.
  /// Must be accessible via web browser.
  static const String privacyPolicyUrl = 'https://yourapp.com/privacy';

  /// Terms of Service URL.
  ///
  /// Recommended for all apps, required if you have user accounts.
  static const String termsOfServiceUrl = 'https://yourapp.com/terms';

  /// Support email for legal inquiries.
  static const String supportEmail = 'support@yourapp.com';
}

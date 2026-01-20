// Template: Social login related
//
// Location: lib/features/{feature}/data/utils/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Template: App Constants Addition for Social Login
//
// Location: lib/core/constants/app_constants.dart
//
// Add the deepLinkScheme constant to your existing AppConstants class.
// This is used for OAuth callback deep links on Android.

final class AppConstants {
  AppConstants._();

  // ... existing constants ...

  /// Bundle ID used as deep link scheme for OAuth callbacks.
  ///
  /// Used by Apple Sign-In on Android to redirect back to the app
  /// after browser authentication.
  ///
  /// Must match:
  /// - AndroidManifest.xml intent-filter scheme
  /// - Supabase redirect URL configuration
  /// - Apple Service ID return URL
  static const String bundleId = 'com.company.myapp'; // TODO: Update
  static const String deepLinkScheme = bundleId;
}

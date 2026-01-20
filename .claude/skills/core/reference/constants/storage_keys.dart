// Template: Storage Keys
//
// Location: lib/core/constants/storage_keys.dart
//
// Usage:
// 1. Copy to target location
// 2. Add/remove keys based on app requirements
// 3. Use with SecureStorageService and SharedPrefsService

/// Keys for SecureStorage (sensitive data).
/// Use for tokens, PII, credentials.
abstract final class SecureStorageKeys {
  // Auth
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String idToken = 'id_token';

  // User PII
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String userPhone = 'user_phone';

  // Credentials
  static const String apiKey = 'api_key';
  static const String deviceId = 'device_id';
}

/// Keys for SharedPreferences (non-sensitive data).
/// Use for flags, settings, cached state.
abstract final class PrefsKeys {
  // Onboarding
  static const String hasCompletedOnboarding = 'has_completed_onboarding';
  static const String onboardingVersion = 'onboarding_version';

  // Auth state
  static const String hasUser = 'has_user';
  static const String lastLoginTime = 'last_login_time';

  // App settings
  static const String themeMode = 'theme_mode'; // 'light', 'dark', 'system'
  static const String locale = 'locale'; // 'en', 'es', etc.
  static const String notificationsEnabled = 'notifications_enabled';

  // Feature flags
  static const String hasSeenWhatsNew = 'has_seen_whats_new';
  static const String lastVersionSeen = 'last_version_seen';

  // Cache timestamps
  static const String lastSyncTime = 'last_sync_time';
  static const String cacheExpiry = 'cache_expiry';
}

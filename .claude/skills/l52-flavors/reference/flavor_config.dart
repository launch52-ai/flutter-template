// Template: flavor_config.dart
// Location: lib/core/config/flavor_config.dart
//
// Compile-time environment configuration for multi-flavor apps.
// Values are set via --dart-define-from-file=.env.{flavor}
//
// Usage:
//   flutter run --flavor dev --dart-define-from-file=.env.dev
//   flutter run --flavor prod --dart-define-from-file=.env.prod
//
// NOTE: Debug/mock flags (useMockAuth, logNetworkRequests, etc.) should stay
// in lib/core/constants/debug_constants.dart (from /core skill).
// This class handles FLAVOR IDENTIFICATION and ENVIRONMENT-SPECIFIC CONFIG only.

/// Represents the app's environment flavor.
enum Flavor {
  dev,
  staging,
  prod;

  /// Parse flavor from string, defaulting to dev.
  static Flavor fromString(String value) {
    return Flavor.values.firstWhere(
      (f) => f.name == value.toLowerCase(),
      orElse: () => Flavor.dev,
    );
  }
}

/// Compile-time configuration that varies by environment.
///
/// All values are set at build time via --dart-define-from-file.
/// This ensures secrets are not bundled in the source code.
///
/// Example:
/// ```dart
/// if (FlavorConfig.isDev) {
///   debugPrint('Running in development mode');
/// }
///
/// final apiUrl = FlavorConfig.apiUrl;
/// ```
final class FlavorConfig {
  FlavorConfig._();

  // ===========================================================================
  // FLAVOR IDENTIFICATION
  // ===========================================================================

  /// Current flavor name (dev, staging, prod).
  static const String flavorName = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// Current flavor enum value.
  static Flavor get flavor => Flavor.fromString(flavorName);

  /// App display name (varies per flavor).
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'My App',
  );

  // ===========================================================================
  // FLAVOR CHECKS
  // ===========================================================================

  /// True if running in development mode.
  static bool get isDev => flavor == Flavor.dev;

  /// True if running in staging mode.
  static bool get isStaging => flavor == Flavor.staging;

  /// True if running in production mode.
  static bool get isProd => flavor == Flavor.prod;

  /// True if NOT in production (dev or staging).
  static bool get isDebugEnvironment => !isProd;

  // ===========================================================================
  // API CONFIGURATION
  // ===========================================================================

  /// Base URL for API requests.
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.example.com',
  );

  // ===========================================================================
  // SUPABASE CONFIGURATION
  // ===========================================================================

  /// Supabase project URL.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase anonymous key.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// True if Supabase is configured.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ===========================================================================
  // GOOGLE SIGN-IN CONFIGURATION
  // ===========================================================================

  /// Google Web Client ID (used for Android serverClientId).
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// Google iOS Client ID.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  // ===========================================================================
  // DEBUG INFO
  // ===========================================================================

  /// Print all configuration values (for debugging).
  /// Only prints in non-production environments.
  static void printConfig() {
    if (isProd) return;

    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════════');
    // ignore: avoid_print
    print('  FlavorConfig');
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════════');
    // ignore: avoid_print
    print('  Flavor:          $flavorName');
    // ignore: avoid_print
    print('  App Name:        $appName');
    // ignore: avoid_print
    print('  API URL:         $apiUrl');
    // ignore: avoid_print
    print('  Supabase URL:    ${supabaseUrl.isEmpty ? "(not set)" : supabaseUrl}');
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════════');
  }
}

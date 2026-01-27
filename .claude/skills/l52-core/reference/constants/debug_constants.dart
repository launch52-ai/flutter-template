// Template: Debug Constants
//
// Location: lib/core/constants/debug_constants.dart
//
// Features:
// - Compile-time debug flags
// - Runtime-toggleable mock mode with SharedPreferences persistence
// - Works with DebugMenu widget

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug feature flags.
/// Set to false before releasing to production.
final class DebugConstants {
  DebugConstants._();

  static const String _mockModeKey = 'debug_mock_mode_enabled';

  /// Show debug buttons and options.
  /// Set to false for production builds.
  static const bool showDebugOptions = kDebugMode;

  /// Enable verbose logging.
  static const bool verboseLogging = kDebugMode;

  /// Show performance overlays.
  static const bool showPerformanceOverlay = false;

  /// Log network requests.
  static const bool logNetworkRequests = kDebugMode;

  /// Log state changes.
  static const bool logStateChanges = kDebugMode;

  /// Artificial delay for loading states (ms).
  /// Set to 0 in production.
  static const int artificialDelay = kDebugMode ? 500 : 0;

  /// Mock mode - bypasses real API calls for all features.
  /// Runtime toggleable via debug menu, persists across restarts.
  static final ValueNotifier<bool> mockModeEnabled = ValueNotifier(false);

  /// Initialize debug settings from SharedPreferences.
  /// Call this in main() after WidgetsFlutterBinding.ensureInitialized().
  static Future<void> init(SharedPreferences prefs) async {
    mockModeEnabled.value = prefs.getBool(_mockModeKey) ?? false;
  }

  /// Set mock mode and persist to SharedPreferences.
  static Future<void> setMockMode(
    SharedPreferences prefs,
    bool enabled,
  ) async {
    mockModeEnabled.value = enabled;
    await prefs.setBool(_mockModeKey, enabled);
  }
}

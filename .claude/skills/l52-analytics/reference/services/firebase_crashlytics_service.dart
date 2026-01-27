// Template: Firebase Crashlytics implementation
//
// Location: lib/core/services/firebase_crashlytics_service.dart
//
// Dependencies:
//   firebase_crashlytics: ^4.3.0
//
// Usage:
// 1. Copy to target location
// 2. Import in main.dart
// 3. Call initialize() after Firebase.initializeApp()
// 4. Set up FlutterError.onError and PlatformDispatcher.instance.onError

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'error_tracking_service.dart';

/// Firebase Crashlytics implementation of [ErrorTrackingService].
final class FirebaseCrashlyticsService implements ErrorTrackingService {
  FirebaseCrashlyticsService._();

  static final instance = FirebaseCrashlyticsService._();

  FirebaseCrashlytics? _crashlytics;
  bool _enabled = true;

  @override
  Future<void> initialize() async {
    _crashlytics = FirebaseCrashlytics.instance;

    // Disable in debug mode to avoid noise
    if (kDebugMode) {
      await _crashlytics!.setCrashlyticsCollectionEnabled(false);
      _enabled = false;
    } else {
      await _crashlytics!.setCrashlyticsCollectionEnabled(true);
    }
  }

  @override
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (_crashlytics == null || !_enabled) return;

    await _crashlytics!.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (_crashlytics == null || !_enabled) return;

    await _crashlytics!.recordFlutterFatalError(details);
  }

  @override
  Future<void> addBreadcrumb(String message, {Map<String, dynamic>? data}) async {
    if (_crashlytics == null || !_enabled) return;

    // Firebase Crashlytics uses log() for breadcrumbs
    await _crashlytics!.log(message);
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    if (_crashlytics == null) return;

    await _crashlytics!.setCustomKey(key, value);
  }

  @override
  Future<void> setUserIdentifier(String? identifier) async {
    if (_crashlytics == null) return;

    await _crashlytics!.setUserIdentifier(identifier ?? '');
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (_crashlytics == null) return;

    await _crashlytics!.setCrashlyticsCollectionEnabled(enabled);
    _enabled = enabled;
  }

  @override
  Future<bool> isEnabled() async => _enabled;

  /// Force a test crash.
  ///
  /// **Only use in debug builds for testing!**
  void crash() {
    assert(kDebugMode, 'crash() should only be called in debug mode');
    _crashlytics?.crash();
  }
}

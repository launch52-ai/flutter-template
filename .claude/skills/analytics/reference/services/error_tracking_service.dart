// Template: Provider-agnostic error tracking interface
//
// Location: lib/core/services/error_tracking_service.dart
//
// Usage:
// 1. Copy to target location
// 2. Use the appropriate implementation (Firebase, Sentry)
// 3. Initialize in main.dart before runApp

import 'package:flutter/foundation.dart';

/// Provider-agnostic interface for error tracking.
///
/// Implementations:
/// - [FirebaseErrorTrackingService] - Firebase Crashlytics
/// - [SentryErrorTrackingService] - Sentry
abstract interface class ErrorTrackingService {
  /// Initialize the error tracking service.
  Future<void> initialize();

  /// Record a non-fatal error.
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// Record a Flutter error.
  Future<void> recordFlutterError(FlutterErrorDetails details);

  /// Add a breadcrumb/log message for crash context.
  Future<void> addBreadcrumb(String message, {Map<String, dynamic>? data});

  /// Set a custom key-value for crash context.
  Future<void> setCustomKey(String key, Object value);

  /// Set the user identifier.
  Future<void> setUserIdentifier(String? identifier);

  /// Enable or disable error collection.
  Future<void> setEnabled(bool enabled);

  /// Check if collection is enabled.
  Future<bool> isEnabled();
}

/// Provider-agnostic interface for product analytics.
///
/// Implementations:
/// - [FirebaseAnalyticsService] - Firebase Analytics
/// - [PostHogAnalyticsService] - PostHog
/// - [MixpanelAnalyticsService] - Mixpanel
abstract interface class ProductAnalyticsService {
  /// Initialize the analytics service.
  Future<void> initialize();

  /// Log a custom event.
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  });

  /// Log a screen view.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  });

  /// Set a user property.
  Future<void> setUserProperty({
    required String name,
    required String? value,
  });

  /// Set the user ID.
  Future<void> setUserId(String? userId);

  /// Enable or disable analytics collection.
  Future<void> setEnabled(bool enabled);

  /// Check if collection is enabled.
  Future<bool> isEnabled();

  /// Reset analytics data.
  Future<void> reset();
}

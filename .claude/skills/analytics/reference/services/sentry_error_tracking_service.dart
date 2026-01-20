// Template: Sentry error tracking implementation
//
// Location: lib/core/services/sentry_error_tracking_service.dart
//
// Dependencies:
//   sentry_flutter: ^8.12.0
//
// Usage:
// 1. Copy to target location
// 2. Call SentryFlutter.init() in main.dart (see implementation guide)
// 3. Use this service for error tracking

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'error_tracking_service.dart';

/// Sentry implementation of [ErrorTrackingService].
///
/// Sentry provides superior error tracking compared to Crashlytics:
/// - Better stack traces and debugging info
/// - Performance monitoring
/// - Release health tracking
/// - Better grouping of similar errors
final class SentryErrorTrackingService implements ErrorTrackingService {
  SentryErrorTrackingService._();

  static final instance = SentryErrorTrackingService._();

  bool _enabled = true;

  @override
  Future<void> initialize() async {
    // Sentry initialization happens in main.dart via SentryFlutter.init()
    // This is just for interface compliance
    _enabled = !kDebugMode;
  }

  @override
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (!_enabled) return;

    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: reason != null ? Hint.withMap({'reason': reason}) : null,
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!_enabled) return;

    await Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
      hint: Hint.withMap({
        'library': details.library,
        'context': details.context?.toString(),
      }),
    );
  }

  @override
  Future<void> addBreadcrumb(String message, {Map<String, dynamic>? data}) async {
    if (!_enabled) return;

    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        data: data,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    Sentry.configureScope((scope) {
      scope.setTag(key, value.toString());
    });
  }

  @override
  Future<void> setUserIdentifier(String? identifier) async {
    Sentry.configureScope((scope) {
      if (identifier != null) {
        scope.setUser(SentryUser(id: identifier));
      } else {
        scope.setUser(null);
      }
    });
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    // Note: Sentry doesn't have a direct enable/disable at runtime
    // You'd need to check _enabled before each operation
  }

  @override
  Future<bool> isEnabled() async => _enabled;

  // Sentry-specific methods

  /// Set user information for better error context.
  void setUser({
    String? id,
    String? email,
    String? username,
    Map<String, String>? data,
  }) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: id,
        email: email,
        username: username,
        data: data,
      ));
    });
  }

  /// Set extra context data.
  void setExtra(String key, dynamic value) {
    Sentry.configureScope((scope) {
      scope.setExtra(key, value);
    });
  }

  /// Start a performance transaction.
  ISentrySpan startTransaction(String name, String operation) {
    return Sentry.startTransaction(name, operation);
  }
}

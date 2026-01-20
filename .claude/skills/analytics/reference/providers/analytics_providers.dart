// Template: Riverpod providers for analytics (provider-agnostic)
//
// Location: lib/features/analytics/presentation/providers/analytics_providers.dart
//
// Usage:
// 1. Copy to target location
// 2. Import your chosen service implementations
// 3. Change the provider implementations to swap providers

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/error_tracking_service.dart';
import '../../core/services/firebase_analytics_service.dart';
import '../../core/services/firebase_crashlytics_service.dart';
// import '../../core/services/sentry_error_tracking_service.dart';
// import '../../core/services/posthog_analytics_service.dart';

part 'analytics_providers.g.dart';

/// Provider for analytics service (event tracking, user properties).
///
/// To swap providers, change the implementation:
/// - [FirebaseAnalyticsService] (default)
/// - [PostHogAnalyticsService]
@riverpod
ProductAnalyticsService analyticsService(AnalyticsServiceRef ref) {
  return FirebaseAnalyticsService.instance;
  // return PostHogAnalyticsService.instance;
}

/// Provider for error tracking service (crashes, errors).
///
/// To swap providers, change the implementation:
/// - [FirebaseCrashlyticsService] (default)
/// - [SentryErrorTrackingService]
@riverpod
ErrorTrackingService errorTrackingService(ErrorTrackingServiceRef ref) {
  return FirebaseCrashlyticsService.instance;
  // return SentryErrorTrackingService.instance;
}

/// Provider for analytics enabled state.
@riverpod
class AnalyticsEnabled extends _$AnalyticsEnabled {
  @override
  Future<bool> build() async {
    final service = ref.watch(analyticsServiceProvider);
    return service.isEnabled();
  }

  /// Toggle analytics collection.
  Future<void> setEnabled(bool enabled) async {
    final service = ref.read(analyticsServiceProvider);
    await service.setEnabled(enabled);
    ref.invalidateSelf();
  }
}

/// Provider for error tracking enabled state.
@riverpod
class ErrorTrackingEnabled extends _$ErrorTrackingEnabled {
  @override
  Future<bool> build() async {
    final service = ref.watch(errorTrackingServiceProvider);
    return service.isEnabled();
  }

  /// Toggle error tracking collection.
  Future<void> setEnabled(bool enabled) async {
    final service = ref.read(errorTrackingServiceProvider);
    await service.setEnabled(enabled);
    ref.invalidateSelf();
  }
}

/// Helper for logging analytics events.
///
/// Usage:
/// ```dart
/// ref.read(analyticsLoggerProvider).logEvent(
///   name: 'button_clicked',
///   parameters: {'button_id': 'checkout'},
/// );
/// ```
@riverpod
AnalyticsLogger analyticsLogger(AnalyticsLoggerRef ref) {
  return AnalyticsLogger(
    ref.watch(analyticsServiceProvider),
    ref.watch(errorTrackingServiceProvider),
  );
}

/// Convenience class for common analytics operations.
final class AnalyticsLogger {
  const AnalyticsLogger(this._analytics, this._errorTracking);

  final ProductAnalyticsService _analytics;
  final ErrorTrackingService _errorTracking;

  /// Log a custom event.
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Log a screen view.
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  /// Set a user property.
  Future<void> setUserProperty(String name, String? value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Record a non-fatal error.
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    await _errorTracking.recordError(error, stackTrace, reason: reason);
  }

  /// Add a breadcrumb for crash context.
  Future<void> addBreadcrumb(String message) async {
    await _errorTracking.addBreadcrumb(message);
  }

  /// Configure user identity on login.
  Future<void> onLogin({
    required String userId,
    String? subscriptionTier,
    String? accountType,
  }) async {
    await _analytics.setUserId(userId);
    await _errorTracking.setUserIdentifier(userId);

    if (subscriptionTier != null) {
      await _analytics.setUserProperty(
        name: 'subscription_tier',
        value: subscriptionTier,
      );
    }

    if (accountType != null) {
      await _analytics.setUserProperty(
        name: 'account_type',
        value: accountType,
      );
    }

    await _analytics.logEvent(name: 'login');
  }

  /// Clear user identity on logout.
  Future<void> onLogout() async {
    await _analytics.setUserId(null);
    await _errorTracking.setUserIdentifier(null);
    await _analytics.setUserProperty(name: 'subscription_tier', value: null);
    await _analytics.setUserProperty(name: 'account_type', value: null);
    await _analytics.logEvent(name: 'logout');
  }
}

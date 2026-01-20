// Template: Firebase Analytics implementation
//
// Location: lib/core/services/firebase_analytics_service.dart
//
// Dependencies:
//   firebase_analytics: ^11.4.0
//
// Usage:
// 1. Copy to target location
// 2. Import in main.dart
// 3. Call initialize() after Firebase.initializeApp()

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'error_tracking_service.dart';

/// Firebase Analytics implementation of [ProductAnalyticsService].
final class FirebaseAnalyticsService implements ProductAnalyticsService {
  FirebaseAnalyticsService._();

  static final instance = FirebaseAnalyticsService._();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _enabled = true;

  /// Get the analytics observer for GoRouter.
  FirebaseAnalyticsObserver? get observer => _observer;

  @override
  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics!);

    // Disable collection in debug mode (optional)
    if (kDebugMode) {
      await _analytics!.setAnalyticsCollectionEnabled(false);
      _enabled = false;
    }
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    if (_analytics == null || !_enabled) return;

    await _analytics!.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (_analytics == null || !_enabled) return;

    await _analytics!.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (_analytics == null) return;

    await _analytics!.setUserProperty(
      name: name,
      value: value,
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (_analytics == null) return;

    await _analytics!.setUserId(id: userId);
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (_analytics == null) return;

    await _analytics!.setAnalyticsCollectionEnabled(enabled);
    _enabled = enabled;
  }

  @override
  Future<bool> isEnabled() async => _enabled;

  @override
  Future<void> reset() async {
    if (_analytics == null) return;

    await _analytics!.resetAnalyticsData();
  }

  // Firebase-specific convenience methods

  /// Log user login (Firebase standard event).
  Future<void> logLogin({required String loginMethod}) async {
    if (_analytics == null || !_enabled) return;
    await _analytics!.logLogin(loginMethod: loginMethod);
  }

  /// Log user sign up (Firebase standard event).
  Future<void> logSignUp({required String signUpMethod}) async {
    if (_analytics == null || !_enabled) return;
    await _analytics!.logSignUp(signUpMethod: signUpMethod);
  }

  /// Log a purchase (Firebase standard event).
  Future<void> logPurchase({
    required String currency,
    required double value,
    List<AnalyticsEventItem>? items,
    String? transactionId,
  }) async {
    if (_analytics == null || !_enabled) return;

    await _analytics!.logPurchase(
      currency: currency,
      value: value,
      items: items,
      transactionId: transactionId,
    );
  }
}

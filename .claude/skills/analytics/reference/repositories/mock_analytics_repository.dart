// Template: Mock analytics repository for testing
//
// Location: lib/features/analytics/data/repositories/mock_analytics_repository.dart
//
// Usage:
// 1. Copy to target location
// 2. Use in tests to verify event logging
// 3. Override provider in ProviderContainer

import 'package:fpdart/fpdart.dart';

import '../../domain/failures/analytics_failures.dart';
import '../../domain/repositories/analytics_repository.dart';

/// Mock implementation of [AnalyticsRepository] for testing.
final class MockAnalyticsRepository implements AnalyticsRepository {
  MockAnalyticsRepository();

  /// Logged events for verification.
  final List<AnalyticsEvent> loggedEvents = [];

  /// Logged screen views for verification.
  final List<String> loggedScreenViews = [];

  /// User properties that have been set.
  final Map<String, String?> userProperties = {};

  /// Current user ID.
  String? userId;

  /// Whether analytics is enabled.
  bool enabled = true;

  /// Whether to simulate failures.
  bool simulateFailure = false;

  @override
  Future<Either<AnalyticsFailure, void>> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    if (simulateFailure) {
      return left(const AnalyticsFailure.unknown(message: 'Simulated failure'));
    }

    if (!enabled) {
      return left(const AnalyticsFailure.disabled());
    }

    loggedEvents.add(AnalyticsEvent(name: name, parameters: parameters));
    return right(null);
  }

  @override
  Future<Either<AnalyticsFailure, void>> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (simulateFailure) {
      return left(const AnalyticsFailure.unknown(message: 'Simulated failure'));
    }

    if (!enabled) {
      return left(const AnalyticsFailure.disabled());
    }

    loggedScreenViews.add(screenName);
    return right(null);
  }

  @override
  Future<Either<AnalyticsFailure, void>> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (simulateFailure) {
      return left(const AnalyticsFailure.unknown(message: 'Simulated failure'));
    }

    userProperties[name] = value;
    return right(null);
  }

  @override
  Future<Either<AnalyticsFailure, void>> setUserId(String? userId) async {
    if (simulateFailure) {
      return left(const AnalyticsFailure.unknown(message: 'Simulated failure'));
    }

    this.userId = userId;
    return right(null);
  }

  @override
  Future<Either<AnalyticsFailure, void>> setEnabled(bool enabled) async {
    this.enabled = enabled;
    return right(null);
  }

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<Either<AnalyticsFailure, void>> reset() async {
    loggedEvents.clear();
    loggedScreenViews.clear();
    userProperties.clear();
    userId = null;
    return right(null);
  }

  /// Clear all recorded data (for test setup).
  void clear() {
    loggedEvents.clear();
    loggedScreenViews.clear();
    userProperties.clear();
    userId = null;
    simulateFailure = false;
    enabled = true;
  }

  /// Check if a specific event was logged.
  bool hasEvent(String name, {Map<String, Object?>? parameters}) {
    return loggedEvents.any((e) {
      if (e.name != name) return false;
      if (parameters == null) return true;
      return _mapsEqual(e.parameters, parameters);
    });
  }

  bool _mapsEqual(Map<String, Object?>? a, Map<String, Object?>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Recorded analytics event.
final class AnalyticsEvent {
  const AnalyticsEvent({
    required this.name,
    this.parameters,
  });

  final String name;
  final Map<String, Object?>? parameters;

  @override
  String toString() => 'AnalyticsEvent(name: $name, parameters: $parameters)';
}

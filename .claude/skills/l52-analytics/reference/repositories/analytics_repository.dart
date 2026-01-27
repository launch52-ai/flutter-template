// Template: Analytics repository interface
//
// Location: lib/features/analytics/domain/repositories/analytics_repository.dart
//
// Usage:
// 1. Copy to target location
// 2. Implement in data layer
// 3. Use fpdart Either for error handling

import 'package:fpdart/fpdart.dart';

import '../failures/analytics_failures.dart';

/// Repository interface for analytics operations.
///
/// Abstracts analytics service for testability and potential
/// provider switching (e.g., Firebase to Amplitude).
abstract interface class AnalyticsRepository {
  /// Log a custom event.
  ///
  /// Returns [AnalyticsFailure] if analytics is disabled or event is invalid.
  Future<Either<AnalyticsFailure, void>> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  });

  /// Log a screen view.
  Future<Either<AnalyticsFailure, void>> logScreenView({
    required String screenName,
    String? screenClass,
  });

  /// Set a user property.
  Future<Either<AnalyticsFailure, void>> setUserProperty({
    required String name,
    required String? value,
  });

  /// Set the user ID.
  Future<Either<AnalyticsFailure, void>> setUserId(String? userId);

  /// Enable or disable analytics collection.
  Future<Either<AnalyticsFailure, void>> setEnabled(bool enabled);

  /// Check if analytics is enabled.
  Future<bool> isEnabled();

  /// Reset all analytics data.
  Future<Either<AnalyticsFailure, void>> reset();
}

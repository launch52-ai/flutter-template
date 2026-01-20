// Template: Analytics repository implementation
//
// Location: lib/features/analytics/data/repositories/analytics_repository_impl.dart
//
// Usage:
// 1. Copy to target location
// 2. Inject AnalyticsService and CrashlyticsService
// 3. Register with Riverpod provider

import 'package:fpdart/fpdart.dart';

import '../../domain/failures/analytics_failures.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../../core/services/analytics_service.dart';

/// Firebase Analytics implementation of [AnalyticsRepository].
final class AnalyticsRepositoryImpl implements AnalyticsRepository {
  const AnalyticsRepositoryImpl();

  bool _isEnabled = true;

  @override
  Future<Either<AnalyticsFailure, void>> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    if (!_isEnabled) {
      return left(const AnalyticsFailure.disabled());
    }

    final validation = _validateEventName(name);
    if (validation != null) {
      return left(validation);
    }

    try {
      await AnalyticsService.logEvent(
        name: name,
        parameters: parameters,
      );
      return right(null);
    } catch (e) {
      return left(AnalyticsFailure.unknown(error: e));
    }
  }

  @override
  Future<Either<AnalyticsFailure, void>> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isEnabled) {
      return left(const AnalyticsFailure.disabled());
    }

    try {
      await AnalyticsService.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      return right(null);
    } catch (e) {
      return left(AnalyticsFailure.unknown(error: e));
    }
  }

  @override
  Future<Either<AnalyticsFailure, void>> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_isEnabled) {
      return left(const AnalyticsFailure.disabled());
    }

    try {
      await AnalyticsService.setUserProperty(name: name, value: value);
      return right(null);
    } catch (e) {
      return left(AnalyticsFailure.unknown(error: e));
    }
  }

  @override
  Future<Either<AnalyticsFailure, void>> setUserId(String? userId) async {
    try {
      await AnalyticsService.setUserId(userId);
      return right(null);
    } catch (e) {
      return left(AnalyticsFailure.unknown(error: e));
    }
  }

  @override
  Future<Either<AnalyticsFailure, void>> setEnabled(bool enabled) async {
    try {
      await AnalyticsService.setAnalyticsCollectionEnabled(enabled);
      _isEnabled = enabled;
      return right(null);
    } catch (e) {
      return left(AnalyticsFailure.unknown(error: e));
    }
  }

  @override
  Future<bool> isEnabled() async => _isEnabled;

  @override
  Future<Either<AnalyticsFailure, void>> reset() async {
    try {
      await AnalyticsService.resetAnalyticsData();
      return right(null);
    } catch (e) {
      return left(AnalyticsFailure.unknown(error: e));
    }
  }

  /// Validate event name according to Firebase rules.
  AnalyticsFailure? _validateEventName(String name) {
    if (name.isEmpty) {
      return AnalyticsFailure.eventValidation(
        eventName: name,
        reason: 'Event name cannot be empty',
      );
    }

    if (name.length > 40) {
      return AnalyticsFailure.eventValidation(
        eventName: name,
        reason: 'Event name must be 40 characters or less',
      );
    }

    // Check for reserved prefixes
    final reservedPrefixes = ['firebase_', 'google_', 'ga_'];
    for (final prefix in reservedPrefixes) {
      if (name.toLowerCase().startsWith(prefix)) {
        return AnalyticsFailure.eventValidation(
          eventName: name,
          reason: 'Event name cannot start with "$prefix"',
        );
      }
    }

    // Check for valid characters (alphanumeric + underscore)
    final validPattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
    if (!validPattern.hasMatch(name)) {
      return AnalyticsFailure.eventValidation(
        eventName: name,
        reason:
            'Event name must start with a letter and contain only letters, numbers, and underscores',
      );
    }

    return null;
  }
}

// Template: Analytics failure types
//
// Location: lib/features/analytics/domain/failures/analytics_failures.dart
//
// Usage:
// 1. Copy to target location
// 2. Import core Failure class
// 3. Add feature-specific failures as needed

import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_failures.freezed.dart';

/// Sealed failure types for analytics operations.
@freezed
sealed class AnalyticsFailure with _$AnalyticsFailure {
  /// User has opted out of analytics.
  const factory AnalyticsFailure.disabled() = AnalyticsDisabledFailure;

  /// Event name or parameters are invalid.
  const factory AnalyticsFailure.eventValidation({
    required String eventName,
    required String reason,
  }) = EventValidationFailure;

  /// Failed to upload crash report.
  const factory AnalyticsFailure.crashlyticsUpload({
    String? message,
  }) = CrashlyticsUploadFailure;

  /// User consent required before tracking.
  const factory AnalyticsFailure.consentRequired() = ConsentRequiredFailure;

  /// Unknown/unexpected error.
  const factory AnalyticsFailure.unknown({
    String? message,
    Object? error,
  }) = UnknownAnalyticsFailure;
}

/// Extension to get user-friendly error messages.
extension AnalyticsFailureMessage on AnalyticsFailure {
  String get message => switch (this) {
        AnalyticsDisabledFailure() =>
          'Analytics is disabled. Enable in settings to track usage.',
        EventValidationFailure(:final eventName, :final reason) =>
          'Invalid event "$eventName": $reason',
        CrashlyticsUploadFailure(:final message) =>
          message ?? 'Failed to upload crash report.',
        ConsentRequiredFailure() =>
          'Please accept analytics consent to continue.',
        UnknownAnalyticsFailure(:final message) =>
          message ?? 'An unexpected error occurred.',
      };
}

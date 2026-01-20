// Template: Account Deletion Failure Types
//
// Location: lib/features/settings/domain/failures/account_deletion_failure.dart
//
// Usage:
// 1. Copy to target location
// 2. Run build_runner if using Freezed (optional for sealed classes)
// 3. Import in repository and presentation layers

import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_deletion_failure.freezed.dart';

/// Failure types for account deletion operations.
///
/// Used as the Left value in Either<AccountDeletionFailure, void> returns.
@freezed
sealed class AccountDeletionFailure with _$AccountDeletionFailure {
  /// Network connection failure.
  /// Show retry button and check connection message.
  const factory AccountDeletionFailure.network({
    @Default('Unable to connect. Please check your internet connection.')
    String message,
  }) = AccountDeletionNetworkFailure;

  /// Server-side error during deletion.
  /// Show generic error and suggest trying again later.
  const factory AccountDeletionFailure.server({
    @Default('An error occurred. Please try again later.') String message,
    String? code,
  }) = AccountDeletionServerFailure;

  /// User is not authenticated.
  /// Navigate to login screen.
  const factory AccountDeletionFailure.auth({
    @Default('Your session has expired. Please sign in again.') String message,
  }) = AccountDeletionAuthFailure;

  /// Confirmation input was incorrect.
  /// Show validation error on confirmation field.
  const factory AccountDeletionFailure.confirmation({
    @Default('Please type "DELETE" exactly to confirm.') String message,
  }) = AccountDeletionConfirmationFailure;

  /// Rate limit exceeded.
  /// Show cooldown message.
  const factory AccountDeletionFailure.rateLimit({
    @Default('Too many attempts. Please try again later.') String message,
    Duration? retryAfter,
  }) = AccountDeletionRateLimitFailure;

  /// Unknown/unexpected error.
  /// Log for debugging, show generic message.
  const factory AccountDeletionFailure.unknown({
    @Default('An unexpected error occurred.') String message,
    Object? error,
    StackTrace? stackTrace,
  }) = AccountDeletionUnknownFailure;
}

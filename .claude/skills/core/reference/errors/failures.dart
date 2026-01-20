// Template: Typed Failures
//
// Location: lib/core/errors/failures.dart
//
// Usage:
// 1. Copy to target location
// 2. Run build_runner to generate Freezed code
// 3. Presentation layer maps failures to i18n strings

import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Base failure type for all errors in the app.
/// Presentation layer maps these to localized strings via i18n.
///
/// Example:
/// ```dart
/// result.when(
///   success: (data) => ...,
///   failure: (f) => f.when(
///     network: (n) => n.when(
///       noConnection: () => t.errors.noConnection,
///       timeout: () => t.errors.timeout,
///       unknown: (d) => t.errors.unknown,
///     ),
///     ...
///   ),
/// );
/// ```
@freezed
sealed class Failure with _$Failure {
  const Failure._();

  const factory Failure.network(NetworkFailure failure) = _NetworkFailure;
  const factory Failure.server(ServerFailure failure) = _ServerFailure;
  const factory Failure.cache(CacheFailure failure) = _CacheFailure;
  const factory Failure.validation(ValidationFailure failure) = _ValidationFailure;
}

/// Network-related failures.
@freezed
sealed class NetworkFailure with _$NetworkFailure {
  const factory NetworkFailure.noConnection() = NoConnectionFailure;
  const factory NetworkFailure.timeout() = TimeoutFailure;
  const factory NetworkFailure.unknown(String? details) = UnknownNetworkFailure;
}

/// Server-related failures.
@freezed
sealed class ServerFailure with _$ServerFailure {
  const factory ServerFailure.badRequest({String? message}) = BadRequestFailure;
  const factory ServerFailure.unauthorized() = UnauthorizedFailure;
  const factory ServerFailure.forbidden() = ForbiddenFailure;
  const factory ServerFailure.notFound() = NotFoundFailure;
  const factory ServerFailure.conflict({String? message}) = ConflictFailure;
  const factory ServerFailure.tooManyRequests() = TooManyRequestsFailure;
  const factory ServerFailure.internal() = InternalServerFailure;
  const factory ServerFailure.serviceUnavailable() = ServiceUnavailableFailure;
  const factory ServerFailure.unknown({int? statusCode, String? message}) = UnknownServerFailure;
}

/// Cache-related failures.
@freezed
sealed class CacheFailure with _$CacheFailure {
  const factory CacheFailure.notFound() = CacheNotFoundFailure;
  const factory CacheFailure.expired() = CacheExpiredFailure;
  const factory CacheFailure.corrupted() = CacheCorruptedFailure;
  const factory CacheFailure.writeError() = CacheWriteFailure;
}

/// Validation failures.
@freezed
sealed class ValidationFailure with _$ValidationFailure {
  const factory ValidationFailure.invalidFormat({required String field}) = InvalidFormatFailure;
  const factory ValidationFailure.required({required String field}) = RequiredFieldFailure;
  const factory ValidationFailure.tooShort({required String field, required int minLength}) = TooShortFailure;
  const factory ValidationFailure.tooLong({required String field, required int maxLength}) = TooLongFailure;
}

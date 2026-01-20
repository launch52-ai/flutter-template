// Template: Sealed failure types for error handling
//
// Location: lib/features/{feature}/domain/failures/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Failure Types (No Hardcoded Strings)
// Failures are typed - presentation layer maps to localized strings.
//
// IMPORTANT: Do NOT put message strings in failures.
// The presentation layer uses i18n to convert failure types to user messages.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Base failure type for all errors in the app.
/// Presentation layer maps these to localized strings via i18n.
@freezed
sealed class Failure with _$Failure {
  const Failure._();

  const factory Failure.network(NetworkFailure failure) = _NetworkFailure;
  const factory Failure.server(ServerFailure failure) = _ServerFailure;
  const factory Failure.cache(CacheFailure failure) = _CacheFailure;
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
  const factory ServerFailure.badRequest() = BadRequestFailure;
  const factory ServerFailure.unauthorized() = UnauthorizedFailure;
  const factory ServerFailure.forbidden() = ForbiddenFailure;
  const factory ServerFailure.notFound() = NotFoundFailure;
  const factory ServerFailure.conflict() = ConflictFailure;
  const factory ServerFailure.internal() = InternalServerFailure;
  const factory ServerFailure.unknown(int? statusCode) = UnknownServerFailure;
}

/// Cache-related failures.
@freezed
sealed class CacheFailure with _$CacheFailure {
  const factory CacheFailure.notFound() = CacheNotFoundFailure;
  const factory CacheFailure.expired() = CacheExpiredFailure;
  const factory CacheFailure.corrupted() = CacheCorruptedFailure;
}

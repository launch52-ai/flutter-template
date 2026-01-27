// Template: Sealed failure types for error handling
//
// Location: lib/features/{feature}/domain/failures/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Failure to i18n Mapper
// Presentation layer maps typed failures to localized strings.
// This file goes in: lib/core/utils/failure_mapper.dart

import '../../../core/i18n/translations.g.dart';
import '../../../core/errors/failures.dart';

/// Maps failures to localized user-friendly messages.
/// Uses slang i18n: t.errors.{key}
extension FailureMessage on Failure {
  String toLocalizedMessage() {
    return switch (this) {
      _NetworkFailure(:final failure) => failure.toLocalizedMessage(),
      _ServerFailure(:final failure) => failure.toLocalizedMessage(),
      _CacheFailure(:final failure) => failure.toLocalizedMessage(),
    };
  }
}

extension NetworkFailureMessage on NetworkFailure {
  String toLocalizedMessage() {
    return switch (this) {
      NoConnectionFailure() => t.errors.noConnection,
      TimeoutFailure() => t.errors.timeout,
      UnknownNetworkFailure() => t.errors.networkUnknown,
    };
  }
}

extension ServerFailureMessage on ServerFailure {
  String toLocalizedMessage() {
    return switch (this) {
      BadRequestFailure() => t.errors.badRequest,
      UnauthorizedFailure() => t.errors.unauthorized,
      ForbiddenFailure() => t.errors.forbidden,
      NotFoundFailure() => t.errors.notFound,
      ConflictFailure() => t.errors.conflict,
      InternalServerFailure() => t.errors.serverError,
      UnknownServerFailure() => t.errors.serverUnknown,
    };
  }
}

extension CacheFailureMessage on CacheFailure {
  String toLocalizedMessage() {
    return switch (this) {
      CacheNotFoundFailure() => t.errors.cacheNotFound,
      CacheExpiredFailure() => t.errors.cacheExpired,
      CacheCorruptedFailure() => t.errors.cacheCorrupted,
    };
  }
}

// -----------------------------------------------------
// Example i18n file: lib/core/i18n/common.i18n.yaml
// -----------------------------------------------------
// errors:
//   noConnection: No internet connection
//   timeout: Connection timed out
//   networkUnknown: Network error occurred
//   badRequest: Invalid request
//   unauthorized: Please sign in to continue
//   forbidden: You don't have permission
//   notFound: Not found
//   conflict: Data conflict occurred
//   serverError: Server error occurred
//   serverUnknown: Something went wrong
//   cacheNotFound: Data not available offline
//   cacheExpired: Cached data expired
//   cacheCorrupted: Local data corrupted

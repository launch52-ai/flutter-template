// Template: App Exceptions
//
// Location: lib/core/errors/exceptions.dart
//
// Usage:
// 1. Copy to target location
// 2. Throw these from data layer
// 3. Catch and map to Failures in repository

/// Base exception for all app exceptions.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String? message;

  @override
  String toString() => message ?? runtimeType.toString();
}

/// Server returned an error response.
final class ServerException extends AppException {
  const ServerException({
    required this.statusCode,
    String? message,
  }) : super(message);

  final int statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Network connection failed.
final class NetworkException extends AppException {
  const NetworkException([super.message]);
}

/// Request timed out.
final class TimeoutException extends AppException {
  const TimeoutException([super.message]);
}

/// Cache operation failed.
final class CacheException extends AppException {
  const CacheException([super.message]);
}

/// Authentication failed.
final class AuthException extends AppException {
  const AuthException([super.message]);
}

/// Session expired, need to re-authenticate.
final class SessionExpiredException extends AppException {
  const SessionExpiredException() : super('Session expired');
}

/// Rate limit exceeded.
final class RateLimitException extends AppException {
  const RateLimitException({
    this.retryAfter,
  }) : super('Rate limit exceeded');

  final Duration? retryAfter;
}

/// Validation failed.
final class ValidationException extends AppException {
  const ValidationException({
    required this.field,
    String? message,
  }) : super(message);

  final String field;
}

/// Resource not found.
final class NotFoundException extends AppException {
  const NotFoundException([super.message]);
}

/// Operation cancelled by user.
final class CancelledException extends AppException {
  const CancelledException() : super('Operation cancelled');
}

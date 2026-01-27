// Template: Phone number utilities
//
// Location: lib/features/{feature}/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

/// Base exception for phone auth errors.
sealed class PhoneAuthException implements Exception {
  const PhoneAuthException();
}

/// Phone number format is invalid.
final class InvalidPhoneException extends PhoneAuthException {
  const InvalidPhoneException();
}

/// Rate limit exceeded - too many requests.
final class RateLimitException extends PhoneAuthException {
  /// Duration until next request is allowed.
  final Duration retryAfter;

  const RateLimitException(this.retryAfter);
}

/// OTP verification failed - wrong code.
final class InvalidOtpException extends PhoneAuthException {
  /// Number of attempts remaining before OTP is invalidated.
  final int attemptsRemaining;

  const InvalidOtpException(this.attemptsRemaining);
}

/// OTP has expired.
final class OtpExpiredException extends PhoneAuthException {
  const OtpExpiredException();
}

/// Maximum verification attempts exceeded for this OTP.
final class MaxAttemptsException extends PhoneAuthException {
  const MaxAttemptsException();
}

/// Network connection error.
final class NetworkException extends PhoneAuthException {
  const NetworkException();
}

// Template: Sealed failure types for error handling
//
// Location: lib/features/{feature}/domain/failures/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

import '../../../../core/errors/failures.dart';

/// Base failure type for phone authentication errors.
///
/// Extends the core [Failure] type for consistency with the data layer pattern.
/// Map to localized strings in presentation layer using t.errors.phoneAuth.*
sealed class PhoneAuthFailure extends Failure {
  const PhoneAuthFailure(super.message);
}

/// Phone number format is invalid.
///
/// Display: t.errors.phoneAuth.invalidPhone
final class InvalidPhoneFailure extends PhoneAuthFailure {
  const InvalidPhoneFailure() : super('Invalid phone number format');
}

/// Rate limit exceeded - too many OTP requests.
///
/// Display: t.errors.phoneAuth.rateLimited with countdown
final class RateLimitFailure extends PhoneAuthFailure {
  /// Duration until next request is allowed.
  final Duration retryAfter;

  const RateLimitFailure(this.retryAfter)
      : super('Too many requests. Please wait.');
}

/// OTP verification failed - wrong code.
///
/// Display: t.errors.phoneAuth.invalidOtp with attempts remaining
final class InvalidOtpFailure extends PhoneAuthFailure {
  /// Number of attempts remaining before OTP is invalidated.
  final int attemptsRemaining;

  const InvalidOtpFailure(this.attemptsRemaining)
      : super('Incorrect verification code');
}

/// OTP has expired (typically after 5-10 minutes).
///
/// Display: t.errors.phoneAuth.otpExpired with resend option
final class OtpExpiredFailure extends PhoneAuthFailure {
  const OtpExpiredFailure() : super('Verification code has expired');
}

/// Maximum verification attempts exceeded for this OTP.
/// User must request a new OTP.
///
/// Display: t.errors.phoneAuth.maxAttempts
final class MaxAttemptsFailure extends PhoneAuthFailure {
  const MaxAttemptsFailure()
      : super('Too many failed attempts. Please request a new code.');
}

/// Network connection error.
///
/// Display: t.errors.network with retry option
final class PhoneAuthNetworkFailure extends PhoneAuthFailure {
  const PhoneAuthNetworkFailure() : super('Connection failed. Please check your internet.');
}

/// Server error (5xx responses).
///
/// Display: t.errors.server
final class PhoneAuthServerFailure extends PhoneAuthFailure {
  const PhoneAuthServerFailure() : super('Server error. Please try again.');
}

// ===========================================================================
// FAILURE MAPPING HELPER
// ===========================================================================

/// Map [PhoneAuthFailure] to localized string.
///
/// Usage in presentation layer:
/// ```dart
/// final message = mapPhoneAuthFailure(failure, t);
/// ```
///
/// This function should be in your presentation/utils/ folder and use
/// your actual i18n strings. Example implementation:
///
/// ```dart
/// String mapPhoneAuthFailure(PhoneAuthFailure failure, Translations t) {
///   return switch (failure) {
///     InvalidPhoneFailure() => t.errors.phoneAuth.invalidPhone,
///     RateLimitFailure(:final retryAfter) =>
///       t.errors.phoneAuth.rateLimited(seconds: retryAfter.inSeconds),
///     InvalidOtpFailure(:final attemptsRemaining) =>
///       t.errors.phoneAuth.invalidOtp(attempts: attemptsRemaining),
///     OtpExpiredFailure() => t.errors.phoneAuth.otpExpired,
///     MaxAttemptsFailure() => t.errors.phoneAuth.maxAttempts,
///     PhoneAuthNetworkFailure() => t.errors.network,
///     PhoneAuthServerFailure() => t.errors.server,
///   };
/// }
/// ```

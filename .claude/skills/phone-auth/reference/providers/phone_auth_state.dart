// Template: Freezed state class for Riverpod
//
// Location: lib/features/{feature}/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

import 'package:freezed_annotation/freezed_annotation.dart';

part 'phone_auth_state.freezed.dart';

/// Phone authentication UI state.
@freezed
sealed class PhoneAuthState with _$PhoneAuthState {
  /// Initial state - phone input screen
  const factory PhoneAuthState.initial() = PhoneAuthInitial;

  /// Sending OTP request to backend
  const factory PhoneAuthState.sendingOtp() = PhoneAuthSendingOtp;

  /// OTP sent successfully - OTP input screen
  const factory PhoneAuthState.otpSent({
    required String phoneNumber,
    required DateTime sentAt,
  }) = PhoneAuthOtpSent;

  /// Verifying OTP with backend
  const factory PhoneAuthState.verifying() = PhoneAuthVerifying;

  /// Authentication successful
  const factory PhoneAuthState.success() = PhoneAuthSuccess;

  /// Error occurred
  const factory PhoneAuthState.error({
    required PhoneAuthErrorType errorType,
    String? phoneNumber,
    int? attemptsRemaining,
    Duration? retryAfter,
  }) = PhoneAuthError;
}

/// Phone auth error types.
///
/// For user-facing messages, use i18n skill.
/// Map these types to localized strings in your presentation layer.
enum PhoneAuthErrorType {
  /// Phone number format is invalid
  invalidPhone,

  /// Too many OTP requests - rate limited
  rateLimitedSend,

  /// Too many verification attempts - rate limited
  rateLimitedVerify,

  /// OTP code is incorrect
  invalidOtp,

  /// OTP code has expired
  otpExpired,

  /// Maximum verification attempts exceeded for this OTP
  maxAttempts,

  /// Network connection error
  network,

  /// Server error
  server,

  /// Unknown error
  unknown,
}

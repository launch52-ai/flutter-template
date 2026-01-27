// Template: Riverpod provider definition
//
// Location: lib/features/{feature}/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'phone_auth_exceptions.dart';
import 'phone_auth_repository.dart';
import 'phone_auth_state.dart';

part 'phone_auth_provider.g.dart';

/// Phone authentication state notifier.
///
/// Manages the phone auth flow: send OTP → verify OTP → success.
@riverpod
class PhoneAuthNotifier extends _$PhoneAuthNotifier {
  @override
  PhoneAuthState build() => const PhoneAuthState.initial();

  /// Request OTP to be sent to phone number.
  ///
  /// [phoneNumber] should be in E.164 format (+994501234567)
  Future<void> sendOtp(String phoneNumber) async {
    state = const PhoneAuthState.sendingOtp();

    try {
      final repository = ref.read(phoneAuthRepositoryProvider);
      await repository.sendOtp(phoneNumber);

      state = PhoneAuthState.otpSent(
        phoneNumber: phoneNumber,
        sentAt: DateTime.now(),
      );
    } on RateLimitException catch (e) {
      state = PhoneAuthState.error(
        errorType: PhoneAuthErrorType.rateLimitedSend,
        phoneNumber: phoneNumber,
        retryAfter: e.retryAfter,
      );
    } on InvalidPhoneException {
      state = PhoneAuthState.error(
        errorType: PhoneAuthErrorType.invalidPhone,
        phoneNumber: phoneNumber,
      );
    } on NetworkException {
      state = PhoneAuthState.error(
        errorType: PhoneAuthErrorType.network,
        phoneNumber: phoneNumber,
      );
    } catch (_) {
      state = PhoneAuthState.error(
        errorType: PhoneAuthErrorType.server,
        phoneNumber: phoneNumber,
      );
    }
  }

  /// Verify OTP code entered by user.
  Future<void> verifyOtp(String otp) async {
    final currentState = state;
    if (currentState is! PhoneAuthOtpSent) return;

    state = const PhoneAuthState.verifying();

    try {
      final repository = ref.read(phoneAuthRepositoryProvider);
      await repository.verifyOtp(currentState.phoneNumber, otp);

      state = const PhoneAuthState.success();
    } on InvalidOtpException catch (e) {
      state = PhoneAuthState.error(
        errorType: PhoneAuthErrorType.invalidOtp,
        phoneNumber: currentState.phoneNumber,
        attemptsRemaining: e.attemptsRemaining,
      );
    } on OtpExpiredException {
      state = PhoneAuthState.error(
        errorType: PhoneAuthErrorType.otpExpired,
        phoneNumber: currentState.phoneNumber,
      );
    } on MaxAttemptsException {
      state = PhoneAuthState.error(
        errorType: PhoneAuthErrorType.maxAttempts,
        phoneNumber: currentState.phoneNumber,
      );
    } on RateLimitException catch (e) {
      state = PhoneAuthState.error(
        errorType: PhoneAuthErrorType.rateLimitedVerify,
        phoneNumber: currentState.phoneNumber,
        retryAfter: e.retryAfter,
      );
    } on NetworkException {
      state = PhoneAuthState.error(
        errorType: PhoneAuthErrorType.network,
        phoneNumber: currentState.phoneNumber,
      );
    } catch (_) {
      state = PhoneAuthState.error(
        errorType: PhoneAuthErrorType.server,
        phoneNumber: currentState.phoneNumber,
      );
    }
  }

  /// Reset to initial state.
  void reset() {
    state = const PhoneAuthState.initial();
  }

  /// Go back to OTP sent state (for retry after error).
  void backToOtpSent(String phoneNumber) {
    state = PhoneAuthState.otpSent(
      phoneNumber: phoneNumber,
      sentAt: DateTime.now(),
    );
  }
}

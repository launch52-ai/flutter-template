// Template: Repository implementation
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

import 'phone_auth_exceptions.dart';

/// Phone authentication repository interface.
///
/// Implement this for your specific backend API.
/// All security logic (OTP generation, rate limiting, etc.) is handled by backend.
abstract interface class PhoneAuthRepository {
  /// Request OTP to be sent to phone number.
  ///
  /// [phoneNumber] must be in E.164 format (+994501234567)
  ///
  /// Throws:
  /// - [InvalidPhoneException] if phone format is invalid
  /// - [RateLimitException] if too many requests (includes retryAfter)
  /// - [NetworkException] on connection failure
  Future<void> sendOtp(String phoneNumber);

  /// Verify OTP and authenticate user.
  ///
  /// [phoneNumber] must be in E.164 format
  /// [otp] is the code entered by user
  ///
  /// Throws:
  /// - [InvalidOtpException] if code is wrong (includes attemptsRemaining)
  /// - [OtpExpiredException] if code has expired
  /// - [MaxAttemptsException] if too many failed attempts
  /// - [RateLimitException] if rate limited
  /// - [NetworkException] on connection failure
  Future<void> verifyOtp(String phoneNumber, String otp);
}

// ---------------------------------------------------------------------------
// EXAMPLE IMPLEMENTATION
// ---------------------------------------------------------------------------
//
// final class PhoneAuthRepositoryImpl implements PhoneAuthRepository {
//   final Dio _dio;
//
//   const PhoneAuthRepositoryImpl(this._dio);
//
//   @override
//   Future<void> sendOtp(String phoneNumber) async {
//     try {
//       await _dio.post('/auth/otp/send', data: {'phone': phoneNumber});
//     } on DioException catch (e) {
//       if (e.response?.statusCode == 400) {
//         throw const InvalidPhoneException();
//       }
//       if (e.response?.statusCode == 429) {
//         final retryAfter = e.response?.headers['retry-after']?.first;
//         throw RateLimitException(
//           Duration(seconds: int.tryParse(retryAfter ?? '60') ?? 60),
//         );
//       }
//       throw const NetworkException();
//     }
//   }
//
//   @override
//   Future<void> verifyOtp(String phoneNumber, String otp) async {
//     try {
//       await _dio.post('/auth/otp/verify', data: {
//         'phone': phoneNumber,
//         'otp': otp,
//       });
//     } on DioException catch (e) {
//       final data = e.response?.data as Map<String, dynamic>?;
//       final errorCode = data?['error'] as String?;
//
//       switch (errorCode) {
//         case 'invalid_otp':
//           final remaining = data?['attempts_remaining'] as int? ?? 0;
//           throw InvalidOtpException(remaining);
//         case 'otp_expired':
//           throw const OtpExpiredException();
//         case 'max_attempts':
//           throw const MaxAttemptsException();
//       }
//
//       if (e.response?.statusCode == 429) {
//         final retryAfter = e.response?.headers['retry-after']?.first;
//         throw RateLimitException(
//           Duration(seconds: int.tryParse(retryAfter ?? '60') ?? 60),
//         );
//       }
//
//       throw const NetworkException();
//     }
//   }
// }

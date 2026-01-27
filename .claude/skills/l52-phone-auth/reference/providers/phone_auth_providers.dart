// Template: Riverpod provider definition
//
// Location: lib/features/{feature}/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Template: Phone Auth Providers
//
// Location: lib/core/providers.dart (add to existing file)
//           OR lib/features/auth/presentation/providers/phone_auth_providers.dart
//
// These providers wire up the phone auth feature.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Import your implementations
// import 'phone_auth_repository.dart';
// import 'phone_auth_repository_impl.dart';
// import 'mock_phone_auth_repository.dart';
// import 'debug_constants.dart';

part 'phone_auth_providers.g.dart';

// ===========================================================================
// REPOSITORY PROVIDER
// ===========================================================================

/// Provider for [PhoneAuthRepository].
///
/// Returns mock implementation in debug mode, real implementation in release.
/// Configure mock behavior in [DebugConstants].
@riverpod
PhoneAuthRepository phoneAuthRepository(Ref ref) {
  // Use mock in debug mode for development
  // if (DebugConstants.useMockAuth) {
  //   return MockPhoneAuthRepository();
  // }

  // Real implementation
  // return PhoneAuthRepositoryImpl(
  //   ref.watch(dioProvider),
  //   // OR for Supabase:
  //   // ref.watch(supabaseProvider),
  // );

  throw UnimplementedError('Configure phone auth repository provider');
}

// ===========================================================================
// ALTERNATIVE: SEPARATE PROVIDERS FOR DIFFERENT BACKENDS
// ===========================================================================

// /// Supabase phone auth repository.
// @riverpod
// PhoneAuthRepository supabasePhoneAuthRepository(Ref ref) {
//   return SupabasePhoneAuthRepository(ref.watch(supabaseProvider));
// }

// /// Custom API phone auth repository.
// @riverpod
// PhoneAuthRepository apiPhoneAuthRepository(Ref ref) {
//   return ApiPhoneAuthRepository(ref.watch(dioProvider));
// }

// ===========================================================================
// RETRY CONFIGURATION PROVIDER
// ===========================================================================

/// OTP retry intervals following best practice escalation pattern.
///
/// Pattern: 30s → 40s → 60s → 90s → 120s
/// This prevents abuse while remaining user-friendly.
@riverpod
List<Duration> otpRetryIntervals(Ref ref) {
  return const [
    Duration(seconds: 30),
    Duration(seconds: 40),
    Duration(seconds: 60),
    Duration(seconds: 90),
    Duration(seconds: 120),
  ];
}

/// Maximum OTP resend attempts before blocking.
@riverpod
int maxOtpResendAttempts(Ref ref) => 5;

/// OTP code length (typically 6 digits).
@riverpod
int otpCodeLength(Ref ref) => 6;

/// OTP expiration time (backend enforces, this is for UI display).
@riverpod
Duration otpExpirationTime(Ref ref) => const Duration(minutes: 10);

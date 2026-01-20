// Template: Repository implementation
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Template: Mock Phone Auth Repository
//
// Location: lib/features/auth/data/repositories/mock_phone_auth_repository.dart
//
// Mock implementation for development and testing.
// Simulates backend behavior without actual API calls.

import 'phone_auth_failures.dart';
import 'phone_auth_repository.dart';

/// Mock phone auth repository for development and testing.
///
/// Behavior controlled by configuration. Supports:
/// - Simulated delays for realistic UX testing
/// - Configurable success/failure scenarios
/// - Spy pattern for interaction tracking in tests
final class MockPhoneAuthRepository implements PhoneAuthRepository {
  MockPhoneAuthRepository({
    this.simulateDelay = true,
    this.delayDuration = const Duration(seconds: 1),
    this.validOtp = '123456',
    this.maxAttempts = 3,
    this.shouldSucceed = true,
    this.failureToThrow,
  });

  /// Whether to simulate network delay
  final bool simulateDelay;

  /// Duration of simulated delay
  final Duration delayDuration;

  /// OTP code that will be accepted as valid
  final String validOtp;

  /// Maximum verification attempts before failure
  final int maxAttempts;

  /// Whether operations should succeed (when true and no failureToThrow)
  final bool shouldSucceed;

  /// Specific failure to throw (overrides shouldSucceed)
  final PhoneAuthFailure? failureToThrow;

  // ===========================================================================
  // SPY: INTERACTION TRACKING FOR TESTS
  // ===========================================================================

  /// Tracks all sendOtp calls
  final List<String> sendOtpCalls = [];

  /// Tracks all verifyOtp calls
  final List<({String phoneNumber, String otp})> verifyOtpCalls = [];

  /// Current verification attempts for each phone number
  final Map<String, int> _verificationAttempts = {};

  /// Clear all tracking data (call in test setUp)
  void reset() {
    sendOtpCalls.clear();
    verifyOtpCalls.clear();
    _verificationAttempts.clear();
  }

  // ===========================================================================
  // REPOSITORY IMPLEMENTATION
  // ===========================================================================

  @override
  Future<void> sendOtp(String phoneNumber) async {
    // Track call
    sendOtpCalls.add(phoneNumber);

    // Simulate delay
    if (simulateDelay) {
      await Future<void>.delayed(delayDuration);
    }

    // Check for configured failure
    if (failureToThrow != null) {
      throw failureToThrow!;
    }

    // Check for rate limit simulation
    if (!shouldSucceed) {
      throw const RateLimitFailure(Duration(seconds: 60));
    }

    // Reset verification attempts for this number
    _verificationAttempts[phoneNumber] = 0;

    // Success - OTP "sent"
    return;
  }

  @override
  Future<void> verifyOtp(String phoneNumber, String otp) async {
    // Track call
    verifyOtpCalls.add((phoneNumber: phoneNumber, otp: otp));

    // Simulate delay
    if (simulateDelay) {
      await Future<void>.delayed(delayDuration);
    }

    // Check for configured failure
    if (failureToThrow != null) {
      throw failureToThrow!;
    }

    // Track attempts
    final attempts = (_verificationAttempts[phoneNumber] ?? 0) + 1;
    _verificationAttempts[phoneNumber] = attempts;

    // Check max attempts
    if (attempts > maxAttempts) {
      throw const MaxAttemptsFailure();
    }

    // Verify OTP
    if (otp != validOtp) {
      final remaining = maxAttempts - attempts;
      if (remaining <= 0) {
        throw const MaxAttemptsFailure();
      }
      throw InvalidOtpFailure(remaining);
    }

    // Success - user authenticated
    return;
  }

  // ===========================================================================
  // TEST ASSERTION HELPERS
  // ===========================================================================

  /// Whether sendOtp was called for a specific number
  bool wasSendOtpCalled(String phoneNumber) =>
      sendOtpCalls.contains(phoneNumber);

  /// How many times sendOtp was called
  int get sendOtpCallCount => sendOtpCalls.length;

  /// Whether verifyOtp was called with specific values
  bool wasVerifyOtpCalled(String phoneNumber, String otp) =>
      verifyOtpCalls.any((c) => c.phoneNumber == phoneNumber && c.otp == otp);

  /// How many times verifyOtp was called
  int get verifyOtpCallCount => verifyOtpCalls.length;
}

// ===========================================================================
// TEST HELPER FACTORIES
// ===========================================================================

/// Create mock that always succeeds
MockPhoneAuthRepository createSuccessMock({
  String validOtp = '123456',
  bool simulateDelay = false,
}) {
  return MockPhoneAuthRepository(
    validOtp: validOtp,
    shouldSucceed: true,
    simulateDelay: simulateDelay,
  );
}

/// Create mock that always fails with rate limit
MockPhoneAuthRepository createRateLimitedMock({
  Duration retryAfter = const Duration(seconds: 60),
}) {
  return MockPhoneAuthRepository(
    failureToThrow: RateLimitFailure(retryAfter),
    simulateDelay: false,
  );
}

/// Create mock that fails with invalid OTP
MockPhoneAuthRepository createInvalidOtpMock({
  int attemptsRemaining = 2,
}) {
  return MockPhoneAuthRepository(
    failureToThrow: InvalidOtpFailure(attemptsRemaining),
    simulateDelay: false,
  );
}

/// Create mock that fails with network error
MockPhoneAuthRepository createNetworkErrorMock() {
  return MockPhoneAuthRepository(
    failureToThrow: const PhoneAuthNetworkFailure(),
    simulateDelay: false,
  );
}

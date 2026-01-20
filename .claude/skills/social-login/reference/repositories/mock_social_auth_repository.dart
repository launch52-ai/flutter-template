// Template: Repository implementation
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Template: Mock Social Auth Repository
//
// Location: lib/features/auth/data/repositories/mock_social_auth_repository.dart
//
// Mock implementation for development and testing.
// Simulates OAuth flows without actual provider SDK calls.

import 'social_auth_failures.dart';
import 'social_auth_repository.dart';

/// Auth result returned on successful authentication.
final class MockAuthResult {
  final String userId;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isNewUser;

  const MockAuthResult({
    required this.userId,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isNewUser = false,
  });
}

/// Mock social auth repository for development and testing.
///
/// Behavior controlled by configuration. Supports:
/// - Simulated delays for realistic UX testing
/// - Configurable success/failure scenarios
/// - Spy pattern for interaction tracking in tests
/// - isNewUser flag for testing first-time user flows
final class MockSocialAuthRepository implements SocialAuthRepository {
  MockSocialAuthRepository({
    this.simulateDelay = true,
    this.delayDuration = const Duration(seconds: 1),
    this.shouldSucceed = true,
    this.returnNewUser = false,
    this.googleFailure,
    this.appleFailure,
  });

  /// Whether to simulate network delay
  final bool simulateDelay;

  /// Duration of simulated delay
  final Duration delayDuration;

  /// Whether operations should succeed (when true and no failure configured)
  final bool shouldSucceed;

  /// Whether to return isNewUser = true (for testing first-time flows)
  final bool returnNewUser;

  /// Specific failure to throw for Google sign-in
  final SocialAuthFailure? googleFailure;

  /// Specific failure to throw for Apple sign-in
  final SocialAuthFailure? appleFailure;

  // ===========================================================================
  // SPY: INTERACTION TRACKING FOR TESTS
  // ===========================================================================

  /// Tracks all Google sign-in calls
  final List<DateTime> googleSignInCalls = [];

  /// Tracks all Apple sign-in calls
  final List<DateTime> appleSignInCalls = [];

  /// Tracks all sign-out calls
  final List<DateTime> signOutCalls = [];

  /// Clear all tracking data (call in test setUp)
  void reset() {
    googleSignInCalls.clear();
    appleSignInCalls.clear();
    signOutCalls.clear();
  }

  // ===========================================================================
  // REPOSITORY IMPLEMENTATION
  // ===========================================================================

  @override
  Future<MockAuthResult?> signInWithGoogle() async {
    // Track call
    googleSignInCalls.add(DateTime.now());

    // Simulate delay
    if (simulateDelay) {
      await Future<void>.delayed(delayDuration);
    }

    // Check for configured failure
    if (googleFailure != null) {
      throw googleFailure!;
    }

    // Simulate cancellation
    if (!shouldSucceed) {
      throw const GoogleSignInCancelledFailure();
    }

    // Success - return mock user
    return MockAuthResult(
      userId: 'google_mock_user_123',
      email: 'mockuser@gmail.com',
      displayName: 'Mock User',
      photoUrl: 'https://example.com/photo.jpg',
      isNewUser: returnNewUser,
    );
  }

  @override
  Future<MockAuthResult?> signInWithApple() async {
    // Track call
    appleSignInCalls.add(DateTime.now());

    // Simulate delay
    if (simulateDelay) {
      await Future<void>.delayed(delayDuration);
    }

    // Check for configured failure
    if (appleFailure != null) {
      throw appleFailure!;
    }

    // Simulate cancellation
    if (!shouldSucceed) {
      throw const AppleSignInCancelledFailure();
    }

    // Success - return mock user
    // Note: Apple may not provide email on subsequent sign-ins
    return MockAuthResult(
      userId: 'apple_mock_user_456',
      email: returnNewUser ? 'mockuser@icloud.com' : null,
      displayName: returnNewUser ? 'Mock User' : null,
      isNewUser: returnNewUser,
    );
  }

  @override
  Future<void> signOut() async {
    // Track call
    signOutCalls.add(DateTime.now());

    // Simulate delay
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  // ===========================================================================
  // TEST ASSERTION HELPERS
  // ===========================================================================

  /// Whether Google sign-in was called
  bool get wasGoogleSignInCalled => googleSignInCalls.isNotEmpty;

  /// How many times Google sign-in was called
  int get googleSignInCallCount => googleSignInCalls.length;

  /// Whether Apple sign-in was called
  bool get wasAppleSignInCalled => appleSignInCalls.isNotEmpty;

  /// How many times Apple sign-in was called
  int get appleSignInCallCount => appleSignInCalls.length;

  /// Whether sign-out was called
  bool get wasSignOutCalled => signOutCalls.isNotEmpty;

  /// How many times sign-out was called
  int get signOutCallCount => signOutCalls.length;
}

// ===========================================================================
// TEST HELPER FACTORIES
// ===========================================================================

/// Create mock that always succeeds with existing user
MockSocialAuthRepository createSuccessMock({
  bool simulateDelay = false,
}) {
  return MockSocialAuthRepository(
    shouldSucceed: true,
    simulateDelay: simulateDelay,
  );
}

/// Create mock that returns a new user (for testing onboarding flows)
MockSocialAuthRepository createNewUserMock({
  bool simulateDelay = false,
}) {
  return MockSocialAuthRepository(
    shouldSucceed: true,
    returnNewUser: true,
    simulateDelay: simulateDelay,
  );
}

/// Create mock where Google sign-in is cancelled
MockSocialAuthRepository createGoogleCancelledMock() {
  return MockSocialAuthRepository(
    googleFailure: const GoogleSignInCancelledFailure(),
    simulateDelay: false,
  );
}

/// Create mock where Apple sign-in is cancelled
MockSocialAuthRepository createAppleCancelledMock() {
  return MockSocialAuthRepository(
    appleFailure: const AppleSignInCancelledFailure(),
    simulateDelay: false,
  );
}

/// Create mock with Google sign-in failure
MockSocialAuthRepository createGoogleFailureMock({
  SocialAuthFailure? failure,
}) {
  return MockSocialAuthRepository(
    googleFailure: failure ?? const GoogleSignInFailedFailure(),
    simulateDelay: false,
  );
}

/// Create mock with Apple sign-in failure
MockSocialAuthRepository createAppleFailureMock({
  SocialAuthFailure? failure,
}) {
  return MockSocialAuthRepository(
    appleFailure: failure ?? const AppleSignInFailedFailure(),
    simulateDelay: false,
  );
}

/// Create mock that fails with network error
MockSocialAuthRepository createNetworkErrorMock() {
  return MockSocialAuthRepository(
    googleFailure: const SocialAuthNetworkFailure(),
    appleFailure: const SocialAuthNetworkFailure(),
    simulateDelay: false,
  );
}

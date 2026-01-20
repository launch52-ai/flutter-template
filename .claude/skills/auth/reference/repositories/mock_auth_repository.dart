// Template: Mock Auth Repository
//
// Location: lib/features/auth/data/repositories/mock_auth_repository.dart
//
// Usage:
// 1. Copy to target location
// 2. Add mock implementations for auth methods you support
// 3. Use in tests and development mode

import 'dart:async';

import '../../domain/failures/auth_failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_result.dart';
import '../models/user_profile.dart';

/// Mock implementation of [AuthRepository] for testing and development.
///
/// Configure behavior via constructor parameters:
/// - [mockUser] - The user to return (null = not authenticated)
/// - [shouldFail] - Force failures for testing error handling
/// - [failureType] - Which failure to throw when shouldFail is true
/// - [delay] - Simulate network latency
///
/// Example usage in tests:
/// ```dart
/// final mockRepo = MockAuthRepository(
///   mockUser: UserProfile(id: 'test-user', email: 'test@example.com'),
/// );
///
/// container = ProviderContainer(overrides: [
///   authRepositoryProvider.overrideWithValue(mockRepo),
/// ]);
/// ```
final class MockAuthRepository implements AuthRepository {
  /// The mock user to return. Null means not authenticated.
  UserProfile? mockUser;

  /// Whether operations should fail.
  final bool shouldFail;

  /// The failure type to throw when shouldFail is true.
  final AuthFailure? failureType;

  /// Simulated network delay.
  final Duration delay;

  /// Stream controller for auth state changes.
  final _authStateController = StreamController<UserProfile?>.broadcast();

  /// Track method calls for verification in tests.
  int signOutCallCount = 0;
  int getCurrentUserCallCount = 0;
  int refreshSessionCallCount = 0;

  MockAuthRepository({
    this.mockUser,
    this.shouldFail = false,
    this.failureType,
    this.delay = const Duration(milliseconds: 100),
  });

  /// Create a mock with a pre-authenticated user.
  factory MockAuthRepository.authenticated({
    String id = 'mock-user-id',
    String? email = 'user@example.com',
    String? displayName = 'Test User',
  }) {
    return MockAuthRepository(
      mockUser: UserProfile(
        id: id,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Create a mock that simulates network failure.
  factory MockAuthRepository.networkError() {
    return MockAuthRepository(
      shouldFail: true,
      failureType: const AuthNetworkFailure(),
    );
  }

  /// Create a mock that simulates server error.
  factory MockAuthRepository.serverError() {
    return MockAuthRepository(
      shouldFail: true,
      failureType: const AuthServerFailure(),
    );
  }

  /// Create a mock with expired session.
  factory MockAuthRepository.sessionExpired() {
    return MockAuthRepository(
      shouldFail: true,
      failureType: const AuthSessionExpiredFailure(),
    );
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    getCurrentUserCallCount++;
    await Future.delayed(delay);

    if (shouldFail) {
      throw failureType ?? const AuthUnknownFailure();
    }

    return mockUser;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    await Future.delayed(delay);

    if (shouldFail) {
      throw failureType ?? const AuthUnknownFailure();
    }

    mockUser = null;
    _authStateController.add(null);
  }

  @override
  Stream<UserProfile?> get authStateChanges => _authStateController.stream;

  @override
  bool get isAuthenticated => mockUser != null;

  @override
  Future<void> refreshSession() async {
    refreshSessionCallCount++;
    await Future.delayed(delay);

    if (shouldFail) {
      throw failureType ?? const AuthSessionExpiredFailure();
    }

    // Session refreshed successfully - no change to user
  }

  // ===========================================================================
  // TEST HELPERS
  // ===========================================================================

  /// Simulate user sign-in (for testing).
  void simulateSignIn(UserProfile user) {
    mockUser = user;
    _authStateController.add(user);
  }

  /// Simulate user sign-out (for testing).
  void simulateSignOut() {
    mockUser = null;
    _authStateController.add(null);
  }

  /// Reset all call counts.
  void resetCallCounts() {
    signOutCallCount = 0;
    getCurrentUserCallCount = 0;
    refreshSessionCallCount = 0;
  }

  /// Dispose resources.
  void dispose() {
    _authStateController.close();
  }
}

// ===========================================================================
// MOCK FACTORIES FOR SPECIFIC AUTH METHODS
// ===========================================================================

/// Create mock that returns successful social login.
MockAuthRepository createSocialLoginSuccessMock({
  String id = 'google-user-id',
  String email = 'google@example.com',
  String displayName = 'Google User',
  bool isNewUser = false,
}) {
  return MockAuthRepository.authenticated(
    id: id,
    email: email,
    displayName: displayName,
  );
}

/// Create mock that returns cancelled social login.
MockAuthRepository createSocialLoginCancelledMock() {
  return MockAuthRepository(); // No user = cancelled
}

/// Create mock for phone auth flow.
MockAuthRepository createPhoneAuthMock({
  String validOtp = '123456',
  String phoneNumber = '+15551234567',
}) {
  return MockAuthRepository(
    mockUser: UserProfile(
      id: 'phone-user-id',
      phoneNumber: phoneNumber,
      createdAt: DateTime.now(),
    ),
  );
}

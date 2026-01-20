// Template: Repository implementation
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Template: Social Auth Methods for MockAuthRepository
//
// Location: lib/features/auth/data/repositories/mock_auth_repository.dart
//
// Add these methods to your existing MockAuthRepository.
// Used for development and testing without real OAuth providers.

// ===========================================================================
// CLASS DECLARATION
// ===========================================================================

// Add SocialAuthRepository to your implements clause:
// final class MockAuthRepository implements AuthRepository, SocialAuthRepository

// ===========================================================================
// MOCK SOCIAL SIGN-IN METHODS
// ===========================================================================

@override
Future<AuthResult?> signInWithGoogle() async {
  // Simulate network delay
  await Future.delayed(const Duration(seconds: 1));

  // Persist mock session
  await _persistMockSession();

  return AuthResult(
    user: _mockUser.copyWith(createdAt: DateTime.now()),
    isNewUser: false,
    accessToken: 'mock_access_token',
    refreshToken: 'mock_refresh_token',
  );
}

@override
Future<AuthResult?> signInWithApple() async {
  // Simulate network delay
  await Future.delayed(const Duration(seconds: 1));

  // Persist mock session
  await _persistMockSession();

  return AuthResult(
    user: _mockUser.copyWith(createdAt: DateTime.now()),
    isNewUser: false,
    accessToken: 'mock_access_token',
    refreshToken: 'mock_refresh_token',
  );
}

// ===========================================================================
// HELPER (if not already present)
// ===========================================================================

Future<void> _persistMockSession() async {
  await _secureStorage.write(
    key: StorageKeys.accessToken,
    value: 'mock_access_token',
  );
  await _secureStorage.write(
    key: StorageKeys.refreshToken,
    value: 'mock_refresh_token',
  );
  await _sharedPrefs.setBool(SharedPrefsKeys.isLoggedIn, value: true);
}

UserProfile get _mockUser => UserProfile(
      id: 'mock-user-id',
      email: 'mock@example.com',
      fullName: 'Mock User',
      createdAt: DateTime.now(),
    );

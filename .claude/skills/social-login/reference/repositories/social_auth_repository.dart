// Template: Repository interface
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Template: Social Auth Repository Interface
//
// Location: lib/features/auth/domain/repositories/social_auth_repository.dart
//
// This interface defines the contract for social authentication.
// Implement this in AuthRepositoryImpl and MockAuthRepository.

import '../../data/models/auth_result.dart';

/// Social login authentication interface.
///
/// Implementations:
/// - [AuthRepositoryImpl] - Real Supabase implementation
/// - [MockAuthRepository] - Mock for development/testing
abstract interface class SocialAuthRepository {
  /// Sign in with Google.
  ///
  /// Returns [AuthResult] on success, null if user cancels.
  /// Throws [AuthException] on failure.
  Future<AuthResult?> signInWithGoogle();

  /// Sign in with Apple.
  ///
  /// Returns [AuthResult] on success, null if user cancels.
  ///
  /// On Android, throws [OAuthPendingException] as the flow
  /// opens an external browser. The app should wait for the
  /// deep link callback to complete authentication.
  Future<AuthResult?> signInWithApple();
}

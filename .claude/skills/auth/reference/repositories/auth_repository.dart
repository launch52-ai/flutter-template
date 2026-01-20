// Template: Auth Repository Interface
//
// Location: lib/features/auth/domain/repositories/auth_repository.dart
//
// Usage:
// 1. Copy to target location
// 2. This is the BASE interface - specific auth methods add their own interfaces
// 3. AuthRepositoryImpl implements this + SocialAuthRepository + PhoneAuthRepository

import '../../../data/models/user_profile.dart';

/// Base authentication repository interface.
///
/// Defines core auth operations shared across all auth methods.
/// Specific auth methods (social, phone) have their own interfaces that
/// the implementation also implements.
///
/// Implementations:
/// - [AuthRepositoryImpl] - Real Supabase/API implementation
/// - [MockAuthRepository] - Mock for development/testing
abstract interface class AuthRepository {
  /// Get the currently authenticated user.
  ///
  /// Returns [UserProfile] if authenticated, null otherwise.
  Future<UserProfile?> getCurrentUser();

  /// Sign out the current user.
  ///
  /// Clears all auth tokens and session data.
  Future<void> signOut();

  /// Stream of auth state changes.
  ///
  /// Emits [UserProfile] when user signs in, null when signs out.
  /// Use to update UI reactively based on auth state.
  Stream<UserProfile?> get authStateChanges;

  /// Check if user is currently authenticated.
  ///
  /// Synchronous check of current auth state.
  bool get isAuthenticated;

  /// Refresh the current session token.
  ///
  /// Call when receiving 401 errors to attempt token refresh.
  /// Throws [AuthSessionExpiredFailure] if refresh fails.
  Future<void> refreshSession();
}

// ===========================================================================
// EMAIL AUTH EXTENSION (Optional)
// ===========================================================================

/// Email/password authentication interface.
///
/// Implement this alongside [AuthRepository] if supporting email auth.
abstract interface class EmailAuthRepository {
  /// Sign in with email and password.
  ///
  /// Returns [AuthResult] on success.
  /// Throws appropriate [AuthFailure] on error.
  Future<void> signInWithEmail(String email, String password);

  /// Register new user with email and password.
  ///
  /// Throws [AuthEmailAlreadyExistsFailure] if email taken.
  Future<void> signUpWithEmail(String email, String password);

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Update password for authenticated user.
  Future<void> updatePassword(String newPassword);
}

// ===========================================================================
// NOTE: Social and Phone auth interfaces are in their respective skills
// ===========================================================================
//
// - SocialAuthRepository: .claude/skills/social-login/reference/repositories/
// - PhoneAuthRepository: .claude/skills/phone-auth/reference/repositories/
//
// Your AuthRepositoryImpl should implement the interfaces you need:
//
// final class AuthRepositoryImpl implements
//     AuthRepository,
//     EmailAuthRepository,    // if using email
//     SocialAuthRepository,   // if using social login
//     PhoneAuthRepository {   // if using phone auth
//   ...
// }

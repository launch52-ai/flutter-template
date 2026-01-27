// Template: Auth Repository Implementation (Supabase)
//
// Location: lib/features/auth/data/repositories/auth_repository_impl.dart
//
// Usage:
// 1. Copy to target location
// 2. Add interfaces for auth methods you support (SocialAuthRepository, etc.)
// 3. Implement methods from those interfaces
// 4. Run: dart run build_runner build

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/failures/auth_failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_result.dart';
import '../models/user_profile.dart';

/// Supabase implementation of [AuthRepository].
///
/// Add additional interfaces based on your auth methods:
/// - [SocialAuthRepository] - for Google/Apple sign-in
/// - [PhoneAuthRepository] - for phone OTP
/// - [EmailAuthRepository] - for email/password
///
/// Example with all methods:
/// ```dart
/// final class AuthRepositoryImpl implements
///     AuthRepository,
///     SocialAuthRepository,
///     PhoneAuthRepository,
///     EmailAuthRepository {
///   // ...
/// }
/// ```
final class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  const AuthRepositoryImpl(this._supabase);

  // ===========================================================================
  // AUTH REPOSITORY - BASE METHODS
  // ===========================================================================

  @override
  Future<UserProfile?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return UserProfileFactory.fromSupabaseUser(user);
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Stream<UserProfile?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;
      return UserProfileFactory.fromSupabaseUser(user);
    });
  }

  @override
  bool get isAuthenticated => _supabase.auth.currentSession != null;

  @override
  Future<void> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      if (response.session == null) {
        throw const AuthSessionExpiredFailure();
      }
    } on AuthException {
      throw const AuthSessionExpiredFailure();
    }
  }

  // ===========================================================================
  // ERROR MAPPING
  // ===========================================================================

  AuthFailure _mapAuthException(AuthException e) {
    // Map Supabase auth exceptions to our failure types
    final message = e.message.toLowerCase();

    if (message.contains('network') || message.contains('connection')) {
      return const AuthNetworkFailure();
    }

    if (message.contains('session') || message.contains('expired')) {
      return const AuthSessionExpiredFailure();
    }

    if (message.contains('disabled') || message.contains('banned')) {
      return AuthAccountDisabledFailure(e.message);
    }

    if (message.contains('not found')) {
      return const AuthAccountNotFoundFailure();
    }

    return AuthUnknownFailure(e.message);
  }

  // ===========================================================================
  // ADD AUTH METHOD IMPLEMENTATIONS BELOW
  // ===========================================================================

  // For social login, see: /social-login skill
  // Copy methods from: reference/repositories/auth_repository_social_methods.dart

  // For phone auth, see: /phone-auth skill
  // The phone auth skill creates a separate PhoneAuthRepository

  // For email auth, implement EmailAuthRepository interface:
  //
  // Future<void> signInWithEmail(String email, String password) async {
  //   try {
  //     await _supabase.auth.signInWithPassword(
  //       email: email,
  //       password: password,
  //     );
  //   } on AuthException catch (e) {
  //     throw _mapAuthException(e);
  //   }
  // }
  //
  // Future<void> signUpWithEmail(String email, String password) async {
  //   try {
  //     await _supabase.auth.signUp(
  //       email: email,
  //       password: password,
  //     );
  //   } on AuthException catch (e) {
  //     throw _mapAuthException(e);
  //   }
  // }
}

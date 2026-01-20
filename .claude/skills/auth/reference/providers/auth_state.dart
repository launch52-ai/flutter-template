// Template: Auth State
//
// Location: lib/features/auth/presentation/providers/auth_state.dart
//
// Usage:
// 1. Copy to target location
// 2. Run: dart run build_runner build

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/user_profile.dart';

part 'auth_state.freezed.dart';

/// Authentication state for the app.
///
/// Used by [AuthNotifier] to manage auth state across screens.
/// UI should react to state changes using ref.watch(authNotifierProvider).
@freezed
sealed class AuthState with _$AuthState {
  /// Initial state - checking if user is authenticated.
  ///
  /// UI: Show splash screen or loading indicator.
  const factory AuthState.initial() = AuthInitial;

  /// Loading state - auth operation in progress.
  ///
  /// UI: Show loading indicator, disable auth buttons.
  const factory AuthState.loading() = AuthLoading;

  /// Authenticated state - user is signed in.
  ///
  /// UI: Navigate to home/dashboard, show user info.
  const factory AuthState.authenticated({
    required UserProfile user,
    @Default(false) bool isNewUser,
  }) = AuthAuthenticated;

  /// Unauthenticated state - no user signed in.
  ///
  /// UI: Show login screen.
  const factory AuthState.unauthenticated() = AuthUnauthenticated;

  /// OTP sent state - waiting for user to enter OTP.
  ///
  /// UI: Show OTP input screen.
  const factory AuthState.otpSent() = AuthOtpSent;

  /// Error state - auth operation failed.
  ///
  /// UI: Show error message with optional retry.
  const factory AuthState.error(String message) = AuthError;
}

// ===========================================================================
// STATE HELPERS
// ===========================================================================

extension AuthStateHelpers on AuthState {
  /// Check if user is authenticated.
  bool get isAuthenticated => this is AuthAuthenticated;

  /// Check if auth is in progress.
  bool get isLoading => this is AuthLoading || this is AuthInitial;

  /// Check if there's an error.
  bool get hasError => this is AuthError;

  /// Get the authenticated user, or null if not authenticated.
  UserProfile? get user => switch (this) {
        AuthAuthenticated(:final user) => user,
        _ => null,
      };

  /// Get error message, or null if no error.
  String? get errorMessage => switch (this) {
        AuthError(:final message) => message,
        _ => null,
      };

  /// Check if this is a new user (first sign-in).
  bool get isNewUser => switch (this) {
        AuthAuthenticated(:final isNewUser) => isNewUser,
        _ => false,
      };
}

// ===========================================================================
// STATE TRANSITIONS
// ===========================================================================

/// Valid state transitions for auth flow.
///
/// ```
/// initial → loading → authenticated
///                   → unauthenticated
///                   → error
///
/// authenticated → loading (sign out) → unauthenticated
///
/// unauthenticated → loading (sign in) → authenticated
///                                     → error
///
/// error → loading (retry) → authenticated
///                         → error
/// ```
///
/// The [AuthNotifier] enforces these transitions.

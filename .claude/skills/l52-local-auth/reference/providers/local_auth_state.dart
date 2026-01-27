// Template: Local auth state with Freezed
//
// Location: lib/core/providers/local_auth_state.dart
//
// Usage:
// 1. Copy to target location
// 2. Run: dart run build_runner build

import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_auth_state.freezed.dart';

/// State for local authentication flow.
@freezed
sealed class LocalAuthState with _$LocalAuthState {
  /// Initial state - checking if auth is needed.
  const factory LocalAuthState.checking() = LocalAuthChecking;

  /// Auth required - show lock screen.
  const factory LocalAuthState.requiresAuth() = LocalAuthRequired;

  /// Authenticated - show app content.
  const factory LocalAuthState.authenticated() = LocalAuthAuthenticated;

  /// Failed attempt.
  const factory LocalAuthState.failed({
    String? message,
    int? attemptsRemaining,
  }) = LocalAuthFailed;

  /// Locked out - too many failures.
  const factory LocalAuthState.lockedOut({
    required String message,
    Duration? retryAfter,
  }) = LocalAuthLockedOut;

  /// Requires full remote login.
  ///
  /// Triggered when:
  /// - Too many local auth failures
  /// - Biometrics changed (banking-grade security)
  const factory LocalAuthState.requiresFullLogin() = LocalAuthRequiresFullLogin;

  /// Disabled - user has not enabled local auth.
  const factory LocalAuthState.disabled() = LocalAuthDisabled;
}

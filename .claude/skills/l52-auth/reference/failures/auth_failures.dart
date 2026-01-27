// Template: Base Auth Failures
//
// Location: lib/features/auth/domain/failures/auth_failures.dart
//
// Usage:
// 1. Copy to target location
// 2. Import core Failure base class
// 3. Specific auth skills (social-login, phone-auth) extend with their own failures

import '../../../../core/errors/failures.dart';

/// Base failure type for authentication errors.
///
/// Extends the core [Failure] type for consistency with the data layer pattern.
/// Specific auth methods (social, phone) have their own failure types that
/// may extend or complement these.
///
/// Map to localized strings in presentation layer using t.errors.auth.*
sealed class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

// ===========================================================================
// SESSION FAILURES
// ===========================================================================

/// User session has expired and needs to re-authenticate.
///
/// Display: t.errors.auth.sessionExpired
final class AuthSessionExpiredFailure extends AuthFailure {
  const AuthSessionExpiredFailure() : super('Your session has expired');
}

/// User is not authenticated when expected.
///
/// Display: t.errors.auth.notAuthenticated
final class AuthNotAuthenticatedFailure extends AuthFailure {
  const AuthNotAuthenticatedFailure() : super('Please sign in to continue');
}

/// Token refresh failed.
///
/// Display: t.errors.auth.tokenRefreshFailed
final class AuthTokenRefreshFailure extends AuthFailure {
  const AuthTokenRefreshFailure() : super('Failed to refresh session');
}

// ===========================================================================
// NETWORK FAILURES
// ===========================================================================

/// Network connection error during authentication.
///
/// Display: t.errors.network with retry option
final class AuthNetworkFailure extends AuthFailure {
  const AuthNetworkFailure()
      : super('Connection failed. Please check your internet.');
}

/// Server error during authentication (5xx responses).
///
/// Display: t.errors.server
final class AuthServerFailure extends AuthFailure {
  const AuthServerFailure() : super('Server error. Please try again later.');
}

// ===========================================================================
// ACCOUNT FAILURES
// ===========================================================================

/// User account is disabled or banned.
///
/// Display: t.errors.auth.accountDisabled
final class AuthAccountDisabledFailure extends AuthFailure {
  final String? reason;

  const AuthAccountDisabledFailure([this.reason])
      : super('This account has been disabled');
}

/// User account not found.
///
/// Display: t.errors.auth.accountNotFound
final class AuthAccountNotFoundFailure extends AuthFailure {
  const AuthAccountNotFoundFailure() : super('Account not found');
}

// ===========================================================================
// UNKNOWN FAILURES
// ===========================================================================

/// Unknown authentication error.
///
/// Display: t.errors.unknown
final class AuthUnknownFailure extends AuthFailure {
  final String? originalError;

  const AuthUnknownFailure([this.originalError])
      : super('An unexpected error occurred');
}

// ===========================================================================
// FAILURE HELPERS
// ===========================================================================

/// Check if failure should be displayed to user.
///
/// Some failures (like session expired) might trigger automatic re-auth
/// instead of showing an error message.
bool shouldDisplayAuthFailure(AuthFailure failure) {
  return switch (failure) {
    AuthSessionExpiredFailure() => true, // Show, then redirect to login
    AuthNotAuthenticatedFailure() => false, // Just redirect to login
    _ => true,
  };
}

/// Check if failure is retryable.
bool isRetryableAuthFailure(AuthFailure failure) {
  return switch (failure) {
    AuthNetworkFailure() => true,
    AuthServerFailure() => true,
    AuthTokenRefreshFailure() => true,
    _ => false,
  };
}

/// Check if failure requires re-authentication.
bool requiresReauthentication(AuthFailure failure) {
  return switch (failure) {
    AuthSessionExpiredFailure() => true,
    AuthNotAuthenticatedFailure() => true,
    AuthTokenRefreshFailure() => true,
    _ => false,
  };
}

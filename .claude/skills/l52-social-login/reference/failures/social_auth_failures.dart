// Template: Sealed failure types for error handling
//
// Location: lib/features/{feature}/domain/failures/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

import '../../../../core/errors/failures.dart';

/// Base failure type for social authentication errors.
///
/// Extends the core [Failure] type for consistency with the data layer pattern.
/// Map to localized strings in presentation layer using t.errors.socialAuth.*
sealed class SocialAuthFailure extends Failure {
  const SocialAuthFailure(super.message);
}

// ===========================================================================
// GOOGLE SIGN-IN FAILURES
// ===========================================================================

/// User cancelled Google sign-in by dismissing the picker.
///
/// Display: Silent or t.errors.socialAuth.cancelled
final class GoogleSignInCancelledFailure extends SocialAuthFailure {
  const GoogleSignInCancelledFailure() : super('Google sign-in was cancelled');
}

/// Google sign-in failed due to technical error.
///
/// Display: t.errors.socialAuth.googleFailed
final class GoogleSignInFailedFailure extends SocialAuthFailure {
  /// Optional error code from Google SDK
  final String? errorCode;

  const GoogleSignInFailedFailure([this.errorCode])
      : super('Google sign-in failed');
}

/// Google account not available on device.
///
/// Display: t.errors.socialAuth.noGoogleAccount
final class GoogleAccountNotFoundFailure extends SocialAuthFailure {
  const GoogleAccountNotFoundFailure()
      : super('No Google account found on device');
}

// ===========================================================================
// APPLE SIGN-IN FAILURES
// ===========================================================================

/// User cancelled Apple sign-in by dismissing the dialog.
///
/// Display: Silent or t.errors.socialAuth.cancelled
final class AppleSignInCancelledFailure extends SocialAuthFailure {
  const AppleSignInCancelledFailure() : super('Apple sign-in was cancelled');
}

/// Apple sign-in failed due to technical error.
///
/// Display: t.errors.socialAuth.appleFailed
final class AppleSignInFailedFailure extends SocialAuthFailure {
  /// Optional error code from Apple SDK
  final String? errorCode;

  const AppleSignInFailedFailure([this.errorCode])
      : super('Apple sign-in failed');
}

/// Apple Sign-In not available (iOS < 13 or not configured).
///
/// Display: t.errors.socialAuth.appleNotAvailable
final class AppleSignInNotAvailableFailure extends SocialAuthFailure {
  const AppleSignInNotAvailableFailure()
      : super('Sign in with Apple is not available');
}

// ===========================================================================
// TOKEN / BACKEND FAILURES
// ===========================================================================

/// ID token validation failed (nonce mismatch, expired, invalid signature).
///
/// Display: t.errors.socialAuth.tokenValidationFailed
final class TokenValidationFailure extends SocialAuthFailure {
  const TokenValidationFailure() : super('Token validation failed');
}

/// OAuth flow is pending (waiting for redirect - Android only).
/// This is not really an error, used for state tracking.
///
/// Display: Show loading indicator
final class OAuthPendingFailure extends SocialAuthFailure {
  const OAuthPendingFailure() : super('OAuth flow pending');
}

/// Backend rejected the social sign-in (disabled provider, blocked user).
///
/// Display: t.errors.socialAuth.backendRejected
final class SocialAuthBackendFailure extends SocialAuthFailure {
  final String? reason;

  const SocialAuthBackendFailure([this.reason])
      : super('Authentication was rejected');
}

// ===========================================================================
// COMMON FAILURES
// ===========================================================================

/// Network connection error during social sign-in.
///
/// Display: t.errors.network with retry option
final class SocialAuthNetworkFailure extends SocialAuthFailure {
  const SocialAuthNetworkFailure()
      : super('Connection failed. Please check your internet.');
}

/// Server error (5xx responses).
///
/// Display: t.errors.server
final class SocialAuthServerFailure extends SocialAuthFailure {
  const SocialAuthServerFailure() : super('Server error. Please try again.');
}

/// Unknown social auth error.
///
/// Display: t.errors.unknown
final class SocialAuthUnknownFailure extends SocialAuthFailure {
  final String? originalError;

  const SocialAuthUnknownFailure([this.originalError])
      : super('An unexpected error occurred');
}

// ===========================================================================
// FAILURE MAPPING HELPER
// ===========================================================================

/// Map [SocialAuthFailure] to localized string.
///
/// Usage in presentation layer:
/// ```dart
/// final message = mapSocialAuthFailure(failure, t);
/// ```
///
/// This function should be in your presentation/utils/ folder and use
/// your actual i18n strings. Example implementation:
///
/// ```dart
/// String? mapSocialAuthFailure(SocialAuthFailure failure, Translations t) {
///   return switch (failure) {
///     // Cancellation - usually silent, return null to not show error
///     GoogleSignInCancelledFailure() => null,
///     AppleSignInCancelledFailure() => null,
///
///     // Google errors
///     GoogleSignInFailedFailure() => t.errors.socialAuth.googleFailed,
///     GoogleAccountNotFoundFailure() => t.errors.socialAuth.noGoogleAccount,
///
///     // Apple errors
///     AppleSignInFailedFailure() => t.errors.socialAuth.appleFailed,
///     AppleSignInNotAvailableFailure() => t.errors.socialAuth.appleNotAvailable,
///
///     // Token errors
///     TokenValidationFailure() => t.errors.socialAuth.tokenValidationFailed,
///     OAuthPendingFailure() => null, // Show loading, not error
///
///     // Backend errors
///     SocialAuthBackendFailure(:final reason) =>
///       reason ?? t.errors.socialAuth.backendRejected,
///
///     // Common errors
///     SocialAuthNetworkFailure() => t.errors.network,
///     SocialAuthServerFailure() => t.errors.server,
///     SocialAuthUnknownFailure() => t.errors.unknown,
///   };
/// }
/// ```

/// Check if failure should be displayed to user.
///
/// Cancellation failures are typically silent.
bool shouldDisplayFailure(SocialAuthFailure failure) {
  return switch (failure) {
    GoogleSignInCancelledFailure() => false,
    AppleSignInCancelledFailure() => false,
    OAuthPendingFailure() => false,
    _ => true,
  };
}

/// Check if failure is retryable.
bool isRetryableFailure(SocialAuthFailure failure) {
  return switch (failure) {
    SocialAuthNetworkFailure() => true,
    SocialAuthServerFailure() => true,
    GoogleSignInFailedFailure() => true,
    AppleSignInFailedFailure() => true,
    _ => false,
  };
}

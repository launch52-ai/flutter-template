// Template: Riverpod provider definition
//
// Location: lib/features/{feature}/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Template: Social Auth Provider Methods
//
// Location: lib/features/auth/presentation/providers/auth_provider.dart
//
// Add these providers and methods to your existing auth_provider.dart file.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/error_utils.dart';
import '../../domain/repositories/social_auth_repository.dart';

// ===========================================================================
// PROVIDER FOR SOCIAL AUTH REPOSITORY
// ===========================================================================

/// Provider for [SocialAuthRepository].
///
/// Returns the auth repository cast to SocialAuthRepository interface.
/// This allows access to social login methods while maintaining
/// separation of concerns.
@riverpod
SocialAuthRepository socialAuthRepository(Ref ref) {
  return ref.watch(authRepositoryProvider) as SocialAuthRepository;
}

// ===========================================================================
// AUTH NOTIFIER METHODS
// ===========================================================================

// Add these methods to your existing AuthNotifier class:

/// Sign in with Google.
///
/// Updates state to loading, attempts sign-in, then updates to
/// authenticated or error state.
Future<void> signInWithGoogle() async {
  _safeSetState(const AuthState.loading());

  try {
    final repository = ref.read(socialAuthRepositoryProvider);
    final result = await repository.signInWithGoogle();
    if (_disposed) return;

    if (result != null) {
      _safeSetState(AuthState.authenticated(
        user: result.user,
        isNewUser: result.isNewUser,
      ));
    } else {
      // User cancelled - return to unauthenticated without error
      _safeSetState(const AuthState.unauthenticated());
    }
  } catch (e) {
    if (_disposed) return;
    _safeSetState(AuthState.error(ErrorUtils.getUserFriendlyMessage(e)));
  }
}

/// Sign in with Apple.
///
/// On iOS: Native flow, updates state normally.
/// On Android: Opens browser, catches OAuthPendingException and
/// keeps loading state while waiting for deep link callback.
Future<void> signInWithApple() async {
  _safeSetState(const AuthState.loading());

  try {
    final repository = ref.read(socialAuthRepositoryProvider);
    final result = await repository.signInWithApple();
    if (_disposed) return;

    if (result != null) {
      _safeSetState(AuthState.authenticated(
        user: result.user,
        isNewUser: result.isNewUser,
      ));
    } else {
      // User cancelled
      _safeSetState(const AuthState.unauthenticated());
    }
  } on OAuthPendingException {
    // Android Apple Sign-In opened browser
    // Keep loading state - OAuthCallbackScreen handles completion
    // Do NOT change state here
  } catch (e) {
    if (_disposed) return;
    _safeSetState(AuthState.error(ErrorUtils.getUserFriendlyMessage(e)));
  }
}

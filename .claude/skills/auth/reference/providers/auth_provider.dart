// Template: Auth Provider (Notifier)
//
// Location: lib/features/auth/presentation/providers/auth_provider.dart
//
// Features:
// - Disposal-safe pattern with _safeSetState
// - isNewUser tracking for onboarding flows
// - Helper providers (isAuthenticated, currentUser)
// - Modular auth methods (email, phone, social - uncomment as needed)
//
// Run: dart run build_runner build

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/debug_constants.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/error_utils.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/email_auth_repository.dart';
import '../../domain/repositories/phone_auth_repository.dart';
// import '../../domain/repositories/social_auth_repository.dart'; // TODO: Uncomment if using social login
import 'auth_state.dart';

part 'auth_provider.g.dart';

// ============================================================================
// AUTH PROVIDERS
// ============================================================================
//
// Update these providers based on project requirements:
//
// If Email/Password = NO:
//   - Remove emailAuthRepositoryProvider
//   - Remove signInWithEmail, signUpWithEmail methods from AuthNotifier
//
// If Phone OTP = NO:
//   - Remove phoneAuthRepositoryProvider
//   - Remove sendOtp, verifyOtp methods from AuthNotifier
//
// If Social Login = NO:
//   - Remove socialAuthRepositoryProvider (already commented)
//   - Remove signInWithGoogle, signInWithApple methods from AuthNotifier
//
// ============================================================================

/// Provider for base AuthRepository.
@riverpod
AuthRepository authRepository(Ref ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final sharedPrefs = ref.watch(sharedPrefsProvider);

  if (DebugConstants.mockModeEnabled.value) {
    return MockAuthRepository(secureStorage, sharedPrefs);
  }

  final supabaseAuth = ref.watch(supabaseAuthProvider);
  return AuthRepositoryImpl(supabaseAuth, secureStorage, sharedPrefs);
}

/// Provider for EmailAuthRepository. (Delete if Email/Password = NO)
@riverpod
EmailAuthRepository emailAuthRepository(Ref ref) {
  return ref.watch(authRepositoryProvider) as EmailAuthRepository;
}

/// Provider for PhoneAuthRepository. (Delete if Phone OTP = NO)
@riverpod
PhoneAuthRepository phoneAuthRepository(Ref ref) {
  return ref.watch(authRepositoryProvider) as PhoneAuthRepository;
}

// /// Provider for SocialAuthRepository. (Uncomment if Social Login = YES)
// @riverpod
// SocialAuthRepository socialAuthRepository(Ref ref) {
//   return ref.watch(authRepositoryProvider) as SocialAuthRepository;
// }

/// Authentication state notifier.
@riverpod
final class AuthNotifier extends _$AuthNotifier {
  bool _disposed = false;

  @override
  AuthState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _checkAuthStatus();
    return const AuthState.initial();
  }

  void _safeSetState(AuthState newState) {
    if (!_disposed) {
      state = newState;
    }
  }

  Future<void> _checkAuthStatus() async {
    final repository = ref.read(authRepositoryProvider);

    try {
      final isAuthenticated = await repository.isAuthenticated();
      if (_disposed) return;

      if (isAuthenticated) {
        final user = await repository.getCurrentUser();
        if (_disposed) return;

        if (user != null) {
          _safeSetState(AuthState.authenticated(user: user, isNewUser: false));
        } else {
          _safeSetState(const AuthState.unauthenticated());
        }
      } else {
        _safeSetState(const AuthState.unauthenticated());
      }
    } catch (e) {
      if (_disposed) return;
      _safeSetState(const AuthState.unauthenticated());
    }
  }

  // ==========================================================================
  // EMAIL AUTH (Delete if Email/Password = NO)
  // ==========================================================================

  /// Sign in with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    _safeSetState(const AuthState.loading());

    try {
      final repository = ref.read(emailAuthRepositoryProvider);
      final result = await repository.signInWithEmail(email, password);
      if (_disposed) return;
      _safeSetState(AuthState.authenticated(
        user: result.user,
        isNewUser: result.isNewUser,
      ));
    } catch (e) {
      if (_disposed) return;
      _safeSetState(AuthState.error(ErrorUtils.getUserFriendlyMessage(e)));
    }
  }

  /// Sign up with email and password.
  Future<void> signUpWithEmail(String email, String password) async {
    _safeSetState(const AuthState.loading());

    try {
      final repository = ref.read(emailAuthRepositoryProvider);
      final result = await repository.signUpWithEmail(email, password);
      if (_disposed) return;
      _safeSetState(AuthState.authenticated(
        user: result.user,
        isNewUser: result.isNewUser,
      ));
    } catch (e) {
      if (_disposed) return;
      _safeSetState(AuthState.error(ErrorUtils.getUserFriendlyMessage(e)));
    }
  }

  // ==========================================================================
  // PHONE AUTH (Delete if Phone OTP = NO)
  // ==========================================================================

  /// Send OTP to phone number.
  Future<void> sendOtp(String phoneNumber) async {
    _safeSetState(const AuthState.loading());

    try {
      final repository = ref.read(phoneAuthRepositoryProvider);
      await repository.sendOtp(phoneNumber);
      if (_disposed) return;
      _safeSetState(const AuthState.otpSent());
    } catch (e) {
      if (_disposed) return;
      _safeSetState(AuthState.error(ErrorUtils.getUserFriendlyMessage(e)));
    }
  }

  /// Verify OTP and sign in.
  Future<void> verifyOtp(String phoneNumber, String otp) async {
    _safeSetState(const AuthState.loading());

    try {
      final repository = ref.read(phoneAuthRepositoryProvider);
      final result = await repository.verifyOtp(phoneNumber, otp);
      if (_disposed) return;
      _safeSetState(AuthState.authenticated(
        user: result.user,
        isNewUser: result.isNewUser,
      ));
    } catch (e) {
      if (_disposed) return;
      _safeSetState(AuthState.error(ErrorUtils.getUserFriendlyMessage(e)));
    }
  }

  // ==========================================================================
  // SOCIAL AUTH (Uncomment if Social Login = YES)
  // ==========================================================================

  // /// Sign in with Google.
  // Future<void> signInWithGoogle() async {
  //   _safeSetState(const AuthState.loading());
  //
  //   try {
  //     final repository = ref.read(socialAuthRepositoryProvider);
  //     final result = await repository.signInWithGoogle();
  //     if (_disposed) return;
  //     if (result != null) {
  //       _safeSetState(AuthState.authenticated(
  //         user: result.user,
  //         isNewUser: result.isNewUser,
  //       ));
  //     } else {
  //       _safeSetState(const AuthState.unauthenticated());
  //     }
  //   } catch (e) {
  //     if (_disposed) return;
  //     _safeSetState(AuthState.error(ErrorUtils.getUserFriendlyMessage(e)));
  //   }
  // }

  // /// Sign in with Apple.
  // Future<void> signInWithApple() async {
  //   _safeSetState(const AuthState.loading());
  //
  //   try {
  //     final repository = ref.read(socialAuthRepositoryProvider);
  //     final result = await repository.signInWithApple();
  //     if (_disposed) return;
  //     if (result != null) {
  //       _safeSetState(AuthState.authenticated(
  //         user: result.user,
  //         isNewUser: result.isNewUser,
  //       ));
  //     } else {
  //       _safeSetState(const AuthState.unauthenticated());
  //     }
  //   } catch (e) {
  //     if (_disposed) return;
  //     _safeSetState(AuthState.error(ErrorUtils.getUserFriendlyMessage(e)));
  //   }
  // }

  // ==========================================================================
  // BASE AUTH (Always required)
  // ==========================================================================

  /// Sign out the current user.
  Future<void> signOut() async {
    _safeSetState(const AuthState.loading());

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();
      if (_disposed) return;
      _safeSetState(const AuthState.unauthenticated());
    } catch (e) {
      if (_disposed) return;
      _safeSetState(const AuthState.unauthenticated());
    }
  }

  /// Update the current user in state.
  void updateUser(UserProfile user) {
    if (_disposed) return;
    final currentState = state;
    if (currentState is AuthStateAuthenticated) {
      _safeSetState(AuthState.authenticated(user: user, isNewUser: false));
    }
  }

  /// Reset to initial state.
  void reset() {
    _safeSetState(const AuthState.unauthenticated());
  }
}

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

/// Helper provider to check if user is authenticated.
@riverpod
bool isAuthenticated(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthStateAuthenticated;
}

/// Helper provider to get current user.
@riverpod
UserProfile? currentUser(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthStateAuthenticated) {
    return authState.user;
  }
  return null;
}

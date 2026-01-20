// Template: Local auth provider with Riverpod
//
// Location: lib/core/providers/local_auth_provider.dart
//
// Usage:
// 1. Copy to target location
// 2. Update imports
// 3. Run: dart run build_runner build

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/local_auth_service.dart';
import 'local_auth_settings.dart';
import 'local_auth_state.dart';

part 'local_auth_provider.g.dart';

/// Manages local authentication state and timeout logic.
@riverpod
class LocalAuthNotifier extends _$LocalAuthNotifier {
  /// Maximum failed attempts before requiring full re-login.
  /// Set to null to disable this behavior and let device handle lockout.
  static const int? maxFailedAttempts = null; // or 3 for banking apps

  int _failedAttempts = 0;
  DateTime? _lastAuthTime;

  @override
  LocalAuthState build() {
    // Check settings on build
    _checkInitialState();
    return const LocalAuthState.checking();
  }

  Future<void> _checkInitialState() async {
    final settings = await ref.read(localAuthSettingsProvider.future);

    if (!settings.enabled) {
      state = const LocalAuthState.disabled();
      return;
    }

    // If local auth is enabled, require auth on fresh start
    state = const LocalAuthState.requiresAuth();
  }

  /// Check if auth is required based on background duration.
  ///
  /// Called by AppLifecycleObserver when app resumes.
  Future<void> checkAuthRequired(Duration backgroundDuration) async {
    final settings = await ref.read(localAuthSettingsProvider.future);

    if (!settings.enabled) {
      state = const LocalAuthState.disabled();
      return;
    }

    // Timeout of -1 means never require re-auth
    if (settings.timeoutMinutes < 0) {
      return;
    }

    // Timeout of 0 means always require re-auth
    if (settings.timeoutMinutes == 0) {
      state = const LocalAuthState.requiresAuth();
      return;
    }

    // Check if background duration exceeds timeout
    final timeoutDuration = Duration(minutes: settings.timeoutMinutes);
    if (backgroundDuration >= timeoutDuration) {
      state = const LocalAuthState.requiresAuth();
    }
  }

  /// Attempt local authentication.
  ///
  /// [reason] - Message shown to user explaining why auth is needed.
  ///
  /// Returns true if authenticated successfully.
  Future<bool> authenticate({required String reason}) async {
    final service = ref.read(localAuthServiceProvider);

    final result = await service.authenticate(
      reason: reason,
      biometricOnly: false, // Allow device credential fallback
    );

    if (result.success) {
      _failedAttempts = 0;
      _lastAuthTime = DateTime.now();
      state = const LocalAuthState.authenticated();
      return true;
    }

    // Handle cancellation silently
    if (result.isCancelled) {
      // Don't change state - user can retry
      return false;
    }

    // Handle lockout
    if (result.isLockout) {
      state = LocalAuthState.lockedOut(
        message: result.errorMessage ?? 'Too many attempts',
      );
      return false;
    }

    // Handle failed attempt
    _failedAttempts++;

    // Check if should force full re-login
    if (maxFailedAttempts != null && _failedAttempts >= maxFailedAttempts!) {
      state = const LocalAuthState.requiresFullLogin();
      return false;
    }

    state = LocalAuthState.failed(
      message: result.errorMessage,
      attemptsRemaining: maxFailedAttempts != null
          ? maxFailedAttempts! - _failedAttempts
          : null,
    );
    return false;
  }

  /// Mark as authenticated (e.g., after full login).
  void markAuthenticated() {
    _failedAttempts = 0;
    _lastAuthTime = DateTime.now();
    state = const LocalAuthState.authenticated();
  }

  /// Reset to require auth (e.g., user locks manually).
  void lock() {
    state = const LocalAuthState.requiresAuth();
  }

  /// Called when user completes full re-login.
  void onFullLoginCompleted() {
    _failedAttempts = 0;
    _lastAuthTime = DateTime.now();
    state = const LocalAuthState.authenticated();
  }
}

// ===========================================================================
// CONVENIENCE PROVIDERS
// ===========================================================================

/// Whether local auth is available on this device.
@riverpod
Future<bool> canLocalAuth(Ref ref) async {
  final service = ref.watch(localAuthServiceProvider);
  return service.canAuthenticate();
}

/// Whether app content should be shown (authenticated or disabled).
@riverpod
bool isAppUnlocked(Ref ref) {
  final state = ref.watch(localAuthNotifierProvider);

  return state.maybeWhen(
    authenticated: () => true,
    disabled: () => true,
    orElse: () => false,
  );
}

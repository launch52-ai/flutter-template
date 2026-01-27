// Template: Account Deletion Notifier
//
// Location: lib/features/settings/presentation/providers/account_deletion_notifier.dart
//
// Usage:
// 1. Copy to target location
// 2. Adjust imports for your project structure
// 3. Run build_runner to generate .g.dart file
// 4. Wire up in settings screen

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/failures/account_deletion_failure.dart';
import '../../domain/repositories/settings_repository.dart';
// Import your providers
// import '../../../../core/providers.dart';

part 'account_deletion_notifier.freezed.dart';
part 'account_deletion_notifier.g.dart';

/// State for account deletion flow.
@freezed
sealed class AccountDeletionState with _$AccountDeletionState {
  /// Initial state, ready to delete.
  const factory AccountDeletionState.initial() = _Initial;

  /// Deletion in progress.
  const factory AccountDeletionState.loading() = _Loading;

  /// Deletion successful.
  const factory AccountDeletionState.success() = _Success;

  /// Deletion failed.
  const factory AccountDeletionState.error(AccountDeletionFailure failure) =
      _Error;
}

/// Notifier for account deletion operations.
///
/// Usage in widget:
/// ```dart
/// final state = ref.watch(accountDeletionNotifierProvider);
/// ref.listen(accountDeletionNotifierProvider, (_, state) {
///   state.whenOrNull(
///     success: () => context.go('/login'),
///     error: (failure) => showErrorSnackbar(failure.message),
///   );
/// });
/// ```
@riverpod
final class AccountDeletionNotifier extends _$AccountDeletionNotifier {
  bool _disposed = false;

  @override
  AccountDeletionState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const AccountDeletionState.initial();
  }

  void _safeSetState(AccountDeletionState newState) {
    if (!_disposed) state = newState;
  }

  /// Validates the confirmation input.
  ///
  /// Returns true if confirmation is valid.
  /// For "type DELETE" confirmation method.
  bool validateConfirmation(String input) {
    return input.trim().toUpperCase() == 'DELETE';
  }

  /// Deletes the user's account.
  ///
  /// [confirmation] - The confirmation input (optional, based on method).
  ///
  /// After successful deletion:
  /// - All user data is removed from backend
  /// - Local storage is cleared
  /// - User is signed out
  /// - Navigate to login screen
  Future<void> deleteAccount({String? confirmation}) async {
    // Validate confirmation if required
    if (confirmation != null && !validateConfirmation(confirmation)) {
      _safeSetState(
        const AccountDeletionState.error(
          AccountDeletionFailure.confirmation(),
        ),
      );
      return;
    }

    _safeSetState(const AccountDeletionState.loading());

    // Get repository from ref
    // final repository = ref.read(settingsRepositoryProvider);
    // For now, using a placeholder
    final SettingsRepository? repository = null;

    if (repository == null) {
      _safeSetState(
        const AccountDeletionState.error(
          AccountDeletionFailure.unknown(
            message: 'Repository not configured',
          ),
        ),
      );
      return;
    }

    final result = await repository.deleteAccount();

    if (_disposed) return;

    result.fold(
      (failure) => _safeSetState(AccountDeletionState.error(failure)),
      (_) => _safeSetState(const AccountDeletionState.success()),
    );
  }

  /// Resets state to initial.
  ///
  /// Call when user dismisses error or closes dialog.
  void reset() {
    _safeSetState(const AccountDeletionState.initial());
  }
}

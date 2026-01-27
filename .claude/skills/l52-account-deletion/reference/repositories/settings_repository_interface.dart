// Template: Settings Repository Interface Extension
//
// Location: lib/features/settings/domain/repositories/settings_repository.dart
//
// Usage:
// 1. Add this method to your existing SettingsRepository interface
// 2. Or create new interface if settings feature doesn't exist yet

import 'package:fpdart/fpdart.dart';

import '../failures/account_deletion_failure.dart';

/// Settings repository interface.
///
/// Add this method to your existing settings repository,
/// or use as base for new settings feature.
abstract interface class SettingsRepository {
  /// Permanently deletes the current user's account and all associated data.
  ///
  /// This operation:
  /// 1. Deletes the user account from the backend
  /// 2. Removes all user data from storage
  /// 3. Signs out the user locally
  /// 4. Resets analytics user ID
  ///
  /// Returns [Right(void)] on success.
  /// Returns [Left(AccountDeletionFailure)] on error.
  ///
  /// After successful deletion, the app should navigate to the login screen.
  Future<Either<AccountDeletionFailure, void>> deleteAccount();
}

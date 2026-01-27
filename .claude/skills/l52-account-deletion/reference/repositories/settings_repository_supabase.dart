// Template: Settings Repository - Supabase Implementation
//
// Location: lib/features/settings/data/repositories/settings_repository_impl.dart
//
// Usage:
// 1. Copy to target location
// 2. Adjust imports for your project structure
// 3. Create the Supabase Edge Function (see templates/supabase-delete-user-function.ts)
// 4. Update service injections as needed

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/failures/account_deletion_failure.dart';
import '../../domain/repositories/settings_repository.dart';
// Import your services
// import '../../../core/services/secure_storage_service.dart';
// import '../../../core/services/shared_prefs_service.dart';
// import '../../../core/services/analytics_service.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(
    this._supabase,
    // this._secureStorage,
    // this._sharedPrefs,
    // this._analytics,
  );

  final SupabaseClient _supabase;
  // final SecureStorageService _secureStorage;
  // final SharedPrefsService _sharedPrefs;
  // final AnalyticsService _analytics;

  @override
  Future<Either<AccountDeletionFailure, void>> deleteAccount() async {
    try {
      // 1. Check if user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return left(const AccountDeletionFailure.auth());
      }

      // 2. Call Edge Function to delete user
      // The Edge Function uses service_role key to delete user server-side
      final response = await _supabase.functions.invoke(
        'delete-user',
        body: {'userId': user.id},
      );

      if (response.status != 200) {
        final error = response.data?['error'] as String?;
        return left(AccountDeletionFailure.server(
          message: error ?? 'Failed to delete account',
          code: response.status.toString(),
        ));
      }

      // 3. Clean up local data
      await _cleanupLocalData();

      // 4. Sign out locally
      await _supabase.auth.signOut();

      return right(null);
    } on AuthException catch (e) {
      return left(AccountDeletionFailure.auth(message: e.message));
    } on FunctionException catch (e) {
      if (e.status == 429) {
        return left(const AccountDeletionFailure.rateLimit());
      }
      return left(AccountDeletionFailure.server(
        message: e.details?.toString() ?? 'Server error',
        code: e.status?.toString(),
      ));
    } catch (e, st) {
      // Check for network errors
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        return left(const AccountDeletionFailure.network());
      }
      return left(AccountDeletionFailure.unknown(error: e, stackTrace: st));
    }
  }

  Future<void> _cleanupLocalData() async {
    // Clear secure storage (tokens, PII)
    // await _secureStorage.deleteAll();

    // Clear shared preferences user data
    // await _sharedPrefs.remove(StorageKeys.hasUser);
    // await _sharedPrefs.remove(StorageKeys.userId);
    // await _sharedPrefs.remove(StorageKeys.userEmail);

    // Reset analytics
    // await _analytics.setUserId(null);
    // await _analytics.resetAnalyticsData();
  }
}

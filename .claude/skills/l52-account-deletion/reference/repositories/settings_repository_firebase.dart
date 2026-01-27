// Template: Settings Repository - Firebase Implementation
//
// Location: lib/features/settings/data/repositories/settings_repository_impl.dart
//
// Usage:
// 1. Copy to target location
// 2. Adjust imports for your project structure
// 3. Update service injections as needed
// 4. Note: Firebase may require re-authentication for sensitive operations

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/failures/account_deletion_failure.dart';
import '../../domain/repositories/settings_repository.dart';
// Import your services
// import '../../../core/services/secure_storage_service.dart';
// import '../../../core/services/shared_prefs_service.dart';
// import '../../../core/services/analytics_service.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(
    this._firebaseAuth,
    this._firestore,
    // this._secureStorage,
    // this._sharedPrefs,
    // this._analytics,
  );

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  // final SecureStorageService _secureStorage;
  // final SharedPrefsService _sharedPrefs;
  // final AnalyticsService _analytics;

  @override
  Future<Either<AccountDeletionFailure, void>> deleteAccount() async {
    try {
      // 1. Check if user is authenticated
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return left(const AccountDeletionFailure.auth());
      }

      final userId = user.uid;

      // 2. Delete user data from Firestore
      await _deleteUserData(userId);

      // 3. Delete Firebase Auth user
      // Note: This may throw requires-recent-login error
      await user.delete();

      // 4. Clean up local data
      await _cleanupLocalData();

      return right(null);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'requires-recent-login':
          // User needs to re-authenticate
          return left(const AccountDeletionFailure.auth(
            message: 'Please sign in again to delete your account.',
          ));
        case 'network-request-failed':
          return left(const AccountDeletionFailure.network());
        default:
          return left(AccountDeletionFailure.server(
            message: e.message ?? 'Failed to delete account',
            code: e.code,
          ));
      }
    } on FirebaseException catch (e) {
      return left(AccountDeletionFailure.server(
        message: e.message ?? 'Failed to delete account',
        code: e.code,
      ));
    } catch (e, st) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        return left(const AccountDeletionFailure.network());
      }
      return left(AccountDeletionFailure.unknown(error: e, stackTrace: st));
    }
  }

  /// Delete all user data from Firestore.
  ///
  /// Customize this based on your data model.
  Future<void> _deleteUserData(String userId) async {
    final batch = _firestore.batch();

    // Delete main user document
    batch.delete(_firestore.collection('users').doc(userId));

    // Delete user's subcollections (customize as needed)
    // Example: Delete user's posts
    // final posts = await _firestore
    //     .collection('posts')
    //     .where('userId', isEqualTo: userId)
    //     .get();
    // for (final doc in posts.docs) {
    //   batch.delete(doc.reference);
    // }

    await batch.commit();
  }

  Future<void> _cleanupLocalData() async {
    // Clear secure storage
    // await _secureStorage.deleteAll();

    // Clear shared preferences
    // await _sharedPrefs.remove(StorageKeys.hasUser);
    // await _sharedPrefs.remove(StorageKeys.userId);

    // Reset analytics
    // await _analytics.setUserId(null);
    // await _analytics.resetAnalyticsData();
  }
}

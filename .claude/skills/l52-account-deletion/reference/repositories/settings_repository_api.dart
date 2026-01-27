// Template: Settings Repository - Custom API Implementation
//
// Location: lib/features/settings/data/repositories/settings_repository_impl.dart
//
// Usage:
// 1. Copy to target location
// 2. Adjust imports for your project structure
// 3. Update API endpoint to match your backend
// 4. Update service injections as needed

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/failures/account_deletion_failure.dart';
import '../../domain/repositories/settings_repository.dart';
// Import your services
// import '../../../core/network/dio_client.dart';
// import '../../../core/services/secure_storage_service.dart';
// import '../../../core/services/shared_prefs_service.dart';
// import '../../../core/services/analytics_service.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(
    this._dio,
    // this._secureStorage,
    // this._sharedPrefs,
    // this._analytics,
  );

  final Dio _dio;
  // final SecureStorageService _secureStorage;
  // final SharedPrefsService _sharedPrefs;
  // final AnalyticsService _analytics;

  @override
  Future<Either<AccountDeletionFailure, void>> deleteAccount() async {
    try {
      // 1. Call deletion endpoint
      // Assumes auth token is added by Dio interceptor
      final response = await _dio.delete('/api/users/me');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = response.data?['error'] as String?;
        return left(AccountDeletionFailure.server(
          message: error ?? 'Failed to delete account',
          code: response.statusCode.toString(),
        ));
      }

      // 2. Clean up local data
      await _cleanupLocalData();

      return right(null);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return left(const AccountDeletionFailure.network());

        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final errorMessage =
              e.response?.data?['error'] as String? ?? e.message;

          if (statusCode == 401) {
            return left(const AccountDeletionFailure.auth());
          }
          if (statusCode == 429) {
            final retryAfter = e.response?.headers.value('Retry-After');
            return left(AccountDeletionFailure.rateLimit(
              retryAfter: retryAfter != null
                  ? Duration(seconds: int.tryParse(retryAfter) ?? 60)
                  : null,
            ));
          }

          return left(AccountDeletionFailure.server(
            message: errorMessage ?? 'Server error',
            code: statusCode?.toString(),
          ));

        default:
          return left(AccountDeletionFailure.unknown(
            error: e,
            stackTrace: e.stackTrace,
          ));
      }
    } catch (e, st) {
      return left(AccountDeletionFailure.unknown(error: e, stackTrace: st));
    }
  }

  Future<void> _cleanupLocalData() async {
    // Clear auth tokens from secure storage
    // await _secureStorage.delete(key: StorageKeys.accessToken);
    // await _secureStorage.delete(key: StorageKeys.refreshToken);
    // await _secureStorage.deleteAll();

    // Clear user preferences
    // await _sharedPrefs.remove(StorageKeys.hasUser);
    // await _sharedPrefs.remove(StorageKeys.userId);

    // Reset analytics
    // await _analytics.setUserId(null);
    // await _analytics.resetAnalyticsData();
  }
}

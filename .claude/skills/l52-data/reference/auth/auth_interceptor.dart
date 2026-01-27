// Template: Dio interceptor
//
// Location: lib/core/data/auth/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Authentication Interceptor with Token Refresh
// QueuedInterceptor that automatically refreshes expired tokens.

import 'package:dio/dio.dart';

/// Authentication interceptor with automatic token refresh.
final class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio dio,
    required SecureStorageService storage,
    required void Function() onAuthFailure,
  })  : _dio = dio,
        _storage = storage,
        _onAuthFailure = onAuthFailure;

  final Dio _dio;
  final SecureStorageService _storage;
  final void Function() _onAuthFailure;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }

    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Try to refresh token
    if (_isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
      if (refreshToken == null) {
        _onAuthFailure();
        handler.next(err);
        return;
      }

      // Refresh the token
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );

      final newAccessToken = response.data!['access_token'] as String;
      final newRefreshToken = response.data!['refresh_token'] as String;

      await _storage.write(key: StorageKeys.accessToken, value: newAccessToken);
      await _storage.write(
          key: StorageKeys.refreshToken, value: newRefreshToken);

      // Retry original request
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await _dio.fetch(options);
      handler.resolve(retryResponse);
    } catch (e) {
      _onAuthFailure();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}

// -----------------------------------------------------
// Placeholder interfaces - replace with actual implementations
// -----------------------------------------------------

abstract class SecureStorageService {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
}

class StorageKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
}

// -----------------------------------------------------
// Usage:
// -----------------------------------------------------
// final dio = Dio();
// dio.interceptors.add(
//   AuthInterceptor(
//     dio: dio,
//     storage: secureStorageService,
//     onAuthFailure: () {
//       // Navigate to login, clear session
//       ref.read(authNotifierProvider.notifier).signOut();
//     },
//   ),
// );

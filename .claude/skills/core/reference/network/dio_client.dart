// Template: Dio Client
//
// Location: lib/core/network/dio_client.dart
//
// Usage:
// 1. Copy to target location
// 2. Configure base URL from .env
// 3. Add auth interceptor for token handling

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/app_constants.dart';
import '../constants/debug_constants.dart';

part 'dio_client.g.dart';

/// Dio client provider.
/// Configured with interceptors for auth, logging, error handling.
@riverpod
Dio dioClient(Ref ref) {
  final baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: AppConstants.apiTimeout,
    receiveTimeout: AppConstants.apiTimeout,
    sendTimeout: AppConstants.apiTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Auth interceptor
  dio.interceptors.add(_AuthInterceptor(ref));

  // Logging interceptor (debug only)
  if (DebugConstants.logNetworkRequests) {
    dio.interceptors.add(_LoggingInterceptor());
  }

  // Error interceptor
  dio.interceptors.add(_ErrorInterceptor());

  return dio;
}

/// Auth interceptor.
/// Adds Bearer token and handles 401 responses.
final class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Get token from secure storage
    // final storage = _ref.read(secureStorageProvider);
    // final token = await storage.read(SecureStorageKeys.accessToken);
    //
    // if (token != null) {
    //   options.headers['Authorization'] = 'Bearer $token';
    // }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Handle token refresh or logout
      // final refreshed = await _refreshToken();
      // if (refreshed) {
      //   // Retry request
      //   final response = await _retry(err.requestOptions);
      //   return handler.resolve(response);
      // }
    }

    handler.next(err);
  }
}

/// Logging interceptor.
/// Logs requests and responses in debug mode.
final class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌─────────────────────────────────────────────────────────');
    debugPrint('│ ${options.method} ${options.uri}');
    if (options.data != null) {
      debugPrint('│ Body: ${options.data}');
    }
    debugPrint('└─────────────────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('┌─────────────────────────────────────────────────────────');
    debugPrint('│ ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('│ Response: ${response.data}');
    debugPrint('└─────────────────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌─────────────────────────────────────────────────────────');
    debugPrint('│ ERROR ${err.response?.statusCode} ${err.requestOptions.uri}');
    debugPrint('│ ${err.message}');
    debugPrint('└─────────────────────────────────────────────────────────');
    handler.next(err);
  }
}

/// Error interceptor.
/// Normalizes error handling.
final class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Normalize connection errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      handler.next(DioException(
        requestOptions: err.requestOptions,
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timed out',
      ));
      return;
    }

    if (err.type == DioExceptionType.connectionError) {
      handler.next(DioException(
        requestOptions: err.requestOptions,
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      ));
      return;
    }

    handler.next(err);
  }
}

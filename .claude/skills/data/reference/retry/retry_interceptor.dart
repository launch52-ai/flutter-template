// Template: Dio interceptor
//
// Location: lib/core/data/retry/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Dio Retry Interceptor
// Automatic retry interceptor for Dio with exponential backoff.

import 'dart:math';

import 'package:dio/dio.dart';

import 'retry_config.dart';

/// Automatic retry interceptor for Dio.
final class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.config = const RetryConfig(),
  });

  final Dio dio;
  final RetryConfig config;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final extra = err.requestOptions.extra;
    final attempt = (extra['retry_attempt'] as int?) ?? 0;

    if (_shouldRetry(err) && attempt < config.maxAttempts) {
      // Calculate delay
      final delay = Duration(
        milliseconds: (config.initialDelay.inMilliseconds *
                pow(config.backoffMultiplier, attempt))
            .toInt(),
      );

      await Future.delayed(delay);

      // Clone request with incremented attempt
      final options = err.requestOptions;
      options.extra['retry_attempt'] = attempt + 1;

      try {
        final response = await dio.fetch(options);
        handler.resolve(response);
        return;
      } on DioException catch (e) {
        handler.next(e);
        return;
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.badResponse =>
        err.response?.statusCode != null && err.response!.statusCode! >= 500,
      _ => false,
    };
  }
}

// -----------------------------------------------------
// Usage:
// -----------------------------------------------------
// final dio = Dio();
// dio.interceptors.add(
//   RetryInterceptor(
//     dio: dio,
//     config: const RetryConfig(maxAttempts: 3),
//   ),
// );

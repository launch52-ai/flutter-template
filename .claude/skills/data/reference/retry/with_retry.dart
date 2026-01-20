// Template: Retry logic for network requests
//
// Location: lib/core/data/retry/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Simple Retry with Exponential Backoff
// Helper function to retry operations with configurable backoff.

import 'package:dio/dio.dart';

import 'retry_config.dart';

/// Execute with retry.
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  RetryConfig config = const RetryConfig(),
  bool Function(Exception)? shouldRetry,
}) async {
  var attempt = 0;
  var delay = config.initialDelay;

  while (true) {
    attempt++;
    try {
      return await operation();
    } on Exception catch (e) {
      // Check if we should retry
      final canRetry = shouldRetry?.call(e) ?? _isRetryable(e);

      if (!canRetry || attempt >= config.maxAttempts) {
        rethrow;
      }

      // Wait before retry
      await Future.delayed(delay);

      // Calculate next delay with exponential backoff
      delay = Duration(
        milliseconds: (delay.inMilliseconds * config.backoffMultiplier).toInt(),
      );
      if (delay > config.maxDelay) {
        delay = config.maxDelay;
      }
    }
  }
}

bool _isRetryable(Exception e) {
  if (e is DioException) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.badResponse =>
        e.response?.statusCode != null && e.response!.statusCode! >= 500,
      _ => false,
    };
  }
  return false;
}

// -----------------------------------------------------
// Usage in Repository:
// -----------------------------------------------------
// @override
// Future<List<Post>> getPosts() async {
//   return withRetry(
//     () async {
//       final response = await _dio.get<List<dynamic>>('/posts');
//       return response.data!
//           .map((json) => PostModel.fromJson(json).toEntity())
//           .toList();
//     },
//     config: const RetryConfig(maxAttempts: 3),
//   );
// }

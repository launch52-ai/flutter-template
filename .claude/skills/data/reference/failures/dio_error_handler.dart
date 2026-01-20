// Template: Failure type definitions
//
// Location: lib/features/{feature}/domain/failures/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Dio Error Handler
// Maps DioException to typed Failure.
// This file goes in: lib/core/network/dio_error_handler.dart

import 'package:dio/dio.dart';
import '../errors/failures.dart';

/// Maps DioException to typed Failure.
Failure mapDioError(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      const Failure.network(NetworkFailure.timeout()),
    DioExceptionType.connectionError =>
      const Failure.network(NetworkFailure.noConnection()),
    DioExceptionType.badResponse => _mapStatusCode(e.response?.statusCode),
    _ => Failure.network(NetworkFailure.unknown(e.message)),
  };
}

Failure _mapStatusCode(int? statusCode) {
  return switch (statusCode) {
    400 => const Failure.server(ServerFailure.badRequest()),
    401 => const Failure.server(ServerFailure.unauthorized()),
    403 => const Failure.server(ServerFailure.forbidden()),
    404 => const Failure.server(ServerFailure.notFound()),
    409 => const Failure.server(ServerFailure.conflict()),
    500 => const Failure.server(ServerFailure.internal()),
    _ => Failure.server(ServerFailure.unknown(statusCode)),
  };
}

// -----------------------------------------------------
// Usage in Repository:
// -----------------------------------------------------
// @override
// Future<List<Task>> getAll() async {
//   try {
//     final models = await _remoteDataSource.fetchAll();
//     return models.map((m) => m.toEntity()).toList();
//   } on DioException catch (e) {
//     throw mapDioError(e);
//   }
// }

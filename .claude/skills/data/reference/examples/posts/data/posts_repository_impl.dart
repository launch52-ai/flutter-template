// Template: Repository implementation
//
// Location: lib/features/{feature}/data/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: NestJS backend code
// Complete repository implementation with error handling.

import 'package:dio/dio.dart';

import '../domain/post.dart';
import '../domain/posts_repository.dart';
import 'create_post_request.dart';
import 'post_model.dart';
import 'update_post_request.dart';

final class PostsRepositoryImpl implements PostsRepository {
  const PostsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<({List<Post> items, int total})> getAll({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/posts',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data!;
      final items = (data['data'] as List)
          .map((json) => PostModel.fromJson(json).toEntity())
          .toList();
      return (items: items, total: data['total'] as int);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<Post?> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/posts/$id');
      return PostModel.fromJson(response.data!).toEntity();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _mapDioError(e);
    }
  }

  @override
  Future<Post> create({
    required String title,
    required String content,
    String? categoryId,
    List<String> tags = const [],
  }) async {
    try {
      final request = CreatePostRequest(
        title: title,
        content: content,
        categoryId: categoryId,
        tags: tags,
      );
      final response = await _dio.post<Map<String, dynamic>>(
        '/posts',
        data: request.toJson(),
      );
      return PostModel.fromJson(response.data!).toEntity();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<Post> update({
    required String id,
    String? title,
    String? content,
    String? categoryId,
    List<String>? tags,
  }) async {
    try {
      final request = UpdatePostRequest(
        title: title,
        content: content,
        categoryId: categoryId,
        tags: tags,
      );
      final response = await _dio.patch<Map<String, dynamic>>(
        '/posts/$id',
        data: request.toJson(),
      );
      return PostModel.fromJson(response.data!).toEntity();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/posts/$id');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Failure _mapDioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const NetworkFailure('Connection timeout'),
      DioExceptionType.connectionError =>
        const NetworkFailure('No internet connection'),
      DioExceptionType.badResponse => _mapStatusCode(e.response),
      _ => UnknownFailure(e.message ?? 'Unexpected error'),
    };
  }

  Failure _mapStatusCode(Response? response) {
    final statusCode = response?.statusCode ?? 0;
    final message = response?.data?['message'] as String? ?? 'Server error';

    return switch (statusCode) {
      400 => ValidationFailure(message),
      401 => const AuthFailure('Please sign in again'),
      403 => const AuthFailure('Permission denied'),
      404 => ServerFailure(message),
      >= 500 => const ServerFailure('Server error'),
      _ => ServerFailure(message),
    };
  }
}

// Placeholder failure types - use your actual failure classes
sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

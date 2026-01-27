// Template: Repository implementation
//
// Location: test/features/{feature}/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Repository Test Example
// Complete example of testing a repository with mocked Dio.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_dio.dart';

// Replace with actual imports:
// import 'package:your_app/features/posts/data/repositories/posts_repository_impl.dart';
// import 'package:your_app/features/posts/domain/entities/post.dart';
// import 'package:your_app/core/errors/failures.dart';

void main() {
  late PostsRepositoryImpl sut; // System under test
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    sut = PostsRepositoryImpl(mockDio);
  });

  group('getPosts', () {
    test('returns posts on success', () async {
      // Arrange
      when(() => mockDio.get<List<dynamic>>(any()))
          .thenAnswer((_) async => mockResponse([
                {'id': '1', 'title': 'Test', 'created_at': '2024-01-01'},
              ]));

      // Act
      final result = await sut.getPosts();

      // Assert
      expect(result, hasLength(1));
      expect(result.first.title, 'Test');
      verify(() => mockDio.get<List<dynamic>>('/posts')).called(1);
    });

    test('throws NetworkFailure on connection error', () async {
      // Arrange
      when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
        mockDioError(type: DioExceptionType.connectionError),
      );

      // Act & Assert
      expect(
        () => sut.getPosts(),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('throws AuthFailure on 401', () async {
      // Arrange
      when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
        mockDioError(
          type: DioExceptionType.badResponse,
          statusCode: 401,
        ),
      );

      // Act & Assert
      expect(
        () => sut.getPosts(),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('throws ServerFailure on 500', () async {
      // Arrange
      when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
        mockDioError(
          type: DioExceptionType.badResponse,
          statusCode: 500,
        ),
      );

      // Act & Assert
      expect(
        () => sut.getPosts(),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}

// -----------------------------------------------------
// Placeholder types - replace with actual implementations
// -----------------------------------------------------

class PostsRepositoryImpl {
  PostsRepositoryImpl(this._dio);
  final MockDio _dio;

  Future<List<Post>> getPosts() async {
    throw UnimplementedError();
  }
}

class Post {
  Post({required this.id, required this.title});
  final String id;
  final String title;
}

class NetworkFailure implements Exception {}

class AuthFailure implements Exception {}

class ServerFailure implements Exception {}

// Template: Repository implementation
//
// Location: test/features/{feature}/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Widget Test with Provider Overrides
// Testing widgets that depend on Riverpod providers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Replace with actual imports:
// import 'package:your_app/features/posts/domain/repositories/posts_repository.dart';
// import 'package:your_app/features/posts/presentation/screens/posts_screen.dart';

void main() {
  group('PostsScreen', () {
    testWidgets('shows loading then posts', (tester) async {
      // Arrange
      final mockRepository = MockPostsRepository();
      when(() => mockRepository.getPosts()).thenAnswer(
        (_) async => [
          Post(id: '1', title: 'Test Post', createdAt: DateTime.now()),
        ],
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            postsRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(home: PostsScreen()),
        ),
      );

      // Assert - loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for async
      await tester.pumpAndSettle();

      // Assert - loaded
      expect(find.text('Test Post'), findsOneWidget);
    });

    testWidgets('shows error on failure', (tester) async {
      // Arrange
      final mockRepository = MockPostsRepository();
      when(() => mockRepository.getPosts()).thenThrow(
        const NetworkFailure('No connection'),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            postsRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(home: PostsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No connection'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('refresh button reloads data', (tester) async {
      // Arrange
      final mockRepository = MockPostsRepository();
      var callCount = 0;
      when(() => mockRepository.getPosts()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw const NetworkFailure('No connection');
        }
        return [Post(id: '1', title: 'Test Post', createdAt: DateTime.now())];
      });

      // Act - initial load fails
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            postsRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(home: PostsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - error shown
      expect(find.text('No connection'), findsOneWidget);

      // Act - tap refresh
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Assert - data shown
      expect(find.text('Test Post'), findsOneWidget);
    });
  });
}

// -----------------------------------------------------
// Placeholder types - replace with actual implementations
// -----------------------------------------------------

class MockPostsRepository extends Mock implements PostsRepository {}

abstract class PostsRepository {
  Future<List<Post>> getPosts();
}

class Post {
  Post({required this.id, required this.title, required this.createdAt});
  final String id;
  final String title;
  final DateTime createdAt;
}

class NetworkFailure implements Exception {
  const NetworkFailure(this.message);
  final String message;
}

final postsRepositoryProvider =
    Provider<PostsRepository>((ref) => throw UnimplementedError());

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) => const Placeholder();
}

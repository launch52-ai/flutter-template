// Template: Riverpod provider definition
//
// Location: lib/core/data/pagination/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Infinite Scroll Provider
// Riverpod provider for paginated lists with load more.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'infinite_scroll_provider.freezed.dart';
part 'infinite_scroll_provider.g.dart';

// Replace 'Post' with your entity type
// Replace 'postsRepositoryProvider' with your repository provider

@freezed
sealed class PostsState with _$PostsState {
  const factory PostsState.initial() = PostsStateInitial;
  const factory PostsState.loading() = PostsStateLoading;
  const factory PostsState.loaded({
    required List<Post> items,
    required bool hasMore,
    @Default(false) bool isLoadingMore,
    String? nextCursor,
  }) = PostsStateLoaded;
  const factory PostsState.error(String message) = PostsStateError;
}

@riverpod
final class PostsNotifier extends _$PostsNotifier {
  bool _disposed = false;

  @override
  PostsState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _loadInitial();
    return const PostsState.initial();
  }

  Future<void> _loadInitial() async {
    state = const PostsState.loading();

    try {
      final result = await ref.read(postsRepositoryProvider).getPosts();
      if (_disposed) return;

      state = PostsState.loaded(
        items: result.items,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
      );
    } catch (e) {
      if (_disposed) return;
      state = PostsState.error(e.toString());
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! PostsStateLoaded) return;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    state = currentState.copyWith(isLoadingMore: true);

    try {
      final result = await ref.read(postsRepositoryProvider).getPosts(
            cursor: currentState.nextCursor,
          );
      if (_disposed) return;

      state = PostsState.loaded(
        items: [...currentState.items, ...result.items],
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
      );
    } catch (e) {
      if (_disposed) return;
      // Keep existing data, just stop loading
      state = currentState.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    await _loadInitial();
  }
}

// Placeholder types - replace with actual imports
class Post {}
final postsRepositoryProvider = Provider<dynamic>((ref) => throw UnimplementedError());

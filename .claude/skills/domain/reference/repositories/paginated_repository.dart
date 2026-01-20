// Template: Repository interface
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Repository with Pagination
// For large datasets that need paged fetching.

import '../entities/post.dart';

/// Paginated result container.
final class PaginatedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  const PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < total;
  int get totalPages => (total / pageSize).ceil();
}

/// Repository for post operations with pagination.
abstract interface class PostsRepository {
  /// Get posts with pagination.
  Future<PaginatedResult<Post>> getPosts({
    int page = 1,
    int pageSize = 20,
  });

  /// Get posts by author with pagination.
  Future<PaginatedResult<Post>> getPostsByAuthor({
    required String authorId,
    int page = 1,
    int pageSize = 20,
  });
}

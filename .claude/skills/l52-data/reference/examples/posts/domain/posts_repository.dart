// Template: Repository interface
//
// Location: lib/features/{feature}/domain/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: NestJS backend code
// Shows repository interface extracted from controller methods.

import 'post.dart';

/// Posts repository interface.
abstract interface class PostsRepository {
  /// Get paginated posts.
  Future<({List<Post> items, int total})> getAll({
    int page = 1,
    int limit = 20,
  });

  /// Get post by ID.
  Future<Post?> getById(String id);

  /// Create a new post.
  Future<Post> create({
    required String title,
    required String content,
    String? categoryId,
    List<String> tags = const [],
  });

  /// Update existing post.
  Future<Post> update({
    required String id,
    String? title,
    String? content,
    String? categoryId,
    List<String>? tags,
  });

  /// Delete post.
  Future<void> delete(String id);
}

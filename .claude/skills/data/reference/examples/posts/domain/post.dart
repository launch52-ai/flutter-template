// Template: Example implementation
//
// Location: lib/features/{feature}/domain/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: NestJS backend code
// Input: posts.controller.ts, create-post.dto.ts, post.entity.ts
//
// This shows what Claude generates for domain entities from backend code.

/// Post domain entity.
final class Post {
  const Post({
    required this.id,
    required this.title,
    required this.content,
    this.categoryId,
    required this.tags,
    required this.author,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final String? categoryId;
  final List<String> tags;
  final PostAuthor author;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

/// Author nested within Post.
final class PostAuthor {
  const PostAuthor({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? avatarUrl;
}

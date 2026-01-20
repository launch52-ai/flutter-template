// Template: Domain entity with Freezed
//
// Location: lib/features/{feature}/domain/entities/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Simple Entity (Minimal)
// Just data holder, no equality or copyWith needed.

/// A task item in the task list.
final class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.completedAt,
  });
}

// No ==, hashCode, or copyWith - only add when needed.

// Template: Repository interface
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Basic CRUD Repository Interface
// Standard create, read, update, delete operations.

import '../entities/task.dart';

/// Repository for task operations.
abstract interface class TasksRepository {
  /// Get all tasks.
  Future<List<Task>> getAll();

  /// Get a single task by ID.
  /// Returns null if not found.
  Future<Task?> getById(String id);

  /// Create a new task.
  Future<Task> create({
    required String title,
    String? description,
  });

  /// Update an existing task.
  /// Throws if task not found.
  Future<Task> update({
    required String id,
    String? title,
    String? description,
  });

  /// Delete a task.
  /// Throws if task not found.
  Future<void> delete(String id);
}

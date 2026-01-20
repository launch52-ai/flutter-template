// Template: Repository interface
//
// Location: lib/features/{feature}/domain/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: Endpoint description
// Repository interface matching the API endpoints.

import 'task.dart';

/// Tasks repository interface.
abstract interface class TasksRepository {
  /// Get all tasks.
  Future<List<Task>> getAll();

  /// Get task by ID.
  Future<Task?> getById(String id);

  /// Create a new task.
  Future<Task> create({
    required String title,
    String? description,
    DateTime? dueDate,
    required TaskPriority priority,
  });

  /// Update existing task.
  Future<Task> update({
    required String id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
  });

  /// Delete task.
  Future<void> delete(String id);
}

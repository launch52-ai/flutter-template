// Template: Example implementation
//
// Location: lib/features/{feature}/domain/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: Endpoint description
// Input:
//   GET /tasks → List<Task>
//   POST /tasks { title, description?, due_date?, priority } → Task
//   Task has: id, title, description?, due_date?, priority (enum), status (enum), created_at
//
// Shows enum handling and computed properties.

/// Task priority levels.
enum TaskPriority { low, medium, high }

/// Task status.
enum TaskStatus { todo, inProgress, done }

/// Task domain entity.
final class Task {
  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;

  /// Whether task is overdue.
  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != TaskStatus.done;

  /// Whether task is completed.
  bool get isCompleted => status == TaskStatus.done;
}

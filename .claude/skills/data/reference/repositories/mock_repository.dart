// Template: Repository implementation
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Mock Repository
// For testing and development without backend.

import '../../domain/entities/task.dart';
import '../../domain/repositories/tasks_repository.dart';

/// Mock implementation of TasksRepository for testing/development.
final class MockTasksRepository implements TasksRepository {
  final List<Task> _items = [];
  int _idCounter = 0;

  @override
  Future<List<Task>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_items);
  }

  @override
  Future<Task?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _items.where((item) => item.id == id).firstOrNull;
  }

  @override
  Future<Task> create({
    required String title,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final item = Task(
      id: 'mock-${++_idCounter}',
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );
    _items.add(item);
    return item;
  }

  @override
  Future<Task> update({
    required String id,
    String? title,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('Task not found');
    }
    // In real implementation, use copyWith if available
    final existing = _items[index];
    final updated = Task(
      id: existing.id,
      title: title ?? existing.title,
      description: description ?? existing.description,
      createdAt: existing.createdAt,
    );
    _items[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _items.removeWhere((item) => item.id == id);
  }

  /// Reset mock data for testing.
  void reset() {
    _items.clear();
    _idCounter = 0;
  }

  /// Seed with test data.
  void seed(List<Task> items) {
    _items
      ..clear()
      ..addAll(items);
  }
}

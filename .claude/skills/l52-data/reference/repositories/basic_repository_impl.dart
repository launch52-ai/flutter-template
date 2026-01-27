// Template: Repository implementation
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Basic CRUD Repository Implementation
// Implements domain interface, maps DTOs to entities.

import '../../domain/entities/task.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../models/task_model.dart';
import '../models/create_task_request.dart';
import '../models/update_task_request.dart';
import '../data_sources/tasks_remote_data_source.dart';

final class TasksRepositoryImpl implements TasksRepository {
  const TasksRepositoryImpl({
    required TasksRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final TasksRemoteDataSource _remoteDataSource;

  @override
  Future<List<Task>> getAll() async {
    final models = await _remoteDataSource.fetchAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Task?> getById(String id) async {
    final model = await _remoteDataSource.fetchById(id);
    return model?.toEntity();
  }

  @override
  Future<Task> create({
    required String title,
    String? description,
  }) async {
    final request = CreateTaskRequest(
      title: title,
      description: description,
    );
    final model = await _remoteDataSource.create(request);
    return model.toEntity();
  }

  @override
  Future<Task> update({
    required String id,
    String? title,
    String? description,
  }) async {
    final request = UpdateTaskRequest(
      title: title,
      description: description,
    );
    final model = await _remoteDataSource.update(id, request);
    return model.toEntity();
  }

  @override
  Future<void> delete(String id) async {
    await _remoteDataSource.delete(id);
  }
}

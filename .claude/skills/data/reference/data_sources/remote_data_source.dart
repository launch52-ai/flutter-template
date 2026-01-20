// Template: Data source for API/local storage
//
// Location: lib/features/{feature}/data/data_sources/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Remote Data Source (Dio)
// Handles API calls, returns DTOs (not entities).

import 'package:dio/dio.dart';
import '../models/task_model.dart';
import '../models/create_task_request.dart';
import '../models/update_task_request.dart';

final class TasksRemoteDataSource {
  const TasksRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<TaskModel>> fetchAll() async {
    final response = await _dio.get('/tasks');
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => TaskModel.fromJson(json)).toList();
  }

  Future<TaskModel?> fetchById(String id) async {
    try {
      final response = await _dio.get('/tasks/$id');
      return TaskModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<TaskModel> create(CreateTaskRequest request) async {
    final response = await _dio.post('/tasks', data: request.toJson());
    return TaskModel.fromJson(response.data);
  }

  Future<TaskModel> update(String id, UpdateTaskRequest request) async {
    final response = await _dio.patch('/tasks/$id', data: request.toJson());
    return TaskModel.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/tasks/$id');
  }
}

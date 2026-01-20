// Template: Freezed DTO model for API serialization
//
// Location: lib/features/{feature}/data/models/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Simple DTO
// Basic Freezed model with JSON serialization and entity mapping.

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/task.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
abstract class TaskModel with _$TaskModel {
  const TaskModel._();

  const factory TaskModel({
    required String id,
    required String title,
    String? description,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  /// Convert to domain entity.
  Task toEntity() => Task(
        id: id,
        title: title,
        description: description,
        createdAt: createdAt,
      );

  /// Create from domain entity.
  factory TaskModel.fromEntity(Task entity) => TaskModel(
        id: entity.id,
        title: entity.title,
        description: entity.description,
        createdAt: entity.createdAt,
      );
}

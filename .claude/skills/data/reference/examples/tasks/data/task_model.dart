// Template: Freezed DTO model for API serialization
//
// Location: lib/features/{feature}/data/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: Endpoint description
// Shows enum handling with @JsonKey(unknownEnumValue: ...) for graceful fallback.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/task.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
abstract class TaskModel with _$TaskModel {
  const TaskModel._();

  const factory TaskModel({
    required String id,
    required String title,
    String? description,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    // unknownEnumValue handles unknown API values gracefully
    @JsonKey(unknownEnumValue: TaskPriority.medium)
    required TaskPriority priority,
    @JsonKey(unknownEnumValue: TaskStatus.todo)
    required TaskStatus status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  Task toEntity() => Task(
        id: id,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        status: status,
        createdAt: createdAt,
      );

  factory TaskModel.fromEntity(Task entity) => TaskModel(
        id: entity.id,
        title: entity.title,
        description: entity.description,
        dueDate: entity.dueDate,
        priority: entity.priority,
        status: entity.status,
        createdAt: entity.createdAt,
      );
}

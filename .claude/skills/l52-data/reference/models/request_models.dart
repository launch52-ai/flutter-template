// Template: Freezed DTO model for API serialization
//
// Location: lib/features/{feature}/data/models/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Request DTOs
// Separate models for create/update request bodies (not all fields needed).

import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_requests.freezed.dart';
part 'task_requests.g.dart';

/// Request body for creating a task.
@freezed
abstract class CreateTaskRequest with _$CreateTaskRequest {
  const factory CreateTaskRequest({
    required String title,
    String? description,
    @JsonKey(name: 'due_date') DateTime? dueDate,
  }) = _CreateTaskRequest;

  factory CreateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTaskRequestFromJson(json);
}

/// Request body for updating a task.
/// Uses includeIfNull: false to omit null fields from JSON.
@freezed
abstract class UpdateTaskRequest with _$UpdateTaskRequest {
  const factory UpdateTaskRequest({
    String? title,
    String? description,
    @JsonKey(name: 'due_date', includeIfNull: false) DateTime? dueDate,
    @JsonKey(includeIfNull: false) bool? completed,
  }) = _UpdateTaskRequest;

  factory UpdateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTaskRequestFromJson(json);
}

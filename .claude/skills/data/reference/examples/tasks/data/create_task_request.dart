// Template: Example implementation
//
// Location: lib/features/{feature}/data/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: Endpoint description
// Request model for POST /tasks

import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/task.dart';

part 'create_task_request.freezed.dart';
part 'create_task_request.g.dart';

@freezed
abstract class CreateTaskRequest with _$CreateTaskRequest {
  const factory CreateTaskRequest({
    required String title,
    String? description,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    required TaskPriority priority,
  }) = _CreateTaskRequest;

  factory CreateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTaskRequestFromJson(json);
}

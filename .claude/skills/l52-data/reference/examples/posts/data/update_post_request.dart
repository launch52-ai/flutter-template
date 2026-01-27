// Template: Example implementation
//
// Location: lib/features/{feature}/data/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: NestJS UpdatePostDto
// Request model for PATCH /posts/:id
// All fields optional for partial updates.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_post_request.freezed.dart';
part 'update_post_request.g.dart';

@freezed
abstract class UpdatePostRequest with _$UpdatePostRequest {
  const factory UpdatePostRequest({
    String? title,
    String? content,
    @JsonKey(name: 'category_id') String? categoryId,
    List<String>? tags,
  }) = _UpdatePostRequest;

  factory UpdatePostRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePostRequestFromJson(json);
}

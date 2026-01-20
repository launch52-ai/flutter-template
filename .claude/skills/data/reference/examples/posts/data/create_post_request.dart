// Template: Example implementation
//
// Location: lib/features/{feature}/data/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: NestJS CreatePostDto
// Request model for POST /posts

import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_post_request.freezed.dart';
part 'create_post_request.g.dart';

@freezed
abstract class CreatePostRequest with _$CreatePostRequest {
  const factory CreatePostRequest({
    required String title,
    required String content,
    @JsonKey(name: 'category_id') String? categoryId,
    @Default([]) List<String> tags,
  }) = _CreatePostRequest;

  factory CreatePostRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePostRequestFromJson(json);
}

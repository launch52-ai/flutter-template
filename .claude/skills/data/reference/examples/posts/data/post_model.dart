// Template: Freezed DTO model for API serialization
//
// Location: lib/features/{feature}/data/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: NestJS backend code
// Shows DTO with @JsonKey for snake_case mapping and nested models.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/post.dart';

part 'post_model.freezed.dart';
part 'post_model.g.dart';

@freezed
abstract class PostModel with _$PostModel {
  const PostModel._();

  const factory PostModel({
    required String id,
    required String title,
    required String content,
    @JsonKey(name: 'category_id') String? categoryId,
    @Default([]) List<String> tags,
    required PostAuthorModel author,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _PostModel;

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);

  Post toEntity() => Post(
        id: id,
        title: title,
        content: content,
        categoryId: categoryId,
        tags: tags,
        author: author.toEntity(),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory PostModel.fromEntity(Post entity) => PostModel(
        id: entity.id,
        title: entity.title,
        content: entity.content,
        categoryId: entity.categoryId,
        tags: entity.tags,
        author: PostAuthorModel.fromEntity(entity.author),
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}

@freezed
abstract class PostAuthorModel with _$PostAuthorModel {
  const PostAuthorModel._();

  const factory PostAuthorModel({
    required String id,
    required String name,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _PostAuthorModel;

  factory PostAuthorModel.fromJson(Map<String, dynamic> json) =>
      _$PostAuthorModelFromJson(json);

  PostAuthor toEntity() => PostAuthor(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
      );

  factory PostAuthorModel.fromEntity(PostAuthor entity) => PostAuthorModel(
        id: entity.id,
        name: entity.name,
        avatarUrl: entity.avatarUrl,
      );
}

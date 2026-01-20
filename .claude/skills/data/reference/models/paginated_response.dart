// Template: Freezed DTO model
//
// Location: lib/features/{feature}/data/models/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Paginated Response
// Generic wrapper for paginated API responses.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated_response.freezed.dart';
part 'paginated_response.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const factory PaginatedResponse({
    required List<T> items,
    required int total,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
  }) = _PaginatedResponse<T>;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$PaginatedResponseFromJson(json, fromJsonT);
}

// Usage in data source:
// final response = await _dio.get('/tasks', queryParameters: {'page': 1});
// return PaginatedResponse<TaskModel>.fromJson(
//   response.data,
//   (json) => TaskModel.fromJson(json as Map<String, dynamic>),
// );

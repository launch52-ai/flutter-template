// Template: Cursor-based pagination
//
// Location: lib/core/data/pagination/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Cursor-Based Pagination
// Better for real-time data. Uses cursor (usually last item ID) instead of page number.

/// Domain entity for cursor-based results.
final class CursorResult<T> {
  const CursorResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}

// -----------------------------------------------------
// Repository Implementation Example:
// -----------------------------------------------------
// @override
// Future<CursorResult<Post>> getPosts({
//   String? cursor,
//   int limit = 20,
// }) async {
//   try {
//     final response = await _dio.get<Map<String, dynamic>>(
//       '/posts',
//       queryParameters: {
//         if (cursor != null) 'cursor': cursor,
//         'limit': limit,
//       },
//     );
//
//     final data = response.data!;
//     final items = (data['data'] as List)
//         .map((json) => PostModel.fromJson(json).toEntity())
//         .toList();
//
//     return CursorResult(
//       items: items,
//       nextCursor: data['next_cursor'] as String?,
//       hasMore: data['has_more'] as bool? ?? false,
//     );
//   } on DioException catch (e) {
//     throw mapDioError(e);
//   }
// }

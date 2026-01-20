// Template: Repository interface
//
// Location: lib/core/data/pagination/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Offset-Based Pagination
// Domain entity for paginated results with page numbers.

/// Domain entity for paginated results.
final class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  final List<T> items;
  final int total;
  final int page;
  final int perPage;

  bool get hasMore => page * perPage < total;
  int get totalPages => (total / perPage).ceil();
}

// -----------------------------------------------------
// Repository Interface Example:
// -----------------------------------------------------
// abstract interface class PostsRepository {
//   Future<PaginatedResult<Post>> getPosts({
//     int page = 1,
//     int perPage = 20,
//   });
// }

// -----------------------------------------------------
// Repository Implementation Example:
// -----------------------------------------------------
// @override
// Future<PaginatedResult<Post>> getPosts({
//   int page = 1,
//   int perPage = 20,
// }) async {
//   try {
//     final response = await _dio.get<Map<String, dynamic>>(
//       '/posts',
//       queryParameters: {
//         'page': page,
//         'per_page': perPage,
//       },
//     );
//
//     final data = response.data!;
//     final items = (data['data'] as List)
//         .map((json) => PostModel.fromJson(json).toEntity())
//         .toList();
//
//     return PaginatedResult(
//       items: items,
//       total: data['total'] as int,
//       page: data['page'] as int,
//       perPage: data['per_page'] as int,
//     );
//   } on DioException catch (e) {
//     throw mapDioError(e);
//   }
// }

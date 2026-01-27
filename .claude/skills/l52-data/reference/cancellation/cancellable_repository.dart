// Template: Repository implementation
//
// Location: lib/core/data/cancellation/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Request Cancellation
// Repository with cancellation support for search and other interruptible operations.

import 'package:dio/dio.dart';

/// Repository with cancellation support.
final class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._dio);

  final Dio _dio;
  CancelToken? _searchCancelToken;

  @override
  Future<List<SearchResult>> search(String query) async {
    // Cancel previous search
    _searchCancelToken?.cancel('New search started');
    _searchCancelToken = CancelToken();

    try {
      final response = await _dio.get<List<dynamic>>(
        '/search',
        queryParameters: {'q': query},
        cancelToken: _searchCancelToken,
      );

      return response.data!
          .map((json) => SearchResultModel.fromJson(json).toEntity())
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Return empty for cancelled requests
        return [];
      }
      throw _mapDioError(e);
    }
  }

  void cancelSearch() {
    _searchCancelToken?.cancel('Search cancelled');
    _searchCancelToken = null;
  }

  Failure _mapDioError(DioException e) {
    // Map to your failure types
    throw UnimplementedError();
  }
}

// -----------------------------------------------------
// Provider with Cancellation Example:
// -----------------------------------------------------
//
// @riverpod
// final class SearchNotifier extends _$SearchNotifier {
//   CancelToken? _cancelToken;
//   bool _disposed = false;
//
//   @override
//   SearchState build() {
//     _disposed = false;
//     ref.onDispose(() {
//       _disposed = true;
//       _cancelToken?.cancel('Provider disposed');
//     });
//     return const SearchState.initial();
//   }
//
//   Future<void> search(String query) async {
//     if (query.isEmpty) {
//       state = const SearchState.initial();
//       return;
//     }
//
//     // Cancel previous
//     _cancelToken?.cancel();
//     _cancelToken = CancelToken();
//
//     state = const SearchState.loading();
//
//     try {
//       final results = await ref.read(searchRepositoryProvider).search(
//             query,
//             cancelToken: _cancelToken,
//           );
//
//       if (_disposed) return;
//       state = SearchState.loaded(results);
//     } on DioException catch (e) {
//       if (e.type == DioExceptionType.cancel) return;
//       if (_disposed) return;
//       state = SearchState.error(e.message ?? 'Search failed');
//     }
//   }
// }

// -----------------------------------------------------
// Placeholder types - replace with actual implementations
// -----------------------------------------------------

abstract class SearchRepository {
  Future<List<SearchResult>> search(String query);
}

class SearchResult {}

class SearchResultModel {
  static SearchResultModel fromJson(dynamic json) => SearchResultModel();
  SearchResult toEntity() => SearchResult();
}

class Failure implements Exception {}

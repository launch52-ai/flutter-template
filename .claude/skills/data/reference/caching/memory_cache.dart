// Template: Repository implementation
//
// Location: lib/core/data/caching/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: In-Memory Cache with TTL
// Simple in-memory cache with time-to-live expiration.

/// In-memory cache with TTL.
final class MemoryCache<T> {
  MemoryCache({this.ttl = const Duration(minutes: 5)});

  final Duration ttl;
  final Map<String, _CacheEntry<T>> _cache = {};

  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  void set(String key, T value) {
    _cache[key] = _CacheEntry(
      value: value,
      expiry: DateTime.now().add(ttl),
    );
  }

  void invalidate(String key) {
    _cache.remove(key);
  }

  void invalidateAll() {
    _cache.clear();
  }
}

final class _CacheEntry<T> {
  const _CacheEntry({required this.value, required this.expiry});

  final T value;
  final DateTime expiry;
}

// -----------------------------------------------------
// Usage in Repository:
// -----------------------------------------------------
// final class PostsRepositoryImpl implements PostsRepository {
//   final Dio _dio;
//   final MemoryCache<List<Post>> _cache;
//
//   PostsRepositoryImpl(this._dio)
//       : _cache = MemoryCache(ttl: const Duration(minutes: 5));
//
//   @override
//   Future<List<Post>> getPosts({bool forceRefresh = false}) async {
//     const cacheKey = 'posts_all';
//
//     // Check cache first
//     if (!forceRefresh) {
//       final cached = _cache.get(cacheKey);
//       if (cached != null) return cached;
//     }
//
//     // Fetch from API
//     try {
//       final response = await _dio.get<List<dynamic>>('/posts');
//       final posts = response.data!
//           .map((json) => PostModel.fromJson(json).toEntity())
//           .toList();
//
//       // Cache result
//       _cache.set(cacheKey, posts);
//
//       return posts;
//     } on DioException catch (e) {
//       // On error, return stale cache if available
//       final stale = _cache.get(cacheKey);
//       if (stale != null) return stale;
//       throw mapDioError(e);
//     }
//   }
//
//   @override
//   Future<Post> createPost(CreatePostRequest request) async {
//     // ... create post
//     // Invalidate cache after mutation
//     _cache.invalidate('posts_all');
//     // ... return created post
//   }
// }

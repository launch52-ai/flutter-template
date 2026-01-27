// Template: Repository implementation
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Repository with Caching
// In-memory cache with fallback to local storage on network failure.

import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';
import '../models/product_model.dart';
import '../data_sources/products_remote_data_source.dart';
import '../data_sources/products_local_data_source.dart';

final class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl({
    required ProductsRemoteDataSource remoteDataSource,
    required ProductsLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final ProductsRemoteDataSource _remoteDataSource;
  final ProductsLocalDataSource _localDataSource;

  // In-memory cache
  List<ProductModel>? _cachedProducts;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  bool get _isCacheValid =>
      _cachedProducts != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration;

  @override
  Future<List<Product>> getAll({bool forceRefresh = false}) async {
    // Return cache if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid) {
      return _cachedProducts!.map((m) => m.toEntity()).toList();
    }

    try {
      // Fetch from remote
      final models = await _remoteDataSource.fetchAll();

      // Update cache
      _cachedProducts = models;
      _cacheTime = DateTime.now();

      // Persist to local storage
      await _localDataSource.saveAll(models);

      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      // Fallback to local storage on network error
      final localModels = await _localDataSource.getAll();
      if (localModels.isNotEmpty) {
        return localModels.map((m) => m.toEntity()).toList();
      }
      rethrow;
    }
  }

  @override
  Future<Product?> getById(String id) async {
    // Check cache first
    if (_isCacheValid) {
      final cached = _cachedProducts!.where((m) => m.id == id).firstOrNull;
      if (cached != null) return cached.toEntity();
    }

    // Fetch from remote
    final model = await _remoteDataSource.fetchById(id);
    return model?.toEntity();
  }

  void clearCache() {
    _cachedProducts = null;
    _cacheTime = null;
  }
}

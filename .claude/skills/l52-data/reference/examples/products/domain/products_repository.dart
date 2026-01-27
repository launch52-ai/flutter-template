// Template: Repository interface
//
// Location: lib/features/{feature}/domain/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: OpenAPI spec
// Repository interface from paths section.

import 'product.dart';

/// Products repository interface.
abstract interface class ProductsRepository {
  /// Get products, optionally filtered by category.
  Future<List<Product>> getAll({String? categorySlug});

  /// Get product by ID.
  Future<Product?> getById(String id);

  /// Get all categories.
  Future<List<ProductCategory>> getCategories();
}

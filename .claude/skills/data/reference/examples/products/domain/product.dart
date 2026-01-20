// Template: Example implementation
//
// Location: lib/features/{feature}/domain/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: OpenAPI spec
// Input: openapi.yaml with Product and Category schemas
//
// Shows computed properties for business logic.

/// Product domain entity.
final class Product {
  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.discountPrice,
    required this.images,
    required this.category,
    required this.inStock,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final double price;
  final double? discountPrice;
  final List<String> images;
  final ProductCategory category;
  final bool inStock;
  final DateTime createdAt;

  /// Current price considering discount.
  double get currentPrice => discountPrice ?? price;

  /// Whether product has a discount.
  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  /// Discount percentage if applicable.
  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((price - discountPrice!) / price) * 100).round();
  }

  /// Primary image or null.
  String? get primaryImage => images.isNotEmpty ? images.first : null;
}

/// Product category.
final class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;
}

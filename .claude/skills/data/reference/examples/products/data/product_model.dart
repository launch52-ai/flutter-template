// Template: Freezed DTO model for API serialization
//
// Location: lib/features/{feature}/data/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Generated from: OpenAPI spec
// Shows handling of:
// - Nested objects (category)
// - Arrays (images)
// - Default values (@Default)
// - snake_case to camelCase mapping

import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/product.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
abstract class ProductModel with _$ProductModel {
  const ProductModel._();

  const factory ProductModel({
    required String id,
    required String name,
    String? description,
    required double price,
    @JsonKey(name: 'discount_price') double? discountPrice,
    @Default([]) List<String> images,
    required ProductCategoryModel category,
    @JsonKey(name: 'in_stock') @Default(true) bool inStock,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Product toEntity() => Product(
        id: id,
        name: name,
        description: description,
        price: price,
        discountPrice: discountPrice,
        images: images,
        category: category.toEntity(),
        inStock: inStock,
        createdAt: createdAt,
      );

  factory ProductModel.fromEntity(Product entity) => ProductModel(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        price: entity.price,
        discountPrice: entity.discountPrice,
        images: entity.images,
        category: ProductCategoryModel.fromEntity(entity.category),
        inStock: entity.inStock,
        createdAt: entity.createdAt,
      );
}

@freezed
abstract class ProductCategoryModel with _$ProductCategoryModel {
  const ProductCategoryModel._();

  const factory ProductCategoryModel({
    required String id,
    required String name,
    required String slug,
  }) = _ProductCategoryModel;

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$ProductCategoryModelFromJson(json);

  ProductCategory toEntity() => ProductCategory(
        id: id,
        name: name,
        slug: slug,
      );

  factory ProductCategoryModel.fromEntity(ProductCategory entity) =>
      ProductCategoryModel(
        id: entity.id,
        name: entity.name,
        slug: entity.slug,
      );
}

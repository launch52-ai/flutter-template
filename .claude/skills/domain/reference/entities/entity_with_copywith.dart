// Template: Domain entity with Freezed
//
// Location: lib/features/{feature}/domain/entities/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Entity with copyWith
// Add copyWith when:
// - You need to create modified copies (immutable updates)
// - Entity is used in state management where you update fields

/// An item in the shopping cart.
/// Quantity can be updated - needs copyWith.
final class CartItem {
  final String productId;
  final String productName;
  final int priceInCents;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.priceInCents,
    required this.quantity,
  });

  /// Total price for this line item.
  int get totalCents => priceInCents * quantity;

  /// Price formatted as dollars.
  String get priceFormatted => '\$${(priceInCents / 100).toStringAsFixed(2)}';

  /// Total formatted as dollars.
  String get totalFormatted => '\$${(totalCents / 100).toStringAsFixed(2)}';

  CartItem copyWith({
    String? productId,
    String? productName,
    int? priceInCents,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      priceInCents: priceInCents ?? this.priceInCents,
      quantity: quantity ?? this.quantity,
    );
  }

  // Equality by productId (same product = same item)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem && other.productId == productId;

  @override
  int get hashCode => productId.hashCode;
}

// Usage:
// final item = CartItem(productId: '1', productName: 'Widget', priceInCents: 999, quantity: 1);
// final updated = item.copyWith(quantity: 2);  // Only changes quantity

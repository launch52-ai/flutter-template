// Template: Value object
//
// Location: lib/features/{feature}/domain/value_objects/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Value Object (Money)
// Encapsulates monetary value with operations.

/// Monetary value with currency.
final class Money {
  final int cents;
  final String currency;

  const Money({
    required this.cents,
    this.currency = 'USD',
  });

  /// Creates Money from a dollar amount.
  factory Money.fromDollars(double amount, {String currency = 'USD'}) {
    return Money(cents: (amount * 100).round(), currency: currency);
  }

  /// Amount in dollars.
  double get dollars => cents / 100;

  /// Formatted string (e.g., "$12.50").
  String get formatted {
    const symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£'};
    final symbol = symbols[currency] ?? currency;
    return '$symbol${dollars.toStringAsFixed(2)}';
  }

  /// Add two money values (must be same currency).
  Money operator +(Money other) {
    assert(currency == other.currency, 'Cannot add different currencies');
    return Money(cents: cents + other.cents, currency: currency);
  }

  /// Subtract money values.
  Money operator -(Money other) {
    assert(currency == other.currency, 'Cannot subtract different currencies');
    return Money(cents: cents - other.cents, currency: currency);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && other.cents == cents && other.currency == currency;

  @override
  int get hashCode => Object.hash(cents, currency);

  @override
  String toString() => formatted;
}

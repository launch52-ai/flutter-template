// Template: Enum definition
//
// Location: lib/features/{feature}/domain/enums/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Enum with Methods
// Enum with computed properties and state machine logic.

/// Order status in e-commerce flow.
enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled;

  /// Whether order can be cancelled.
  bool get canCancel => this == pending || this == confirmed;

  /// Whether order is in a final state.
  bool get isFinal => this == delivered || this == cancelled;

  /// Next status in the flow (null if final).
  OrderStatus? get nextStatus {
    return switch (this) {
      pending => confirmed,
      confirmed => processing,
      processing => shipped,
      shipped => delivered,
      delivered => null,
      cancelled => null,
    };
  }
}

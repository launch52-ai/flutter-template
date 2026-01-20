// Template: Enum definition
//
// Location: lib/features/{feature}/domain/enums/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Enum with Properties
// Enhanced enum with labels and values.

/// Priority level for tasks.
enum Priority {
  low('Low', 1),
  medium('Medium', 2),
  high('High', 3),
  urgent('Urgent', 4);

  const Priority(this.label, this.value);

  /// Human-readable label.
  final String label;

  /// Numeric value for sorting.
  final int value;

  /// Whether this is high priority or above.
  bool get isHighPriority => value >= 3;
}

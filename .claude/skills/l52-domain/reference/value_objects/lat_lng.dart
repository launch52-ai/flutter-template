// Template: Value object
//
// Location: lib/features/{feature}/domain/value_objects/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Value Object (Coordinate)
// Value objects are small, immutable, compared by value.
// Always need == and hashCode.

/// Geographic coordinates.
final class LatLng {
  final double latitude;
  final double longitude;

  const LatLng({
    required this.latitude,
    required this.longitude,
  });

  /// Whether coordinates are within valid ranges.
  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

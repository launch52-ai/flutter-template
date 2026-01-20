// Template: Domain entity with Freezed
//
// Location: lib/features/{feature}/domain/entities/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Entity with Equality
// Add == and hashCode when:
// - Entity is in a List that gets compared (state management)
// - Entity is used as a Map key or in a Set
// - You need to check if two instances represent the same thing

/// A user in the system.
/// Used in auth state - equality needed for state comparison.
final class User {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
  });

  /// Display name or email as fallback.
  String get displayNameOrEmail => displayName ?? email;

  /// Whether user has a custom display name.
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;

  /// Whether user has an avatar.
  bool get hasAvatar => avatarUrl != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          other.id == id &&
          other.email == email &&
          other.displayName == displayName &&
          other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, email, displayName, avatarUrl);
}

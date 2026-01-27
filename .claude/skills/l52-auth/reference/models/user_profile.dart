// Template: UserProfile Model
//
// Location: lib/features/auth/data/models/user_profile.dart
//
// Usage:
// 1. Copy to target location
// 2. Add/remove fields based on your user data
// 3. Run: dart run build_runner build

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// User profile model for authenticated users.
///
/// This model represents the core user data used across the app.
/// Extend with additional fields based on your requirements.
@freezed
final class UserProfile with _$UserProfile {
  const factory UserProfile({
    /// Unique user identifier from auth provider.
    required String id,

    /// User's email address (may be null for phone-only auth).
    String? email,

    /// User's display name.
    String? displayName,

    /// URL to user's avatar image.
    String? avatarUrl,

    /// Phone number in E.164 format (if phone auth used).
    String? phoneNumber,

    /// When the user account was created.
    DateTime? createdAt,

    /// When the user profile was last updated.
    DateTime? updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

// ===========================================================================
// FACTORY METHODS
// ===========================================================================

extension UserProfileFactory on UserProfile {
  /// Create UserProfile from Supabase User.
  ///
  /// Example:
  /// ```dart
  /// final profile = UserProfileX.fromSupabaseUser(supabase.auth.currentUser!);
  /// ```
  static UserProfile fromSupabaseUser(dynamic user) {
    // user is supabase_flutter User
    return UserProfile(
      id: user.id as String,
      email: user.email as String?,
      displayName: user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      phoneNumber: user.phone as String?,
      createdAt: DateTime.tryParse(user.createdAt ?? ''),
      updatedAt: DateTime.tryParse(user.updatedAt ?? ''),
    );
  }

  /// Create empty profile for unauthenticated state.
  static UserProfile empty() => const UserProfile(id: '');
}

// ===========================================================================
// COMPUTED PROPERTIES
// ===========================================================================

extension UserProfileHelpers on UserProfile {
  /// Check if profile has minimal required data.
  bool get isComplete => id.isNotEmpty;

  /// Get initials for avatar placeholder.
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return '?';
  }

  /// Get display identifier (name, email, or phone).
  String get displayIdentifier {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      return phoneNumber!;
    }
    return 'User';
  }
}

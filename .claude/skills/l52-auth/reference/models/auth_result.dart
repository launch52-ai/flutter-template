// Template: AuthResult Model
//
// Location: lib/features/auth/data/models/auth_result.dart
//
// Usage:
// 1. Copy to target location
// 2. Import UserProfile
// 3. Run: dart run build_runner build

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_profile.dart';

part 'auth_result.freezed.dart';

/// Result of a successful authentication operation.
///
/// Contains the authenticated user profile and metadata about the sign-in.
/// Used by all auth methods (social, phone, email) to return consistent data.
@freezed
final class AuthResult with _$AuthResult {
  const factory AuthResult({
    /// The authenticated user's profile.
    required UserProfile user,

    /// Whether this is the user's first sign-in.
    ///
    /// Use this to route new users to onboarding/profile completion.
    @Default(false) bool isNewUser,

    /// The authentication method used.
    AuthMethod? method,

    /// Access token (if using custom API, not Supabase).
    String? accessToken,

    /// Refresh token (if using custom API, not Supabase).
    String? refreshToken,
  }) = _AuthResult;
}

/// Authentication methods supported by the app.
enum AuthMethod {
  /// Email and password authentication.
  email,

  /// Google OAuth sign-in.
  google,

  /// Apple OAuth sign-in.
  apple,

  /// Phone OTP authentication.
  phone,

  /// Magic link (passwordless email).
  magicLink,

  /// Anonymous/guest authentication.
  anonymous,
}

// ===========================================================================
// FACTORY METHODS
// ===========================================================================

extension AuthResultFactory on AuthResult {
  /// Create AuthResult from Supabase AuthResponse.
  ///
  /// Example:
  /// ```dart
  /// final response = await supabase.auth.signInWithOAuth(...);
  /// final result = AuthResultX.fromSupabaseResponse(response, AuthMethod.google);
  /// ```
  static AuthResult fromSupabaseResponse(
    dynamic response,
    AuthMethod method,
  ) {
    // response is supabase_flutter AuthResponse
    final user = response.user;
    final isNew = user?.createdAt == user?.updatedAt;

    return AuthResult(
      user: UserProfileFactory.fromSupabaseUser(user),
      isNewUser: isNew,
      method: method,
    );
  }

  /// Create AuthResult from API response with tokens.
  ///
  /// Example:
  /// ```dart
  /// final result = AuthResultX.fromApiResponse(
  ///   userData: json['user'],
  ///   accessToken: json['access_token'],
  ///   refreshToken: json['refresh_token'],
  ///   method: AuthMethod.phone,
  /// );
  /// ```
  static AuthResult fromApiResponse({
    required Map<String, dynamic> userData,
    required String accessToken,
    String? refreshToken,
    required AuthMethod method,
    bool isNewUser = false,
  }) {
    return AuthResult(
      user: UserProfile.fromJson(userData),
      isNewUser: isNewUser,
      method: method,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}

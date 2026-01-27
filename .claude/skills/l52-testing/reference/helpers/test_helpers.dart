/// Test data factory functions.
///
/// Reduces boilerplate and ensures consistent test data across tests.
/// Pattern from Essential Feed: `any*()` factory methods.
library;

import '../../lib/features/auth/data/models/auth_result.dart';
import '../../lib/features/auth/data/models/user_profile.dart';

// =============================================================================
// PRIMITIVE FACTORIES
// =============================================================================

/// Returns a test URL string.
String anyUrl() => 'https://example.com';

/// Returns a test URI.
Uri anyUri() => Uri.parse(anyUrl());

/// Returns a generic test exception.
Exception anyException([String? message]) =>
    Exception(message ?? 'any error');

/// Returns a generic error message.
String anyErrorMessage() => 'any error message';

// =============================================================================
// ID FACTORIES
// =============================================================================

/// Returns a test ID string.
String anyId() => 'any-id-123';

/// Returns a test user ID.
String anyUserId() => 'user-123-abc';

// =============================================================================
// AUTH FACTORIES
// =============================================================================

/// Returns a test email address.
String anyEmail() => 'test@example.com';

/// Returns a test password.
String anyPassword() => 'password123';

/// Returns a test phone number.
String anyPhoneNumber() => '+1234567890';

/// Returns a test OTP code.
String anyOtp() => '123456';

/// Returns a test access token.
String anyAccessToken() => 'access-token-abc-123';

/// Returns a test refresh token.
String anyRefreshToken() => 'refresh-token-xyz-456';

// =============================================================================
// TIMESTAMP FACTORIES
// =============================================================================

/// Returns a fixed test timestamp.
DateTime anyTimestamp() => DateTime(2024, 1, 15, 12, 0, 0);

/// Returns a timestamp in the future.
DateTime futureTimestamp([Duration duration = const Duration(days: 1)]) =>
    DateTime.now().add(duration);

/// Returns a timestamp in the past.
DateTime pastTimestamp([Duration duration = const Duration(days: 1)]) =>
    DateTime.now().subtract(duration);

// =============================================================================
// MODEL FACTORIES
// =============================================================================

/// Creates a test [UserProfile].
///
/// All fields have sensible defaults but can be overridden.
UserProfile anyUserProfile({
  String? id,
  String? email,
  String? fullName,
  String? phoneNumber,
  String? avatarUrl,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return UserProfile(
    id: id ?? anyUserId(),
    email: email ?? anyEmail(),
    fullName: fullName ?? 'Test User',
    phoneNumber: phoneNumber,
    avatarUrl: avatarUrl,
    createdAt: createdAt ?? anyTimestamp(),
    updatedAt: updatedAt,
  );
}

/// Creates a test [AuthResult].
AuthResult anyAuthResult({
  UserProfile? user,
  bool isNewUser = false,
  String? accessToken,
  String? refreshToken,
}) {
  return AuthResult(
    user: user ?? anyUserProfile(),
    isNewUser: isNewUser,
    accessToken: accessToken ?? anyAccessToken(),
    refreshToken: refreshToken ?? anyRefreshToken(),
  );
}

/// Creates a [UserProfile] with minimal data (new user scenario).
UserProfile anyMinimalUserProfile({String? id}) {
  return UserProfile(
    id: id ?? anyUserId(),
    createdAt: anyTimestamp(),
  );
}

// =============================================================================
// JSON FACTORIES
// =============================================================================

/// Creates user JSON for testing deserialization.
Map<String, dynamic> makeUserJson({
  String? id,
  String? email,
  String? fullName,
  String? phoneNumber,
  String? avatarUrl,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return {
    'id': id ?? anyUserId(),
    'email': email ?? anyEmail(),
    'full_name': fullName ?? 'Test User',
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    'created_at': (createdAt ?? anyTimestamp()).toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt.toIso8601String(),
  };
}

// =============================================================================
// UNIQUE FACTORIES (for tests needing distinct values)
// =============================================================================

int _uniqueCounter = 0;

/// Returns a unique ID for each call.
String uniqueId() => 'unique-id-${_uniqueCounter++}';

/// Returns a unique email for each call.
String uniqueEmail() => 'user${_uniqueCounter++}@example.com';

/// Resets the unique counter (call in setUp if needed).
void resetUniqueCounter() => _uniqueCounter = 0;

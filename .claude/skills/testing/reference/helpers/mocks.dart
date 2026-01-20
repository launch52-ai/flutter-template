/// Mock implementations using mocktail.
///
/// Use these when you need to:
/// - Control return values with `when()`
/// - Verify calls with `verify()`
///
/// For tracking call sequences, use Spy classes in `fakes.dart` instead.
library;

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/core/services/secure_storage_service.dart';
import '../../lib/core/services/shared_prefs_service.dart';
import '../../lib/features/auth/data/models/user_profile.dart';
import '../../lib/features/auth/domain/repositories/auth_repository.dart';
import '../../lib/features/auth/domain/repositories/email_auth_repository.dart';
import '../../lib/features/auth/domain/repositories/phone_auth_repository.dart';
import '../../lib/features/auth/presentation/providers/auth_state.dart';

// =============================================================================
// REPOSITORY MOCKS
// =============================================================================

/// Mock for [AuthRepository].
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock for [EmailAuthRepository].
class MockEmailAuthRepository extends Mock implements EmailAuthRepository {}

/// Mock for [PhoneAuthRepository].
class MockPhoneAuthRepository extends Mock implements PhoneAuthRepository {}

// =============================================================================
// SERVICE MOCKS
// =============================================================================

/// Mock for [SecureStorageService].
class MockSecureStorageService extends Mock implements SecureStorageService {}

/// Mock for [SharedPrefsService].
class MockSharedPrefsService extends Mock implements SharedPrefsService {}

// =============================================================================
// SUPABASE MOCKS
// =============================================================================

/// Mock for [GoTrueClient] (Supabase Auth).
class MockGoTrueClient extends Mock implements GoTrueClient {}

/// Mock for [SupabaseClient].
class MockSupabaseClient extends Mock implements SupabaseClient {}

// =============================================================================
// FALLBACK VALUE REGISTRATION
// =============================================================================

/// Register fallback values for mocktail.
///
/// Call this in `setUpAll()` before using any mocks with matchers like `any()`.
///
/// ```dart
/// void main() {
///   setUpAll(() {
///     registerFallbackValues();
///   });
///   // ... tests
/// }
/// ```
void registerFallbackValues() {
  // URIs
  registerFallbackValue(Uri());

  // Models
  registerFallbackValue(
    UserProfile(
      id: 'fallback-id',
      createdAt: DateTime(2024),
    ),
  );

  // States
  registerFallbackValue(const AuthState.initial());
}

// =============================================================================
// MOCK SETUP HELPERS
// =============================================================================

/// Extension for setting up common mock behaviors.
extension MockSecureStorageSetup on MockSecureStorageService {
  /// Sets up the mock to return null for all reads (empty storage).
  void setupEmpty() {
    when(() => read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => containsKey(key: any(named: 'key')))
        .thenAnswer((_) async => false);
  }

  /// Sets up the mock to succeed for all writes/deletes.
  void setupWriteSuccess() {
    when(() => write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(() => deleteAll()).thenAnswer((_) async {});
  }

  /// Sets up the mock with a stored access token.
  void setupWithToken(String token) {
    when(() => read(key: 'access_token')).thenAnswer((_) async => token);
    when(() => containsKey(key: 'access_token')).thenAnswer((_) async => true);
  }
}

/// Extension for setting up common SharedPrefs mock behaviors.
extension MockSharedPrefsSetup on MockSharedPrefsService {
  /// Sets up the mock to return default values (new user).
  void setupNewUser() {
    when(() => getBool(any())).thenReturn(false);
    when(() => getString(any())).thenReturn(null);
  }

  /// Sets up the mock to return values for existing user.
  void setupExistingUser() {
    when(() => getBool('has_user')).thenReturn(true);
    when(() => getBool('has_completed_onboarding')).thenReturn(true);
  }

  /// Sets up the mock to succeed for all writes.
  void setupWriteSuccess() {
    when(() => setBool(any(), any())).thenAnswer((_) async => true);
    when(() => setString(any(), any())).thenAnswer((_) async => true);
    when(() => remove(any())).thenAnswer((_) async => true);
  }
}

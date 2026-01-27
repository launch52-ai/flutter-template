import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../lib/core/constants/storage_keys.dart';
import '../../../../../../lib/features/auth/data/repositories/auth_repository_impl.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/test_helpers.dart';

void main() {
  late AuthRepositoryImpl sut;
  late MockGoTrueClient mockAuth;
  late MockSecureStorageService mockSecureStorage;
  late MockSharedPrefsService mockSharedPrefs;

  /// Creates System Under Test with all dependencies injected.
  ///
  /// Pattern from Essential Feed: `makeSUT()` factory function.
  AuthRepositoryImpl makeSUT() {
    mockAuth = MockGoTrueClient();
    mockSecureStorage = MockSecureStorageService();
    mockSharedPrefs = MockSharedPrefsService();

    // Default setup: storage operations succeed
    mockSecureStorage.setupWriteSuccess();
    mockSharedPrefs.setupWriteSuccess();

    return AuthRepositoryImpl(mockAuth, mockSecureStorage, mockSharedPrefs);
  }

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    sut = makeSUT();
  });

  // ===========================================================================
  // isAuthenticated
  // ===========================================================================

  group('isAuthenticated', () {
    test('returnsTrue_whenSessionExists', () async {
      // Arrange
      when(() => mockAuth.currentSession).thenReturn(_makeSession());

      // Act
      final result = await sut.isAuthenticated();

      // Assert
      expect(result, isTrue);
    });

    test('returnsTrue_whenNoSession_butTokenInStorage', () async {
      // Arrange
      when(() => mockAuth.currentSession).thenReturn(null);
      when(() => mockSecureStorage.read(key: StorageKeys.accessToken))
          .thenAnswer((_) async => anyAccessToken());

      // Act
      final result = await sut.isAuthenticated();

      // Assert
      expect(result, isTrue);
    });

    test('returnsFalse_whenNoSession_andNoToken', () async {
      // Arrange
      when(() => mockAuth.currentSession).thenReturn(null);
      when(() => mockSecureStorage.read(key: StorageKeys.accessToken))
          .thenAnswer((_) async => null);

      // Act
      final result = await sut.isAuthenticated();

      // Assert
      expect(result, isFalse);
    });
  });

  // ===========================================================================
  // signInWithEmail
  // ===========================================================================

  group('signInWithEmail', () {
    test('returnsAuthResult_onSuccess', () async {
      // Arrange
      final email = anyEmail();
      final password = anyPassword();
      final user = _makeUser(email: email);
      final session = _makeSession(user: user);

      when(() => mockAuth.signInWithPassword(
            email: email,
            password: password,
          )).thenAnswer((_) async => AuthResponse(
            session: session,
            user: user,
          ));

      // Act
      final result = await sut.signInWithEmail(email, password);

      // Assert
      expect(result.user.email, email);
      expect(result.isNewUser, isFalse);
      expect(result.accessToken, isNotNull);
    });

    test('persistsSession_onSuccess', () async {
      // Arrange
      final email = anyEmail();
      final password = anyPassword();
      final user = _makeUser(email: email);
      final session = _makeSession(user: user);

      when(() => mockAuth.signInWithPassword(
            email: email,
            password: password,
          )).thenAnswer((_) async => AuthResponse(
            session: session,
            user: user,
          ));

      // Act
      await sut.signInWithEmail(email, password);

      // Assert - verify storage was called
      verify(() => mockSecureStorage.write(
            key: StorageKeys.accessToken,
            value: any(named: 'value'),
          )).called(1);
      verify(() => mockSecureStorage.write(
            key: StorageKeys.userId,
            value: user.id,
          )).called(1);
      verify(() => mockSharedPrefs.setBool(StorageKeys.hasUser, true)).called(1);
    });

    test('throwsException_onAuthError', () async {
      // Arrange
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('invalid_credentials'));

      // Act & Assert
      expect(
        () => sut.signInWithEmail(anyEmail(), anyPassword()),
        throwsA(isA<AuthException>()),
      );
    });

    test('doesNotPersistSession_onError', () async {
      // Arrange
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('invalid_credentials'));

      // Act
      try {
        await sut.signInWithEmail(anyEmail(), anyPassword());
      } catch (_) {}

      // Assert - storage should NOT be called on error
      verifyNever(() => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ));
    });
  });

  // ===========================================================================
  // signUpWithEmail
  // ===========================================================================

  group('signUpWithEmail', () {
    test('returnsAuthResult_withIsNewUserTrue_onSuccess', () async {
      // Arrange
      final email = anyEmail();
      final password = anyPassword();
      final user = _makeUser(email: email);
      final session = _makeSession(user: user);

      when(() => mockAuth.signUp(
            email: email,
            password: password,
          )).thenAnswer((_) async => AuthResponse(
            session: session,
            user: user,
          ));

      // Act
      final result = await sut.signUpWithEmail(email, password);

      // Assert
      expect(result.user.email, email);
      expect(result.isNewUser, isTrue);
    });

    test('handlesNullSession_whenEmailConfirmationRequired', () async {
      // Arrange
      final email = anyEmail();
      final password = anyPassword();
      final user = _makeUser(email: email);

      when(() => mockAuth.signUp(
            email: email,
            password: password,
          )).thenAnswer((_) async => AuthResponse(
            session: null, // No session when email confirmation required
            user: user,
          ));

      // Act
      final result = await sut.signUpWithEmail(email, password);

      // Assert
      expect(result.user.email, email);
      expect(result.accessToken, isNull);
    });
  });

  // ===========================================================================
  // signOut
  // ===========================================================================

  group('signOut', () {
    test('callsAuthSignOut', () async {
      // Arrange
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      // Act
      await sut.signOut();

      // Assert
      verify(() => mockAuth.signOut()).called(1);
    });

    test('clearsAllStoredData', () async {
      // Arrange
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      // Act
      await sut.signOut();

      // Assert - verify all keys are deleted
      verify(() => mockSecureStorage.delete(key: StorageKeys.accessToken))
          .called(1);
      verify(() => mockSecureStorage.delete(key: StorageKeys.refreshToken))
          .called(1);
      verify(() => mockSecureStorage.delete(key: StorageKeys.userId)).called(1);
      verify(() => mockSecureStorage.delete(key: StorageKeys.userEmail))
          .called(1);
      verify(() => mockSharedPrefs.setBool(StorageKeys.hasUser, false))
          .called(1);
    });
  });

  // ===========================================================================
  // getCurrentUser
  // ===========================================================================

  group('getCurrentUser', () {
    test('returnsUserFromAuth_whenSessionExists', () async {
      // Arrange
      final user = _makeUser(email: anyEmail());
      when(() => mockAuth.currentUser).thenReturn(user);

      // Act
      final result = await sut.getCurrentUser();

      // Assert
      expect(result, isNotNull);
      expect(result!.email, user.email);
    });

    test('returnsUserFromStorage_whenNoSession', () async {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockSecureStorage.read(key: StorageKeys.userId))
          .thenAnswer((_) async => anyUserId());
      when(() => mockSecureStorage.read(key: StorageKeys.userEmail))
          .thenAnswer((_) async => anyEmail());
      when(() => mockSecureStorage.read(key: StorageKeys.userFullName))
          .thenAnswer((_) async => 'Test User');
      when(() => mockSecureStorage.read(key: StorageKeys.userPhoneNumber))
          .thenAnswer((_) async => null);

      // Act
      final result = await sut.getCurrentUser();

      // Assert
      expect(result, isNotNull);
      expect(result!.id, anyUserId());
      expect(result.email, anyEmail());
    });

    test('returnsNull_whenNoSessionAndNoStoredUser', () async {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockSecureStorage.read(key: StorageKeys.userId))
          .thenAnswer((_) async => null);

      // Act
      final result = await sut.getCurrentUser();

      // Assert
      expect(result, isNull);
    });
  });

  // ===========================================================================
  // sendOtp (Phone Auth)
  // ===========================================================================

  group('sendOtp', () {
    test('callsAuthWithPhone', () async {
      // Arrange
      final phone = anyPhoneNumber();
      when(() => mockAuth.signInWithOtp(phone: phone))
          .thenAnswer((_) async {});

      // Act
      await sut.sendOtp(phone);

      // Assert
      verify(() => mockAuth.signInWithOtp(phone: phone)).called(1);
    });
  });

  // ===========================================================================
  // verifyOtp (Phone Auth)
  // ===========================================================================

  group('verifyOtp', () {
    test('returnsAuthResult_onSuccess', () async {
      // Arrange
      final phone = anyPhoneNumber();
      final otp = anyOtp();
      final user = _makeUser(phone: phone);
      final session = _makeSession(user: user);

      when(() => mockAuth.verifyOTP(
            phone: phone,
            token: otp,
            type: OtpType.sms,
          )).thenAnswer((_) async => AuthResponse(
            session: session,
            user: user,
          ));

      // Act
      final result = await sut.verifyOtp(phone, otp);

      // Assert
      expect(result.user.phoneNumber, phone);
    });
  });
}

// =============================================================================
// TEST HELPERS
// =============================================================================

/// Creates a mock Supabase User.
User _makeUser({
  String? id,
  String? email,
  String? phone,
}) {
  return User(
    id: id ?? anyUserId(),
    email: email,
    phone: phone,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: anyTimestamp().toIso8601String(),
  );
}

/// Creates a mock Supabase Session.
Session _makeSession({
  User? user,
  String? accessToken,
  String? refreshToken,
}) {
  final sessionUser = user ?? _makeUser();
  return Session(
    accessToken: accessToken ?? anyAccessToken(),
    refreshToken: refreshToken ?? anyRefreshToken(),
    tokenType: 'bearer',
    user: sessionUser,
  );
}

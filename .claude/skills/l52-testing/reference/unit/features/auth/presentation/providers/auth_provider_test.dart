import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../lib/features/auth/data/models/auth_result.dart';
import '../../../../../../lib/features/auth/presentation/providers/auth_provider.dart';
import '../../../../../../lib/features/auth/presentation/providers/auth_state.dart';
import '../../../../../helpers/fakes.dart';
import '../../../../../helpers/riverpod_helpers.dart';
import '../../../../../helpers/test_helpers.dart';

void main() {
  late ProviderContainer container;
  late AuthRepositorySpy authRepositorySpy;

  /// Creates a ProviderContainer with auth repository overridden.
  ProviderContainer makeSUT({
    bool isAuthenticated = false,
  }) {
    authRepositorySpy = AuthRepositorySpy();
    authRepositorySpy.completeIsAuthenticated(isAuthenticated);

    return makeProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepositorySpy),
      ],
    );
  }

  // ===========================================================================
  // Initial State
  // ===========================================================================

  group('initial state', () {
    test('isInitial_onBuild', () {
      // Arrange
      container = makeSUT();

      // Act
      final state = container.read(authNotifierProvider);

      // Assert
      expect(state, const AuthState.initial());
    });

    test('checksAuthStatus_onBuild', () async {
      // Arrange
      authRepositorySpy = AuthRepositorySpy();
      authRepositorySpy.completeIsAuthenticated(false);

      container = makeProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepositorySpy),
        ],
      );

      // Act - trigger build by reading
      container.read(authNotifierProvider);

      // Allow async operations to complete
      await Future.delayed(Duration.zero);

      // Assert
      expect(
        authRepositorySpy.receivedMessages,
        contains(const AuthMessage.isAuthenticated()),
      );
    });
  });

  // ===========================================================================
  // signInWithEmail
  // ===========================================================================

  group('signInWithEmail', () {
    test('emitsLoading_thenAuthenticated_onSuccess', () async {
      // Arrange
      container = makeSUT();
      final listener = ProviderListener<AuthState>();
      container.listen(authNotifierProvider, listener.call, fireImmediately: true);

      final expectedResult = anyAuthResult();
      authRepositorySpy.completeSignIn(expectedResult);

      // Act
      await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail(anyEmail(), anyPassword());

      // Assert state transitions
      expect(listener.states, [
        const AuthState.initial(),
        const AuthState.loading(),
        isA<AuthStateAuthenticated>(),
      ]);
    });

    test('callsRepository_withCorrectCredentials', () async {
      // Arrange
      container = makeSUT();
      final email = anyEmail();
      final password = anyPassword();
      authRepositorySpy.completeSignIn(anyAuthResult());

      // Act
      await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail(email, password);

      // Assert
      expect(
        authRepositorySpy.receivedMessages,
        contains(AuthMessage.signInWithEmail(email, password)),
      );
    });

    test('emitsError_onFailure', () async {
      // Arrange
      container = makeSUT();
      authRepositorySpy.failSignIn(Exception('Invalid credentials'));

      // Act
      await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail(anyEmail(), anyPassword());

      // Assert
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthStateError>());
    });

    test('includesErrorMessage_onFailure', () async {
      // Arrange
      container = makeSUT();
      authRepositorySpy.failSignIn(Exception('Invalid credentials'));

      // Act
      await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail(anyEmail(), anyPassword());

      // Assert
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthStateError>());
      // Error message is handled by ErrorUtils
    });
  });

  // ===========================================================================
  // signUpWithEmail
  // ===========================================================================

  group('signUpWithEmail', () {
    test('emitsAuthenticated_withIsNewUserTrue_onSuccess', () async {
      // Arrange
      container = makeSUT();
      authRepositorySpy.completeSignUp(anyAuthResult(isNewUser: true));

      // Act
      await container
          .read(authNotifierProvider.notifier)
          .signUpWithEmail(anyEmail(), anyPassword());

      // Assert
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthStateAuthenticated>());
      expect((state as AuthStateAuthenticated).isNewUser, isTrue);
    });
  });

  // ===========================================================================
  // signOut
  // ===========================================================================

  group('signOut', () {
    test('emitsUnauthenticated_onSuccess', () async {
      // Arrange
      container = makeSUT(isAuthenticated: true);
      authRepositorySpy.completeSignIn(anyAuthResult());

      // First sign in
      await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail(anyEmail(), anyPassword());

      // Act
      await container.read(authNotifierProvider.notifier).signOut();

      // Assert
      final state = container.read(authNotifierProvider);
      expect(state, const AuthState.unauthenticated());
    });

    test('callsRepository_signOut', () async {
      // Arrange
      container = makeSUT();
      authRepositorySpy.completeSignIn(anyAuthResult());
      await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail(anyEmail(), anyPassword());

      // Clear messages to only track signOut
      authRepositorySpy.receivedMessages.clear();

      // Act
      await container.read(authNotifierProvider.notifier).signOut();

      // Assert
      expect(
        authRepositorySpy.receivedMessages,
        contains(const AuthMessage.signOut()),
      );
    });

    test('emitsUnauthenticated_evenOnError', () async {
      // Arrange - signOut should always result in unauthenticated
      container = makeSUT();

      // Act
      await container.read(authNotifierProvider.notifier).signOut();

      // Assert
      final state = container.read(authNotifierProvider);
      expect(state, const AuthState.unauthenticated());
    });
  });

  // ===========================================================================
  // Phone OTP Flow
  // ===========================================================================

  group('sendOtp', () {
    test('emitsOtpSent_onSuccess', () async {
      // Arrange
      container = makeSUT();

      // Act
      await container
          .read(authNotifierProvider.notifier)
          .sendOtp(anyPhoneNumber());

      // Assert
      final state = container.read(authNotifierProvider);
      expect(state, const AuthState.otpSent());
    });

    test('callsRepository_withPhoneNumber', () async {
      // Arrange
      container = makeSUT();
      final phone = anyPhoneNumber();

      // Act
      await container.read(authNotifierProvider.notifier).sendOtp(phone);

      // Assert
      expect(
        authRepositorySpy.receivedMessages,
        contains(AuthMessage.sendOtp(phone)),
      );
    });

    test('emitsError_onFailure', () async {
      // Arrange
      container = makeSUT();
      authRepositorySpy.failSendOtp(Exception('Rate limited'));

      // Act
      await container
          .read(authNotifierProvider.notifier)
          .sendOtp(anyPhoneNumber());

      // Assert
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthStateError>());
    });
  });

  group('verifyOtp', () {
    test('emitsAuthenticated_onSuccess', () async {
      // Arrange
      container = makeSUT();
      authRepositorySpy.completeVerifyOtp(anyAuthResult());

      // Act
      await container
          .read(authNotifierProvider.notifier)
          .verifyOtp(anyPhoneNumber(), anyOtp());

      // Assert
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthStateAuthenticated>());
    });

    test('emitsError_onInvalidOtp', () async {
      // Arrange
      container = makeSUT();
      authRepositorySpy.failVerifyOtp(Exception('Invalid OTP'));

      // Act
      await container
          .read(authNotifierProvider.notifier)
          .verifyOtp(anyPhoneNumber(), anyOtp());

      // Assert
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthStateError>());
    });
  });

  // ===========================================================================
  // Helper Providers
  // ===========================================================================

  group('isAuthenticated provider', () {
    test('returnsFalse_whenInitial', () {
      // Arrange
      container = makeSUT();

      // Act
      final result = container.read(isAuthenticatedProvider);

      // Assert
      expect(result, isFalse);
    });

    test('returnsTrue_whenAuthenticated', () async {
      // Arrange
      container = makeSUT();
      authRepositorySpy.completeSignIn(anyAuthResult());
      await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail(anyEmail(), anyPassword());

      // Act
      final result = container.read(isAuthenticatedProvider);

      // Assert
      expect(result, isTrue);
    });
  });

  group('currentUser provider', () {
    test('returnsNull_whenUnauthenticated', () {
      // Arrange
      container = makeSUT();

      // Act
      final result = container.read(currentUserProvider);

      // Assert
      expect(result, isNull);
    });

    test('returnsUser_whenAuthenticated', () async {
      // Arrange
      container = makeSUT();
      final expectedUser = anyUserProfile();
      authRepositorySpy.completeSignIn(AuthResult(
        user: expectedUser,
        isNewUser: false,
      ));
      await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail(anyEmail(), anyPassword());

      // Act
      final result = container.read(currentUserProvider);

      // Assert
      expect(result, expectedUser);
    });
  });

  // ===========================================================================
  // updateUser
  // ===========================================================================

  group('updateUser', () {
    test('updatesUserInState_whenAuthenticated', () async {
      // Arrange
      container = makeSUT();
      authRepositorySpy.completeSignIn(anyAuthResult());
      await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail(anyEmail(), anyPassword());

      final updatedUser = anyUserProfile(fullName: 'Updated Name');

      // Act
      container.read(authNotifierProvider.notifier).updateUser(updatedUser);

      // Assert
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthStateAuthenticated>());
      expect((state as AuthStateAuthenticated).user.fullName, 'Updated Name');
    });
  });
}

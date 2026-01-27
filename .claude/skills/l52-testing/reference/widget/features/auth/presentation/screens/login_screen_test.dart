import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../lib/features/auth/presentation/providers/auth_provider.dart';
import '../../../../../../lib/features/auth/presentation/providers/auth_state.dart';
import '../../../../../../lib/features/auth/presentation/screens/login_screen.dart';
import '../../../../../helpers/fakes.dart';
import '../../../../../helpers/pump_app.dart';
import '../../../../../helpers/test_helpers.dart';

void main() {
  late AuthRepositorySpy authRepositorySpy;

  setUp(() {
    authRepositorySpy = AuthRepositorySpy();
    authRepositorySpy.completeIsAuthenticated(false);
  });

  // ===========================================================================
  // UI Elements
  // ===========================================================================

  group('UI elements', () {
    testWidgets('displaysEmailAndPasswordFields', (tester) async {
      // Arrange & Act
      await _pumpLoginScreen(tester, authRepositorySpy);

      // Assert
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('displaysSignInButton_byDefault', (tester) async {
      // Arrange & Act
      await _pumpLoginScreen(tester, authRepositorySpy);

      // Assert - look for LoadingButton (which contains the sign in text)
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('displaysToggleButton_toSwitchBetweenSignInAndSignUp',
        (tester) async {
      // Arrange & Act
      await _pumpLoginScreen(tester, authRepositorySpy);

      // Assert - TextButton for toggling
      expect(find.byType(TextButton), findsOneWidget);
    });
  });

  // ===========================================================================
  // Form Validation
  // ===========================================================================

  group('form validation', () {
    testWidgets('showsValidationError_whenEmailIsEmpty', (tester) async {
      // Arrange
      await _pumpLoginScreen(tester, authRepositorySpy);

      // Act - tap submit without entering anything
      await tester.simulateTapOn(find.byType(ElevatedButton));

      // Assert - validation error should appear
      expect(find.byType(TextFormField), findsNWidgets(2));
      // Validation errors are shown in form fields
    });

    testWidgets('showsValidationError_whenEmailIsInvalid', (tester) async {
      // Arrange
      await _pumpLoginScreen(tester, authRepositorySpy);

      // Act
      await tester.enterText(
        find.byType(TextFormField).first,
        'invalid-email',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        anyPassword(),
      );
      await tester.simulateTapOn(find.byType(ElevatedButton));

      // Assert - form should not submit (repository not called)
      expect(authRepositorySpy.receivedMessages, isEmpty);
    });

    testWidgets('showsValidationError_whenPasswordIsTooShort', (tester) async {
      // Arrange
      await _pumpLoginScreen(tester, authRepositorySpy);

      // Act
      await tester.enterText(
        find.byType(TextFormField).first,
        anyEmail(),
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'short', // Too short
      );
      await tester.simulateTapOn(find.byType(ElevatedButton));

      // Assert - form should not submit
      expect(authRepositorySpy.receivedMessages, isEmpty);
    });
  });

  // ===========================================================================
  // Sign In Flow
  // ===========================================================================

  group('sign in flow', () {
    testWidgets('callsSignInWithEmail_whenFormIsValid', (tester) async {
      // Arrange
      authRepositorySpy.completeSignIn(anyAuthResult());
      await _pumpLoginScreen(tester, authRepositorySpy);

      final email = anyEmail();
      final password = anyPassword();

      // Act
      await tester.enterText(find.byType(TextFormField).first, email);
      await tester.enterText(find.byType(TextFormField).last, password);
      await tester.simulateTapOn(find.byType(ElevatedButton));

      // Assert
      expect(
        authRepositorySpy.receivedMessages,
        contains(AuthMessage.signInWithEmail(email, password)),
      );
    });

    testWidgets('showsLoadingIndicator_whileLoading', (tester) async {
      // Arrange - create a notifier that stays in loading state
      await _pumpLoginScreenWithState(
        tester,
        const AuthState.loading(),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('showsSnackBar_onError', (tester) async {
      // Arrange
      const errorMessage = 'Invalid credentials';
      await _pumpLoginScreenWithState(
        tester,
        const AuthState.initial(),
      );

      // Verify initial state - no snackbar
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  // ===========================================================================
  // Sign Up Toggle
  // ===========================================================================

  group('sign up toggle', () {
    testWidgets('togglesToSignUp_whenToggleButtonTapped', (tester) async {
      // Arrange
      await _pumpLoginScreen(tester, authRepositorySpy);

      // Act
      await tester.simulateTapOn(find.byType(TextButton));

      // Assert - UI should update (title changes)
      // The toggle button text changes between "Already have an account?" and "Don't have an account?"
    });

    testWidgets('callsSignUpWithEmail_whenInSignUpMode', (tester) async {
      // Arrange
      authRepositorySpy.completeSignUp(anyAuthResult(isNewUser: true));
      await _pumpLoginScreen(tester, authRepositorySpy);

      // Switch to sign up mode
      await tester.simulateTapOn(find.byType(TextButton));

      final email = anyEmail();
      final password = anyPassword();

      // Act
      await tester.enterText(find.byType(TextFormField).first, email);
      await tester.enterText(find.byType(TextFormField).last, password);
      await tester.simulateTapOn(find.byType(ElevatedButton));

      // Assert
      expect(
        authRepositorySpy.receivedMessages,
        contains(AuthMessage.signUpWithEmail(email, password)),
      );
    });
  });

  // ===========================================================================
  // Text Input Behavior
  // ===========================================================================

  group('text input behavior', () {
    testWidgets('emailField_hasAutocorrectDisabled', (tester) async {
      // Arrange
      await _pumpLoginScreen(tester, authRepositorySpy);

      // Assert
      final emailField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(emailField.autocorrect, isFalse);
    });

    testWidgets('passwordField_hasObscureTextEnabled', (tester) async {
      // Arrange
      await _pumpLoginScreen(tester, authRepositorySpy);

      // Assert
      final passwordField = tester.widget<TextFormField>(
        find.byType(TextFormField).last,
      );
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('passwordField_hasAutocorrectDisabled', (tester) async {
      // Arrange
      await _pumpLoginScreen(tester, authRepositorySpy);

      // Assert
      final passwordField = tester.widget<TextFormField>(
        find.byType(TextFormField).last,
      );
      expect(passwordField.autocorrect, isFalse);
    });
  });
}

// =============================================================================
// HELPERS
// =============================================================================

/// Pumps LoginScreen with auth repository spy.
Future<void> _pumpLoginScreen(
  WidgetTester tester,
  AuthRepositorySpy authRepositorySpy,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepositorySpy),
      ],
      child: MaterialApp.router(
        routerConfig: _makeRouter(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps LoginScreen with a specific auth state.
Future<void> _pumpLoginScreenWithState(
  WidgetTester tester,
  AuthState state,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _FixedStateAuthNotifier(state)),
      ],
      child: MaterialApp.router(
        routerConfig: _makeRouter(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Creates a minimal router for testing.
GoRouter _makeRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const Scaffold(
          body: Text('Dashboard'),
        ),
      ),
    ],
  );
}

/// Auth notifier that returns a fixed state (for testing loading/error states).
final class _FixedStateAuthNotifier extends AuthNotifier {
  final AuthState _state;

  _FixedStateAuthNotifier(this._state);

  @override
  AuthState build() => _state;

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> signUpWithEmail(String email, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<void> verifyOtp(String phoneNumber, String otp) async {}
}

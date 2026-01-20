/// Golden tests for LoginScreen.
///
/// These tests capture visual snapshots of the login screen in different
/// states and themes, comparing them against stored reference images.
///
/// To update golden files:
/// ```bash
/// flutter test --update-goldens test/golden/
/// ```
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../../../../lib/features/auth/presentation/providers/auth_provider.dart';
import '../../../../../lib/features/auth/presentation/providers/auth_state.dart';
import '../../../../../lib/features/auth/presentation/screens/login_screen.dart';
import '../../../../helpers/fakes.dart';
import '../../../../helpers/golden_helpers.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('LoginScreen Golden Tests', () {
    // =========================================================================
    // INITIAL STATE
    // =========================================================================

    testGoldens('initial_state_light', (tester) async {
      // Arrange
      final widget = _buildLoginScreen(
        theme: GoldenTheme.light,
        state: const AuthState.initial(),
      );

      // Act
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: GoldenDevices.iPhone14.size,
      );
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'login_screen_initial_light');
    });

    testGoldens('initial_state_dark', (tester) async {
      // Arrange
      final widget = _buildLoginScreen(
        theme: GoldenTheme.dark,
        state: const AuthState.initial(),
      );

      // Act
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: GoldenDevices.iPhone14.size,
      );
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'login_screen_initial_dark');
    });

    // =========================================================================
    // LOADING STATE
    // =========================================================================

    testGoldens('loading_state_light', (tester) async {
      // Arrange
      final widget = _buildLoginScreen(
        theme: GoldenTheme.light,
        state: const AuthState.loading(),
      );

      // Act
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: GoldenDevices.iPhone14.size,
      );
      // Don't pumpAndSettle - loading indicator animates forever
      await tester.pump();

      // Assert
      await screenMatchesGolden(tester, 'login_screen_loading_light');
    });

    testGoldens('loading_state_dark', (tester) async {
      // Arrange
      final widget = _buildLoginScreen(
        theme: GoldenTheme.dark,
        state: const AuthState.loading(),
      );

      // Act
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: GoldenDevices.iPhone14.size,
      );
      await tester.pump();

      // Assert
      await screenMatchesGolden(tester, 'login_screen_loading_dark');
    });

    // =========================================================================
    // ERROR STATE
    // =========================================================================

    testGoldens('error_state_light', (tester) async {
      // Arrange
      final widget = _buildLoginScreen(
        theme: GoldenTheme.light,
        state: const AuthState.error('Invalid email or password'),
      );

      // Act
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: GoldenDevices.iPhone14.size,
      );
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'login_screen_error_light');
    });

    testGoldens('error_state_dark', (tester) async {
      // Arrange
      final widget = _buildLoginScreen(
        theme: GoldenTheme.dark,
        state: const AuthState.error('Invalid email or password'),
      );

      // Act
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: GoldenDevices.iPhone14.size,
      );
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'login_screen_error_dark');
    });

    // =========================================================================
    // SIGN UP MODE
    // =========================================================================

    testGoldens('sign_up_mode_light', (tester) async {
      // Arrange
      final widget = _buildLoginScreen(
        theme: GoldenTheme.light,
        state: const AuthState.initial(),
      );

      // Act
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: GoldenDevices.iPhone14.size,
      );
      await tester.pumpAndSettle();

      // Tap toggle to switch to sign up mode
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'login_screen_signup_light');
    });

    testGoldens('sign_up_mode_dark', (tester) async {
      // Arrange
      final widget = _buildLoginScreen(
        theme: GoldenTheme.dark,
        state: const AuthState.initial(),
      );

      // Act
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: GoldenDevices.iPhone14.size,
      );
      await tester.pumpAndSettle();

      // Tap toggle to switch to sign up mode
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'login_screen_signup_dark');
    });

    // =========================================================================
    // WITH FILLED FORM
    // =========================================================================

    testGoldens('filled_form_light', (tester) async {
      // Arrange
      final widget = _buildLoginScreen(
        theme: GoldenTheme.light,
        state: const AuthState.initial(),
      );

      // Act
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: GoldenDevices.iPhone14.size,
      );
      await tester.pumpAndSettle();

      // Fill in form fields
      await tester.enterText(
        find.byType(TextFormField).first,
        'user@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'login_screen_filled_light');
    });

    // =========================================================================
    // VALIDATION ERRORS
    // =========================================================================

    testGoldens('validation_errors_light', (tester) async {
      // Arrange
      final widget = _buildLoginScreen(
        theme: GoldenTheme.light,
        state: const AuthState.initial(),
      );

      // Act
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: GoldenDevices.iPhone14.size,
      );
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(
        find.byType(TextFormField).first,
        'invalid-email',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'short',
      );

      // Tap submit to trigger validation
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'login_screen_validation_light');
    });

    // =========================================================================
    // DIFFERENT DEVICE SIZES
    // =========================================================================

    testGoldens('small_device_light', (tester) async {
      // Arrange
      final widget = _buildLoginScreen(
        theme: GoldenTheme.light,
        state: const AuthState.initial(),
      );

      // Act - iPhone SE size
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: GoldenDevices.iPhoneSE.size,
      );
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'login_screen_small_device_light');
    });

    testGoldens('large_device_light', (tester) async {
      // Arrange
      final widget = _buildLoginScreen(
        theme: GoldenTheme.light,
        state: const AuthState.initial(),
      );

      // Act - iPhone 14 Pro Max size
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: GoldenDevices.iPhone14ProMax.size,
      );
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'login_screen_large_device_light');
    });

    // =========================================================================
    // MULTI-SCENARIO TEST
    // =========================================================================

    testGoldens('all_states_matrix', (tester) async {
      final scenarios = [
        (
          'initial',
          const AuthState.initial(),
        ),
        (
          'loading',
          const AuthState.loading(),
        ),
        (
          'error',
          const AuthState.error('Invalid credentials'),
        ),
      ];

      for (final (name, state) in scenarios) {
        for (final theme in GoldenTheme.values) {
          final widget = _buildLoginScreen(theme: theme, state: state);

          await tester.pumpWidgetBuilder(
            widget,
            surfaceSize: GoldenDevices.iPhone14.size,
          );

          // For loading state, don't settle (animation)
          if (state is AuthStateLoading) {
            await tester.pump();
          } else {
            await tester.pumpAndSettle();
          }

          await screenMatchesGolden(
            tester,
            'login_screen_${name}_${theme.suffix}',
          );
        }
      }
    });
  });
}

// =============================================================================
// HELPERS
// =============================================================================

/// Builds LoginScreen wrapped for golden testing.
Widget _buildLoginScreen({
  required GoldenTheme theme,
  required AuthState state,
}) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => _FixedStateAuthNotifier(state)),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: theme.themeData,
      themeMode: theme.themeMode,
      routerConfig: _makeRouter(),
    ),
  );
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
          body: Center(child: Text('Dashboard')),
        ),
      ),
    ],
  );
}

/// Auth notifier that returns a fixed state.
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

// Template: Authentication related
//
// Location: lib/features/{feature}/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Template: Router Configuration for OAuth Callback
//
// Location: lib/core/router/app_router.dart
//
// Add this route to your GoRouter configuration for handling
// Apple Sign-In OAuth callback on Android.

import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/oauth_callback_screen.dart';

// ===========================================================================
// ROUTE CONSTANT
// ===========================================================================

// Add to your AppRouter class:
static const String oauthCallback = '/login-callback';

// ===========================================================================
// ROUTE DEFINITION
// ===========================================================================

// Add this GoRoute to your routes list:
GoRoute(
  path: '/login-callback',
  builder: (context, state) => const OAuthCallbackScreen(),
),

// ===========================================================================
// FULL EXAMPLE
// ===========================================================================

/*
final class AppRouter {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String oauthCallback = '/login-callback';

  static GoRouter router({required Ref ref}) {
    return GoRouter(
      initialLocation: login,
      routes: [
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        // OAuth callback for Apple Sign-In on Android
        GoRoute(
          path: oauthCallback,
          builder: (context, state) => const OAuthCallbackScreen(),
        ),
      ],
    );
  }
}
*/

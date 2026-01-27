// Template: Router Configuration for OAuth Callback
//
// Location: lib/core/router/app_router.dart
//
// Add this route and redirect to your GoRouter configuration for handling
// Apple Sign-In OAuth callback on Android.
//
// IMPORTANT: The redirect is required because GoRouter receives deep links
// as full URLs (e.g., io.zangy://login-callback?code=...) which don't match
// standard route paths. The redirect extracts the query params and routes
// to the callback screen.

import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/oauth_callback_screen.dart';

// ===========================================================================
// ROUTE CONSTANT
// ===========================================================================

// Add to your AppRouter class:
static const String oauthCallback = '/login-callback';

// ===========================================================================
// REDIRECT FOR DEEP LINKS
// ===========================================================================

// Add this redirect to your GoRouter configuration.
// Replace 'your.bundle.id' with your actual bundle ID (e.g., 'io.zangy').

redirect: (context, state) {
  final uri = state.uri;

  // Handle deep link OAuth callbacks (your.bundle.id://login-callback?code=...)
  // The deep link URL must be redirected to the callback route with query params
  if (uri.scheme == 'your.bundle.id' && uri.host == 'login-callback') {
    return '$oauthCallback?${uri.query}';
  }

  // Fallback: GoRouter may receive the full URL as a path string
  final path = uri.path;
  if (path.startsWith('your.bundle.id://login-callback')) {
    final deepLinkUri = Uri.parse(path);
    return '$oauthCallback?${deepLinkUri.query}';
  }

  return null;
},

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
  static const String profileCompletion = '/complete-profile';
  static const String oauthCallback = '/login-callback';

  static GoRouter router({
    required bool hasStoredUser,
    required bool hasCompletedProfile,
  }) {
    return GoRouter(
      initialLocation: hasStoredUser
          ? (hasCompletedProfile ? dashboard : profileCompletion)
          : login,

      // REQUIRED: Handle deep link OAuth callbacks
      redirect: (context, state) {
        final uri = state.uri;

        // Handle deep link OAuth callbacks
        if (uri.scheme == 'com.example.myapp' && uri.host == 'login-callback') {
          return '$oauthCallback?${uri.query}';
        }

        // Fallback for path-style deep links
        final path = uri.path;
        if (path.startsWith('com.example.myapp://login-callback')) {
          final deepLinkUri = Uri.parse(path);
          return '$oauthCallback?${deepLinkUri.query}';
        }

        return null;
      },

      routes: [
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: profileCompletion,
          builder: (context, state) => const ProfileCompletionScreen(),
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

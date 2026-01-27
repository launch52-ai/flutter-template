// Template: App Router
//
// Location: lib/core/router/app_router.dart
//
// Usage:
// 1. Copy to target location
// 2. Add routes as features are created
// 3. Configure redirects based on auth state

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Import navigation shell if using bottom nav
// import '../navigation/main_shell.dart';

// Import screens as they're created
// import '../../features/auth/presentation/screens/login_screen.dart';
// import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

part 'app_router.g.dart';

/// Route paths as constants.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// GoRouter provider.
/// Watches auth state for redirects.
@riverpod
GoRouter router(Ref ref) {
  // Watch auth state for redirects
  // final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    // Redirect logic based on auth state
    redirect: (context, state) {
      // final isLoggedIn = authState.valueOrNull != null;
      // final isOnLoginPage = state.matchedLocation == AppRoutes.login;
      //
      // if (!isLoggedIn && !isOnLoginPage) {
      //   return AppRoutes.login;
      // }
      // if (isLoggedIn && isOnLoginPage) {
      //   return AppRoutes.dashboard;
      // }
      return null;
    },

    routes: [
      // Splash/Initial route
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _PlaceholderScreen(title: 'Splash'),
      ),

      // Login route (full screen, no bottom nav)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const _PlaceholderScreen(title: 'Login'),
      ),

      // Main app with bottom navigation
      // Uncomment when using StatefulShellRoute:
      //
      // StatefulShellRoute.indexedStack(
      //   builder: (context, state, navigationShell) {
      //     return MainShell(navigationShell: navigationShell);
      //   },
      //   branches: [
      //     // Dashboard tab
      //     StatefulShellBranch(
      //       routes: [
      //         GoRoute(
      //           path: AppRoutes.dashboard,
      //           builder: (context, state) => const DashboardScreen(),
      //         ),
      //       ],
      //     ),
      //     // Profile tab
      //     StatefulShellBranch(
      //       routes: [
      //         GoRoute(
      //           path: AppRoutes.profile,
      //           builder: (context, state) => const ProfileScreen(),
      //         ),
      //       ],
      //     ),
      //     // Settings tab
      //     StatefulShellBranch(
      //       routes: [
      //         GoRoute(
      //           path: AppRoutes.settings,
      //           builder: (context, state) => const SettingsScreen(),
      //         ),
      //       ],
      //     ),
      //   ],
      // ),

      // Simple routes without shell (temporary)
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const _PlaceholderScreen(title: 'Dashboard'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const _PlaceholderScreen(title: 'Profile'),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const _PlaceholderScreen(title: 'Settings'),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
}

/// Placeholder screen for routes not yet implemented.
final class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'TODO: Implement $title screen',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// Error screen for invalid routes.
final class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

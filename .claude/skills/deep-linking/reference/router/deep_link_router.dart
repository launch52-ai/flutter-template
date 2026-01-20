// Template: GoRouter configuration with deep link handling
//
// Location: lib/core/router/app_router.dart
//
// Usage:
// 1. Merge deep link routes with existing app_router.dart
// 2. Update paths to match your AASA/assetlinks.json patterns
// 3. Add authentication redirects if needed

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Route paths as constants.
/// Keep in sync with AASA (iOS) and AndroidManifest (Android) paths.
abstract final class AppRoutes {
  // Core routes
  static const String home = '/';
  static const String login = '/login';

  // Deep link routes
  static const String product = '/products/:id';
  static const String user = '/users/:userId';
  static const String order = '/orders/:orderId';
  static const String search = '/search';

  // Helper to build parameterized paths
  static String productDetail(String id) => '/products/$id';
  static String userProfile(String userId) => '/users/$userId';
  static String orderDetail(String orderId) => '/orders/$orderId';
}

/// GoRouter provider with deep link support.
@riverpod
GoRouter router(Ref ref) {
  // Watch auth state for protected routes
  // final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true, // Logs deep link navigation

    // Global redirect for authentication
    redirect: (context, state) {
      // Uncomment when auth is configured:
      // final isLoggedIn = authState.valueOrNull != null;
      // final isOnLoginPage = state.matchedLocation == AppRoutes.login;
      //
      // // Protected routes that require authentication
      // final protectedPaths = ['/orders', '/profile'];
      // final isProtected = protectedPaths.any(
      //   (path) => state.matchedLocation.startsWith(path),
      // );
      //
      // // Not logged in + accessing protected route → save destination, go to login
      // if (isProtected && !isLoggedIn) {
      //   final redirect = Uri.encodeComponent(state.uri.toString());
      //   return '${AppRoutes.login}?redirect=$redirect';
      // }
      //
      // // Logged in + on login page → check for pending redirect from deep link
      // if (isOnLoginPage && isLoggedIn) {
      //   final redirectTo = state.uri.queryParameters['redirect'];
      //   if (redirectTo != null) {
      //     return Uri.decodeComponent(redirectTo);
      //   }
      //   return AppRoutes.home;
      // }

      return null;
    },

    routes: [
      // Home route
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _PlaceholderScreen(title: 'Home'),
      ),

      // Login route
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          // Extract redirect URL if coming from protected deep link
          final redirect = state.uri.queryParameters['redirect'];
          return _PlaceholderScreen(
            title: 'Login',
            subtitle: redirect != null ? 'Redirect to: $redirect' : null,
          );
        },
      ),

      // Deep link: /products/:id
      GoRoute(
        path: AppRoutes.product,
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          // Validate ID format if needed
          if (id == null || id.isEmpty) {
            return AppRoutes.home;
          }
          return null;
        },
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _PlaceholderScreen(
            title: 'Product Detail',
            subtitle: 'ID: $id',
          );
        },
      ),

      // Deep link: /users/:userId
      GoRoute(
        path: AppRoutes.user,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return _PlaceholderScreen(
            title: 'User Profile',
            subtitle: 'User ID: $userId',
          );
        },
      ),

      // Deep link: /orders/:orderId (protected)
      GoRoute(
        path: AppRoutes.order,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return _PlaceholderScreen(
            title: 'Order Detail',
            subtitle: 'Order ID: $orderId',
          );
        },
      ),

      // Deep link: /search?q=query&category=cat
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          final category = state.uri.queryParameters['category'];
          return _PlaceholderScreen(
            title: 'Search',
            subtitle: 'Query: $query${category != null ? ', Category: $category' : ''}',
          );
        },
      ),
    ],

    // Handle unknown deep links
    errorBuilder: (context, state) => _NotFoundScreen(
      attemptedPath: state.uri.toString(),
    ),
  );
}

/// Placeholder screen for routes.
/// Replace with actual screen implementations.
final class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'TODO: Implement $title screen',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Not found screen for invalid deep links.
final class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.attemptedPath});

  final String attemptedPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.link_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              attemptedPath,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

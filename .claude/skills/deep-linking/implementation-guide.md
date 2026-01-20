# Implementation Guide

GoRouter integration for handling deep links in Flutter.

---

## Overview

GoRouter handles deep links automatically when routes match incoming URLs. This guide covers:
- Route configuration for deep links
- Parameter extraction
- Redirect handling
- Error handling for unknown links

---

## Project Structure

```
lib/core/router/
├── app_router.dart           # Main router with deep link routes
└── deep_link_routes.dart     # Deep link specific routes (optional)
```

---

## Basic Setup

GoRouter handles deep links out of the box. The key is defining routes that match your deep link paths.

### Route Configuration

```dart
// lib/core/router/app_router.dart

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true, // Enable for deep link debugging

    routes: [
      // Home
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),

      // Deep link: /products/:id
      GoRoute(
        path: '/products/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailScreen(productId: productId);
        },
      ),

      // Deep link: /users/:userId
      GoRoute(
        path: '/users/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfileScreen(userId: userId);
        },
      ),

      // Deep link: /orders/:orderId
      GoRoute(
        path: '/orders/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailScreen(orderId: orderId);
        },
      ),
    ],

    // Handle unknown routes
    errorBuilder: (context, state) => NotFoundScreen(
      attemptedPath: state.uri.toString(),
    ),
  );
}
```

---

## Route Patterns

### Path Parameters

```dart
// Single parameter
GoRoute(
  path: '/products/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return ProductScreen(productId: id);
  },
),

// Multiple parameters
GoRoute(
  path: '/users/:userId/posts/:postId',
  builder: (context, state) {
    final userId = state.pathParameters['userId']!;
    final postId = state.pathParameters['postId']!;
    return PostScreen(userId: userId, postId: postId);
  },
),
```

### Query Parameters

For URLs like `/search?q=flutter&category=tutorials`:

```dart
GoRoute(
  path: '/search',
  builder: (context, state) {
    final query = state.uri.queryParameters['q'] ?? '';
    final category = state.uri.queryParameters['category'];
    return SearchScreen(query: query, category: category);
  },
),
```

### Optional Parameters

```dart
GoRoute(
  path: '/products',
  builder: (context, state) {
    final category = state.uri.queryParameters['category'];
    final sort = state.uri.queryParameters['sort'] ?? 'newest';
    return ProductListScreen(category: category, sortBy: sort);
  },
),
```

---

## Nested Routes

For deep links that should show within a shell (e.g., bottom navigation):

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    return MainShell(navigationShell: navigationShell);
  },
  branches: [
    // Home tab
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
          routes: [
            // Deep link opens product within home tab
            GoRoute(
              path: 'products/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return ProductDetailScreen(productId: id);
              },
            ),
          ],
        ),
      ],
    ),
    // Profile tab
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            // Deep link opens settings within profile tab
            GoRoute(
              path: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
),
```

---

## Authentication Redirects

Handle deep links that require authentication:

```dart
@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnLoginPage = state.matchedLocation == '/login';

      // Protected routes
      final protectedPaths = ['/orders', '/profile', '/settings'];
      final isProtected = protectedPaths.any(
        (path) => state.matchedLocation.startsWith(path),
      );

      // Not logged in + accessing protected route → save destination, go to login
      if (isProtected && !isLoggedIn) {
        final redirectTo = state.uri.toString();
        return '/login?redirect=${Uri.encodeComponent(redirectTo)}';
      }

      // Logged in + on login page → check for pending redirect
      if (isOnLoginPage && isLoggedIn) {
        final redirectTo = state.uri.queryParameters['redirect'];
        if (redirectTo != null) {
          return Uri.decodeComponent(redirectTo);
        }
        return '/';
      }

      return null;
    },
    routes: [...],
  );
}
```

### Flow Explained

1. **User taps deep link** `/orders/123` while logged out
2. **Router redirect** detects protected path + not logged in
3. **Redirects to** `/login?redirect=%2Forders%2F123`
4. **User logs in** → auth state changes → router re-evaluates
5. **Router redirect** detects on login page + logged in + has redirect param
6. **Redirects to** `/orders/123` (the original deep link)

### Alternative: Manual Redirect After Login

If you prefer explicit control in the login notifier:

```dart
// In AuthNotifier
Future<void> login(String email, String password) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() => _repository.login(email, password));

  // Don't navigate here - let router redirect handle it
  // The router will automatically redirect when auth state changes
}
```

Or handle it manually in the login screen:

```dart
// In LoginScreen - after successful login
void _onLoginSuccess() {
  final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];

  if (redirect != null) {
    context.go(Uri.decodeComponent(redirect));
  } else {
    context.go('/');
  }
}
```

**Note:** Choose one approach - either router-based (automatic) or manual. Don't mix both or you'll get double navigation.

---

## Error Handling

### Unknown Routes

```dart
GoRouter(
  errorBuilder: (context, state) {
    // Log unknown deep link for analytics
    debugPrint('Unknown deep link: ${state.uri}');

    return NotFoundScreen(
      message: 'Page not found',
      onGoHome: () => context.go('/'),
    );
  },
);
```

### Validation

Validate deep link parameters before navigation:

```dart
GoRoute(
  path: '/products/:id',
  redirect: (context, state) {
    final id = state.pathParameters['id'];

    // Validate ID format (e.g., must be numeric)
    if (id == null || int.tryParse(id) == null) {
      return '/'; // Redirect to home for invalid IDs
    }

    return null; // Continue to route
  },
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return ProductDetailScreen(productId: id);
  },
),
```

---

## Deep Link from Push Notifications

Integrate with push notifications:

```dart
// In push notification service
void handleNotificationTap(RemoteMessage message) {
  final router = ref.read(routerProvider);
  final data = message.data;

  final type = data['type'];
  final id = data['id'];

  switch (type) {
    case 'product':
      router.go('/products/$id');
    case 'order':
      router.go('/orders/$id');
    case 'user':
      router.go('/users/$id');
    default:
      // Unknown type, go to home
      router.go('/');
  }
}
```

---

## Testing Deep Links

### Unit Tests

```dart
void main() {
  group('Deep link routing', () {
    late GoRouter router;

    setUp(() {
      router = createTestRouter();
    });

    test('navigates to product detail', () {
      router.go('/products/123');
      expect(router.location, '/products/123');
    });

    test('handles unknown routes', () {
      router.go('/unknown/path');
      // Verify error page is shown
    });

    test('extracts query parameters', () {
      router.go('/search?q=flutter');
      final state = router.state;
      expect(state?.uri.queryParameters['q'], 'flutter');
    });
  });
}
```

### Integration Tests

```dart
testWidgets('deep link opens product screen', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
      ),
    ),
  );

  // Simulate deep link
  router.go('/products/123');
  await tester.pumpAndSettle();

  expect(find.byType(ProductDetailScreen), findsOneWidget);
  expect(find.text('Product 123'), findsOneWidget);
});
```

### Manual Testing Commands

```bash
# iOS Simulator
xcrun simctl openurl booted "https://yourdomain.com/products/123"

# Android Emulator/Device
adb shell am start -a android.intent.action.VIEW \
  -d "https://yourdomain.com/products/123" \
  com.example.yourapp
```

---

## Reference File

**See:** `reference/router/deep_link_handler.dart` for a complete router configuration with deep link handling.

---

## Best Practices

1. **Use path parameters** for required IDs (`/products/:id`)
2. **Use query parameters** for optional filters (`/search?q=flutter`)
3. **Validate parameters** before showing screens
4. **Handle unknown routes** gracefully with error page
5. **Log deep link attempts** for analytics
6. **Test all deep link paths** on both platforms
7. **Consider authentication** for protected routes
8. **Match paths exactly** between router and platform configs

---

## Related

- [ios-guide.md](ios-guide.md) - iOS Universal Links setup
- [android-guide.md](android-guide.md) - Android App Links setup
- [checklist.md](checklist.md) - Verification checklist
- `/push-notifications` - Deep links from notifications

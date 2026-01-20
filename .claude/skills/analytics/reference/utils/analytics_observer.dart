// Template: GoRouter observer for automatic screen tracking
//
// Location: lib/core/router/analytics_observer.dart
//
// Usage:
// 1. Copy to target location
// 2. Add to GoRouter observers list
// 3. Screens will be automatically tracked

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/analytics_service.dart';

/// Route observer that logs screen views to Firebase Analytics.
///
/// Add to [GoRouter.observers]:
/// ```dart
/// final router = GoRouter(
///   observers: [AnalyticsRouteObserver()],
///   routes: [...],
/// );
/// ```
final class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _logScreenView(previousRoute);
    }
  }

  void _logScreenView(Route<dynamic> route) {
    final screenName = _extractScreenName(route);
    if (screenName != null && screenName.isNotEmpty) {
      AnalyticsService.logScreenView(
        screenName: screenName,
        screenClass: route.settings.name,
      );
    }
  }

  /// Extract a readable screen name from the route.
  String? _extractScreenName(Route<dynamic> route) {
    // Try route name first
    final routeName = route.settings.name;
    if (routeName != null && routeName.isNotEmpty && routeName != '/') {
      return _formatRouteName(routeName);
    }

    // Fall back to route path if available
    if (route is GoRoute) {
      return _formatRouteName(route.path);
    }

    return null;
  }

  /// Format route path into a readable screen name.
  ///
  /// Examples:
  /// - '/home' -> 'HomeScreen'
  /// - '/settings/profile' -> 'SettingsProfileScreen'
  /// - '/orders/:id' -> 'OrdersDetailScreen'
  String _formatRouteName(String path) {
    if (path.isEmpty || path == '/') {
      return 'HomeScreen';
    }

    // Remove leading slash and split by '/'
    final parts = path.replaceFirst('/', '').split('/');

    // Filter out path parameters (e.g., :id)
    final nameParts = parts
        .where((part) => !part.startsWith(':'))
        .map(_capitalize)
        .toList();

    if (nameParts.isEmpty) {
      return 'DetailScreen';
    }

    return '${nameParts.join('')}Screen';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

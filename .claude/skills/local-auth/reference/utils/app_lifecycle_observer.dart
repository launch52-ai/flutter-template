// Template: App lifecycle observer for local auth
//
// Location: lib/core/utils/app_lifecycle_observer.dart
//
// Usage:
// 1. Copy to target location
// 2. Update imports
// 3. Initialize in main.dart or app widget

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/local_auth_provider.dart';

/// Observes app lifecycle and triggers local auth when needed.
///
/// Tracks time spent in background and triggers re-authentication
/// based on configured timeout.
///
/// Usage:
/// ```dart
/// final observer = AppLifecycleObserver(ref);
/// observer.init();
/// // Later: observer.dispose();
/// ```
final class AppLifecycleObserver with WidgetsBindingObserver {
  final Ref _ref;
  DateTime? _backgroundedAt;

  AppLifecycleObserver(this._ref);

  /// Start observing lifecycle events.
  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Stop observing lifecycle events.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App going to background - record time
        _backgroundedAt ??= DateTime.now();
        break;

      case AppLifecycleState.resumed:
        // App coming to foreground - check if auth needed
        _onResumed();
        break;

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App being terminated or hidden
        break;
    }
  }

  void _onResumed() {
    if (_backgroundedAt == null) return;

    final backgroundDuration = DateTime.now().difference(_backgroundedAt!);
    _backgroundedAt = null;

    // Notify the auth notifier to check if re-auth is needed
    _ref
        .read(localAuthNotifierProvider.notifier)
        .checkAuthRequired(backgroundDuration);
  }
}

// =============================================================================
// INTEGRATION EXAMPLE
// =============================================================================

// Option 1: Using a ConsumerStatefulWidget at app root
//
// class App extends ConsumerStatefulWidget {
//   @override
//   ConsumerState<App> createState() => _AppState();
// }
//
// class _AppState extends ConsumerState<App> {
//   late final AppLifecycleObserver _lifecycleObserver;
//
//   @override
//   void initState() {
//     super.initState();
//     _lifecycleObserver = AppLifecycleObserver(ref);
//     _lifecycleObserver.init();
//   }
//
//   @override
//   void dispose() {
//     _lifecycleObserver.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(...);
//   }
// }

// Option 2: Using a provider (cleaner)
//
// @riverpod
// AppLifecycleObserver appLifecycleObserver(Ref ref) {
//   final observer = AppLifecycleObserver(ref);
//   observer.init();
//   ref.onDispose(() => observer.dispose());
//   return observer;
// }
//
// // In main.dart or app widget:
// ref.watch(appLifecycleObserverProvider); // Ensures it's initialized

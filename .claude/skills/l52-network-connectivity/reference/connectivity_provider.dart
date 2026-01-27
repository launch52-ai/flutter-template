// Template: Riverpod providers for connectivity monitoring
//
// Location: lib/core/providers/connectivity_provider.dart
//
// Usage:
// 1. Copy to target location
// 2. Ensure ConnectivityService is available
// 3. Use ref.watch(isOnlineProvider) in widgets
// 4. Call reportRequestSuccess() from Dio interceptor on successful requests

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// TODO: Update import to match your project structure
import '../services/connectivity_service.dart';

part 'connectivity_provider.g.dart';

/// Provider for [ConnectivityService].
@Riverpod(keepAlive: true)
ConnectivityService connectivityService(ConnectivityServiceRef ref) {
  return ConnectivityService();
}

/// Raw connectivity status from connectivity_plus.
///
/// Note: This only reflects network interface status, not actual internet access.
/// Use [isOnlineProvider] instead for accurate online/offline status.
@Riverpod(keepAlive: true)
Stream<List<ConnectivityResult>> connectivity(ConnectivityRef ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
}

/// Notifier that tracks actual connectivity based on both library status
/// AND real API request success.
///
/// The connectivity_plus library can report false negatives when:
/// - Government blocks connectivity check endpoints
/// - Captive portals intercept requests
/// - DNS issues affect only certain domains
///
/// This notifier considers the device online if:
/// - connectivity_plus reports a connection, OR
/// - A real API request succeeded recently (within [_requestSuccessWindow])
@Riverpod(keepAlive: true)
class ActualConnectivity extends _$ActualConnectivity {
  /// How long a successful request keeps us "online" even if
  /// connectivity_plus reports no connection.
  static const _requestSuccessWindow = Duration(seconds: 30);

  DateTime? _lastSuccessfulRequest;
  Timer? _windowTimer;

  @override
  bool build() {
    // Listen to connectivity_plus changes
    ref.listen(connectivityProvider, (prev, next) {
      next.whenData((results) {
        _updateState(results);
      });
    });

    // Cleanup timer on dispose
    ref.onDispose(() {
      _windowTimer?.cancel();
    });

    // Initial state: assume online until proven otherwise
    return true;
  }

  void _updateState(List<ConnectivityResult> results) {
    final libraryOnline = !results.contains(ConnectivityResult.none);
    final recentSuccess = _hasRecentSuccessfulRequest();

    // Online if EITHER:
    // 1. connectivity_plus says we have a connection, OR
    // 2. We had a successful API request recently
    state = libraryOnline || recentSuccess;
  }

  bool _hasRecentSuccessfulRequest() {
    if (_lastSuccessfulRequest == null) return false;
    return DateTime.now().difference(_lastSuccessfulRequest!) < _requestSuccessWindow;
  }

  /// Call this when an API request succeeds.
  ///
  /// This overrides connectivity_plus false negatives caused by
  /// blocked endpoints or government restrictions.
  ///
  /// Typically called from a Dio interceptor on successful responses.
  void reportRequestSuccess() {
    _lastSuccessfulRequest = DateTime.now();

    // If we were showing offline, immediately update to online
    if (!state) {
      state = true;
    }

    // Reset the window timer
    _windowTimer?.cancel();
    _windowTimer = Timer(_requestSuccessWindow, () {
      // After window expires, re-evaluate based on connectivity_plus
      final connectivityState = ref.read(connectivityProvider).valueOrNull;
      if (connectivityState != null) {
        _updateState(connectivityState);
      }
    });
  }

  /// Call this when an API request fails due to network error.
  ///
  /// Only affects state if connectivity_plus also reports offline.
  void reportRequestFailure() {
    final connectivityState = ref.read(connectivityProvider).valueOrNull;
    if (connectivityState != null &&
        connectivityState.contains(ConnectivityResult.none)) {
      state = false;
    }
  }
}

/// Provider that returns `true` when device is actually online.
///
/// Uses smart detection that considers both connectivity_plus status
/// AND actual API request success. This avoids false negatives from
/// blocked connectivity check endpoints.
@Riverpod(keepAlive: true)
bool isOnline(IsOnlineRef ref) {
  return ref.watch(actualConnectivityProvider);
}

/// One-shot provider to check current connectivity status.
@riverpod
Future<bool> checkConnectivity(CheckConnectivityRef ref) async {
  final service = ref.watch(connectivityServiceProvider);
  return service.isOnline();
}

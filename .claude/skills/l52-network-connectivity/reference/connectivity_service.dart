// Template: Connectivity Service wrapping connectivity_plus
//
// Location: lib/core/services/connectivity_service.dart
//
// Usage:
// 1. Copy to target location
// 2. Import in main.dart and initialize
// 3. Use with Riverpod provider for state management

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Service that monitors network connectivity status.
///
/// Wraps [Connectivity] from connectivity_plus package and provides
/// a simple API for checking and streaming connectivity status.
final class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Stream of connectivity status changes.
  ///
  /// Emits whenever the network connectivity changes (wifi, mobile, none, etc).
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// Check current connectivity status.
  ///
  /// Returns a list of current connectivity results.
  /// Check for [ConnectivityResult.none] to determine if offline.
  Future<List<ConnectivityResult>> checkConnectivity() =>
      _connectivity.checkConnectivity();

  /// Convenience method to check if device is currently online.
  ///
  /// Returns `true` if any network connection is available.
  Future<bool> isOnline() async {
    final results = await checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}

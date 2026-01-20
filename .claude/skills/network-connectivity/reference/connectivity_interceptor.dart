// Template: Dio interceptor for connectivity tracking
//
// Location: lib/core/network/connectivity_interceptor.dart
//
// Usage:
// 1. Copy to target location
// 2. Add to Dio interceptors in dio_client.dart
// 3. Pass the WidgetRef or ProviderContainer to the interceptor

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Update import to match your project structure
import '../providers/connectivity_provider.dart';

/// Dio interceptor that reports request success/failure to the
/// connectivity notifier.
///
/// This enables smart connectivity detection that overrides
/// connectivity_plus false negatives when actual API requests succeed.
///
/// Add to Dio:
/// ```dart
/// dio.interceptors.add(ConnectivityInterceptor(ref));
/// ```
final class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._ref);

  final Ref _ref;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Any successful response means we're online
    _ref.read(actualConnectivityProvider.notifier).reportRequestSuccess();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Only report failure for connection-related errors
    if (_isConnectionError(err)) {
      _ref.read(actualConnectivityProvider.notifier).reportRequestFailure();
    }
    handler.next(err);
  }

  bool _isConnectionError(DioException err) {
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      _ => false,
    };
  }
}

/// Alternative: Standalone function for use outside Dio.
///
/// Call after any successful network operation to update connectivity state.
void reportNetworkSuccess(Ref ref) {
  ref.read(actualConnectivityProvider.notifier).reportRequestSuccess();
}

/// Alternative: Standalone function for use outside Dio.
///
/// Call after network failures to update connectivity state.
void reportNetworkFailure(Ref ref) {
  ref.read(actualConnectivityProvider.notifier).reportRequestFailure();
}

/// Riverpod testing utilities.
///
/// Helpers for testing providers and state management.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// PROVIDER CONTAINER FACTORY
// =============================================================================

/// Creates a [ProviderContainer] with automatic cleanup.
///
/// Usage:
/// ```dart
/// late ProviderContainer container;
///
/// setUp(() {
///   container = makeProviderContainer(
///     overrides: [
///       authRepositoryProvider.overrideWithValue(mockRepo),
///     ],
///   );
/// });
///
/// test('example', () {
///   final state = container.read(authNotifierProvider);
///   expect(state, const AuthState.initial());
/// });
/// ```
ProviderContainer makeProviderContainer({
  List<Override> overrides = const [],
  ProviderContainer? parent,
  List<ProviderObserver>? observers,
}) {
  final container = ProviderContainer(
    overrides: overrides,
    parent: parent,
    observers: observers,
  );

  // Automatically dispose after test
  addTearDown(container.dispose);

  return container;
}

// =============================================================================
// STATE LISTENER
// =============================================================================

/// Tracks provider state changes for testing.
///
/// Usage:
/// ```dart
/// final listener = ProviderListener<AuthState>();
/// container.listen(authNotifierProvider, listener.call, fireImmediately: true);
///
/// await container.read(authNotifierProvider.notifier).signIn(...);
///
/// expect(listener.states, [
///   const AuthState.initial(),
///   const AuthState.loading(),
///   isA<AuthStateAuthenticated>(),
/// ]);
/// ```
final class ProviderListener<T> {
  /// All states captured, in order.
  final List<T> states = [];

  /// Callback to pass to `container.listen()`.
  void call(T? previous, T next) {
    states.add(next);
  }

  /// Clears captured states.
  void reset() => states.clear();

  /// Returns true if a state matching [predicate] was captured.
  bool hasState(bool Function(T state) predicate) {
    return states.any(predicate);
  }

  /// Returns the last captured state, or null if empty.
  T? get lastState => states.isEmpty ? null : states.last;

  /// Returns the number of captured states.
  int get stateCount => states.length;
}

// =============================================================================
// ASYNC VALUE MATCHERS
// =============================================================================

/// Extension for testing [AsyncValue] states.
extension AsyncValueMatchers<T> on AsyncValue<T> {
  /// Asserts this is [AsyncData] with the expected value.
  void expectData(T expected) {
    expect(this, isA<AsyncData<T>>());
    expect((this as AsyncData<T>).value, expected);
  }

  /// Asserts this is [AsyncData] matching the predicate.
  void expectDataMatching(bool Function(T value) predicate) {
    expect(this, isA<AsyncData<T>>());
    expect(predicate((this as AsyncData<T>).value), isTrue);
  }

  /// Asserts this is loading (either [AsyncLoading] or [isLoading] is true).
  void expectLoading() {
    expect(isLoading, isTrue);
  }

  /// Asserts this is [AsyncError].
  void expectError([Object? expectedError]) {
    expect(this, isA<AsyncError<T>>());
    if (expectedError != null) {
      expect((this as AsyncError<T>).error, expectedError);
    }
  }

  /// Asserts this is [AsyncError] with error matching the predicate.
  void expectErrorMatching(bool Function(Object error) predicate) {
    expect(this, isA<AsyncError<T>>());
    expect(predicate((this as AsyncError<T>).error), isTrue);
  }
}

// =============================================================================
// PROVIDER TESTING UTILITIES
// =============================================================================

/// Extension on [ProviderContainer] for common test operations.
extension ProviderContainerTestX on ProviderContainer {
  /// Reads and verifies a provider returns expected value.
  void expectProvider<T>(ProviderListenable<T> provider, T expected) {
    expect(read(provider), expected);
  }

  /// Reads and verifies a provider matches a matcher.
  void expectProviderMatches<T>(
    ProviderListenable<T> provider,
    Matcher matcher,
  ) {
    expect(read(provider), matcher);
  }
}

// =============================================================================
// ASYNC NOTIFIER TESTING
// =============================================================================

/// Helper for testing async operations in notifiers.
///
/// Waits for state to settle after triggering an action.
Future<void> waitForProviderState<T>(
  ProviderContainer container,
  ProviderListenable<T> provider, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final completer = Completer<void>();
  final listener = container.listen(
    provider,
    (_, __) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    },
  );

  try {
    await completer.future.timeout(timeout);
  } finally {
    listener.close();
  }
}

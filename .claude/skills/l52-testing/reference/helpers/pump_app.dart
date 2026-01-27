/// Widget test utilities.
///
/// Helpers for pumping widgets with all necessary wrappers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/theme/app_theme.dart';

// =============================================================================
// PUMP APP EXTENSION
// =============================================================================

/// Extension on [WidgetTester] for pumping widgets with providers.
extension PumpAppExtension on WidgetTester {
  /// Pumps a widget wrapped with [ProviderScope] and [MaterialApp].
  ///
  /// Usage:
  /// ```dart
  /// await tester.pumpApp(
  ///   const LoginScreen(),
  ///   overrides: [
  ///     authRepositoryProvider.overrideWithValue(mockRepo),
  ///   ],
  /// );
  /// ```
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
    ThemeData? theme,
    ThemeMode themeMode = ThemeMode.light,
    Locale? locale,
    List<NavigatorObserver> navigatorObservers = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: locale,
          navigatorObservers: navigatorObservers,
          home: widget,
        ),
      ),
    );
  }

  /// Pumps a widget and waits for all animations/futures to settle.
  Future<void> pumpAppAndSettle(
    Widget widget, {
    List<Override> overrides = const [],
    ThemeData? theme,
    ThemeMode themeMode = ThemeMode.light,
    Duration duration = const Duration(milliseconds: 100),
  }) async {
    await pumpApp(
      widget,
      overrides: overrides,
      theme: theme,
      themeMode: themeMode,
    );
    await pumpAndSettle(duration);
  }

  /// Pumps a widget wrapped in a Scaffold (for testing standalone widgets).
  Future<void> pumpWidget_(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await pumpApp(
      Scaffold(body: widget),
      overrides: overrides,
    );
  }
}

// =============================================================================
// INTERACTION HELPERS
// =============================================================================

/// Extension on [WidgetTester] for simulating user interactions.
extension WidgetInteractions on WidgetTester {
  /// Taps a widget and pumps.
  Future<void> simulateTapOn(Finder finder) async {
    await tap(finder);
    await pump();
  }

  /// Taps a widget and waits for animations to settle.
  Future<void> simulateTapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enters text in a TextField and pumps.
  Future<void> simulateTextInput(Finder finder, String text) async {
    await enterText(finder, text);
    await pump();
  }

  /// Clears text in a TextField and pumps.
  Future<void> simulateClearText(Finder finder) async {
    await enterText(finder, '');
    await pump();
  }

  /// Simulates pressing the done/submit action on keyboard.
  Future<void> simulateSubmit() async {
    await testTextInput.receiveAction(TextInputAction.done);
    await pump();
  }

  /// Scrolls until a widget is visible.
  Future<void> scrollUntilVisible(
    Finder finder, {
    Finder? scrollable,
    double delta = 100,
  }) async {
    await dragUntilVisible(
      finder,
      scrollable ?? find.byType(Scrollable).first,
      Offset(0, -delta),
    );
  }

  /// Simulates a pull-to-refresh gesture.
  Future<void> simulatePullToRefresh({Finder? scrollable}) async {
    final target = scrollable ?? find.byType(Scrollable).first;
    await drag(target, const Offset(0, 300));
    await pumpAndSettle();
  }
}

// =============================================================================
// FINDER HELPERS
// =============================================================================

/// Extension on [CommonFinders] for common test finders.
extension FinderHelpers on CommonFinders {
  /// Finds a widget by its Key string.
  Finder byKeyString(String key) => byKey(Key(key));

  /// Finds a TextField with the given label.
  Finder textFieldWithLabel(String label) => byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == label,
      );

  /// Finds an ElevatedButton with the given text.
  Finder elevatedButtonWithText(String text) => byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.child is Text &&
            (widget.child as Text).data == text,
      );

  /// Finds any button (ElevatedButton, TextButton, OutlinedButton) with text.
  Finder buttonWithText(String text) => byWidgetPredicate(
        (widget) =>
            (widget is ElevatedButton ||
                widget is TextButton ||
                widget is OutlinedButton) &&
            widget is ButtonStyleButton &&
            _hasChildWithText(widget, text),
      );
}

bool _hasChildWithText(Widget widget, String text) {
  if (widget is Text && widget.data == text) return true;
  if (widget is ButtonStyleButton) {
    final child = widget.child;
    if (child is Text && child.data == text) return true;
  }
  return false;
}

// =============================================================================
// ASSERTION HELPERS
// =============================================================================

/// Extension on [WidgetTester] for common assertions.
extension WidgetAssertions on WidgetTester {
  /// Asserts that a widget with the given text exists.
  void expectTextExists(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Asserts that a widget with the given text does not exist.
  void expectTextNotExists(String text) {
    expect(find.text(text), findsNothing);
  }

  /// Asserts that a loading indicator is visible.
  void expectLoadingIndicator() {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// Asserts that no loading indicator is visible.
  void expectNoLoadingIndicator() {
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  /// Asserts that a SnackBar with the given text is visible.
  void expectSnackBar(String text) {
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.descendant(of: find.byType(SnackBar), matching: find.text(text)),
        findsOneWidget);
  }

  /// Asserts the number of widgets of a given type.
  void expectWidgetCount<T extends Widget>(int count) {
    expect(find.byType(T), findsNWidgets(count));
  }
}

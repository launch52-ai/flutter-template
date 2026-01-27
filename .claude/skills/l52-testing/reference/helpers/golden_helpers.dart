/// Golden/Snapshot test utilities.
///
/// Helpers for visual regression testing using golden_toolkit.
///
/// Pattern from Essential Feed iOS: Snapshot tests that compare
/// rendered UI against stored reference images.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../lib/core/theme/app_theme.dart';

// =============================================================================
// DEVICE CONFIGURATIONS
// =============================================================================

/// Standard device configurations for golden tests.
///
/// Tests should run against multiple device sizes to catch layout issues.
final class GoldenDevices {
  GoldenDevices._();

  /// iPhone SE (small phone)
  static const Device iPhoneSE = Device(
    name: 'iPhone_SE',
    size: Size(375, 667),
    devicePixelRatio: 2.0,
  );

  /// iPhone 14 (standard phone)
  static const Device iPhone14 = Device(
    name: 'iPhone_14',
    size: Size(390, 844),
    devicePixelRatio: 3.0,
  );

  /// iPhone 14 Pro Max (large phone)
  static const Device iPhone14ProMax = Device(
    name: 'iPhone_14_Pro_Max',
    size: Size(430, 932),
    devicePixelRatio: 3.0,
  );

  /// Pixel 5 (Android)
  static const Device pixel5 = Device(
    name: 'Pixel_5',
    size: Size(393, 851),
    devicePixelRatio: 2.75,
  );

  /// iPad Mini (tablet)
  static const Device iPadMini = Device(
    name: 'iPad_Mini',
    size: Size(744, 1133),
    devicePixelRatio: 2.0,
  );

  /// Default set of devices for phone-only apps
  static const List<Device> phones = [
    iPhoneSE,
    iPhone14,
    pixel5,
  ];

  /// All devices including tablets
  static const List<Device> all = [
    iPhoneSE,
    iPhone14,
    iPhone14ProMax,
    pixel5,
    iPadMini,
  ];
}

// =============================================================================
// THEME VARIANTS
// =============================================================================

/// Theme variant for golden tests.
enum GoldenTheme {
  light('light'),
  dark('dark');

  final String suffix;
  const GoldenTheme(this.suffix);

  ThemeData get themeData => switch (this) {
        GoldenTheme.light => AppTheme.light,
        GoldenTheme.dark => AppTheme.dark,
      };

  ThemeMode get themeMode => switch (this) {
        GoldenTheme.light => ThemeMode.light,
        GoldenTheme.dark => ThemeMode.dark,
      };
}

// =============================================================================
// GOLDEN TEST BUILDERS
// =============================================================================

/// Builds a widget wrapped for golden testing.
///
/// Includes:
/// - ProviderScope with overrides
/// - MaterialApp with theme
/// - Proper sizing for device
Widget buildGoldenWidget({
  required Widget child,
  required GoldenTheme theme,
  List<Override> overrides = const [],
  Locale? locale,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme.themeMode,
      locale: locale,
      home: child,
    ),
  );
}

/// Generates a golden file name with theme and device info.
///
/// Format: `{baseName}_{theme}_{device}.png`
///
/// Example: `login_screen_light_iPhone_14.png`
String goldenFileName(String baseName, GoldenTheme theme, Device device) {
  return '${baseName}_${theme.suffix}_${device.name}';
}

// =============================================================================
// GOLDEN TEST EXTENSIONS
// =============================================================================

/// Extension on WidgetTester for golden test helpers.
extension GoldenTestExtension on WidgetTester {
  /// Pumps a widget configured for golden testing.
  Future<void> pumpGoldenWidget(
    Widget widget, {
    required GoldenTheme theme,
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      buildGoldenWidget(
        child: widget,
        theme: theme,
        overrides: overrides,
      ),
    );
    await pumpAndSettle();
  }

  /// Precaches all images in the widget tree.
  ///
  /// Call this before taking golden snapshots to ensure images are loaded.
  Future<void> precacheImages() async {
    await runAsync(() async {
      for (final element in binding.rootElement!.renderObject!
          .debugDescribeChildren()) {
        // Images will be loaded during pumpAndSettle
      }
    });
    await pumpAndSettle();
  }
}

// =============================================================================
// MULTI-SCENARIO GOLDEN TESTS
// =============================================================================

/// Runs golden tests for a widget across multiple themes and devices.
///
/// Usage:
/// ```dart
/// testGoldens('login_screen', (tester) async {
///   await multiThemeGoldenTest(
///     tester: tester,
///     baseName: 'login_screen',
///     builder: (theme) => buildGoldenWidget(
///       child: const LoginScreen(),
///       theme: theme,
///       overrides: [...],
///     ),
///   );
/// });
/// ```
Future<void> multiThemeGoldenTest({
  required WidgetTester tester,
  required String baseName,
  required Widget Function(GoldenTheme theme) builder,
  List<Device> devices = const [GoldenDevices.iPhone14],
}) async {
  for (final theme in GoldenTheme.values) {
    for (final device in devices) {
      await tester.binding.setSurfaceSize(device.size);
      tester.view.devicePixelRatio = device.devicePixelRatio;

      await tester.pumpWidget(builder(theme));
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        goldenFileName(baseName, theme, device),
      );
    }
  }
}

// =============================================================================
// GOLDEN TEST CONFIGURATION
// =============================================================================

/// Configuration for golden tests.
///
/// Call in `flutter_test_config.dart` to set up golden tests globally.
///
/// ```dart
/// // test/flutter_test_config.dart
/// import 'dart:async';
/// import 'package:golden_toolkit/golden_toolkit.dart';
///
/// Future<void> testExecutable(FutureOr<void> Function() testMain) async {
///   await loadAppFonts();
///   return testMain();
/// }
/// ```
Future<void> configureGoldenTests() async {
  await loadAppFonts();
}

// =============================================================================
// SCENARIO BUILDERS
// =============================================================================

/// Builds common screen scenarios for golden tests.
final class GoldenScenarios {
  GoldenScenarios._();

  /// Builds scenarios for a screen in different states.
  ///
  /// Returns a list of (name, widget) pairs for multi-scenario testing.
  static List<(String name, Widget widget)> authScreenStates({
    required Widget Function() initial,
    required Widget Function() loading,
    required Widget Function() error,
  }) {
    return [
      ('initial', initial()),
      ('loading', loading()),
      ('error', error()),
    ];
  }
}

// =============================================================================
// TOLERANCE CONFIGURATION
// =============================================================================

/// Custom golden file comparator with tolerance for minor pixel differences.
///
/// Useful when running tests on different platforms that may render
/// slightly differently.
class TolerantGoldenFileComparator extends LocalFileComparator {
  TolerantGoldenFileComparator(super.testFile, {this.tolerance = 0.005});

  /// Allowed percentage of different pixels (0.0 to 1.0).
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (!result.passed && result.diffPercent <= tolerance) {
      // Within tolerance, consider it passed
      return true;
    }

    return result.passed;
  }
}

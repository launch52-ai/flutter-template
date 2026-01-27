# Accessibility Testing Guide

Patterns for testing accessibility compliance in Flutter apps, including automated tests and manual verification.

---

## 1. Built-in Accessibility Guidelines

Flutter provides four built-in accessibility test guidelines:

| Guideline | What It Checks | Standard |
|-----------|---------------|----------|
| `textContrastGuideline` | Text has ≥4.5:1 contrast ratio | WCAG 2.1 AA |
| `androidTapTargetGuideline` | Touch targets ≥48×48dp | Material Design |
| `iOSTapTargetGuideline` | Touch targets ≥44×44pt | Apple HIG |
| `labeledTapTargetGuideline` | All tap/long-press have labels | WCAG 2.1 |

---

## 2. Basic Accessibility Tests

### Testing All Guidelines

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('screen meets accessibility guidelines', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MyScreen()));

    // Test all four guidelines
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
```

### Test Helper

Create a reusable helper for consistent testing:

```dart
// test/helpers/accessibility_helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs all accessibility guideline tests on a widget.
Future<void> expectMeetsAccessibilityGuidelines(WidgetTester tester) async {
  await expectLater(
    tester,
    meetsGuideline(textContrastGuideline),
    reason: 'Text must have contrast ratio ≥4.5:1',
  );

  await expectLater(
    tester,
    meetsGuideline(androidTapTargetGuideline),
    reason: 'Touch targets must be ≥48×48dp',
  );

  await expectLater(
    tester,
    meetsGuideline(labeledTapTargetGuideline),
    reason: 'All interactive elements must have semantic labels',
  );
}

/// Pumps widget and runs accessibility tests.
Future<void> pumpAndTestAccessibility(
  WidgetTester tester,
  Widget widget, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: widget,
    ),
  );
  await tester.pumpAndSettle();
  await expectMeetsAccessibilityGuidelines(tester);
}
```

### Usage in Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/accessibility_helpers.dart';

void main() {
  group('LoginScreen accessibility', () {
    testWidgets('meets guidelines in light mode', (tester) async {
      await pumpAndTestAccessibility(
        tester,
        const LoginScreen(),
        theme: AppTheme.light,
      );
    });

    testWidgets('meets guidelines in dark mode', (tester) async {
      await pumpAndTestAccessibility(
        tester,
        const LoginScreen(),
        theme: AppTheme.dark,
      );
    });
  });
}
```

---

## 3. Testing Semantics

### Verifying Semantic Labels

```dart
testWidgets('delete button has correct semantics', (tester) async {
  await tester.pumpWidget(MaterialApp(home: PhotoCard()));

  // Find the widget
  final deleteButton = find.byIcon(Icons.delete);

  // Get its semantics
  final semantics = tester.getSemantics(deleteButton);

  // Verify semantics
  expect(
    semantics,
    matchesSemantics(
      label: 'Delete photo',
      hasTapAction: true,
      isButton: true,
      isEnabled: true,
    ),
  );
});
```

### matchesSemantics Matchers

```dart
matchesSemantics(
  // Content
  label: 'Expected label',
  value: 'Expected value',
  hint: 'Expected hint',

  // Flags
  isButton: true,
  isLink: true,
  isHeader: true,
  isTextField: true,
  isSlider: true,
  isFocusable: true,
  isFocused: true,
  isEnabled: true,
  isChecked: true,
  isSelected: true,
  isToggled: true,
  hasEnabledState: true,
  hasCheckedState: true,
  hasToggledState: true,

  // Actions
  hasTapAction: true,
  hasLongPressAction: true,
  hasScrollLeftAction: true,
  hasScrollRightAction: true,
  hasScrollUpAction: true,
  hasScrollDownAction: true,
)
```

### Testing Semantic Tree Structure

```dart
testWidgets('screen has correct semantic structure', (tester) async {
  final handle = tester.ensureSemantics();

  await tester.pumpWidget(MaterialApp(home: MyScreen()));

  // Get the full semantic tree
  expect(
    tester.semantics,
    hasSemantics(
      TestSemantics.root(
        children: [
          TestSemantics(
            label: 'My Screen',
            children: [
              TestSemantics(label: 'Header'),
              TestSemantics(label: 'Content'),
            ],
          ),
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
      ignoreId: true,
    ),
  );

  handle.dispose();
});
```

---

## 4. Testing Focus Order

### Verifying Focus Traversal

```dart
testWidgets('form has correct focus order', (tester) async {
  await tester.pumpWidget(MaterialApp(home: LoginScreen()));

  // Verify initial focus
  final emailField = find.byKey(Key('email-field'));
  expect(
    FocusScope.of(tester.element(emailField)).hasFocus,
    isTrue,
    reason: 'Email field should have initial focus',
  );

  // Simulate tab/next focus
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();

  // Verify focus moved to password
  final passwordField = find.byKey(Key('password-field'));
  expect(
    Focus.of(tester.element(passwordField)).hasFocus,
    isTrue,
    reason: 'Password field should have focus after tab',
  );
});
```

### Testing Semantic Sort Order

```dart
testWidgets('elements are read in correct order', (tester) async {
  final handle = tester.ensureSemantics();

  await tester.pumpWidget(MaterialApp(home: DashboardScreen()));

  // Get semantic nodes in traversal order
  final root = WidgetsBinding.instance.pipelineOwner.semanticsOwner!.rootSemanticsNode!;

  final labels = <String>[];
  void visitNode(SemanticsNode node) {
    if (node.label.isNotEmpty) {
      labels.add(node.label);
    }
    node.visitChildren(visitNode);
  }
  root.visitChildren(visitNode);

  // Verify order
  expect(labels, [
    'Welcome message',
    'Quick actions',
    'Recent items',
    'Settings',
  ]);

  handle.dispose();
});
```

---

## 5. Testing Dynamic Content

### Live Region Announcements

```dart
testWidgets('status changes are announced', (tester) async {
  final handle = tester.ensureSemantics();

  await tester.pumpWidget(MaterialApp(home: UploadScreen()));

  // Find the status widget
  final statusFinder = find.byKey(Key('upload-status'));

  // Verify it's a live region
  final semantics = tester.getSemantics(statusFinder);
  expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);

  // Trigger status change
  await tester.tap(find.text('Upload'));
  await tester.pump();

  // Verify new status
  expect(
    tester.getSemantics(statusFinder).label,
    'Uploading...',
  );

  handle.dispose();
});
```

---

## 6. Testing Touch Targets

### Verifying Size

```dart
testWidgets('interactive elements have minimum touch target', (tester) async {
  await tester.pumpWidget(MaterialApp(home: IconBar()));

  // Find all icon buttons
  final iconButtons = find.byType(IconButton);

  for (final element in iconButtons.evaluate()) {
    final renderBox = element.renderObject as RenderBox;
    final size = renderBox.size;

    expect(
      size.width,
      greaterThanOrEqualTo(48.0),
      reason: 'Icon button width must be ≥48dp',
    );
    expect(
      size.height,
      greaterThanOrEqualTo(48.0),
      reason: 'Icon button height must be ≥48dp',
    );
  }
});
```

### Custom Touch Target Test

```dart
// test/helpers/accessibility_helpers.dart

/// Verifies all interactive widgets have minimum touch target size.
Future<void> verifyTouchTargets(
  WidgetTester tester, {
  double minSize = 48.0,
}) async {
  final interactiveTypes = [
    IconButton,
    TextButton,
    ElevatedButton,
    OutlinedButton,
    InkWell,
    GestureDetector,
  ];

  for (final type in interactiveTypes) {
    final finder = find.byType(type);

    for (final element in finder.evaluate()) {
      final renderBox = element.renderObject as RenderBox?;
      if (renderBox == null) continue;

      final size = renderBox.size;
      final widget = element.widget;

      expect(
        size.width >= minSize && size.height >= minSize,
        isTrue,
        reason: '${widget.runtimeType} is ${size.width}×${size.height}, '
            'should be at least ${minSize}×$minSize',
      );
    }
  }
}
```

---

## 7. Testing Text Scaling

### UI at Different Scale Factors

```dart
testWidgets('UI handles 2x text scale', (tester) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
      child: MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();

  // Check no overflow errors
  expect(tester.takeException(), isNull);

  // Verify content is still visible
  expect(find.text('Settings'), findsOneWidget);
});

testWidgets('UI handles 3x text scale (maximum)', (tester) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(3.0)),
      child: MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
});
```

### Text Scale Test Helper

```dart
/// Tests widget at various text scale factors.
Future<void> testTextScaling(
  WidgetTester tester,
  Widget widget, {
  List<double> scales = const [1.0, 1.5, 2.0],
}) async {
  for (final scale in scales) {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: MaterialApp(home: widget),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isNull,
      reason: 'Widget should not overflow at ${scale}x text scale',
    );
  }
}
```

---

## 8. Testing Color Contrast

### Using textContrastGuideline

```dart
testWidgets('text has sufficient contrast', (tester) async {
  await tester.pumpWidget(MaterialApp(home: MyScreen()));

  await expectLater(
    tester,
    meetsGuideline(textContrastGuideline),
    reason: 'All text must have ≥4.5:1 contrast ratio',
  );
});
```

### Testing Both Themes

```dart
void main() {
  group('contrast requirements', () {
    testWidgets('light theme meets contrast guidelines', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ProfileScreen(),
        ),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('dark theme meets contrast guidelines', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: ProfileScreen(),
        ),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
```

---

## 9. Manual Testing Checklist

Automated tests catch many issues, but manual testing with real screen readers is essential.

### VoiceOver (iOS)

1. **Enable**: Settings → Accessibility → VoiceOver → On
2. **Navigate**: Swipe right to move to next element
3. **Verify**:
   - [ ] All controls are announced
   - [ ] Labels are meaningful (not "Button" or "Image")
   - [ ] Order matches visual layout
   - [ ] Dynamic content is announced
   - [ ] Custom widgets are accessible

### TalkBack (Android)

1. **Enable**: Settings → Accessibility → TalkBack → On
2. **Navigate**: Swipe right to move to next element
3. **Verify**:
   - [ ] All controls are announced
   - [ ] Touch targets feel adequate
   - [ ] Gestures work correctly
   - [ ] Focus indicator is visible

### Screen Reader Testing Checklist

| Test | Expected Result |
|------|-----------------|
| Navigate through all elements | Each is announced clearly |
| Tap on images | Description is read |
| Tap on buttons | Label + "button" announced |
| Open form | Fields have labels |
| Submit form with error | Error is announced |
| Change toggle | New state is announced |
| Scroll content | New content is announced |
| Dismiss dialog | Focus returns appropriately |

---

## 10. Integration with CI

### Test Configuration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test test/accessibility/
```

### Accessibility Test File Structure

```
test/
├── accessibility/
│   ├── guidelines_test.dart      # All screens against guidelines
│   ├── semantics_test.dart       # Semantic label verification
│   ├── focus_order_test.dart     # Focus traversal
│   └── text_scaling_test.dart    # Large text support
├── helpers/
│   └── accessibility_helpers.dart
└── ...
```

### Comprehensive Test Template

```dart
// test/accessibility/guidelines_test.dart

import 'package:flutter_test/flutter_test.dart';

import '../../lib/features/auth/presentation/screens/login_screen.dart';
import '../../lib/features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../lib/features/settings/presentation/screens/settings_screen.dart';
import '../helpers/accessibility_helpers.dart';
import '../helpers/pump_app.dart';

void main() {
  group('Accessibility Guidelines', () {
    final screens = <String, Widget>{
      'LoginScreen': const LoginScreen(),
      'DashboardScreen': const DashboardScreen(),
      'SettingsScreen': const SettingsScreen(),
    };

    for (final entry in screens.entries) {
      group(entry.key, () {
        testWidgets('meets guidelines (light)', (tester) async {
          await pumpAndTestAccessibility(tester, entry.value);
        });

        testWidgets('meets guidelines (dark)', (tester) async {
          await pumpAndTestAccessibility(
            tester,
            entry.value,
            theme: AppTheme.dark,
          );
        });

        testWidgets('handles 2x text scale', (tester) async {
          await testTextScaling(tester, entry.value);
        });
      });
    }
  });
}
```

---

## 11. Debugging Accessibility Issues

### Visual Semantics Debugger

```dart
// Temporarily enable during development
MaterialApp(
  showSemanticsDebugger: true,  // Shows semantic tree overlay
  home: MyScreen(),
)
```

### Printing Semantic Tree

```dart
testWidgets('debug semantics', (tester) async {
  final handle = tester.ensureSemantics();

  await tester.pumpWidget(MaterialApp(home: MyScreen()));

  // Print full semantic tree
  debugDumpSemanticsTree();

  handle.dispose();
});
```

### Finding Missing Labels

```dart
testWidgets('find unlabeled interactive elements', (tester) async {
  final handle = tester.ensureSemantics();

  await tester.pumpWidget(MaterialApp(home: MyScreen()));

  // This will fail with details about unlabeled elements
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

  handle.dispose();
});
```

---

## Summary

| Test Type | Purpose | Frequency |
|-----------|---------|-----------|
| Guideline tests | Automated WCAG compliance | Every PR |
| Semantic tests | Verify labels and roles | Per widget |
| Focus tests | Navigation order | Per screen |
| Scale tests | Large text support | Per screen |
| Manual testing | Real screen reader UX | Before release |

### Minimum Test Coverage

For each screen:
1. ✅ Passes all four guideline tests
2. ✅ Works in light and dark themes
3. ✅ Handles 2x text scale
4. ✅ All interactive elements have labels
5. ✅ Manual VoiceOver/TalkBack verification

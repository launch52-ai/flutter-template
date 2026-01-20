# Platform Guide

iOS and Android specific conventions, gestures, and user expectations.

> **Template Default**: This project uses Cupertino-style page transitions on both platforms and disables ripple effects for a platform-neutral, iOS-like feel. Adjust if your app needs a more Material/Android-native experience.

---

## 1. Navigation Patterns

### Back Navigation

| Aspect | iOS | Android |
|--------|-----|---------|
| Primary gesture | Swipe from left edge | Swipe from either edge |
| Back button location | Top-left (in nav bar) | System (bottom bar or gesture) |
| Back arrow style | `<` chevron | `←` arrow |
| Swipe to dismiss | Common for modals | Less common |

### Critical: Don't Block iOS Swipe-Back

The iOS swipe-from-left-edge gesture is **sacred**. Users expect it everywhere.

```dart
// ❌ BAD: Left drawer conflicts with iOS back gesture
Scaffold(
  drawer: Drawer(child: ...),  // Blocks swipe-back!
)

// ✅ GOOD: Use end drawer or bottom sheet instead
Scaffold(
  endDrawer: Drawer(child: ...),  // Right side, no conflict
)

// ✅ GOOD: Use bottom sheet for navigation
showModalBottomSheet(
  context: context,
  builder: (_) => NavigationSheet(),
)

// ❌ BAD: PageView with swipe interferes
PageView(
  children: [...],  // Horizontal swipe = back gesture conflict
)

// ✅ GOOD: If PageView needed, handle carefully
PageView(
  // Consider using buttons instead of swipe
  physics: NeverScrollableScrollPhysics(),
)
```

### Testing Back Gesture

Always test that users can swipe back from your screens:

1. Navigate to the screen
2. Swipe from the left edge
3. Verify previous screen appears
4. Verify no interference from horizontal scroll/swipe elements

---

## 2. Navigation Bar / App Bar

### iOS Style

```dart
// iOS-style navigation bar
CupertinoNavigationBar(
  middle: Text('Title'),  // Centered
  leading: CupertinoNavigationBarBackButton(),  // < Back
  trailing: CupertinoButton(
    padding: EdgeInsets.zero,
    child: Text('Done'),
    onPressed: onDone,
  ),
)
```

### Android Style

```dart
// Material app bar
AppBar(
  title: Text('Title'),  // Left-aligned
  leading: BackButton(),  // ← arrow
  actions: [
    IconButton(
      icon: Icon(Icons.done),
      onPressed: onDone,
    ),
  ],
)
```

### Template Approach (Platform-Adaptive)

```dart
// Adaptive app bar
SliverAppBar(
  title: Text(title),
  centerTitle: Platform.isIOS,  // Centered on iOS, left on Android
  leading: Platform.isIOS
      ? CupertinoNavigationBarBackButton()
      : BackButton(),
)
```

---

## 3. Bottom Navigation vs Tab Bar

### iOS Tab Bar

- Always visible at bottom
- Usually 4-5 items
- Active item highlighted with filled icon + color
- Supports swipe between tabs? No (typically)

### Android Bottom Navigation

- Similar to iOS but with Material styling
- Often has FAB integrated
- May hide on scroll
- Ripple effect on tap

### Template Implementation

```dart
// Platform-neutral bottom navigation
NavigationBar(
  selectedIndex: currentIndex,
  onDestinationSelected: onSelect,
  destinations: [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: t.nav.home,
    ),
    NavigationDestination(
      icon: Icon(Icons.search),
      label: t.nav.search,
    ),
    // ...
  ],
)
```

---

## 4. Dialogs & Sheets

### Confirmation Dialogs

| Aspect | iOS | Android |
|--------|-----|---------|
| Style | Action sheet (from bottom) | Dialog (centered) |
| Destructive color | Red text | Red text or outlined |
| Cancel | Separate button at bottom | Right button |

```dart
// Platform-adaptive confirmation
Future<bool?> showConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool isDestructive = false,
}) {
  if (Platform.isIOS) {
    return showCupertinoModalPopup<bool>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(title),
        message: Text(message),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
      ),
    );
  } else {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: AppColors.error)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
```

### Modal Sheets

iOS users expect to swipe down to dismiss modal sheets:

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  enableDrag: true,  // Allow swipe to dismiss
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.9,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (context, scrollController) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [...],
            ),
          ),
        ],
      ),
    ),
  ),
);
```

---

## 5. Pull to Refresh

| Aspect | iOS | Android |
|--------|-----|---------|
| Indicator | Native spinner | Material circular indicator |
| Position | Above content, pulls down | Same |
| Haptic | On trigger | Optional |

```dart
// Platform-adaptive refresh
RefreshIndicator(
  onRefresh: onRefresh,
  // Use Cupertino style on iOS
  child: CustomScrollView(
    physics: BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    slivers: [...],
  ),
)

// Or use Cupertino directly on iOS
if (Platform.isIOS)
  CupertinoSliverRefreshControl(
    onRefresh: onRefresh,
  )
```

---

## 6. Text Selection & Input

### Context Menus

| Action | iOS | Android |
|--------|-----|---------|
| Copy | "Copy" in popup | "Copy" in popup |
| Paste | "Paste" in popup | "Paste" in popup |
| Select All | "Select All" | "Select all" |
| Look Up | "Look Up" | N/A (use browser) |
| Share | "Share..." | "Share" |

Flutter handles this automatically, but you can customize:

```dart
TextField(
  contextMenuBuilder: (context, editableTextState) {
    return AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    );
  },
)
```

### Keyboard Toolbar

iOS has a toolbar above keyboard with "Done" button and navigation arrows:

```dart
// On iOS, TextField automatically gets this
// For custom behavior:
TextField(
  textInputAction: TextInputAction.done,
  onEditingComplete: () {
    FocusScope.of(context).unfocus();
  },
)
```

---

## 7. Haptic Feedback

### iOS Haptic Engine

iOS has a sophisticated Taptic Engine. Use it appropriately:

| Feedback | When to Use |
|----------|-------------|
| `lightImpact` | Light UI touches |
| `mediumImpact` | Button taps, selections |
| `heavyImpact` | Significant actions |
| `selectionClick` | Picker/segment changes |
| `notificationSuccess` | Success confirmation |
| `notificationWarning` | Warning |
| `notificationError` | Error/failure |

### Android Haptics

Android haptics vary by device. Be conservative:

```dart
// Cross-platform haptic helper
void haptic(HapticType type) {
  switch (type) {
    case HapticType.light:
      HapticFeedback.lightImpact();
    case HapticType.medium:
      HapticFeedback.mediumImpact();
    case HapticType.heavy:
      HapticFeedback.heavyImpact();
    case HapticType.selection:
      HapticFeedback.selectionClick();
  }
}
```

---

## 8. Lists & Scrolling

### iOS Bounce

iOS lists have elastic bounce at edges:

```dart
ListView(
  physics: BouncingScrollPhysics(),  // iOS-style bounce
)
```

### Android Glow

Android shows glow/edge effect at scroll limits:

```dart
ListView(
  physics: ClampingScrollPhysics(),  // Android-style clamp with glow
)
```

### Template Default (iOS Everywhere)

```dart
// In app theme
MaterialApp(
  scrollBehavior: const MaterialScrollBehavior().copyWith(
    physics: const BouncingScrollPhysics(),
  ),
)
```

---

## 9. Date & Time Pickers

### iOS Pickers

- Spinning wheel style
- Often inline or in bottom sheet
- Very tactile feel

```dart
// iOS date picker
CupertinoDatePicker(
  mode: CupertinoDatePickerMode.date,
  onDateTimeChanged: (date) => setState(() => _date = date),
)
```

### Android Pickers

- Calendar/clock style
- Modal dialog
- More visual

```dart
// Android date picker
showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2000),
  lastDate: DateTime(2100),
);
```

### Platform-Adaptive

```dart
Future<DateTime?> pickDate(BuildContext context, DateTime initial) async {
  if (Platform.isIOS) {
    DateTime? selected;
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: initial,
          onDateTimeChanged: (date) => selected = date,
        ),
      ),
    );
    return selected;
  } else {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }
}
```

---

## 10. Switches & Toggles

| Aspect | iOS | Android |
|--------|-----|---------|
| Shape | Pill with circle thumb | Pill with circle thumb |
| Width | Wider | Narrower |
| Colors | Green when on | Primary when on |

```dart
// Platform-adaptive switch
Switch.adaptive(
  value: _enabled,
  onChanged: (value) {
    HapticFeedback.selectionClick();
    setState(() => _enabled = value);
  },
)

// Or use Cupertino directly for consistency
CupertinoSwitch(
  value: _enabled,
  onChanged: (value) {
    HapticFeedback.selectionClick();
    setState(() => _enabled = value);
  },
)
```

---

## 11. Buttons

### iOS Style

- Minimal styling, text-based
- Blue text default
- Full-width in forms often

### Android Style

- Various button types (text, outlined, filled, elevated)
- Ripple effect on tap
- FAB for primary actions

### Template Approach

Use opacity feedback instead of ripples for iOS-like feel:
- On tap down: reduce opacity to 0.7
- On tap up/cancel: restore to 1.0
- Animation duration: 100ms

> See [examples.md](examples.md) for complete `LoadingButton` implementation with press states and haptics.

---

## 12. Page Transitions

### iOS Transitions

- Slide from right (push)
- Slide to right (pop)
- Parallel movement of both pages
- Previous page slightly dims

### Android Transitions

- Various: fade, slide, scale
- Material 3 prefers "container transform"
- Previous page may stay static

### Template Default (iOS Everywhere)

```dart
// In app theme
MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  ),
)
```

---

## 13. Status Bar & Safe Areas

### iOS

- Notch/Dynamic Island requires safe area
- Status bar can be light or dark
- Home indicator at bottom needs padding

### Android

- Various notch shapes
- Navigation bar at bottom (3-button or gesture)
- System UI can be hidden

```dart
// Always use SafeArea for content
Scaffold(
  body: SafeArea(
    child: content,
  ),
)

// Control status bar style
SystemChrome.setSystemUIOverlayStyle(
  SystemUiOverlayStyle(
    statusBarBrightness: Brightness.light,  // iOS
    statusBarIconBrightness: Brightness.dark,  // Android
  ),
);
```

---

## Summary

| Feature | iOS Expectation | Android Expectation |
|---------|-----------------|---------------------|
| Back gesture | Swipe from left edge | System back |
| Scrolling | Bounce effect | Glow effect |
| Buttons | Opacity feedback | Ripple effect |
| Modals | Bottom sheet, swipe dismiss | Dialog, tap outside dismiss |
| Pickers | Spinning wheel | Calendar/clock |
| Navigation | Tab bar | Bottom nav + FAB |
| Haptics | Rich, expected | Basic, optional |

### Template Decisions

This template chooses iOS-like patterns as the default:
- Cupertino page transitions
- Bounce scroll physics
- Opacity button feedback (no ripples)
- Swipe-to-dismiss modals

If building an Android-first app, consider enabling:
- Material ripples
- Clamping scroll physics
- FAB for primary actions
- Material date/time pickers

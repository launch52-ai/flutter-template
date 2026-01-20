# Visual Guide

Colors, loading states, dark mode, elevation, icons, and visual hierarchy.

---

## 1. Color Design

### Light vs Dark Mode

Don't just invert colors. Dark mode requires intentional design:

| Aspect | Light Mode | Dark Mode |
|--------|------------|-----------|
| Background | White/Light gray | Dark gray (#121212), NOT pure black |
| Surface | White | Slightly lighter than background |
| Primary color | Full saturation | Desaturated (−20% saturation) |
| Text | Dark on light | Light on dark (not pure white) |
| Elevation | Shadows | Lighter surfaces |

### Why Not Pure Black (#000000)?

- **Eye strain**: High contrast between #000000 and white text
- **OLED smearing**: Pure black on OLED can cause smearing artifacts
- **No shadow depth**: Can't show elevation with shadows
- **Use instead**: #121212 or similar dark gray

### Desaturation for Dark Mode

Saturated colors that look great on white backgrounds can "vibrate" on dark backgrounds:

```dart
// ❌ Same color in both modes
static const Color primary = Color(0xFF2D9D78);

// ✅ Desaturated for dark mode
static const Color primaryLight = Color(0xFF2D9D78);  // Saturated
static const Color primaryDark = Color(0xFF4FBB9F);   // +20% lightness, -20% saturation
```

### Color Contrast Requirements

| Element | Minimum Ratio | Target Ratio |
|---------|---------------|--------------|
| Body text | 4.5:1 | 7:1 |
| Large text (18pt+) | 3:1 | 4.5:1 |
| UI components | 3:1 | 4.5:1 |
| Decorative | No requirement | - |

### Semantic Colors

Use consistent colors for meaning:

| Meaning | Color | Usage |
|---------|-------|-------|
| Success | Green | Confirmations, completed actions |
| Error | Red | Errors, destructive actions |
| Warning | Amber/Orange | Cautions, important notices |
| Info | Blue | Informational messages |
| Primary | Brand color | CTAs, links, active states |

```dart
final class AppColors {
  // Semantic - same meaning in both modes
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF2196F3);

  // Contextual - different per mode
  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFAF8F5)
          : const Color(0xFF1A1A1A);
}
```

### Never Rely on Color Alone

Always pair color with another indicator:

```dart
// ❌ BAD: Only color indicates error
TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey),
    ),
  ),
)

// ✅ GOOD: Color + icon + text
TextField(
  decoration: InputDecoration(
    errorText: hasError ? errorMessage : null,
    suffixIcon: hasError ? Icon(Icons.error, color: AppColors.error) : null,
  ),
)
```

---

## 2. Loading States

### Decision Matrix

| Scenario | Loading Pattern | Why |
|----------|-----------------|-----|
| Page load (structured content) | Skeleton | Shows layout, feels faster |
| Page load (dynamic content) | Centered spinner | Content structure unknown |
| Button action | Button loading state | Shows which action is processing |
| Background refresh | None or subtle | Don't interrupt user |
| Pull to refresh | Refresh indicator | Standard pattern |
| File upload/download | Progress bar | Shows actual progress |
| Form submission | Button disabled + loading | Prevents double submit |
| Search typing | Debounced, no indicator | Feels instant |

### Skeleton Screens

Use for **structured, predictable content**. Match skeleton layout to actual content structure.

> See [examples.md](examples.md) for complete `ShimmerBox`, `SkeletonAvatar`, `SkeletonText`, and `SkeletonListItem` implementations.

### Button Loading States

Disable button and show spinner during loading. Prevents double-submit.

> See [examples.md](examples.md) for complete `LoadingButton` implementation with press feedback and haptics.

### Progress Indicators

For operations where progress is known:

```dart
// Linear progress for file operations
Column(
  children: [
    LinearProgressIndicator(
      value: progress, // 0.0 to 1.0
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation(AppColors.primary),
    ),
    SizedBox(height: 8),
    Text('${(progress * 100).toInt()}%'),
  ],
)

// Stepped progress for multi-step flows
Row(
  children: List.generate(totalSteps, (index) {
    return Expanded(
      child: Container(
        height: 4,
        margin: EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: index < currentStep
              ? AppColors.primary
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }),
)
```

---

## 3. Elevation & Depth

### Light Mode: Shadows

```dart
// Elevation levels (Material 3 style)
final class AppElevation {
  static List<BoxShadow> get level1 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get level2 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get level3 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
```

### Dark Mode: Surface Lightening

In dark mode, elevated surfaces are **lighter**, not shadowed:

```dart
// Elevation overlay colors (Material 3 dark theme)
final class DarkElevation {
  static Color surface(int elevation) {
    // Higher elevation = lighter surface
    const overlays = [
      0.00,  // 0dp
      0.05,  // 1dp
      0.07,  // 2dp
      0.08,  // 3dp
      0.09,  // 4dp
      0.11,  // 6dp
      0.12,  // 8dp
      0.14,  // 12dp
      0.15,  // 16dp
      0.16,  // 24dp
    ];

    final overlay = elevation < overlays.length
        ? overlays[elevation]
        : overlays.last;

    return Color.lerp(
      Color(0xFF121212), // Base dark
      Colors.white,
      overlay,
    )!;
  }
}

// Usage
Container(
  decoration: BoxDecoration(
    color: isDark
        ? DarkElevation.surface(2)
        : Colors.white,
    boxShadow: isDark ? null : AppElevation.level2,
  ),
)
```

---

## 4. Visual Hierarchy

### Size & Weight

| Element | Size | Weight |
|---------|------|--------|
| Page title | 24-32sp | Bold (700) |
| Section header | 18-20sp | SemiBold (600) |
| Body text | 14-16sp | Regular (400) |
| Caption | 12sp | Regular (400) |
| Button label | 14-16sp | Medium (500) |

### Spacing Scale

Use consistent spacing (8dp base):

```dart
final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
```

### Visual Weight

Guide the eye to important elements:

| Technique | Effect | Use For |
|-----------|--------|---------|
| Size | Larger = more important | Titles, CTAs |
| Color | Saturated = attention | CTAs, active states |
| Contrast | High = prominent | Primary actions |
| Weight | Bold = emphasis | Headlines, prices |
| Whitespace | Isolated = important | Hero elements |

---

## 5. Icons

### Consistency

- Use icons from one family (Material, Cupertino, or custom)
- Don't mix filled and outlined styles randomly
- Maintain consistent sizes

### When to Use Icons

| Scenario | Icon | Label | Both |
|----------|------|-------|------|
| Navigation bar | ✅ | ✅ | Best |
| Toolbar actions | ✅ | - | OK if clear |
| Primary CTA | - | ✅ | Better |
| List item action | ✅ | - | OK |
| Settings row | ✅ | ✅ | Best |
| Tab bar | ✅ | ✅ | Best |

### Icon Sizing

| Context | Icon Size | Touch Target |
|---------|-----------|--------------|
| Navigation bar | 24dp | 48dp |
| Toolbar | 24dp | 48dp |
| List leading | 24dp | - |
| List trailing | 20-24dp | 48dp if tappable |
| Inline with text | Match text size | - |

### Icon + Label Pairing

```dart
// ❌ BAD: Icon without clear meaning
IconButton(
  icon: Icon(Icons.more_horiz),
  onPressed: onMore,
)

// ✅ GOOD: Icon with tooltip
IconButton(
  icon: Icon(Icons.more_horiz),
  tooltip: t.common.moreOptions,
  onPressed: onMore,
)

// ✅ BETTER: Icon with visible label
TextButton.icon(
  icon: Icon(Icons.share),
  label: Text(t.common.share),
  onPressed: onShare,
)
```

---

## 6. Empty States

### Structure

Every empty state should have:
1. **Illustration or icon** (optional but recommended)
2. **Title** - What's empty
3. **Description** - Why/what goes here
4. **Action** - How to add content

```dart
final class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Usage
EmptyState(
  icon: Icons.photo_library_outlined,
  title: t.photos.empty.title,
  description: t.photos.empty.description,
  actionLabel: t.photos.empty.action,
  onAction: () => _pickPhoto(),
)
```

### Empty State Variants

| Type | Title Example | Action |
|------|---------------|--------|
| First-time | "No photos yet" | "Add your first photo" |
| Search empty | "No results for 'xyz'" | "Clear search" |
| Filter empty | "No completed tasks" | "View all tasks" |
| Error state | "Couldn't load photos" | "Try again" |
| Offline | "You're offline" | "Check connection" |

---

## 7. Error States

### Visual Error Indicators

```dart
// Field with error
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: hasError ? AppColors.error : Colors.grey[300]!,
      width: hasError ? 2 : 1,
    ),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Expanded(child: textField),
      if (hasError)
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.error_outline, color: AppColors.error),
        ),
    ],
  ),
)
```

### Error Banners

```dart
final class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      color: AppColors.error.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.error),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(t.common.buttons.retry),
            ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
```

---

## 8. Success & Confirmation

### Inline Success

For quick actions, show inline feedback:

```dart
// Animated checkmark
AnimatedSwitcher(
  duration: Duration(milliseconds: 200),
  child: isSuccess
      ? Icon(Icons.check_circle, color: AppColors.success, key: Key('success'))
      : Icon(Icons.bookmark_border, key: Key('normal')),
)
```

### Success Screens

For significant completions:

```dart
final class SuccessScreen extends StatelessWidget {
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: AppColors.success,
              ),
              SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  child: Text(buttonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Summary

| Aspect | Light Mode | Dark Mode |
|--------|------------|-----------|
| Background | White/light | Dark gray (#121212) |
| Surfaces | White + shadows | Lighter grays |
| Primary color | Full saturation | Desaturated |
| Text | Dark (#1A1A1A) | Light (#FAF8F5) |
| Elevation | Shadows | Surface lightening |

| Loading Pattern | When to Use |
|-----------------|-------------|
| Skeleton | Structured content, >1.5s load |
| Spinner | Unknown content, short operations |
| Button loader | Inline actions |
| Progress bar | File operations, known duration |
| None | <300ms operations |

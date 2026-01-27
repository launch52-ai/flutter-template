# Semantics Guide

Comprehensive patterns for making Flutter widgets accessible to screen readers and assistive technologies.

---

## 1. The Semantics Widget

The `Semantics` widget provides metadata about UI elements to the accessibility framework.

### Basic Structure

```dart
Semantics(
  // Identity
  label: 'What this element is',
  value: 'Current state or value',
  hint: 'What happens when activated',

  // Role flags
  button: true,        // This is a button
  slider: true,        // This is a slider
  header: true,        // This is a heading
  link: true,          // This is a link
  image: true,         // This is an image
  textField: true,     // This is a text input

  // State flags
  enabled: true,       // Can be interacted with
  selected: true,      // Is currently selected
  checked: true,       // Checkbox/toggle is checked
  toggled: true,       // Toggle switch is on
  focused: true,       // Has keyboard focus
  hidden: false,       // Should be hidden from a11y

  // Behavior
  liveRegion: true,    // Announce changes automatically
  excludeSemantics: false,  // Hide children from a11y

  child: YourWidget(),
)
```

### Semantic Roles (Flutter 3.32+)

```dart
Semantics(
  role: SemanticsRole.alert,      // Important notification
  role: SemanticsRole.status,     // Status indicator
  role: SemanticsRole.list,       // List container
  role: SemanticsRole.listItem,   // Item in a list
  role: SemanticsRole.tab,        // Tab in tab bar
  role: SemanticsRole.tabPanel,   // Content for a tab
  child: YourWidget(),
)
```

---

## 2. Labels, Values, and Hints

### Label (What it is)

The primary description read by screen readers.

```dart
// ❌ BAD: Vague or missing
Semantics(
  label: 'Button',
  child: deleteButton,
)

// ✅ GOOD: Specific and contextual
Semantics(
  label: 'Delete photo',
  child: deleteButton,
)
```

### Value (Current state)

Dynamic content that changes.

```dart
// Volume slider
Semantics(
  label: 'Volume',
  value: '${(volume * 100).round()} percent',
  child: Slider(value: volume, onChanged: setVolume),
)

// Score display
Semantics(
  label: 'Current score',
  value: '$score points',
  child: ScoreWidget(score: score),
)
```

### Hint (What happens on activation)

Describes the action, not how to perform it.

```dart
// ❌ BAD: Describes gesture
Semantics(
  label: 'Settings',
  hint: 'Double tap to open',  // Screen reader adds this automatically
  child: settingsIcon,
)

// ✅ GOOD: Describes outcome
Semantics(
  label: 'Settings',
  hint: 'Opens app settings',
  child: settingsIcon,
)
```

---

## 3. Label Patterns by Widget Type

### Images

```dart
// Meaningful images
Image.asset(
  'assets/sunset.jpg',
  semanticLabel: 'Orange sunset over the ocean',
)

// Decorative images (no semantic meaning)
Semantics(
  excludeSemantics: true,
  child: Image.asset('assets/decorative_border.png'),
)

// User photos
Image.network(
  user.avatarUrl,
  semanticLabel: 'Profile photo of ${user.displayName}',
)
```

### Icon Buttons

```dart
// Always use tooltip - it provides the semantic label
IconButton(
  icon: Icon(Icons.delete),
  tooltip: 'Delete item',  // Required for accessibility
  onPressed: onDelete,
)

// With conditional state
IconButton(
  icon: Icon(isFavorite ? Icons.star : Icons.star_border),
  tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
  onPressed: toggleFavorite,
)
```

### Buttons with Icons

```dart
// Icon + text - merge for single announcement
MergeSemantics(
  child: ElevatedButton.icon(
    icon: Icon(Icons.send),
    label: Text('Send message'),
    onPressed: send,
  ),
)
```

### Text Fields

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Email',  // Primary label
    hintText: 'name@example.com',  // Format hint
    errorText: hasError ? 'Enter a valid email' : null,
  ),
)

// For custom text inputs
Semantics(
  label: 'Email',
  textField: true,
  enabled: isEnabled,
  child: CustomTextField(),
)
```

### Toggles and Checkboxes

```dart
// Label describes what the toggle controls
Semantics(
  label: 'Dark mode',
  toggled: isDarkMode,
  child: Switch(
    value: isDarkMode,
    onChanged: setDarkMode,
  ),
)

// Checkbox with associated text
MergeSemantics(
  child: Row(
    children: [
      Checkbox(value: agreed, onChanged: setAgreed),
      Text('I agree to the terms'),
    ],
  ),
)
```

### Progress Indicators

```dart
// Determinate progress
Semantics(
  label: 'Upload progress',
  value: '${(progress * 100).round()} percent complete',
  child: LinearProgressIndicator(value: progress),
)

// Indeterminate progress
Semantics(
  label: 'Loading',
  child: CircularProgressIndicator(),
)
```

### Cards and List Items

```dart
// Card with multiple pieces of info
Semantics(
  label: '${item.title}, ${item.subtitle}',
  hint: 'Opens details',
  button: true,
  child: Card(
    child: ListTile(
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      onTap: () => openDetails(item),
    ),
  ),
)
```

---

## 4. Semantic Grouping

### MergeSemantics

Combines multiple widgets into a single announcement.

```dart
// ❌ BAD: Announced separately
Row(
  children: [
    Icon(Icons.star, color: Colors.yellow),
    Text('4.5'),
    Text('(123 reviews)'),
  ],
)
// Screen reader: "Star" ... "4.5" ... "(123 reviews)"

// ✅ GOOD: Single meaningful announcement
MergeSemantics(
  child: Row(
    children: [
      ExcludeSemantics(child: Icon(Icons.star, color: Colors.yellow)),
      Text('4.5'),
      Text('(123 reviews)'),
    ],
  ),
)
// Screen reader: "4.5 (123 reviews)"
```

### ExcludeSemantics

Hides decorative or redundant elements.

```dart
// Decorative dividers
ExcludeSemantics(
  child: Divider(),
)

// Redundant icon when text is present
Row(
  children: [
    ExcludeSemantics(child: Icon(Icons.email)),
    Text('Contact us by email'),
  ],
)

// Background decorations
ExcludeSemantics(
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(/* ... */),
    ),
  ),
)
```

### BlockSemantics

Prevents children from receiving accessibility focus.

```dart
// Modal overlay - block background
Stack(
  children: [
    BlockSemantics(child: ScreenContent()),  // Can't focus when modal open
    ModalDialog(),  // Only this is focusable
  ],
)
```

---

## 5. Dynamic Content

### Live Regions

Automatically announce content changes without user navigation.

```dart
// Status messages
Semantics(
  liveRegion: true,
  child: Text(statusMessage),
)

// When statusMessage changes from "Saving..." to "Saved!"
// Screen reader automatically announces "Saved!"

// Polite vs assertive (handled by context)
// For critical alerts, also use role:
Semantics(
  liveRegion: true,
  role: SemanticsRole.alert,
  child: Text(errorMessage),
)
```

### When to Use Live Regions

| Scenario | Use Live Region |
|----------|-----------------|
| Toast/Snackbar messages | ✅ Yes |
| Form validation errors | ✅ Yes |
| Loading status changes | ✅ Yes |
| Real-time data updates | ✅ Yes (sparingly) |
| Navigation changes | ❌ No (focus handles this) |
| Typing feedback | ❌ No (too frequent) |

---

## 6. Focus Management

### Focus Order

By default, focus follows the widget tree order. Override when needed:

```dart
// Custom focus order
FocusTraversalGroup(
  child: Column(
    children: [
      // Focus order: email (1) → password (2) → submit (3) → forgot (4)
      FocusTraversalOrder(
        order: NumericFocusOrder(1),
        child: TextField(decoration: InputDecoration(labelText: 'Email')),
      ),
      FocusTraversalOrder(
        order: NumericFocusOrder(2),
        child: TextField(decoration: InputDecoration(labelText: 'Password')),
      ),
      Row(
        children: [
          FocusTraversalOrder(
            order: NumericFocusOrder(4),  // After submit
            child: TextButton(child: Text('Forgot password?')),
          ),
          FocusTraversalOrder(
            order: NumericFocusOrder(3),  // Before forgot
            child: ElevatedButton(child: Text('Sign in')),
          ),
        ],
      ),
    ],
  ),
)
```

### Semantic Sort Keys

For complex layouts where focus order should differ from widget tree:

```dart
Semantics(
  sortKey: OrdinalSortKey(1.0),  // Read first
  child: Widget1(),
)

Semantics(
  sortKey: OrdinalSortKey(2.0),  // Read second
  child: Widget2(),
)
```

### Moving Focus Programmatically

```dart
// After form submission error
void _handleError(String field) {
  if (field == 'email') {
    _emailFocusNode.requestFocus();
  }
  // Announce the error
  SemanticsService.announce(
    'Error: Invalid email. Please correct and try again.',
    TextDirection.ltr,
  );
}
```

---

## 7. Custom Widgets

### Making Custom Widgets Accessible

```dart
final class CustomRating extends StatelessWidget {
  final double rating;
  final int maxRating;

  const CustomRating({
    required this.rating,
    this.maxRating = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rating',
      value: '${rating.toStringAsFixed(1)} out of $maxRating stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxRating, (index) {
          return ExcludeSemantics(
            child: Icon(
              index < rating.floor()
                  ? Icons.star
                  : index < rating
                      ? Icons.star_half
                      : Icons.star_border,
              color: Colors.amber,
            ),
          );
        }),
      ),
    );
  }
}
```

### Custom Buttons

```dart
final class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: label,
      hint: isLoading ? 'Loading, please wait' : null,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: Container(
          padding: EdgeInsets.all(16),  // 48dp touch target
          child: isLoading
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
              : Text(label),
        ),
      ),
    );
  }
}
```

### Custom Sliders

```dart
final class CustomSlider extends StatelessWidget {
  final double value;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: label,
      value: '${(value * 100).round()} percent',
      increasedValue: '${((value + 0.1).clamp(0, 1) * 100).round()} percent',
      decreasedValue: '${((value - 0.1).clamp(0, 1) * 100).round()} percent',
      onIncrease: () => onChanged((value + 0.1).clamp(0, 1)),
      onDecrease: () => onChanged((value - 0.1).clamp(0, 1)),
      child: CustomSliderTrack(value: value, onChanged: onChanged),
    );
  }
}
```

---

## 8. Text Scaling

Support users who increase system font size.

### Scaling Sizes

```dart
@override
Widget build(BuildContext context) {
  final textScaler = MediaQuery.textScalerOf(context);

  return Padding(
    // Scale padding with text
    padding: EdgeInsets.all(textScaler.scale(16)),
    child: Row(
      children: [
        // Scale icon with text
        Icon(Icons.info, size: textScaler.scale(24)),
        SizedBox(width: textScaler.scale(8)),
        Expanded(child: Text('Scalable content')),
      ],
    ),
  );
}
```

### Use Text.rich Over RichText

```dart
// ❌ BAD: RichText doesn't scale automatically
RichText(
  text: TextSpan(
    text: 'Hello ',
    children: [TextSpan(text: 'World', style: TextStyle(fontWeight: FontWeight.bold))],
  ),
)

// ✅ GOOD: Text.rich respects text scaling
Text.rich(
  TextSpan(
    text: 'Hello ',
    children: [TextSpan(text: 'World', style: TextStyle(fontWeight: FontWeight.bold))],
  ),
)
```

### Testing at Scale

```dart
testWidgets('UI handles large text scale', (tester) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
      child: MaterialApp(home: MyScreen()),
    ),
  );

  // Verify no overflow
  expect(tester.takeException(), isNull);
});
```

---

## 9. Localization

Semantic labels must be localized.

```dart
// In i18n file
# lib/features/photos/i18n/photos.i18n.yaml
accessibility:
  deletePhoto: Delete photo
  photoBy: Photo by $name
  rating: Rating, $value out of $max stars

# Usage
Semantics(
  label: t.photos.accessibility.deletePhoto,
  button: true,
  child: deleteIcon,
)

Image.network(
  photo.url,
  semanticLabel: t.photos.accessibility.photoBy(name: photo.author),
)
```

---

## 10. Platform Considerations

### iOS vs Android

| Feature | iOS (VoiceOver) | Android (TalkBack) |
|---------|-----------------|-------------------|
| Minimum touch target | 44×44pt | 48×48dp |
| Swipe navigation | Natural | Natural |
| Rotor | Yes | No (uses settings) |
| Screen curtain | Yes | Yes |

### Web Accessibility

```dart
// Enable accessibility on web
void main() {
  // Auto-enable without user button press
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
  runApp(MyApp());
}
```

### Debugging

```dart
// Visual semantics overlay
MaterialApp(
  showSemanticsDebugger: true,  // Shows all semantic nodes
  home: MyApp(),
)
```

---

## Summary

| Element | Required Semantics |
|---------|-------------------|
| **Images** | `semanticLabel` describing content |
| **Icon buttons** | `tooltip` property |
| **Custom widgets** | `Semantics` wrapper with label |
| **Dynamic content** | `liveRegion: true` |
| **Decorative elements** | `ExcludeSemantics` |
| **Related content** | `MergeSemantics` |
| **Custom controls** | Role flags + label + value |
| **Sizing** | Use `textScalerOf` for scalability |

### Label Writing Tips

1. **Be specific**: "Delete photo" not "Delete"
2. **Include state**: "Volume, 75 percent"
3. **Skip redundancy**: Don't say "button" if `button: true`
4. **Use active voice**: "Opens settings" not "Settings will be opened"
5. **Localize everything**: Use i18n, not hardcoded strings

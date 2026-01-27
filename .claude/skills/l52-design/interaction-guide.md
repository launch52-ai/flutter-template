# Interaction Guide

Detailed patterns for touch, focus, gestures, keyboard handling, and user feedback.

---

## 1. Thumb Zone Design

Research shows ~75% of users interact with phones using one thumb. Design for this reality.

### The Thumb Zone Map

```
┌─────────────────────────────────┐
│                                 │
│    ❌ HARD        ❌ HARD       │  Top corners: Nearly impossible
│                                 │  one-handed. Never put primary
│    ⚠️  STRETCH ZONE  ⚠️        │  actions here.
│                                 │
├─────────────────────────────────┤
│                                 │
│    ⚠️  STRETCH     ✅ OK       │  Middle: Reachable but not
│                                 │  comfortable for repeated
│    ✅ OK           ✅ EASY      │  interaction.
│                                 │
├─────────────────────────────────┤
│                                 │
│    ✅ EASY        ✅ EASIEST    │  Bottom third: Natural thumb
│                                 │  rest position. Put primary
│    ✅ EASIEST     ✅ EASY       │  actions here.
│                                 │
└─────────────────────────────────┘
```

### Placement Guidelines

| Element | Recommended Position | Why |
|---------|---------------------|-----|
| Primary CTA | Bottom center/right | Easiest thumb reach |
| Secondary actions | Middle of screen | Reachable, less prominent |
| Navigation | Bottom bar | Always accessible |
| Destructive actions | Require stretch | Prevents accidental taps |
| Cancel/Close | Top corners OK | Less frequent, intentional |
| Search | Top center OK | One-time tap, then keyboard |

### Right vs Left Handed

Most users are right-handed, so the bottom-right is typically easiest. However:

- **Don't assume**: Some users hold phone in left hand
- **Center is safest**: Works for both hands
- **Consider offering**: UI flip option in settings for left-handed users

---

## 2. Touch Targets

### Minimum Sizes

| Platform | Minimum | Recommended |
|----------|---------|-------------|
| iOS (Apple HIG) | 44×44pt | 44×44pt |
| Android (Material) | 48×48dp | 48×48dp |
| **Use for Flutter** | **48×48dp** | **48-56dp** |

### Common Mistakes

```dart
// ❌ BAD: Icon too small, no padding
IconButton(
  icon: Icon(Icons.close, size: 16),
  onPressed: onClose,
)

// ✅ GOOD: Proper touch target
IconButton(
  icon: Icon(Icons.close, size: 24),
  iconSize: 24,
  padding: EdgeInsets.all(12), // Total: 48dp
  onPressed: onClose,
)
```

### Spacing Between Targets

- **Minimum**: 8dp between interactive elements
- **Recommended**: 12-16dp for comfortable separation
- **Why**: Prevents accidental taps on adjacent elements

```dart
// ❌ BAD: Buttons too close
Row(
  children: [
    IconButton(icon: Icon(Icons.edit)),
    IconButton(icon: Icon(Icons.delete)), // Too close!
  ],
)

// ✅ GOOD: Proper spacing
Row(
  children: [
    IconButton(icon: Icon(Icons.edit)),
    SizedBox(width: 8), // Minimum spacing
    IconButton(icon: Icon(Icons.delete)),
  ],
)
```

### Invisible Touch Areas

Make touch targets larger than visual elements:

```dart
// Small visual element, large touch area
GestureDetector(
  behavior: HitTestBehavior.opaque, // Catches taps on padding too
  onTap: onTap,
  child: Padding(
    padding: EdgeInsets.all(12), // Expands touch area
    child: Icon(Icons.info, size: 24),
  ),
)
```

---

## 3. Auto-Focus Strategy

### When to Auto-Focus

| Screen Type | Auto-Focus | Reasoning |
|-------------|------------|-----------|
| Login/Sign up | ✅ First field | Clear user intent |
| Search screen | ✅ Search field | Single purpose |
| Single-input modal | ✅ The input | Modal = intent to input |
| Comment/Reply | ✅ Text field | User tapped to reply |
| Settings | ❌ | User is browsing |
| Profile view | ❌ | User is viewing |
| Dashboard | ❌ | Multiple possible actions |
| Form after error | ✅ First error field | Guide to fix |

### Implementation

```dart
final class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

final class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _emailFocus,
      autofocus: true, // Alternative: simpler but less control
      // ...
    );
  }
}
```

### Focus After Error

```dart
void _handleSubmit() async {
  final result = await ref.read(formProvider.notifier).submit();

  result.when(
    success: (_) => context.go('/dashboard'),
    error: (field, message) {
      // Focus the field with error
      switch (field) {
        case 'email':
          _emailFocus.requestFocus();
        case 'password':
          _passwordFocus.requestFocus();
      }
    },
  );
}
```

---

## 4. Keyboard Handling

### Keyboard Types

| Input Type | Keyboard | Flutter Property |
|------------|----------|------------------|
| Email | @ and .com keys | `TextInputType.emailAddress` |
| Phone | Number pad | `TextInputType.phone` |
| Number | Number pad | `TextInputType.number` |
| Decimal | Number + decimal | `TextInputType.numberWithOptions(decimal: true)` |
| URL | / and .com keys | `TextInputType.url` |
| Password | Standard + secure | `obscureText: true` |
| Multiline | Standard + return | `TextInputType.multiline` |

### Text Input Actions

| Action | When to Use | Flutter Property |
|--------|-------------|------------------|
| `next` | More fields follow | `TextInputAction.next` |
| `done` | Last field, submits | `TextInputAction.done` |
| `search` | Search field | `TextInputAction.search` |
| `send` | Chat/message | `TextInputAction.send` |
| `go` | URL field | `TextInputAction.go` |

### Complete Form Example

```dart
Column(
  children: [
    TextField(
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      onSubmitted: (_) => _passwordFocus.requestFocus(),
      decoration: InputDecoration(
        labelText: t.auth.email,
        hintText: 'name@example.com',
      ),
    ),
    SizedBox(height: 16),
    TextField(
      focusNode: _passwordFocus,
      obscureText: true,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      onSubmitted: (_) => _handleSubmit(),
      decoration: InputDecoration(
        labelText: t.auth.password,
      ),
    ),
  ],
)
```

### Keyboard Dismiss

```dart
// Tap outside to dismiss
GestureDetector(
  onTap: () => FocusScope.of(context).unfocus(),
  child: Scaffold(
    // ...
  ),
)

// Or use behavior on Scaffold
Scaffold(
  body: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child: // ...
  ),
)
```

### Keyboard Aware Scrolling

```dart
// Ensure focused field is visible above keyboard
SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  child: Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: // form content
  ),
)
```

---

## 5. Gesture Patterns

### Standard Gestures

| Gesture | Common Use | Consideration |
|---------|------------|---------------|
| Tap | Primary action | Must have feedback |
| Double tap | Zoom/like | Not for primary actions |
| Long press | Context menu | Show hint on first use |
| Swipe horizontal | Delete/archive | Always show undo |
| Swipe vertical | Dismiss/navigate | Don't block system gestures |
| Pull down | Refresh | Show clear indicator |
| Pinch | Zoom | Natural for images/maps |
| Drag | Reorder/move | Show handle affordance |

### Swipe Actions

```dart
Dismissible(
  key: Key(item.id),
  direction: DismissDirection.endToStart,
  background: Container(
    alignment: Alignment.centerRight,
    padding: EdgeInsets.only(right: 16),
    color: AppColors.error,
    child: Icon(Icons.delete, color: Colors.white),
  ),
  confirmDismiss: (direction) async {
    // For destructive actions, confirm first
    return await showConfirmDialog(
      context,
      title: t.common.dialogs.deleteItem.title,
      message: t.common.dialogs.deleteItem.message,
    );
  },
  onDismissed: (direction) {
    ref.read(itemsProvider.notifier).delete(item.id);
    // Show undo option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.common.itemDeleted),
        action: SnackBarAction(
          label: t.common.buttons.undo,
          onPressed: () => ref.read(itemsProvider.notifier).restore(item),
        ),
      ),
    );
  },
  child: ListTile(/* ... */),
)
```

### Pull to Refresh

```dart
RefreshIndicator(
  onRefresh: () async {
    await ref.read(itemsProvider.notifier).refresh();
  },
  child: ListView.builder(
    physics: AlwaysScrollableScrollPhysics(), // Enable even when content fits
    // ...
  ),
)
```

### Edge Swipe (iOS Back)

**Critical**: Never block the iOS swipe-from-left-edge gesture.

```dart
// ❌ BAD: Drawer on left edge blocks iOS back gesture
Scaffold(
  drawer: Drawer(/* ... */), // Conflicts with iOS back!
)

// ✅ GOOD: Use bottom sheet or right-side drawer
Scaffold(
  endDrawer: Drawer(/* ... */), // Right side, no conflict
)

// Or use a different pattern entirely
showModalBottomSheet(/* ... */);
```

---

## 6. Visual Feedback

### Press States

Every tappable element needs visual feedback:

| State | Visual Change | Duration |
|-------|---------------|----------|
| Default | Normal appearance | - |
| Pressed | Opacity 0.7 or scale 0.95 | Immediate |
| Focused | Border or highlight | While focused |
| Disabled | Opacity 0.4 | - |

```dart
// Custom button with press feedback
final class PressableCard extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        child: child,
      ),
    );
  }
}

// Using InkWell for Material ripple (Android-style)
InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(12),
  child: child,
)

// Using custom opacity feedback (iOS-style, template default)
GestureDetector(
  onTapDown: (_) => setState(() => _pressed = true),
  onTapUp: (_) => setState(() => _pressed = false),
  onTapCancel: () => setState(() => _pressed = false),
  onTap: onTap,
  child: AnimatedOpacity(
    opacity: _pressed ? 0.7 : 1.0,
    duration: Duration(milliseconds: 100),
    child: child,
  ),
)
```

### Haptic Feedback

Use haptics to confirm actions:

| Action | Haptic Type | Flutter Method |
|--------|-------------|----------------|
| Button tap | Light | `HapticFeedback.lightImpact()` |
| Toggle switch | Medium | `HapticFeedback.mediumImpact()` |
| Destructive action | Heavy | `HapticFeedback.heavyImpact()` |
| Success | Success pattern | `HapticFeedback.mediumImpact()` |
| Error | Error pattern | `HapticFeedback.heavyImpact()` |
| Selection change | Selection | `HapticFeedback.selectionClick()` |

```dart
void _onToggle(bool value) {
  HapticFeedback.selectionClick();
  setState(() => _enabled = value);
}

void _onDelete() {
  HapticFeedback.heavyImpact();
  // ... delete logic
}
```

### Animation Feedback

| Action | Animation | Duration |
|--------|-----------|----------|
| Item added | Fade in + slide | 200-300ms |
| Item removed | Fade out + slide | 200ms |
| Success | Checkmark appear | 300ms |
| Error shake | Horizontal shake | 300ms |
| Loading complete | Progress → checkmark | 200ms |

```dart
// Error shake animation
final class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

final class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_controller);
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value * sin(_controller.value * pi * 4), 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
```

---

## 7. Form Validation

### When to Validate

| Validation Timing | Use Case | Implementation |
|-------------------|----------|----------------|
| On submit | Default, least intrusive | Validate all on button press |
| On blur | Important fields | `onEditingComplete` |
| On change | Format-specific (phone, card) | `onChanged` with debounce |
| Real-time | Character counts | `onChanged` |

### Validation Patterns

```dart
// On blur validation (when user leaves field)
TextField(
  onEditingComplete: () {
    _validateEmail();
    _passwordFocus.requestFocus();
  },
)

// On submit validation
void _handleSubmit() {
  // Clear previous errors
  setState(() => _errors = {});

  // Validate all fields
  final errors = <String, String>{};

  if (_email.isEmpty) {
    errors['email'] = t.validation.required(field: t.auth.email);
  } else if (!_email.contains('@')) {
    errors['email'] = t.validation.invalidEmail;
  }

  if (_password.length < 8) {
    errors['password'] = t.validation.passwordTooShort;
  }

  if (errors.isNotEmpty) {
    setState(() => _errors = errors);
    // Focus first error field
    if (errors.containsKey('email')) {
      _emailFocus.requestFocus();
    } else {
      _passwordFocus.requestFocus();
    }
    return;
  }

  // Proceed with submission
  _submit();
}
```

### Error Display

```dart
// Inline error below field
TextField(
  decoration: InputDecoration(
    labelText: t.auth.email,
    errorText: _errors['email'],
    errorMaxLines: 2,
  ),
)

// Custom error widget
if (_errors['email'] != null)
  Padding(
    padding: EdgeInsets.only(top: 4, left: 12),
    child: Text(
      _errors['email']!,
      style: TextStyle(
        color: AppColors.error,
        fontSize: 12,
      ),
    ),
  ),
```

---

## 8. Input Sanitization & Forgiveness

Users make small mistakes constantly. A forgiving app handles these silently.

### Always Trim Whitespace

Accidental spaces are the #1 cause of "invalid email" errors:

```dart
// ❌ BAD: Validate raw input
if (!_emailController.text.contains('@')) {
  // Fails if user typed " email@example.com" (leading space)
}

// ✅ GOOD: Always trim before validation AND submission
final email = _emailController.text.trim();
if (!email.contains('@')) {
  // Now works correctly
}

// Even better: Trim when submitting to API
await api.login(
  email: _emailController.text.trim(),
  password: _passwordController.text, // Don't trim passwords!
);
```

### What to Trim/Sanitize

| Field Type | Sanitization | Example |
|------------|--------------|---------|
| Email | Trim + lowercase | `" User@Email.COM " → "user@email.com"` |
| Username | Trim + lowercase | `" MyUser " → "myuser"` |
| Name | Trim (keep case) | `" John Doe " → "John Doe"` |
| Phone | Trim + strip formatting | `"+1 (555) 123-4567" → "+15551234567"` |
| Search | Trim | `" search term " → "search term"` |
| Password | **Never modify** | Keep exactly as entered |
| Code/OTP | Trim + uppercase | `" abc123 " → "ABC123"` |

### Implementation Pattern

```dart
// Sanitization helpers
extension StringSanitization on String {
  String get trimmedEmail => trim().toLowerCase();
  String get trimmedUsername => trim().toLowerCase();
  String get trimmedName => trim();
  String get trimmedPhone => trim().replaceAll(RegExp(r'[^\d+]'), '');
  String get trimmedCode => trim().toUpperCase();
}

// Usage in form submission
void _handleSubmit() {
  final email = _emailController.text.trimmedEmail;
  final name = _nameController.text.trimmedName;
  final phone = _phoneController.text.trimmedPhone;

  // Validate the sanitized values
  if (!_isValidEmail(email)) {
    // Show error
  }

  // Submit sanitized values
  await api.createUser(email: email, name: name, phone: phone);
}
```

### Visual Feedback for Auto-Correction

For fields where you visibly change the input (like formatting phone numbers), update the controller:

```dart
// Auto-format phone number as user types
TextField(
  controller: _phoneController,
  keyboardType: TextInputType.phone,
  onChanged: (value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    final formatted = _formatPhoneNumber(digits);
    if (formatted != value) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  },
)

String _formatPhoneNumber(String digits) {
  if (digits.length <= 3) return digits;
  if (digits.length <= 6) return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
  return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, min(10, digits.length))}';
}
```

### Don't Trim Passwords

Passwords are the exception - spaces might be intentional:

```dart
// ✅ Password: use exactly as entered
final password = _passwordController.text; // No trim!

// User might have spaces as part of passphrase:
// "correct horse battery staple"
```

### Server-Side Double-Check

Even with client-side sanitization, always sanitize on the server too. Users can bypass client validation.

---

## 9. Scroll Behavior

### Infinite Scroll vs Pagination

| Pattern | Use When | UX Consideration |
|---------|----------|------------------|
| Infinite scroll | Social feeds, timelines | Show loading at bottom |
| Pagination | Search results, data tables | Show page indicator |
| Load more button | Mixed content | Explicit user control |

### Scroll Position Memory

Remember scroll position when navigating away and back:

```dart
final class ScrollMemory {
  static final Map<String, double> _positions = {};

  static void save(String key, double position) {
    _positions[key] = position;
  }

  static double? get(String key) => _positions[key];
}

// Usage in screen
final _scrollController = ScrollController(
  initialScrollOffset: ScrollMemory.get('feed') ?? 0,
);

@override
void dispose() {
  ScrollMemory.save('feed', _scrollController.offset);
  _scrollController.dispose();
  super.dispose();
}
```

### Scroll to Top

Provide easy way to return to top on long lists:

```dart
// Double-tap status bar (iOS) - automatic
// FAB that appears when scrolled down
AnimatedOpacity(
  opacity: _showScrollToTop ? 1.0 : 0.0,
  duration: Duration(milliseconds: 200),
  child: FloatingActionButton.small(
    onPressed: () {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    },
    child: Icon(Icons.arrow_upward),
  ),
)
```

---

## 10. Accessibility Considerations

Design decisions should enable accessibility:

| Consideration | Implementation |
|---------------|----------------|
| **Focus order** | Logical tab/swipe sequence matching visual layout |
| **Labels** | All interactive elements need semantic labels for screen readers |
| **Motion** | Respect `MediaQuery.disableAnimations` for reduced motion preference |
| **Color** | Never use color alone to convey meaning (see visual-guide.md) |
| **Touch targets** | 48dp minimum helps motor impairments |
| **Text** | Support dynamic type sizing, maintain contrast ratios |

```dart
// Check for reduced motion preference
final reduceMotion = MediaQuery.of(context).disableAnimations;

// Use shorter or no animations when enabled
AnimatedContainer(
  duration: reduceMotion ? Duration.zero : Duration(milliseconds: 300),
  // ...
)

// Semantic labels for screen readers
Semantics(
  label: 'Delete item',
  button: true,
  child: IconButton(
    icon: Icon(Icons.delete),
    onPressed: onDelete,
  ),
)
```

---

## Summary

| Principle | Implementation |
|-----------|----------------|
| Thumb-friendly | Primary actions in bottom 2/3 |
| Touch targets | Minimum 48×48dp |
| Auto-focus | Single-purpose screens, after errors |
| Keyboard | Match type to input, logical flow |
| Gestures | Don't block system, always show undo |
| Feedback | Visual + haptic for every action |
| Validation | On submit default, focus error field |
| Sanitization | Trim emails/names, never trim passwords |
| Scrolling | Remember position, easy return to top |
| Accessibility | Focus order, labels, respect reduced motion |

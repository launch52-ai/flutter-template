# i18n Setup Guide

Complete setup for slang localization in Flutter projects.

---

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  slang: ^4.11.1
  slang_flutter: ^4.11.0

dev_dependencies:
  slang_build_runner: ^4.11.0
```

---

## Configuration

### build.yaml (project root)

```yaml
# Slang localization configuration
# Supports modular per-feature i18n files with namespace merging

targets:
  $default:
    builders:
      slang_build_runner:
        options:
          input_directory: lib
          input_file_pattern: .i18n.yaml
          output_directory: lib/core/i18n
          output_file_name: translations.g.dart
          namespaces: true
          translate_var: t
          fallback_strategy: base_locale
```

---

## File Structure

Modular per-feature localization with namespace merging. Each feature has its own i18n file, all merged into a single `t` object.

```
lib/
├── core/i18n/
│   ├── common.i18n.yaml        → t.common.*
│   └── translations.g.dart     → Generated (all namespaces merged)
└── features/
    ├── auth/i18n/
    │   └── auth.i18n.yaml      → t.auth.*
    ├── dashboard/i18n/
    │   └── dashboard.i18n.yaml → t.dashboard.*
    ├── onboarding/i18n/
    │   └── onboarding.i18n.yaml → t.onboarding.*
    └── settings/i18n/
        └── settings.i18n.yaml  → t.settings.*
```

---

## Common Strings Template

Create `lib/core/i18n/common.i18n.yaml`:

```yaml
# Shared strings used across the app
buttons:
  cancel: Cancel
  save: Save
  delete: Delete
  retry: Retry
  done: Done
  next: Next
  back: Back

errors:
  network: No internet connection. Check your Wi-Fi and try again.
  timeout: Taking too long. Check your connection and try again.
  unknown: Something went wrong. Try again.
  serverBusy: Our servers are busy. Try again in a few minutes.

validation:
  required: $field is required
  invalidEmail: Enter an email like name@example.com
  passwordShort: Use at least 8 characters

items:
  count(n):
    zero: No items
    one: 1 item
    other: $n items

loading:
  default: Loading...
  saving: Saving...
  sending: Sending...
```

---

## Feature Strings Template

Create `lib/features/{feature}/i18n/{feature}.i18n.yaml`:

```yaml
# {Feature} feature strings

# Screens
screenName:
  title: Screen Title
  subtitle: Screen subtitle

# Actions
actions:
  primary: Primary Action
  secondary: Secondary Action

# Errors specific to this feature
errors:
  specific: Feature-specific error message

# Accessibility labels (for screen readers)
accessibility:
  buttonLabel: Description for screen reader
  imageLabel: Image description
```

---

## Initialization

Update `main.dart`:

```dart
import 'package:slang_flutter/slang_flutter.dart';
import 'core/i18n/translations.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();
  // ... rest of init
  runApp(TranslationProvider(child: const ProviderScope(child: MyApp())));
}
```

---

## Code Generation

```bash
# Generate translations after adding/modifying i18n files
dart run build_runner build --delete-conflicting-outputs

# Watch mode for development
dart run build_runner watch --delete-conflicting-outputs
```

---

## Usage

Single import, namespaced access:

```dart
import 'package:your_app/core/i18n/translations.g.dart';

// Common strings (shared)
Text(t.common.buttons.cancel)
Text(t.common.errors.network)
Text(t.common.items.count(n: itemCount))

// Feature strings (namespaced)
Text(t.auth.login.title)
Text(t.auth.errors.invalidCredentials)

Text(t.settings.theme.dark)
Text(t.dashboard.greeting(name: userName))
```

---

## Adding i18n to a New Feature

### Option 1: Use the Generator Script

```bash
# Check which features have i18n files
dart run .claude/skills/i18n/scripts/check.dart

# Generate missing i18n files
dart run .claude/skills/i18n/scripts/check.dart --generate
```

### Option 2: Manual Creation

1. Create the i18n directory and file:
   ```
   lib/features/{feature}/i18n/{feature}.i18n.yaml
   ```

2. Add your strings to the YAML file (use templates from [examples.md](examples.md))

3. Regenerate:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Use with namespace:
   ```dart
   Text(t.{feature}.yourKey)
   ```

---

## Pluralization

Handle zero, one, and many cases:

```yaml
photos:
  count(n):
    zero: No photos
    one: 1 photo
    other: $n photos

  selected(n):
    zero: No photos selected
    one: 1 photo selected
    other: $n photos selected
```

Usage:

```dart
Text(t.photos.count(n: photoList.length))
Text(t.photos.selected(n: selectedCount))
```

---

## Interpolation

Use `$variable` for string interpolation:

```yaml
greeting: Hello, $name!
itemsRemaining: $count items remaining
welcomeBack: Welcome back, $userName. You have $messageCount new messages.
```

Usage:

```dart
Text(t.greeting(name: user.name))
Text(t.itemsRemaining(count: remaining))
Text(t.welcomeBack(userName: user.name, messageCount: messages.length))
```

---

## Checklist

- [ ] `build.yaml` configured in project root
- [ ] `slang` and `slang_flutter` in dependencies
- [ ] `slang_build_runner` in dev_dependencies
- [ ] `common.i18n.yaml` created with shared strings
- [ ] `TranslationProvider` wrapping app in `main.dart`
- [ ] `LocaleSettings.useDeviceLocale()` called in init
- [ ] Feature i18n files follow `{feature}.i18n.yaml` naming
- [ ] `build_runner` executed after changes

---

## Related Guides

| Guide | Use For |
|-------|---------|
| [ux-writing-guide.md](ux-writing-guide.md) | How to write clear, user-friendly text |
| [examples.md](examples.md) | Before/after examples for all scenarios |

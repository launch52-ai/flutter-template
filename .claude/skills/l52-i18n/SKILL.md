---
name: l52-i18n
description: Audit Flutter code for hardcoded strings, write clear user-friendly text following UX guidelines, and migrate strings to i18n files. Use when checking localization, finding hardcoded text, improving string clarity, writing error messages, button labels, or any user-facing text.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# i18n - Localization & UX Writing

**Follow shared rules in [l52-base](../l52-base/SKILL.md).**

Ensure all user-facing text is localized and crystal clear. Every string should be understandable by a 10-year-old or non-native English speaker.

## When to Use This Skill

- Checking for hardcoded strings
- Writing or improving user-facing text
- Creating error messages, button labels, confirmations
- Migrating strings to i18n files
- Reviewing string quality

## FIRST: Run the Audit Script

**ALWAYS start by running the audit script.** The script path uses the base directory shown at the top of this skill prompt.

```bash
# Audit all features (default)
dart run {BASE_DIR}/scripts/check.dart --audit

# Audit specific feature
dart run {BASE_DIR}/scripts/check.dart --audit {feature_name}
```

Where `{BASE_DIR}` = the "Base directory for this skill" shown above (e.g., `/Users/you/.claude/skills/l52-i18n`).

**If a feature argument was provided with `/i18n`, audit only that feature.**

## The Golden Rules

1. **Be specific, not vague** - "Could not save photo" not "Error occurred"
2. **Use plain words** - "Sign in" not "Authenticate"
3. **Buttons complete "I want to ___"** - "Delete photo" not "OK"
4. **Errors say what to do** - "Check your connection and try again"
5. **No confusing dialogs** - Never [Cancel] [OK] on a cancel confirmation

## File Structure

Projects may use either approach:

**Option A: i18n YAML files (slang)**
```
lib/features/{feature}/i18n/{feature}.i18n.yaml → t.{feature}.*
```

**Option B: Static string classes**
```
lib/features/{feature}/resources/{feature}_strings.dart → {Feature}Strings.*
```

Check the project's existing pattern before adding strings.

## Workflow

### 1. Run Audit Script (REQUIRED)

```bash
dart run {BASE_DIR}/scripts/check.dart --audit {feature}
```

The script detects: `Text('...')`, `title:`, `hintText:`, `label:`, SnackBar messages, Dialog content.

### 2. Analyze Results

Review the script output. Filter out acceptable cases:
- **Mock/test data** - Sample strings in mock repositories are OK
- **Debug-only UI** - Dev menu strings don't need localization
- **Technical placeholders** - Format hints like `5.00` are OK

Focus on **production UI code** in `presentation/` folders.

### 3. Evaluate String Quality

Check each real finding against [ux-writing-guide.md](ux-writing-guide.md). Use patterns from [examples.md](examples.md).

### 4. Add Strings to Localization File

**For i18n YAML (slang):**
```yaml
# lib/features/auth/i18n/auth.i18n.yaml
login:
  title: Welcome back
  button: Sign in
```

**For static string classes:**
```dart
// lib/features/auth/resources/auth_strings.dart
final class AuthStrings {
  AuthStrings._();
  static const loginTitle = 'Welcome back';
  static const loginButton = 'Sign in';
}
```

### 5. Replace Hardcoded Strings

```dart
// Before
Text('Welcome back')

// After (slang)
Text(t.auth.login.title)

// After (static class)
Text(AuthStrings.loginTitle)
```

## Additional Commands

```bash
# Check which features have i18n files
dart run {BASE_DIR}/scripts/check.dart

# Generate missing i18n skeleton files
dart run {BASE_DIR}/scripts/check.dart --generate

# Regenerate translations (if using slang)
dart run build_runner build --delete-conflicting-outputs
```

## Guides

| Guide | Use For |
|-------|---------|
| [setup-guide.md](setup-guide.md) | Initial slang setup, build.yaml, file structure |
| [ux-writing-guide.md](ux-writing-guide.md) | UX writing principles, patterns |
| [examples.md](examples.md) | Before/after examples by scenario |

## String Quality Checklist

- [ ] A 10-year-old would understand it
- [ ] Names the specific thing (photo, message, account)
- [ ] If error: says what happened AND what to do
- [ ] If button: completes "I want to ___"
- [ ] If confirmation: buttons clearly show outcomes
- [ ] No jargon (credentials, authenticate, invalid, terminate)

## Related Skills

- `/l52-a11y` - Accessibility labels

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

## FIRST: Run Both Checks

**ALWAYS run both scripts in order.** Use the base directory shown at the top of this skill prompt.

### Step 1: Audit for Hardcoded Strings

```bash
dart run {BASE_DIR}/scripts/check.dart --audit {feature}
```

If issues found → Fix them by moving strings to the appropriate strings file.

### Step 2: Quality Check Existing Strings

```bash
dart run {BASE_DIR}/scripts/check.dart --quality {feature}
```

If issues found → Fix them using AI and the UX writing rules below.

Where `{BASE_DIR}` = the "Base directory for this skill" shown above.

**If a feature argument was provided with `/i18n`, use it for both commands.**

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

### Part 1: Fix Hardcoded Strings

#### 1.1 Run Audit

```bash
dart run {BASE_DIR}/scripts/check.dart --audit {feature}
```

Detects: `Text('...')`, `title:`, `hintText:`, `label:`, SnackBar messages, Dialog content.

#### 1.2 Filter Results

Skip acceptable cases:
- **Mock/test data** - Sample strings in mock repositories
- **Debug-only UI** - Dev menu strings
- **Technical placeholders** - Format hints like `5.00`

Focus on **production UI code** in `presentation/` folders.

#### 1.3 Move Strings to Localization File

**For static string classes:**
```dart
// lib/features/auth/resources/auth_strings.dart
final class AuthStrings {
  AuthStrings._();
  static const loginTitle = 'Welcome back';
}
```

**For i18n YAML:**
```yaml
# lib/features/auth/i18n/auth.i18n.yaml
login:
  title: Welcome back
```

#### 1.4 Replace in Code

```dart
// Before
Text('Welcome back')

// After
Text(AuthStrings.loginTitle)  // or Text(t.auth.login.title)
```

### Part 2: Fix String Quality

#### 2.1 Run Quality Script

```bash
dart run {BASE_DIR}/scripts/check.dart --quality {feature}
```

Detects: vague errors, generic buttons, jargon, missing action guidance.

#### 2.2 Fix Script Issues

For each issue flagged, rewrite the string following the rules:

| Issue | Fix |
|-------|-----|
| Vague error | Be specific: "Could not save photo" |
| Generic button | Use action: "Delete photo", "Save changes" |
| Jargon | Plain words: "Sign in" not "Authenticate" |
| No guidance | Add action: "Check connection and try again" |
| "Are you sure?" | State outcome: "Delete this photo?" |

#### 2.3 AI Deep Review (REQUIRED)

After the script, **read the string file directly** and review each string:

```bash
# Read the strings file
Read: lib/features/{feature}/resources/{feature}_strings.dart
```

Check what the script can't catch:
- **Context**: Does this error make sense for the situation?
- **Consistency**: Are related strings using same terminology?
- **Completeness**: Do empty states explain what goes there?
- **Tone**: Is it friendly but not patronizing?
- **Specificity**: Does it name the actual thing (photo, reminder, account)?
- **Pluralization**: Do countable nouns use proper plural forms?

**Pluralization Review:**

Look for strings that display counts and check they handle all cases:

| Pattern | Issue | Fix |
|---------|-------|-----|
| `"$n items"` | Missing zero/one cases | Use plural syntax with zero, one, other |
| `"1 item"` hardcoded | Won't work for other counts | Use interpolation with plural |
| `"items: $n"` | Noun doesn't change with count | Use proper plural form |

**Slang plural syntax:**
```yaml
# Correct plural handling
itemCount(n):
  zero: No items
  one: 1 item
  other: $n items

daysLeft(n):
  one: 1 day left
  other: $n days left
```

**Common nouns needing pluralization:** item, file, photo, message, reminder, task, comment, user, result, day, hour, minute, credit, call, attempt, error, update

Report findings as a table:

```
| String | Issue | Suggestion |
|--------|-------|------------|
| `errorX` | Too vague | "Could not save reminder. Check your connection." |
| `itemsFound` | Missing plural cases | Add zero/one/other variants |
```

## Additional Commands

```bash
# Check which features have i18n files
dart run {BASE_DIR}/scripts/check.dart

# Generate missing i18n skeleton files
dart run {BASE_DIR}/scripts/check.dart --generate
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
- [ ] Counts use proper pluralization (zero, one, other)

## Related Skills

- `/l52-a11y` - Accessibility labels

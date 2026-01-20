# Skill Examples

Examples of well-structured skills across different categories. Use these as reference when creating new skills.

---

## Code-Heavy Skill Example: `/data`

Code-heavy skills focus on generating detailed Dart code from specifications.

### Structure

```
.claude/skills/data/
├── SKILL.md                              # < 200 lines
├── reference/
│   ├── models/
│   │   ├── simple_model.dart             # With header comment
│   │   ├── nested_model.dart
│   │   └── paginated_response.dart
│   ├── repositories/
│   │   ├── basic_repository_impl.dart
│   │   └── cached_repository_impl.dart
│   ├── data_sources/
│   │   ├── remote_data_source.dart
│   │   └── local_data_source.dart
│   └── failures/
│       ├── failures.dart
│       └── failure_mapper.dart
└── scripts/
    └── check.dart
```

### SKILL.md Pattern

```yaml
---
name: data
description: Generate data layer code (Freezed DTOs, repository implementations, data sources) from feature specifications. Use after /domain to implement the data layer.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---
```

Key sections:
- **When to Use** - Clear scenarios
- **Workflow** - Phased approach (DTOs → Repositories → Data Sources)
- **Reference Files** - Table pointing to `reference/` files
- **Checklist** - Verification for generated code

### Reference File Header

```dart
// Template: Repository implementation with Dio HTTP client
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Replace {Feature} placeholders
// 3. Implement missing methods

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

final class FeatureRepositoryImpl implements FeatureRepository {
  // ...
}
```

---

## Auth Skill Example: `/social-login`

Auth skills combine code generation with platform configuration.

### Structure

```
.claude/skills/social-login/
├── SKILL.md
├── google-setup-guide.md               # Platform setup
├── apple-setup-guide.md
├── implementation-guide.md             # Code walkthrough
├── reference/
│   ├── repositories/
│   │   └── social_auth_repository.dart
│   ├── providers/
│   │   └── auth_provider_social.dart
│   ├── widgets/
│   │   └── social_login_button.dart
│   └── utils/
│       └── nonce_helpers.dart
└── templates/
    ├── Runner.entitlements              # iOS capability
    └── android_manifest_additions.xml   # Android config
```

### SKILL.md Pattern

Key characteristics:
- **Questions to Ask** - Backend, OAuth providers, error handling
- **Platform Requirements** - Table with iOS/Android differences
- **Failure Types** - Sealed types with UI actions
- **Guides table** - Separate setup and implementation guides

### Template File Example

```xml
<!-- Template: AndroidManifest additions for Google Sign-In -->
<!--
  Location: android/app/src/main/AndroidManifest.xml

  Usage:
  1. Add inside <application> tag
  2. Replace YOUR_REVERSED_CLIENT_ID with actual value
-->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="YOUR_REVERSED_CLIENT_ID" />
</intent-filter>
```

---

## Config Skill Example: `/release`

Config skills focus on platform configurations and verification.

### Structure

```
.claude/skills/release/
├── SKILL.md
├── android-guide.md                    # Platform-specific
├── ios-guide.md
├── assets-guide.md
├── version-guide.md
├── checklist.md                        # Comprehensive checklist
├── templates/
│   ├── PrivacyInfo.xcprivacy          # iOS Privacy Manifest
│   └── proguard-rules.pro             # Android R8 rules
└── scripts/
    └── check.dart                      # Release readiness audit
```

### SKILL.md Pattern

Key characteristics:
- **Manual vs CI/CD** - Decision table for approach
- **Platform Requirements** - Side-by-side comparison
- **Security Checklist** - Critical files that must not be committed
- **Commands** - Multiple script options with flag explanations

### Check Script Features

```dart
// Multiple output modes
--platform android      // Platform filter
--platform ios
--fix                   // Auto-fix gitignore
--checklist             // Print checklist
--keytool-command       // Generate keystore command
--capabilities          // Detect iOS capabilities
--json                  // CI-friendly output
```

---

## Knowledge Skill Example: `/a11y`

Knowledge skills provide guidelines with code auditing.

### Structure

```
.claude/skills/a11y/
├── SKILL.md
├── semantics-guide.md                  # Detailed patterns
├── testing-guide.md                    # How to test
├── examples.md                         # Code examples
└── scripts/
    └── check.dart                      # Code auditor
```

### SKILL.md Pattern

Key characteristics:
- **Quick Reference** - The Four Pillars, Key Requirements table
- **Workflow** - Audit → Fix → Test → Verify
- **Checklist** - Actionable verification items
- **Commands** - Audit, feature filter, test generation

### Check Script Pattern

```dart
// Pattern detection
_hasImageWithoutSemanticLabel()
_hasIconButtonWithoutTooltip()
_hasGestureDetectorWithoutSemantics()

// Smart filtering
if (_isWrappedInSemantics(lines, index)) return false;
if (_isChildOfListTile(lines, index)) return false;

// Actionable output
print('   💡 Add semanticLabel: \'description\' or wrap in ExcludeSemantics');
```

---

## Orchestration Skill Example: `/feature-init`

Orchestration skills coordinate other skills and create scaffolds.

### Structure

```
.claude/skills/feature-init/
├── SKILL.md
└── examples.md                         # Feature structure examples
```

### SKILL.md Pattern

Key characteristics:
- **Workflow** - Creates structure, delegates to other skills
- **Output** - Clear file structure with TODOs
- **Next Steps** - Explicit delegation to `/domain`, `/data`, `/presentation`
- **Minimal reference code** - Just scaffold patterns

### Delegation Pattern

```markdown
## Next Steps

After running `/feature-init`:
1. `/domain {feature}` - Fill in entities, enums, interfaces
2. `/data {feature}` - Fill in DTOs, repositories, data sources
3. `/presentation {feature}` - Fill in states, notifiers, screens
4. `/i18n {feature}` - Add localized strings
5. `/testing {feature}` - Create test files
```

---

## Anti-Pattern Examples

### Too Much Code in SKILL.md

**Bad:**
```markdown
## Repository Implementation

```dart
final class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final SecureStorage _storage;

  AuthRepositoryImpl(this._dio, this._storage);

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final user = UserDto.fromJson(response.data).toDomain();
      await _storage.write(key: 'token', value: response.data['token']);
      return Right(user);
    } on DioException catch (e) {
      return Left(_mapError(e));
    }
  }

  // ... 50 more lines
}
```
```

**Good:**
```markdown
## Repository Implementation

**See:** `reference/repositories/auth_repository_impl.dart`

**Core pattern:**
```dart
final result = await repository.login(email, password);
result.fold(
  (failure) => showError(failure),
  (user) => navigateToHome(user),
);
```
```

### Missing Delegation

**Bad:**
```markdown
## Checklist

- [ ] Repository implemented
- [ ] Tests written              <!-- Should be /testing -->
- [ ] Strings localized          <!-- Should be /i18n -->
- [ ] Accessibility labels added <!-- Should be /a11y -->
- [ ] UI polished                <!-- Should be /design -->
```

**Good:**
```markdown
## Checklist

- [ ] Repository implemented
- [ ] DTOs match API response
- [ ] Failure types handle all error cases

## Next Steps

- `/testing` - Create unit tests for repository
- `/i18n` - Localize error messages
- `/a11y` - Add accessibility to UI
- `/design` - Polish loading/error states
```

### Vague Description

**Bad:**
```yaml
description: Helps with data stuff and API things
```

**Good:**
```yaml
description: Generate data layer code (Freezed DTOs, repository implementations, data sources) from feature specifications. Use after /domain to implement the data layer.
```

---

## Checklist for New Skills

Based on these examples:

- [ ] SKILL.md < 200 lines (max 300)
- [ ] All code > 10 lines in `reference/`
- [ ] Platform configs in `templates/`
- [ ] Check script with `--help`, `--json`, `--fix`
- [ ] Reference files have header comments
- [ ] Clear delegation to related skills
- [ ] Guides for detailed explanations
- [ ] Actionable checklist items

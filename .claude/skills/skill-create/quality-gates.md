# Skill Quality Gates

Detailed quality criteria that skills must pass before deployment. These gates ensure consistency, discoverability, and effectiveness across all skills.

---

## Overview

Skills progress through four quality gates:

```
┌─────────────────────────────────────────────────────────────────┐
│                      Quality Gate Pipeline                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────────┐ │
│  │ Gate 1   │ → │ Gate 2   │ → │ Gate 3   │ → │ Gate 4       │ │
│  │ Structure│   │ Content  │   │ Quality  │   │ Integration  │ │
│  │ REQUIRED │   │ REQUIRED │   │ RECOMMEND│   │ RECOMMEND    │ │
│  └──────────┘   └──────────┘   └──────────┘   └──────────────┘ │
│                                                                  │
│  Automated ←────────────────────────────────→ Manual            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Gates 1-2:** Required. Skill won't function without passing.
**Gates 3-4:** Recommended. Skill works but may have quality issues.

---

## Gate 1: Structure (Required)

Validates the skill has the minimum required files and structure.

### Checks

| Check | Criteria | Error Code |
|-------|----------|------------|
| Directory exists | `.claude/skills/{name}/` exists | E001 |
| SKILL.md exists | `SKILL.md` file present | E002 |
| Valid directory name | Lowercase, hyphens only, < 64 chars | E003 |
| No reserved names | Not "anthropic", "claude", etc. | E004 |

### Validation

```bash
dart run .claude/skills/skill-create/scripts/validate.dart --skill {name} --gate structure
```

### Pass Criteria

All checks must pass. Any failure blocks deployment.

---

## Gate 2: Content (Required)

Validates the SKILL.md has required content for Claude to use the skill effectively.

### Frontmatter Checks

| Check | Criteria | Error Code |
|-------|----------|------------|
| Frontmatter exists | Valid YAML between `---` markers | E101 |
| Name present | `name:` field exists | E102 |
| Name matches | `name` equals directory name | E103 |
| Description present | `description:` field exists | E104 |
| Description length | < 1024 characters | E105 |
| Description voice | Third person ("Generates..." not "I can...") | E106 |
| Allowed tools present | `allowed-tools:` field exists | E107 |

### Section Checks

| Check | Criteria | Error Code |
|-------|----------|------------|
| Title present | `# {Name}` heading exists | E201 |
| When to Use | `## When to Use` section exists | E202 |
| Workflow | `## Workflow` section exists | E203 |
| Guides table | `## Guides` with markdown table | E204 |
| Checklist | `## Checklist` with `- [ ]` items | E205 |
| Related Skills | `## Related Skills` section exists | E206 |

### Validation

```bash
dart run .claude/skills/skill-create/scripts/validate.dart --skill {name} --gate content
```

### Pass Criteria

All frontmatter checks must pass. At least 4 of 6 section checks must pass.

---

## Gate 3: Quality (Recommended)

Validates content quality and best practices.

### SKILL.md Quality

| Check | Criteria | Warning Code |
|-------|----------|--------------|
| Line count | < 300 lines | W301 |
| Ideal length | < 200 lines | W302 |
| Code block size | No blocks > 10 lines | W303 |
| Checklist items | > 3 items in checklist | W304 |
| Workflow steps | Numbered steps present | W305 |
| Skill boundaries | No content belonging to other skills | W306 |

### Link Validation

| Check | Criteria | Warning Code |
|-------|----------|--------------|
| Internal links resolve | All `[text](path)` links exist | W401 |
| Guides table links | All guide file links resolve | W402 |
| Template references | All `templates/` references exist | W403 |
| Reference mentions | All `reference/` mentions exist | W404 |

### Reference File Quality

| Check | Criteria | Warning Code |
|-------|----------|--------------|
| Header comments | Each `.dart` in `reference/` has header | W501 |
| Location comment | Header includes `// Location:` | W502 |
| Usage comment | Header includes `// Usage:` | W503 |

### Validation Script

| Check | Criteria | Warning Code |
|-------|----------|--------------|
| Script exists | `scripts/check.dart` or `scripts/validate.dart` exists | W601 |
| Script runs | Script executes without error | W602 |
| Help option | Script supports `--help` | W603 |
| JSON output | Script supports `--json` for CI | W604 |

### Validation

```bash
dart run .claude/skills/skill-create/scripts/validate.dart --skill {name} --gate quality
```

### Pass Criteria

Warnings don't block deployment but indicate areas for improvement. Target: < 3 warnings.

---

## Gate 4: Integration (Recommended)

Validates the skill is properly integrated with the skill ecosystem.

### SKILL_STRUCTURE.md Registration

| Check | Criteria | Warning Code |
|-------|----------|--------------|
| In skill table | Listed in "Complete Skill Reference" table | W701 |
| Correct category | Category matches actual skill type | W702 |
| Run after accurate | Dependencies correctly listed | W703 |

### Cross-References

| Check | Criteria | Warning Code |
|-------|----------|--------------|
| Related skills exist | All skills in "Related Skills" exist | W801 |
| Bidirectional refs | Related skills reference back | W802 |
| Delegation documented | Skills we delegate to know about us | W803 |

### No Duplication

| Check | Criteria | Warning Code |
|-------|----------|--------------|
| Unique functionality | No significant overlap with other skills | W901 |
| Clear boundaries | Delegation rules clear | W902 |

### Validation

```bash
dart run .claude/skills/skill-create/scripts/validate.dart --skill {name} --gate integration
```

### Pass Criteria

Integration warnings should be addressed before the skill is widely used. Target: 0 warnings.

---

## Error and Warning Codes

### Error Codes (E###) - Required

| Range | Category |
|-------|----------|
| E001-E099 | Structure errors |
| E101-E199 | Frontmatter errors |
| E201-E299 | Section errors |

### Warning Codes (W###) - Recommended

| Range | Category |
|-------|----------|
| W301-W399 | SKILL.md quality |
| W401-W499 | Link validation |
| W501-W599 | Reference file quality |
| W601-W699 | Validation script |
| W701-W799 | SKILL_STRUCTURE.md integration |
| W801-W899 | Cross-references |
| W901-W999 | Duplication/overlap |

---

## Running All Gates

```bash
# Full validation (all gates)
dart run .claude/skills/skill-create/scripts/validate.dart --skill {name}

# Specific gate
dart run .claude/skills/skill-create/scripts/validate.dart --skill {name} --gate structure

# All skills
dart run .claude/skills/skill-create/scripts/validate.dart --all

# Generate report
dart run .claude/skills/skill-create/scripts/validate.dart --skill {name} --report
```

---

## Quality Scores

Skills receive a quality score based on gate results:

| Score | Criteria |
|-------|----------|
| A | All gates pass, 0 warnings |
| B | Gates 1-2 pass, < 3 warnings |
| C | Gates 1-2 pass, 3-5 warnings |
| D | Gates 1-2 pass, > 5 warnings |
| F | Gate 1 or 2 fails |

**Target:** All skills should be B or better.

---

## Fixing Common Issues

### E105: Description too long

**Before:**
```yaml
description: This skill helps you create data transfer objects and repository implementations for your Flutter applications using Freezed and JSON Serializable. It generates code that follows clean architecture patterns and integrates with the rest of the template. Use when you need to connect to REST APIs or implement the data layer of a feature.
```

**After:**
```yaml
description: Generate data layer code (Freezed DTOs, repository implementations, data sources) from feature specifications. Use after /domain to implement the data layer.
```

### E106: First person description

**Before:**
```yaml
description: I can help you test your Flutter code with unit tests and widget tests.
```

**After:**
```yaml
description: Write and review tests for Flutter projects. Unit tests, widget tests, golden tests, mocks. Use when adding tests or reviewing test quality.
```

### W303: Code block too long

**Before (in SKILL.md):**
```markdown
## Repository Example

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
      // ... 20 more lines
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
```
```

**After:**
```markdown
## Repository Example

**See:** `reference/repositories/auth_repository_impl.dart`

**Core API:**
```dart
final result = await repository.login(email, password);
result.fold(
  (failure) => showError(failure),
  (user) => navigateToHome(user),
);
```
```

### W306: Skill boundary violation

Skills should not include detailed how-to content that belongs to other skills.

**Flagged patterns (avoid these section headers in SKILL.md):**
- `### Localization` / `### Localized Message` → belongs to `/i18n`
- `### Custom Colors` / styling instructions → belongs to `/design`
- `### Accessibility` / semantics setup → belongs to `/a11y`
- `### Unit Tests` / `### Widget Tests` → belongs to `/testing`

**Proper delegation:** Use "Next Steps" section with simple references like `Run /i18n for localization`

**OK patterns:**
- Brief mentions in "Related Skills" section
- Code in `reference/` files (not SKILL.md)
- Simple delegation notes: `Run /i18n`, `Run /design`

### W501: Missing header comment

**Before:**
```dart
import 'package:dio/dio.dart';

final class AuthRepositoryImpl implements AuthRepository {
  // ...
}
```

**After:**
```dart
// Template: Auth repository with Dio HTTP client
//
// Location: lib/features/auth/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Update import paths
// 3. Inject via Riverpod provider

import 'package:dio/dio.dart';

final class AuthRepositoryImpl implements AuthRepository {
  // ...
}
```

---

## Continuous Validation

For CI integration:

```yaml
# .github/workflows/validate-skills.yml
name: Validate Skills
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - name: Validate all skills
        run: |
          dart run .claude/skills/skill-create/scripts/validate.dart --all --json > skill-report.json
          if grep -q '"errors":' skill-report.json | grep -v '"errors":0'; then
            exit 1
          fi
```

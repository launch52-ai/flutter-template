---
name: l52-feature-init
description: Initialize new feature with Clean Architecture folder structure and skeleton files. Creates scaffold for domain, data, and presentation layers with TODOs. Use AFTER /plan to create the initial structure, then run /domain and /data to fill in details.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Feature Init - Initialize Feature Structure

Initialize a new feature with Clean Architecture folder structure and skeleton files. Creates the scaffold, then `/domain` and `/data` fill in the details.

## CRITICAL: Always Create Scaffold Files

**SCAFFOLD FILES ARE MANDATORY** - whether creating a new feature OR extending an existing one.

Scaffold files:
- Contain ONLY TODOs, comments, and empty structure
- Have NO implementation code
- Serve as guidance for `/domain`, `/data`, `/presentation` skills
- Must reference web/backend equivalents where applicable

**Without scaffolds, other skills won't know what to implement.**

## When to Use This Skill

- Creating a new feature from scratch (after `/plan`) → use `--generate`
- Extending an existing feature with new entities/screens → use `--extend`
- User asks to "create feature", "init feature", "scaffold feature", or "add new feature"
- **PLAN.md says "extend existing feature"** → use `--extend` (STILL CREATE SCAFFOLDS)

## COMMON MISTAKES - DO NOT MAKE THESE

**WRONG:** "The plan says to extend an existing feature, so /feature-init doesn't apply."
**RIGHT:** Use `--extend` mode to create scaffold files in the existing feature.

**WRONG:** "I'll skip scaffolding and just implement the code directly."
**RIGHT:** ALWAYS create scaffolds first. Other skills (`/domain`, `/data`) need them.

**WRONG:** "Feature folder exists, so I should just edit files manually."
**RIGHT:** Use `--extend` to add NEW scaffold files, then edit existing files with TODOs.

**This skill ALWAYS applies when adding new entities, models, or screens - regardless of whether the feature folder exists.**

## Two Modes: Generate vs Extend

| Mode | Use When | Creates |
|------|----------|---------|
| `--generate feature_name` | Feature doesn't exist | Full feature folder structure |
| `--extend feature_name entity_name` | Feature exists, adding new entity/screen | New files in existing feature |

**Both modes create scaffold files with TODOs - NEVER skip scaffolding.**

## BEFORE You Start - Mandatory Checks

**ALWAYS run these checks to decide between `--generate` and `--extend`:**

```bash
# 1. Check if a related feature already exists
ls -la lib/features/

# 2. Search for related code (e.g., for "billing" or "payment")
grep -r "billing\|payment\|stripe" lib/features/ --include="*.dart" -l

# 3. Check the backend for existing APIs
# Look at ../call-me/apps/api/src/ for existing modules
```

**Decision:**
- Related feature EXISTS → use `--extend` (add scaffolds to existing feature)
- Related feature DOES NOT exist → use `--generate` (create new feature with scaffolds)

**Example:**

| Scenario | Command | What Gets Created |
|----------|---------|-------------------|
| "Add call rates" but `credits` exists | `--extend credits country_rate` | Scaffold files in credits/ |
| "Add phone auth" but `auth` exists | `--extend auth phone_auth` | Scaffold files in auth/ |
| "Add notifications" (none exists) | `--generate notifications` | New notifications/ folder with scaffolds |

**In ALL cases, scaffold files are created.**

## What Scaffold Files Must Contain

**Scaffold files are blueprints, NOT implementations.**

Each scaffold file MUST have:
1. **File header comment** - What this file is for
2. **Reference to web/backend** - Where to look for implementation details
3. **TODO comments** - What needs to be implemented
4. **Empty structure** - Class/interface shell with no logic

Each scaffold file must NOT have:
- Actual implementation code
- Business logic
- API calls
- Real data transformations

### Scaffold Template Example

```dart
// =============================================================================
// SCAFFOLD FILE - DO NOT IMPLEMENT HERE
// =============================================================================
// Purpose: [What this file does]
// Web equivalent: ../call-me/apps/web/[path]
// API endpoint: [endpoint if applicable]
// =============================================================================

/// TODO: [Brief description]
///
/// Fields to implement:
/// - [field1]: [type] - [description]
/// - [field2]: [type] - [description]
///
/// See web implementation: [file path]
class MyEntity {
  // TODO: Add fields based on web/backend model
}
```

## Dependency Rules

```
┌─────────────┐
│   Domain    │  ← No dependencies (pure Dart, no Flutter)
└──────┬──────┘
       │
   ┌───┴───┐
   ▼       ▼
┌──────┐ ┌──────────────┐
│ Data │ │ Presentation │  ← Both depend on Domain only
└──────┘ └──────────────┘
```

Data and Presentation must NEVER depend on each other.

## Naming Conventions

| Component | Pattern | Example |
|-----------|---------|---------|
| Feature folder | snake_case | `user_profile` |
| Entity | `{Feature}` | `UserProfile` |
| Repository interface | `{Feature}Repository` | `UserProfileRepository` |
| Repository impl | `{Feature}RepositoryImpl` | `UserProfileRepositoryImpl` |
| Model (DTO) | `{Feature}Model` | `UserProfileModel` |
| State | `{Feature}State` | `UserProfileState` |
| Notifier | `{Feature}Notifier` | `UserProfileNotifier` |
| Screen | `{Feature}Screen` | `UserProfileScreen` |

## Commands (Conceptual)

These are conceptual commands to guide your actions:

| Command | Meaning | Action |
|---------|---------|--------|
| `--generate feature_name` | Create new feature | Create full folder structure + all scaffolds |
| `--extend feature_name entity_name` | Extend existing | Add new scaffolds to existing feature folder |

### Examples

| User Request | Command | What You Create |
|--------------|---------|-----------------|
| "Add notifications feature" | `--generate notifications` | New `notifications/` folder with all scaffolds |
| "Add call rates to credits" | `--extend credits country_rate` | New scaffolds in existing `credits/` folder |
| "Add phone auth to auth" | `--extend auth phone_auth` | New scaffolds in existing `auth/` folder |

**Remember: ALWAYS create scaffold files. Never skip to implementation.**

## Workflow

### 0. Check for Existing Features (MANDATORY)

Before doing anything else:
```bash
ls -la lib/features/
grep -ri "keyword" lib/features/ --include="*.dart" -l
```

- Related feature exists → use `--extend`
- No related feature → use `--generate`

### 1. Gather Requirements

Ask: Feature/entity name (snake_case)? What does it do? What screens? Needs API?

### 2. Create Scaffold Files (ALWAYS DO THIS)

**For `--generate feature_name`** (new feature):
Create full folder structure with scaffold files:
- `feature_name/domain/entities/feature_name.dart` - Entity scaffold
- `feature_name/domain/repositories/feature_name_repository.dart` - Interface scaffold
- `feature_name/data/models/feature_name_model.dart` - DTO scaffold
- `feature_name/data/repositories/feature_name_repository_impl.dart` - Impl scaffold
- `feature_name/data/repositories/mock_feature_name_repository.dart` - Mock scaffold
- `feature_name/presentation/providers/feature_name_provider.dart` - Provider scaffold
- `feature_name/presentation/screens/feature_name_screen.dart` - Screen scaffold
- `feature_name/resources/feature_name_strings.dart` - Strings scaffold

**For `--extend feature_name entity_name`** (extending existing):
Add scaffold files to existing feature:
- `feature_name/domain/entities/entity_name.dart` - Entity scaffold
- `feature_name/data/models/entity_name_model.dart` - DTO scaffold
- `feature_name/presentation/screens/entity_name_screen.dart` - Screen scaffold (if needed)
- Update existing repository interface with TODO for new method
- Update existing repository impl with TODO for new method

**All scaffold files contain TODOs and comments only - NO implementation.**

### 3. Hand Off to Specialized Skills

After creating scaffolds, inform user of next steps:
1. `/domain {feature}` - Fill in domain layer details (entities, enums, interfaces)
2. `/data {feature}` - Fill in data layer details (DTOs, repository impl, API calls)
3. `/presentation {feature}` - Fill in presentation layer (providers, screens)
4. `/i18n {feature}` - Add localized strings
5. `/testing {feature}` - Create test files
6. `/design` - Polish the UI
7. `/a11y` - Add Semantics widgets
8. Add route to `app_router.dart`
9. Add repository provider to `core/providers.dart`
10. Run `dart run build_runner build`

## Feature Types

**Standard (Default)**: Full domain + data + presentation. Use for most features - even "simple" ones like onboarding need data persistence.

**Data-Only**: Domain + data without screens. Use for shared services (analytics, notifications).

## Guides

| Guide | Use For |
|-------|---------|
| [templates.md](templates.md) | **PRIMARY** - Scaffold templates to copy, naming conventions |
| [examples.md](examples.md) | Complete "bookmarks" feature example |

**Always reference templates.md when creating scaffold files.**

## Checklist

- [ ] **Checked for related features** (ran `ls lib/features/` and `grep`)
- [ ] **Decided: `--generate` or `--extend`**
- [ ] **Created scaffold files with TODOs** (NO implementation)
- [ ] Domain layer scaffold: entity, repository interface (with TODO comments)
- [ ] Data layer scaffold: model, repository impl, mock (with TODO comments)
- [ ] Presentation layer scaffold: provider, screen (with TODO comments)
- [ ] Each scaffold references web/backend equivalent
- [ ] Informed user of next steps (`/domain`, `/data`, `/presentation`)

**DO NOT:**
- [ ] Write any implementation code
- [ ] Fill in method bodies
- [ ] Add business logic
- [ ] Make API calls

## Related Skills

- `/plan` - Run BEFORE this skill to plan feature requirements
- `/domain` - Run AFTER to fill in domain layer details
- `/data` - Run AFTER to fill in data layer implementation
- `/presentation` - Run AFTER to fill in presentation layer (states, notifiers, screens)
- `/i18n` - Add localized strings
- `/testing` - Create test files
- `/design` - Polish UI components
- `/a11y` - Add accessibility support

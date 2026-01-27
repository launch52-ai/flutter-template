---
name: l52-testing
description: Write, review, and audit tests for Flutter projects using Clean Architecture + Riverpod. Use when writing unit tests, widget tests, golden tests, reviewing test quality, checking test coverage, creating mocks/spies, or testing Riverpod providers.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Testing - Write & Review Tests

Write high-quality, maintainable tests following Clean Architecture patterns. Every test should clearly express intent and catch regressions without being brittle.

## When to Use This Skill

- Writing new tests (unit, widget, golden, integration)
- Reviewing test code quality
- Setting up test infrastructure (helpers, mocks, spies)
- Testing Riverpod providers and notifiers
- Auditing test coverage

## Quick Reference

### Test Types

| Type | Purpose | When to Use |
|------|---------|-------------|
| **Unit** | Isolated logic | Repositories, services, utils, providers |
| **Widget** | UI interactions | Screens, navigation |
| **Golden** | Visual regression | Layout, themes |
| **Integration** | Real implementations | Storage, cache, API flows |

### Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| File | `{component}_test.dart` | `auth_repository_impl_test.dart` |
| Test | `test_{subject}_{scenario}_{expected}` | `test_signIn_withValidCredentials_returnsAuthResult` |
| Factory | `any{Type}()` | `anyEmail()`, `anyUserProfile()` |
| SUT | `makeSUT()` | Creates System Under Test |

### Commands

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific type
flutter test test/unit/
flutter test test/widget/

# Audit test coverage
dart run .claude/skills/testing/scripts/check.dart

# Generate missing test files
dart run .claude/skills/testing/scripts/check.dart --generate

# Update golden files
flutter test --update-goldens test/golden/
```

## Workflow

### 1. Create Test File

Mirror source path: `test/unit/features/{feature}/data/repositories/{name}_test.dart`

### 2. Write Tests Using Patterns

See [patterns-guide.md](patterns-guide.md) for:
- **makeSUT()** - Factory for System Under Test
- **Spy Pattern** - Track method calls
- **Arrange-Act-Assert** - Clear structure
- **Disposal Testing** - Verify cleanup
- **Inbox Checklist** - Infrastructure testing

### 3. Verify Coverage

```bash
dart run .claude/skills/testing/scripts/check.dart
```

## Checklist

**Structure:**
- [ ] Uses `makeSUT()` for consistent setup
- [ ] Uses `any*()` factories for test data
- [ ] Clear Arrange-Act-Assert structure

**Coverage:**
- [ ] Tests success and error paths
- [ ] Verifies side effects (storage, API calls)

**Quality:**
- [ ] No hardcoded delays
- [ ] No flaky assertions
- [ ] Disposal tested

## Coverage Expectations

| Component | Minimum |
|-----------|---------|
| Repositories | 90%+ |
| Providers | 85%+ |
| Utils | 80%+ |
| Widgets | 60%+ |

## Guides

| Guide | Use For |
|-------|---------|
| [patterns-guide.md](patterns-guide.md) | Test patterns, helpers, spies |
| [examples.md](examples.md) | Before/after examples |

## TDD Integration

The testing skill can be called by layer skills (`/domain`, `/data`, `/presentation`) to generate tests as part of TDD workflow.

### Called by /domain --tdd

Generates **contract tests** for repository interfaces:
- Uses mock repositories
- Tests interface behavior, not implementation
- Tests should FAIL (no implementation yet)
- Generates `any*()` factories for domain entities

```bash
# Domain skill delegates test generation
/testing auth --layer=domain --gwt=test/specs/auth.gwt.yaml
```

### Called by /data --tdd

Generates **implementation tests**:
- Repository impl tests (mock data source)
- Data source tests (mock HTTP/Dio)
- DTO mapping tests (fromJson, toEntity)
- Applies Inbox Checklist for storage components

After running, domain contract tests should PASS.

```bash
# Data skill delegates test generation
/testing auth --layer=data
```

### Called by /presentation --tdd

Generates **UI tests**:
- Notifier tests (state transitions, disposal)
- Widget tests (interactions, rendering)
- Golden tests (visual snapshots)

Outputs screenshot paths for review app.

```bash
# Presentation skill delegates test generation
/testing auth --layer=presentation
```

### TDD Commands

```bash
# Generate tests for specific layer
/testing {feature} --layer=domain
/testing {feature} --layer=data
/testing {feature} --layer=presentation

# Generate from GWT input
/testing {feature} --gwt=test/specs/auth.gwt.yaml

# Generate specific test types
/testing {feature} --type=contract     # Domain contracts only
/testing {feature} --type=impl         # Data implementation only
/testing {feature} --type=notifier     # Notifier tests only
/testing {feature} --type=widget       # Widget tests only
/testing {feature} --type=golden       # Golden tests only

# Verify domain contracts pass
/testing {feature} --verify-contracts

# Run full TDD verification
dart run .claude/skills/testing/scripts/run_tdd.dart {feature}
```

### JSON Output

TDD mode outputs structured JSON for automation:

```json
{
  "feature": "auth",
  "layer": "domain",
  "tests_generated": 8,
  "helpers_generated": ["anyAuthResult()", "anyUserProfile()"],
  "spies_generated": ["AuthRepositorySpy"],
  "next_step": "/data auth --tdd"
}
```

See [TDD_INTEGRATION.md](TDD_INTEGRATION.md) for complete integration details.

## Related Skills

- `/a11y` - Accessibility tests (`textContrastGuideline`, etc.)
- `/domain` - Generate domain layer (uses testing skill in TDD mode)
- `/data` - Generate data layer (uses testing skill in TDD mode)
- `/presentation` - Generate presentation layer (uses testing skill in TDD mode)

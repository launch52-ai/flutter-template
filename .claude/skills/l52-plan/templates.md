# Plan Templates

Templates for creating feature specification documents.

---

## Feature Specification Template

Create at `lib/features/{feature}/.spec.md` or `docs/features/{feature}.spec.md`:

```markdown
# Feature Specification: {Feature Name}

> **Status:** Draft | Ready for Implementation | In Progress | Complete
> **Created:** {date}
> **Last Updated:** {date}

---

## 1. Overview

### 1.1 Purpose
{One paragraph describing what this feature does and why it exists}

### 1.2 User Stories
- As a {user type}, I want to {action} so that {benefit}
- As a {user type}, I want to {action} so that {benefit}

### 1.3 Scope
**In Scope:**
- {Feature/functionality included}

**Out of Scope:**
- {Feature/functionality explicitly excluded}

---

## 2. Domain Layer

### 2.1 Entities

#### {EntityName}

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | ✓ | Unique identifier |
| {field} | {Type} | {✓/?} | {Description} |
| createdAt | DateTime | ✓ | Creation timestamp |
| updatedAt | DateTime? | | Last update timestamp |

**Computed Properties:**
- `{propertyName}`: {description of computation}

**Business Rules:**
- {Rule description}

#### {SecondEntity} (if applicable)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| ... | ... | ... | ... |

### 2.2 Enums

#### {EnumName}

| Value | Description |
|-------|-------------|
| {value1} | {Description} |
| {value2} | {Description} |

### 2.3 Repository Interface

```dart
abstract interface class {Feature}Repository {
  /// {Description}
  Future<List<{Entity}>> getAll();

  /// {Description}
  Future<{Entity}?> getById(String id);

  /// {Description}
  ///
  /// Parameters:
  /// - [param1]: {description}
  /// - [param2]: {description}
  Future<{Entity}> create({
    required Type param1,
    Type? param2,
  });

  /// {Description}
  Future<{Entity}> update({
    required String id,
    Type? param1,
  });

  /// {Description}
  Future<void> delete(String id);
}
```

---

## 3. Data Layer

### 3.1 Data Sources

| Source | Type | Operations Needed |
|--------|------|-------------------|
| {source} | REST API / Supabase / Storage / Camera / etc. | {what operations: CRUD, upload, etc.} |

> **Note:** Detailed API endpoints, DTOs, and mappings handled by `/api` skill.

### 3.2 Local Storage (if applicable)

| What | Storage Type | Notes |
|------|--------------|-------|
| {what data} | SharedPrefs / SecureStorage | {why this storage type} |

### 3.3 Caching Strategy (if applicable)

- **What to cache:** {data types}
- **When to invalidate:** {trigger}

### 3.4 Offline Strategy (if applicable)

| Operation | Offline Behavior |
|-----------|------------------|
| Read | {behavior} |
| Create | {behavior} |
| Update | {behavior} |
| Delete | {behavior} |

---

## 4. Presentation Layer

### 4.1 Screens

#### {Feature}ListScreen

**Route:** `/{feature}`

**Purpose:** Display collection of {items} for browsing and management.

**Data Displayed:**
- List of {Entity} items
- For each item: {key fields to show}
- Sync/status indicators (if applicable)

**Required States:**
- Loading (initial fetch)
- Loaded (with items)
- Empty (no items)
- Error (fetch failed)

**User Actions:**
| Action | Result |
|--------|--------|
| View item | Navigate to detail |
| Create new | Navigate to create |
| Refresh | Reload data |
| Delete item | Confirm → Remove |

**Notes for Design:**
- {Any specific requirements, e.g., "items need visual sync status indicator"}
- {Any constraints, e.g., "must support 100+ items efficiently"}

#### {Feature}DetailScreen

**Route:** `/{feature}/:id`

**Purpose:** Display single {item} with full details and actions.

**Data Displayed:**
- Full {Entity} with all fields:
  - {field1}: {description}
  - {field2}: {description}
  - ...
- Related data (if any)

**Required States:**
- Loading
- Loaded
- Error
- Not found

**User Actions:**
| Action | Result |
|--------|--------|
| Edit | Navigate to edit or inline edit |
| Delete | Confirm → Delete → Navigate back |
| {Other} | {Result} |

**Notes for Design:**
- {Any specific requirements}

#### {Feature}FormScreen (Create/Edit)

**Route:** `/{feature}/create` or `/{feature}/:id/edit`

**Purpose:** Create new or edit existing {item}.

**Form Fields:**
| Field | Type | Required | Validation | Notes |
|-------|------|----------|------------|-------|
| {field1} | text | ✓ | Required | |
| {field2} | email | ✓ | Email format | |
| {field3} | number | | Min: 0 | |

**Required States:**
- Editing (form visible)
- Submitting (save in progress)
- Success (saved)
- Error (save failed)

**User Actions:**
| Action | Result |
|--------|--------|
| Save | Validate → Submit → Success/Error |
| Cancel | Warn if unsaved → Navigate back |

**Notes for Design:**
- {Any specific requirements, e.g., "caption has 500 char limit - show counter"}

### 4.2 States

#### {Feature}ListState

```dart
@freezed
sealed class {Feature}ListState with _${Feature}ListState {
  const factory {Feature}ListState.initial() = {Feature}ListStateInitial;
  const factory {Feature}ListState.loading() = {Feature}ListStateLoading;
  const factory {Feature}ListState.loaded({
    required List<{Entity}> items,
    @Default(false) bool isLoadingMore,
    @Default(true) bool hasMore,
  }) = {Feature}ListStateLoaded;
  const factory {Feature}ListState.error(String message) = {Feature}ListStateError;
}
```

#### {Feature}DetailState

```dart
@freezed
sealed class {Feature}DetailState with _${Feature}DetailState {
  const factory {Feature}DetailState.loading() = {Feature}DetailStateLoading;
  const factory {Feature}DetailState.loaded({Entity} item) = {Feature}DetailStateLoaded;
  const factory {Feature}DetailState.error(String message) = {Feature}DetailStateError;
}
```

#### {Feature}FormState

```dart
@freezed
sealed class {Feature}FormState with _${Feature}FormState {
  const factory {Feature}FormState.editing({
    {Entity}? existingItem, // null for create
    @Default({}) Map<String, String> errors,
  }) = {Feature}FormStateEditing;
  const factory {Feature}FormState.submitting() = {Feature}FormStateSubmitting;
  const factory {Feature}FormState.success({Entity} item) = {Feature}FormStateSuccess;
  const factory {Feature}FormState.error(String message) = {Feature}FormStateError;
}
```

### 4.3 Providers

#### {Feature}ListNotifier

| Method | Description | State Transitions |
|--------|-------------|-------------------|
| `build()` | Initial load | initial → loading → loaded/error |
| `refresh()` | Pull to refresh | loaded → loading → loaded/error |
| `loadMore()` | Pagination | loaded(isLoadingMore: true) → loaded |
| `delete(id)` | Delete item | Optimistic remove → success/revert |

#### {Feature}DetailNotifier

| Method | Description | State Transitions |
|--------|-------------|-------------------|
| `build(id)` | Load item | loading → loaded/error |
| `refresh()` | Reload | loaded → loading → loaded/error |
| `update(...)` | Update fields | loaded → submitting → loaded/error |
| `delete()` | Delete item | loaded → success (navigate away) |

#### {Feature}FormNotifier

| Method | Description | State Transitions |
|--------|-------------|-------------------|
| `build(id?)` | Initialize | editing (with existingItem if id) |
| `submit(...)` | Save | editing → submitting → success/error |
| `validate()` | Check fields | Updates errors map |

---

## 5. User Flows

### 5.1 Create Flow

**Navigation:** List → Form → Detail (or List)

**Happy Path:**
1. User initiates create from list
2. Navigate to form screen (empty)
3. User fills in fields
4. User saves
5. Validate → Submit → Navigate to detail (or list)

**Error Path:**
- Validation fails → Show errors, focus first error field
- Submit fails → Show error message, keep form data

**Cancel Path:**
- If form has changes: Confirm discard
- Return to list

### 5.2 Edit Flow

**Navigation:** Detail → Form → Detail

**Happy Path:**
1. User initiates edit from detail
2. Navigate to form (pre-filled)
3. User modifies fields
4. User saves
5. Validate → Submit → Return to detail (updated)

### 5.3 Delete Flow

**Navigation:** Detail → Confirmation → List

**Happy Path:**
1. User initiates delete from detail
2. Show confirmation (destructive action)
3. User confirms
4. Delete item → Navigate to list

**Cancel Path:**
- User cancels confirmation → Stay on detail

---

## 6. Error Handling

### 6.1 Error Types & Recovery

| Error Type | Recovery Action |
|------------|-----------------|
| Network unavailable | Retry option |
| Server error (5xx) | Retry option |
| Not found (404) | Navigate back |
| Unauthorized (401) | Navigate to login |
| Validation (422) | Focus error field |

### 6.2 Empty States

| State | Recovery Action |
|-------|-----------------|
| No items | CTA to create first |
| No search results | Clear search option |
| Filtered empty | Clear filters option |

> **Note:** Actual error/empty messages will be written by `/i18n` skill following UX guidelines.

---

## 7. Implementation Order

| Step | Skill | Command | Creates | Depends On |
|------|-------|---------|---------|------------|
| 1 | domain | `/domain {feature}` | Entities, Repository interface, Enums | - |
| 2 | data | `/data {feature} --source={source}` | Data layer for {source} | 1 |
| 3 | api | `/api {feature}` | REST API integration (if applicable) | 1 |
| 4 | screen | `/screen {feature} list` | List screen, ListNotifier, ListState | 1, 2/3 |
| 5 | screen | `/screen {feature} detail` | Detail screen, DetailNotifier | 1, 2/3 |
| 6 | screen | `/screen {feature} form` | Form screen, FormNotifier | 1, 2/3 |
| 7 | i18n | `/i18n {feature}` | Localized strings | 4, 5, 6 |
| 8 | testing | `/testing {feature}` | Unit, widget tests | All above |
| 9 | design | `/design {feature}` | UI polish, loading states | 4, 5, 6 |
| 10 | a11y | `/a11y {feature}` | Semantics, accessibility | 4, 5, 6 |

---

## 8. Open Questions

| Question | Context | Decision |
|----------|---------|----------|
| {Question} | {Why it matters} | {Pending / Resolved: answer} |

---

## 9. Technical Notes

### Dependencies Required
- {package}: {reason}

### Platform Considerations
- **iOS**: {any iOS-specific notes}
- **Android**: {any Android-specific notes}

### Performance Considerations
- {Any performance notes}

---

## Changelog

| Date | Change | Author |
|------|--------|--------|
| {date} | Initial spec created | {name} |
```

---

## Minimal Spec Template

For simpler features, use this condensed version:

```markdown
# Feature Spec: {Feature}

## Overview
{One paragraph description}

## Domain

### {Entity}
| Field | Type | Required |
|-------|------|----------|
| id | String | ✓ |
| ... | ... | ... |

### Repository
- `getAll()` → `List<{Entity}>`
- `getById(id)` → `{Entity}?`
- `create(...)` → `{Entity}`
- `delete(id)` → `void`

## Data Source
- **Type**: {REST API / Storage / etc.}
- **Details**: {endpoint or storage key}

## Screens
1. **List** (`/{feature}`) - Grid/list of items, FAB to create
2. **Detail** (`/{feature}/:id`) - View item, edit/delete actions
3. **Form** (`/{feature}/new`) - Create/edit form

## Implementation Order
1. `/domain {feature}`
2. `/api {feature}` (or `/data {feature} --source=storage`)
3. `/screen {feature} list`
4. `/screen {feature} detail`
5. `/i18n {feature}` → `/testing {feature}` → `/design` → `/a11y`
```

---

## Spec File Location

| Scenario | Location |
|----------|----------|
| New feature (before creation) | `docs/features/{feature}.spec.md` |
| Existing feature (within folder) | `lib/features/{feature}/.spec.md` |
| Project-wide reference | `docs/features/` directory |

The spec file should be:
- **Committed to git** - Part of project documentation
- **Updated as implementation progresses** - Mark sections complete
- **Referenced by skills** - Skills read from this for context

# Presentation Patterns Guide

Patterns for state management, notifiers, and screen implementation.

---

## State Patterns

### List State (Sealed Union)

For screens displaying collections. Uses Freezed sealed class for exhaustive pattern matching.

**See:** `reference/providers/list_state.dart`

### Detail State (Sealed Union)

For screens showing a single item. Includes `notFound` state for missing items.

**See:** `reference/providers/detail_state.dart`

### Form State (Field-Based)

For create/edit screens with validation. Uses field-based state (not sealed union).

**See:** `reference/providers/form_state.dart`

### Paginated State

For infinite scroll lists. Extends list state with `hasMore` and `isLoadingMore`.

**Core pattern:**
```dart
const factory {Feature}State.loaded({
  required List<{Entity}> items,
  required bool hasMore,
  @Default(false) bool isLoadingMore,
}) = {Feature}StateLoaded;
```

---

## Notifier Patterns

### Basic Notifier (Load Only)

Load and refresh data. Key patterns:
- `_disposed` flag prevents state updates after disposal
- `_safeSetState` checks disposal before updating
- Check `_disposed` after every await

**See:** `reference/providers/basic_notifier.dart`

### CRUD Notifier

Full create, update, delete operations. Reloads list after each mutation.

**See:** `reference/providers/crud_notifier.dart`

### Form Notifier

Field updates, validation, and submission.

**See:** `reference/providers/form_notifier.dart`

### Detail Notifier (With ID Parameter)

Load single item by ID. Uses `arg` to access build parameter.

**See:** `reference/providers/detail_notifier.dart`

---

## Screen Patterns

### List Screen

Pattern matching on sealed state. Shows loading, empty, loaded, and error states.

**See:** `reference/screens/list_screen.dart`

**Core pattern:**
```dart
body: switch (state) {
  {Feature}StateInitial() || {Feature}StateLoading() =>
    const Center(child: CircularProgressIndicator()),
  {Feature}StateLoaded(:final items) => /* list or empty */,
  {Feature}StateError(:final message) => /* error state */,
},
```

### Detail Screen

With ID parameter from router. Shows edit button when loaded.

**See:** `reference/screens/detail_screen.dart`

### Form Screen

Listens for success to pop back. Shows inline validation errors.

**See:** `reference/screens/form_screen.dart`

---

## Widget Extraction Rules

Extract into separate widget file when:

| Condition | Threshold |
|-----------|-----------|
| Size | Widget > 50 lines |
| Reuse | Used in 2+ places |
| Testing | Needs isolated widget tests |
| Screen size | Screen file > 200 lines |

**See:** `reference/widgets/list_item.dart` for list item pattern
**See:** `reference/widgets/form_field.dart` for custom form fields

---

## Error Handling

### In Notifiers

Map exceptions to user-friendly messages using i18n:

```dart
final message = switch (e) {
  NetworkException() => t.errors.noConnection,
  NotFoundException() => t.errors.notFound,
  _ => t.errors.unknown,
};
```

### In Screens

Always use i18n keys for error messages, never hardcode strings.

---

## Navigation Integration

### Adding Routes

In `lib/core/router/app_router.dart`:

```dart
GoRoute(
  path: '/{feature}',
  builder: (context, state) => const {Feature}Screen(),
  routes: [
    GoRoute(
      path: ':id',
      builder: (context, state) => {Feature}DetailScreen(
        id: state.pathParameters['id']!,
      ),
    ),
  ],
),
```

### Navigation in Screens

```dart
context.push('/{feature}/${item.id}');  // Navigate to detail
context.push('/{feature}/new');          // Navigate to form
context.pop();                           // Pop after success
```

---

## Next Steps

After implementing presentation layer:
- `/i18n {feature}` - Add localized strings
- `/design` - Polish UI/UX patterns
- `/a11y` - Add accessibility
- `/testing {feature}` - Create widget tests

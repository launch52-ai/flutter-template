# Domain Layer Patterns

When to use each pattern. See `reference/` directory for actual code.

---

## Entity Patterns

| Pattern | When to Use | Reference |
|---------|-------------|-----------|
| **Simple** | Just a data holder | `reference/entities/simple_entity.dart` |
| **With Computed** | Need derived values | `reference/entities/entity_with_computed.dart` |
| **With Equality** | Used in state comparison, Maps, Sets | `reference/entities/entity_with_equality.dart` |
| **With copyWith** | Need immutable updates | `reference/entities/entity_with_copywith.dart` |

### Entity Requirements

- `final class`
- `const` constructor
- `final` fields
- Doc comments

### When to Add Equality (`==` / `hashCode`)

Add when:
- Entity is in a `List` that gets compared (state management)
- Entity is used as a `Map` key or in a `Set`
- You need to check if two instances represent the same thing

**Don't add** if entity is just a data container identified by ID.

### When to Add copyWith

Add when:
- You need to create modified copies
- Entity is used in state where you update individual fields

---

## Value Object Patterns

Value objects are small, immutable, compared by value. Always need `==` and `hashCode`.

| Pattern | When to Use | Reference |
|---------|-------------|-----------|
| **LatLng** | Geographic coordinates | `reference/value_objects/lat_lng.dart` |
| **Money** | Monetary values with operations | `reference/value_objects/money.dart` |

---

## Enum Patterns

| Pattern | When to Use | Reference |
|---------|-------------|-----------|
| **Simple** | Basic set of values | `reference/enums/simple_enum.dart` |
| **With Properties** | Values have labels, numeric values | `reference/enums/enum_with_properties.dart` |
| **With Methods** | State machine logic, computed properties | `reference/enums/enum_with_methods.dart` |

---

## Repository Interface Patterns

| Pattern | When to Use | Reference |
|---------|-------------|-----------|
| **Basic CRUD** | Standard create/read/update/delete | `reference/repositories/basic_crud_repository.dart` |
| **Paginated** | Large datasets | `reference/repositories/paginated_repository.dart` |
| **Offline** | Local-first with sync | `reference/repositories/offline_repository.dart` |

### Repository Requirements

- `abstract interface class`
- Methods return domain entities (not DTOs)
- Doc comments for each method
- Clear parameter types

---

## Folder Structure

```
lib/features/{feature}/domain/
├── entities/
│   ├── {entity}.dart
│   └── {value_object}.dart
├── enums/
│   └── {enum_name}.dart
└── repositories/
    └── {feature}_repository.dart
```

---

## Import Rules

Domain layer can import:
- ✅ Other domain files within same feature
- ✅ `dart:core` (built-in)
- ✅ `dart:math` (if needed)

Domain layer must NOT import:
- ❌ `package:freezed_annotation`
- ❌ `package:json_annotation`
- ❌ Flutter packages
- ❌ Data layer files
- ❌ Presentation layer files
- ❌ Network packages (dio, http)
- ❌ Storage packages

---

## Quick Reference

```dart
// Minimal entity
final class Task {
  final String id;
  final String title;
  const Task({required this.id, required this.title});
}

// With computed property
bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!);

// With equality (only when needed)
@override
bool operator ==(Object other) =>
    identical(this, other) || other is User && other.id == id;

@override
int get hashCode => id.hashCode;

// With copyWith (only when needed)
Task copyWith({String? title}) => Task(id: id, title: title ?? this.title);
```

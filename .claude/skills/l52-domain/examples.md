# Domain Skill Examples

Example scenarios showing which reference files to use.

---

## Scenario 1: Simple Task Feature

**Need:** Basic task with title, description, dates.

**Use:**
- `reference/entities/simple_entity.dart` → `task.dart`
- `reference/enums/simple_enum.dart` → `task_status.dart`
- `reference/repositories/basic_crud_repository.dart` → `tasks_repository.dart`

---

## Scenario 2: Photo Memories (Offline-First)

**Need:** Photos with location, offline creation, cloud sync.

**Use:**
- `reference/entities/entity_with_computed.dart` → `memory.dart`
- `reference/value_objects/lat_lng.dart` → `lat_lng.dart`
- `reference/enums/simple_enum.dart` → `sync_status.dart`
- `reference/repositories/offline_repository.dart` → `memories_repository.dart`

---

## Scenario 3: User Auth

**Need:** User entity used in auth state (needs equality for state comparison).

**Use:**
- `reference/entities/entity_with_equality.dart` → `user.dart`
- `reference/repositories/basic_crud_repository.dart` → adapt for auth

---

## Scenario 4: Shopping Cart

**Need:** Cart items with quantity updates (needs copyWith).

**Use:**
- `reference/entities/entity_with_copywith.dart` → `cart_item.dart`
- `reference/value_objects/money.dart` → for price calculations

---

## Scenario 5: E-commerce Orders

**Need:** Order status with state machine logic.

**Use:**
- `reference/entities/simple_entity.dart` → `order.dart`
- `reference/enums/enum_with_methods.dart` → `order_status.dart`
- `reference/repositories/paginated_repository.dart` → `orders_repository.dart`

---

## Generated Structure

After running `/domain memories`:

```
lib/features/memories/domain/
├── entities/
│   ├── memory.dart       # Pure Dart, computed properties
│   └── lat_lng.dart      # Value object with equality
├── enums/
│   └── sync_status.dart  # Simple enum
└── repositories/
    └── memories_repository.dart  # Interface with sync methods
```

---

## Decision Matrix

| Scenario | Equality | copyWith | Value Object |
|----------|----------|----------|--------------|
| Simple data holder | ❌ | ❌ | ❌ |
| Used in state comparison | ✅ | ❌ | ❌ |
| Needs immutable updates | ❌ | ✅ | ❌ |
| Small composite type (LatLng) | ✅ | ❌ | ✅ |
| Both state + updates | ✅ | ✅ | ❌ |

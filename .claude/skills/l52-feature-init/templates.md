# Feature Templates

Code templates for generating feature scaffolding. Replace `{feature}` with snake_case name and `{Feature}` with PascalCase.

**Dependency Rule**: Domain has no external dependencies. Data and Presentation depend on Domain only.

---

## Domain Layer

### Entity (Pure Dart)

`lib/features/{feature}/domain/entities/{feature}.dart`

```dart
/// {Feature} domain entity.
///
/// Pure domain model with no external dependencies.
/// Used by repository interfaces and presentation layer.
final class {Feature} {
  const {Feature}({
    required this.id,
    // TODO: Add fields based on feature requirements
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### Repository Interface

`lib/features/{feature}/domain/repositories/{feature}_repository.dart`

```dart
import '../entities/{feature}.dart';

/// {Feature} repository interface.
///
/// Defines the contract for {feature} data operations.
/// Uses domain entities only - no data layer imports.
abstract interface class {Feature}Repository {
  /// Get all {feature} items.
  Future<List<{Feature}>> getAll();

  /// Get {feature} by ID.
  Future<{Feature}?> getById(String id);

  // TODO: Add methods based on feature requirements
}
```

---

## Data Layer

### Model (Freezed DTO)

`lib/features/{feature}/data/models/{feature}_model.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/{feature}.dart';

part '{feature}_model.freezed.dart';
part '{feature}_model.g.dart';

/// {Feature} data transfer object.
///
/// Handles JSON serialization. Maps to domain entity.
@freezed
abstract class {Feature}Model with _${Feature}Model {
  const {Feature}Model._();

  const factory {Feature}Model({
    required String id,
    // TODO: Add fields based on feature requirements
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _{Feature}Model;

  factory {Feature}Model.fromJson(Map<String, dynamic> json) =>
      _${Feature}ModelFromJson(json);

  /// Convert to domain entity.
  {Feature} toEntity() => {Feature}(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Create from domain entity.
  factory {Feature}Model.fromEntity({Feature} entity) => {Feature}Model(
        id: entity.id,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}
```

### Repository Implementation

`lib/features/{feature}/data/repositories/{feature}_repository_impl.dart`

```dart
import '../../domain/entities/{feature}.dart';
import '../../domain/repositories/{feature}_repository.dart';
import '../models/{feature}_model.dart';

/// Implementation of [{Feature}Repository].
///
/// Fetches data, maps DTOs to domain entities.
final class {Feature}RepositoryImpl implements {Feature}Repository {
  const {Feature}RepositoryImpl();
  // TODO: Add dependencies (Dio, storage, etc.) via constructor

  @override
  Future<List<{Feature}>> getAll() async {
    // TODO: Fetch data, map to entities
    // final response = await _dio.get('/features');
    // final models = (response.data as List)
    //     .map((json) => {Feature}Model.fromJson(json))
    //     .toList();
    // return models.map((m) => m.toEntity()).toList();
    throw UnimplementedError();
  }

  @override
  Future<{Feature}?> getById(String id) async {
    // TODO: Fetch data, map to entity
    throw UnimplementedError();
  }
}
```

---

## Presentation Layer

### State (Freezed Sealed)

`lib/features/{feature}/presentation/providers/{feature}_state.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/{feature}.dart';

part '{feature}_state.freezed.dart';

/// {Feature} state.
///
/// Uses domain entities only - no data layer imports.
@freezed
sealed class {Feature}State with _${Feature}State {
  const factory {Feature}State.initial() = {Feature}StateInitial;
  const factory {Feature}State.loading() = {Feature}StateLoading;
  const factory {Feature}State.loaded({
    required List<{Feature}> items,
  }) = {Feature}StateLoaded;
  const factory {Feature}State.error(String message) = {Feature}StateError;
}
```

### Provider (Riverpod)

`lib/features/{feature}/presentation/providers/{feature}_provider.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/{feature}_repository.dart';
import '{feature}_state.dart';

part '{feature}_provider.g.dart';

// Note: Repository provider is defined in core/providers.dart
// to keep presentation layer independent of data layer.
//
// Example in core/providers.dart:
// @riverpod
// {Feature}Repository {feature}Repository(Ref ref) {
//   return {Feature}RepositoryImpl(ref.watch(dioProvider));
// }

/// {Feature} state notifier.
///
/// Uses domain repository interface only - no data layer imports.
@riverpod
final class {Feature}Notifier extends _${Feature}Notifier {
  bool _disposed = false;

  @override
  {Feature}State build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _loadInitialData();
    return const {Feature}State.initial();
  }

  void _safeSetState({Feature}State newState) {
    if (!_disposed) {
      state = newState;
    }
  }

  Future<void> _loadInitialData() async {
    _safeSetState(const {Feature}State.loading());

    try {
      final repository = ref.read({feature}RepositoryProvider);
      final items = await repository.getAll();
      if (_disposed) return;
      _safeSetState({Feature}State.loaded(items: items));
    } catch (e) {
      if (_disposed) return;
      _safeSetState({Feature}State.error(e.toString()));
    }
  }

  Future<void> refresh() async {
    await _loadInitialData();
  }
}
```

### Screen

`lib/features/{feature}/presentation/screens/{feature}_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/strings.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/{feature}_provider.dart';
import '../providers/{feature}_state.dart';

/// {Feature} screen.
///
/// Uses domain entities via state - no data layer imports.
final class {Feature}Screen extends ConsumerWidget {
  const {Feature}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch({feature}NotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.{feature}.title),
      ),
      body: switch (state) {
        {Feature}StateInitial() || {Feature}StateLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        {Feature}StateLoaded(:final items) => items.isEmpty
            ? EmptyState(
                icon: Icons.inbox_outlined,
                message: t.{feature}.empty,
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(item.id), // TODO: Replace with actual field
                  );
                },
              ),
        {Feature}StateError(:final message) => EmptyState(
            icon: Icons.error_outline,
            message: message,
          ),
      },
    );
  }
}
```

---

## i18n

### Localization Template

`lib/features/{feature}/i18n/{feature}.i18n.yaml`

```yaml
# {Feature} strings
# Run: dart run build_runner build --delete-conflicting-outputs

title: {Feature}
empty: No items yet

# TODO: Add feature-specific strings
# Use /i18n skill to write clear, user-friendly text

# Accessibility labels for screen readers
# Use /a11y skill to add Semantics widgets that reference these
accessibility:
  # Example labels - replace with actual feature content
  # itemDescription: Item $name
  # deleteItem: Delete item
```

---

## Test Skeleton (Optional)

`test/unit/features/{feature}/data/repositories/{feature}_repository_impl_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_helpers.dart';

void main() {
  group('{Feature}RepositoryImpl', () {
    // TODO: Use /testing skill to implement tests
    test('placeholder', () {
      expect(true, isTrue);
    });
  });
}
```

---

## Bash Commands

### Create Folder Structure

```bash
FEATURE="{feature}"
mkdir -p "lib/features/$FEATURE/data/models"
mkdir -p "lib/features/$FEATURE/data/repositories"
mkdir -p "lib/features/$FEATURE/domain/repositories"
mkdir -p "lib/features/$FEATURE/i18n"
mkdir -p "lib/features/$FEATURE/presentation/providers"
mkdir -p "lib/features/$FEATURE/presentation/screens"
mkdir -p "lib/features/$FEATURE/presentation/widgets"
```

### Generate Code After Creation

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Checklist

After generating files:

- [ ] Domain entity created (pure Dart, no dependencies)
- [ ] Domain interface created (uses entity only)
- [ ] Model DTO with Freezed created (with toEntity/fromEntity)
- [ ] Repository implementation created (maps DTOs to entities)
- [ ] State sealed class created (uses domain entities)
- [ ] Provider with disposal safety created (no data imports)
- [ ] Screen with state handling created (no data imports)
- [ ] Repository provider added to `core/providers.dart`
- [ ] i18n template added (include `accessibility:` section for semantic labels)
- [ ] Route added to `app_router.dart`
- [ ] `build_runner` executed
- [ ] Hand off to `/i18n`, `/testing`, `/design`, `/a11y`

## Dependency Verification

Run validation to check for violations:
```bash
dart run .claude/skills/feature-init/scripts/check.dart --validate {feature}
```

This checks:
- Domain has no imports from data/ or presentation/
- Presentation has no imports from data/

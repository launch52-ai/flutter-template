# Feature Examples

Complete example of scaffolding a new feature.

---

## Example: "Bookmarks" Feature

**Requirements gathered:**
- Feature name: `bookmarks`
- Description: Users can save and manage bookmarked items
- Screens: list (main) + detail (optional later)
- API integration: Yes (Supabase)

---

### Generated Structure

```
lib/features/bookmarks/
├── domain/                              # No external dependencies
│   ├── entities/
│   │   └── bookmark.dart                # Pure domain entity
│   └── repositories/
│       └── bookmarks_repository.dart    # Uses entities only
├── data/                                # Depends on domain only
│   ├── models/
│   │   └── bookmark_model.dart          # DTO with toEntity/fromEntity
│   └── repositories/
│       └── bookmarks_repository_impl.dart
├── presentation/                        # Depends on domain only
│   ├── providers/
│   │   ├── bookmarks_state.dart         # Uses domain entities
│   │   └── bookmarks_provider.dart
│   ├── screens/
│   │   └── bookmarks_screen.dart
│   └── widgets/
└── i18n/
    └── bookmarks.i18n.yaml
```

---

### Generated Files

#### `domain/entities/bookmark.dart`

```dart
/// Bookmark domain entity.
///
/// Pure domain model with no external dependencies.
final class Bookmark {
  const Bookmark({
    required this.id,
    required this.userId,
    required this.title,
    required this.url,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String url;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

#### `domain/repositories/bookmarks_repository.dart`

```dart
import '../entities/bookmark.dart';

/// Bookmarks repository interface.
///
/// Uses domain entities only - no data layer imports.
abstract interface class BookmarksRepository {
  /// Get all bookmarks for current user.
  Future<List<Bookmark>> getAll();

  /// Get bookmark by ID.
  Future<Bookmark?> getById(String id);

  /// Create a new bookmark.
  Future<Bookmark> create(Bookmark bookmark);

  /// Delete a bookmark.
  Future<void> delete(String id);
}
```

#### `data/models/bookmark_model.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/bookmark.dart';

part 'bookmark_model.freezed.dart';
part 'bookmark_model.g.dart';

/// Bookmark data transfer object.
///
/// Handles JSON serialization. Maps to domain entity.
@freezed
abstract class BookmarkModel with _$BookmarkModel {
  const BookmarkModel._();

  const factory BookmarkModel({
    required String id,
    required String userId,
    required String title,
    required String url,
    String? description,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _BookmarkModel;

  factory BookmarkModel.fromJson(Map<String, dynamic> json) =>
      _$BookmarkModelFromJson(json);

  /// Convert to domain entity.
  Bookmark toEntity() => Bookmark(
        id: id,
        userId: userId,
        title: title,
        url: url,
        description: description,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Create from domain entity.
  factory BookmarkModel.fromEntity(Bookmark entity) => BookmarkModel(
        id: entity.id,
        userId: entity.userId,
        title: entity.title,
        url: entity.url,
        description: entity.description,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}
```

#### `data/repositories/bookmarks_repository_impl.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmarks_repository.dart';
import '../models/bookmark_model.dart';

/// Supabase implementation of [BookmarksRepository].
///
/// Fetches data, maps DTOs to domain entities.
final class BookmarksRepositoryImpl implements BookmarksRepository {
  final SupabaseClient _supabase;

  const BookmarksRepositoryImpl(this._supabase);

  @override
  Future<List<Bookmark>> getAll() async {
    final response = await _supabase.from('bookmarks').select();
    final models = (response as List)
        .map((json) => BookmarkModel.fromJson(json))
        .toList();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Bookmark?> getById(String id) async {
    final response = await _supabase
        .from('bookmarks')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return BookmarkModel.fromJson(response).toEntity();
  }

  @override
  Future<Bookmark> create(Bookmark bookmark) async {
    final model = BookmarkModel.fromEntity(bookmark);
    final response = await _supabase
        .from('bookmarks')
        .insert(model.toJson())
        .select()
        .single();
    return BookmarkModel.fromJson(response).toEntity();
  }

  @override
  Future<void> delete(String id) async {
    await _supabase.from('bookmarks').delete().eq('id', id);
  }
}
```

#### `presentation/providers/bookmarks_state.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/bookmark.dart';

part 'bookmarks_state.freezed.dart';

/// Bookmarks state.
///
/// Uses domain entities only - no data layer imports.
@freezed
sealed class BookmarksState with _$BookmarksState {
  const factory BookmarksState.initial() = BookmarksStateInitial;
  const factory BookmarksState.loading() = BookmarksStateLoading;
  const factory BookmarksState.loaded({
    required List<Bookmark> items,
  }) = BookmarksStateLoaded;
  const factory BookmarksState.error(String message) = BookmarksStateError;
}
```

#### `presentation/providers/bookmarks_provider.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/error_utils.dart';
import '../../domain/repositories/bookmarks_repository.dart';
import 'bookmarks_state.dart';

part 'bookmarks_provider.g.dart';

// Note: Repository provider is in core/providers.dart:
// @riverpod
// BookmarksRepository bookmarksRepository(Ref ref) {
//   final supabase = ref.watch(supabaseClientProvider);
//   return BookmarksRepositoryImpl(supabase);
// }

/// Bookmarks state notifier.
///
/// Uses domain repository interface only - no data layer imports.
@riverpod
final class BookmarksNotifier extends _$BookmarksNotifier {
  bool _disposed = false;

  @override
  BookmarksState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _loadBookmarks();
    return const BookmarksState.initial();
  }

  void _safeSetState(BookmarksState newState) {
    if (!_disposed) {
      state = newState;
    }
  }

  Future<void> _loadBookmarks() async {
    _safeSetState(const BookmarksState.loading());

    try {
      final repository = ref.read(bookmarksRepositoryProvider);
      final items = await repository.getAll();
      if (_disposed) return;
      _safeSetState(BookmarksState.loaded(items: items));
    } catch (e) {
      if (_disposed) return;
      _safeSetState(BookmarksState.error(ErrorUtils.getUserFriendlyMessage(e)));
    }
  }

  Future<void> refresh() async {
    await _loadBookmarks();
  }

  Future<void> deleteBookmark(String id) async {
    try {
      final repository = ref.read(bookmarksRepositoryProvider);
      await repository.delete(id);
      if (_disposed) return;
      await _loadBookmarks();
    } catch (e) {
      if (_disposed) return;
      _safeSetState(BookmarksState.error(ErrorUtils.getUserFriendlyMessage(e)));
    }
  }
}
```

#### `presentation/screens/bookmarks_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/strings.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/bookmarks_state.dart';

/// Bookmarks list screen.
///
/// Uses domain entities via state - no data layer imports.
final class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookmarksNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.bookmarks.title),
      ),
      body: switch (state) {
        BookmarksStateInitial() || BookmarksStateLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        BookmarksStateLoaded(:final items) => items.isEmpty
            ? EmptyState(
                icon: Icons.bookmark_border,
                message: t.bookmarks.empty,
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(bookmarksNotifierProvider.notifier).refresh(),
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];  // This is a Bookmark entity
                    return ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text(item.title),
                      subtitle: item.description != null
                          ? Text(item.description!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(bookmarksNotifierProvider.notifier)
                            .deleteBookmark(item.id),
                      ),
                    );
                  },
                ),
              ),
        BookmarksStateError(:final message) => EmptyState(
            icon: Icons.error_outline,
            message: message,
          ),
      },
    );
  }
}
```

#### `i18n/bookmarks.i18n.yaml`

```yaml
# Bookmarks feature strings
# Run: dart run build_runner build --delete-conflicting-outputs

title: Bookmarks
empty: No bookmarks yet. Save items to find them later.

# TODO: Use /i18n skill to add more strings
```

---

### Router Integration

Add to `lib/core/router/app_router.dart`:

```dart
// In the routes list
GoRoute(
  path: '/bookmarks',
  builder: (context, state) => const BookmarksScreen(),
),

// Or in shell for tab navigation
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/bookmarks',
      builder: (context, state) => const BookmarksScreen(),
    ),
  ],
),
```

---

### Output Message

After scaffolding, output to user:

```
Feature scaffolding complete for `bookmarks`.

Created:
- lib/features/bookmarks/domain/entities/bookmark.dart
- lib/features/bookmarks/domain/repositories/bookmarks_repository.dart
- lib/features/bookmarks/data/models/bookmark_model.dart
- lib/features/bookmarks/data/repositories/bookmarks_repository_impl.dart
- lib/features/bookmarks/presentation/providers/bookmarks_state.dart
- lib/features/bookmarks/presentation/providers/bookmarks_provider.dart
- lib/features/bookmarks/presentation/screens/bookmarks_screen.dart
- lib/features/bookmarks/i18n/bookmarks.i18n.yaml

Dependency structure:
- Domain: No dependencies (pure Dart)
- Data: Depends on Domain only
- Presentation: Depends on Domain only

Next steps:
1. Add repository provider to `lib/core/providers.dart`
2. Run `/i18n bookmarks` to write user-friendly strings
3. Run `/testing bookmarks` to create test files
4. Run `/design` when implementing the UI details
5. Add route to `lib/core/router/app_router.dart`
6. Run `dart run build_runner build --delete-conflicting-outputs`
```

---

## Data-Only Feature Example

For shared services consumed by other features (e.g., analytics):

**Feature:** `analytics`

```
lib/features/analytics/
├── data/
│   └── repositories/
│       └── analytics_repository_impl.dart
└── domain/
    └── repositories/
        └── analytics_repository.dart
```

Only create:
- Domain interface
- Data implementation
- Provider (no screen/state)

Skip presentation layer entirely.

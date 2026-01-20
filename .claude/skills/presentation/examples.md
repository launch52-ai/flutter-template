# Presentation Examples

Complete examples showing presentation layer implementation.

---

## Example: Notes Feature

Full implementation from spec to screens.

### Input: Domain Layer

```dart
// domain/entities/note.dart
final class Note {
  const Note({
    required this.id,
    required this.title,
    this.content,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? content;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

// domain/repositories/notes_repository.dart
abstract interface class NotesRepository {
  Future<List<Note>> getAll();
  Future<Note?> getById(String id);
  Future<Note> create(Note note);
  Future<Note> update(Note note);
  Future<void> delete(String id);
}
```

### Output: Presentation Layer

#### `presentation/providers/notes_state.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/note.dart';

part 'notes_state.freezed.dart';

/// Notes list state.
@freezed
sealed class NotesState with _$NotesState {
  const factory NotesState.initial() = NotesStateInitial;
  const factory NotesState.loading() = NotesStateLoading;
  const factory NotesState.loaded({
    required List<Note> items,
  }) = NotesStateLoaded;
  const factory NotesState.error(String message) = NotesStateError;
}
```

#### `presentation/providers/notes_notifier.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers.dart';
import '../../domain/entities/note.dart';
import 'notes_state.dart';

part 'notes_notifier.g.dart';

/// Notes list notifier with CRUD operations.
@riverpod
final class NotesNotifier extends _$NotesNotifier {
  bool _disposed = false;

  @override
  NotesState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _load();
    return const NotesState.initial();
  }

  void _safeSetState(NotesState newState) {
    if (!_disposed) state = newState;
  }

  Future<void> _load() async {
    _safeSetState(const NotesState.loading());
    try {
      final repository = ref.read(notesRepositoryProvider);
      final items = await repository.getAll();
      if (_disposed) return;
      _safeSetState(NotesState.loaded(items: items));
    } catch (e) {
      if (_disposed) return;
      _safeSetState(NotesState.error(e.toString()));
    }
  }

  Future<void> refresh() async => _load();

  Future<void> deleteNote(String id) async {
    try {
      final repository = ref.read(notesRepositoryProvider);
      await repository.delete(id);
      if (_disposed) return;
      await _load();
    } catch (e) {
      if (_disposed) return;
      _safeSetState(NotesState.error(e.toString()));
    }
  }
}
```

#### `presentation/providers/note_detail_state.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/note.dart';

part 'note_detail_state.freezed.dart';

/// Note detail state.
@freezed
sealed class NoteDetailState with _$NoteDetailState {
  const factory NoteDetailState.initial() = NoteDetailStateInitial;
  const factory NoteDetailState.loading() = NoteDetailStateLoading;
  const factory NoteDetailState.loaded({
    required Note item,
  }) = NoteDetailStateLoaded;
  const factory NoteDetailState.notFound() = NoteDetailStateNotFound;
  const factory NoteDetailState.error(String message) = NoteDetailStateError;
}
```

#### `presentation/providers/note_detail_notifier.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers.dart';
import 'note_detail_state.dart';

part 'note_detail_notifier.g.dart';

/// Note detail notifier with ID parameter.
@riverpod
final class NoteDetailNotifier extends _$NoteDetailNotifier {
  bool _disposed = false;

  @override
  NoteDetailState build(String id) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _loadItem(id);
    return const NoteDetailState.initial();
  }

  void _safeSetState(NoteDetailState newState) {
    if (!_disposed) state = newState;
  }

  Future<void> _loadItem(String id) async {
    _safeSetState(const NoteDetailState.loading());
    try {
      final repository = ref.read(notesRepositoryProvider);
      final item = await repository.getById(id);
      if (_disposed) return;
      if (item == null) {
        _safeSetState(const NoteDetailState.notFound());
      } else {
        _safeSetState(NoteDetailState.loaded(item: item));
      }
    } catch (e) {
      if (_disposed) return;
      _safeSetState(NoteDetailState.error(e.toString()));
    }
  }

  Future<void> refresh() async => _loadItem(arg);
}
```

#### `presentation/providers/note_form_state.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_form_state.freezed.dart';

/// Note form state for create/edit.
@freezed
abstract class NoteFormState with _$NoteFormState {
  const factory NoteFormState({
    @Default('') String title,
    @Default('') String content,
    @Default(null) String? titleError,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    @Default(null) String? submitError,
  }) = _NoteFormState;
}
```

#### `presentation/providers/note_form_notifier.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/i18n/strings.g.dart';
import '../../../../core/providers.dart';
import '../../domain/entities/note.dart';
import 'note_form_state.dart';

part 'note_form_notifier.g.dart';

/// Note form notifier for create/edit operations.
@riverpod
final class NoteFormNotifier extends _$NoteFormNotifier {
  bool _disposed = false;

  @override
  NoteFormState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const NoteFormState();
  }

  void _safeSetState(NoteFormState newState) {
    if (!_disposed) state = newState;
  }

  void updateTitle(String value) {
    _safeSetState(state.copyWith(title: value, titleError: null));
  }

  void updateContent(String value) {
    _safeSetState(state.copyWith(content: value));
  }

  bool _validate() {
    String? titleError;

    if (state.title.trim().isEmpty) {
      titleError = t.notes.validation.titleRequired;
    }

    _safeSetState(state.copyWith(titleError: titleError));
    return titleError == null;
  }

  Future<void> submit() async {
    if (!_validate()) return;

    _safeSetState(state.copyWith(isSubmitting: true, submitError: null));

    try {
      final repository = ref.read(notesRepositoryProvider);
      final note = Note(
        id: const Uuid().v4(),
        title: state.title.trim(),
        content: state.content.trim().isEmpty ? null : state.content.trim(),
        createdAt: DateTime.now(),
      );
      await repository.create(note);
      if (_disposed) return;
      _safeSetState(state.copyWith(isSubmitting: false, isSuccess: true));
    } catch (e) {
      if (_disposed) return;
      _safeSetState(state.copyWith(
        isSubmitting: false,
        submitError: e.toString(),
      ));
    }
  }
}
```

#### `presentation/screens/notes_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/strings.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/notes_notifier.dart';
import '../providers/notes_state.dart';
import '../widgets/note_list_item.dart';

/// Notes list screen.
final class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notes.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notes/new'),
        child: const Icon(Icons.add),
      ),
      body: switch (state) {
        NotesStateInitial() || NotesStateLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        NotesStateLoaded(:final items) => items.isEmpty
            ? EmptyState(
                icon: Icons.note_outlined,
                message: t.notes.empty,
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(notesNotifierProvider.notifier).refresh(),
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return NoteListItem(
                      item: item,
                      onTap: () => context.push('/notes/${item.id}'),
                      onDelete: () => ref
                          .read(notesNotifierProvider.notifier)
                          .deleteNote(item.id),
                    );
                  },
                ),
              ),
        NotesStateError(:final message) => EmptyState(
            icon: Icons.error_outline,
            message: message,
          ),
      },
    );
  }
}
```

#### `presentation/screens/note_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/strings.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/note.dart';
import '../providers/note_detail_notifier.dart';
import '../providers/note_detail_state.dart';

/// Note detail screen.
final class NoteDetailScreen extends ConsumerWidget {
  const NoteDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noteDetailNotifierProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notes.detail.title),
        actions: [
          if (state is NoteDetailStateLoaded)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/notes/$id/edit'),
            ),
        ],
      ),
      body: switch (state) {
        NoteDetailStateInitial() || NoteDetailStateLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        NoteDetailStateLoaded(:final item) => _DetailContent(item: item),
        NoteDetailStateNotFound() => EmptyState(
            icon: Icons.search_off,
            message: t.notes.notFound,
          ),
        NoteDetailStateError(:final message) => EmptyState(
            icon: Icons.error_outline,
            message: message,
          ),
      },
    );
  }
}

final class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.item});

  final Note item;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(item.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (item.content != null) ...[
            const SizedBox(height: 24),
            Text(item.content!),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

#### `presentation/screens/note_form_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/strings.g.dart';
import '../providers/note_form_notifier.dart';

/// Note form screen for creating new notes.
final class NoteFormScreen extends ConsumerWidget {
  const NoteFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noteFormNotifierProvider);
    final notifier = ref.read(noteFormNotifierProvider.notifier);

    ref.listen(noteFormNotifierProvider, (prev, next) {
      if (next.isSuccess) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notes.form.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: notifier.updateTitle,
              decoration: InputDecoration(
                labelText: t.notes.form.titleLabel,
                errorText: state.titleError,
              ),
              autocorrect: false,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                onChanged: notifier.updateContent,
                decoration: InputDecoration(
                  labelText: t.notes.form.contentLabel,
                  alignLabelWithHint: true,
                ),
                autocorrect: false,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            if (state.submitError != null) ...[
              const SizedBox(height: 16),
              Text(
                state.submitError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: state.isSubmitting ? null : notifier.submit,
                child: state.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.common.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### `presentation/widgets/note_list_item.dart`

```dart
import 'package:flutter/material.dart';

import '../../domain/entities/note.dart';

/// Note list item widget.
final class NoteListItem extends StatelessWidget {
  const NoteListItem({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  final Note item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.note),
      title: Text(item.title),
      subtitle: item.content != null
          ? Text(
              item.content!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: onTap,
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            )
          : null,
    );
  }
}
```

---

## Router Integration

Add to `lib/core/router/app_router.dart`:

```dart
GoRoute(
  path: '/notes',
  builder: (context, state) => const NotesScreen(),
  routes: [
    GoRoute(
      path: 'new',
      builder: (context, state) => const NoteFormScreen(),
    ),
    GoRoute(
      path: ':id',
      builder: (context, state) => NoteDetailScreen(
        id: state.pathParameters['id']!,
      ),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => NoteEditScreen(
            id: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
  ],
),
```

---

## Output Message

After generating presentation layer:

```
Presentation layer complete for `notes`.

Created:
- lib/features/notes/presentation/providers/notes_state.dart
- lib/features/notes/presentation/providers/notes_notifier.dart
- lib/features/notes/presentation/providers/note_detail_state.dart
- lib/features/notes/presentation/providers/note_detail_notifier.dart
- lib/features/notes/presentation/providers/note_form_state.dart
- lib/features/notes/presentation/providers/note_form_notifier.dart
- lib/features/notes/presentation/screens/notes_screen.dart
- lib/features/notes/presentation/screens/note_detail_screen.dart
- lib/features/notes/presentation/screens/note_form_screen.dart
- lib/features/notes/presentation/widgets/note_list_item.dart

Next steps:
1. Run `dart run build_runner build --delete-conflicting-outputs`
2. Add routes to `lib/core/router/app_router.dart`
3. Run `/i18n notes` to add localized strings
4. Run `/design` to polish UI/UX
5. Run `/a11y` to add accessibility
6. Run `/testing notes` to create widget tests
```

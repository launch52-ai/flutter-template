// Template: CRUD notifier with create, delete operations
//
// Location: lib/features/{feature}/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Replace {Feature}/{feature} with feature name
// 3. Replace {Entity} with domain entity name
// 4. Run build_runner

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers.dart';
import '../../domain/entities/{entity}.dart';
import '{feature}_state.dart';

part '{feature}_notifier.g.dart';

/// {Feature} notifier with CRUD operations.
@riverpod
final class {Feature}Notifier extends _${Feature}Notifier {
  bool _disposed = false;

  @override
  {Feature}State build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _load();
    return const {Feature}State.initial();
  }

  void _safeSetState({Feature}State newState) {
    if (!_disposed) state = newState;
  }

  Future<void> _load() async {
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

  /// Refresh items from repository.
  Future<void> refresh() async => _load();

  /// Create a new item.
  Future<void> create({Entity} item) async {
    try {
      final repository = ref.read({feature}RepositoryProvider);
      await repository.create(item);
      if (_disposed) return;
      await _load(); // Reload list after create
    } catch (e) {
      if (_disposed) return;
      _safeSetState({Feature}State.error(e.toString()));
    }
  }

  /// Update an existing item.
  Future<void> update({Entity} item) async {
    try {
      final repository = ref.read({feature}RepositoryProvider);
      await repository.update(item);
      if (_disposed) return;
      await _load(); // Reload list after update
    } catch (e) {
      if (_disposed) return;
      _safeSetState({Feature}State.error(e.toString()));
    }
  }

  /// Delete an item by ID.
  Future<void> delete(String id) async {
    try {
      final repository = ref.read({feature}RepositoryProvider);
      await repository.delete(id);
      if (_disposed) return;
      await _load(); // Reload list after delete
    } catch (e) {
      if (_disposed) return;
      _safeSetState({Feature}State.error(e.toString()));
    }
  }
}

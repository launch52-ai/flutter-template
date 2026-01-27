// Template: Detail notifier with ID parameter
//
// Location: lib/features/{feature}/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Replace {Feature}/{feature} with feature name
// 3. Run build_runner

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers.dart';
import '{feature}_detail_state.dart';

part '{feature}_detail_notifier.g.dart';

/// {Feature} detail notifier with ID parameter.
///
/// Usage: ref.watch({feature}DetailNotifierProvider(id))
@riverpod
final class {Feature}DetailNotifier extends _${Feature}DetailNotifier {
  bool _disposed = false;

  @override
  {Feature}DetailState build(String id) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _loadItem(id);
    return const {Feature}DetailState.initial();
  }

  void _safeSetState({Feature}DetailState newState) {
    if (!_disposed) state = newState;
  }

  /// Load single item by ID.
  Future<void> _loadItem(String id) async {
    _safeSetState(const {Feature}DetailState.loading());

    try {
      final repository = ref.read({feature}RepositoryProvider);
      final item = await repository.getById(id);

      if (_disposed) return;

      if (item == null) {
        _safeSetState(const {Feature}DetailState.notFound());
      } else {
        _safeSetState({Feature}DetailState.loaded(item: item));
      }
    } catch (e) {
      if (_disposed) return;
      _safeSetState({Feature}DetailState.error(e.toString()));
    }
  }

  /// Refresh item from repository.
  /// Uses `arg` to access the ID parameter passed to build().
  Future<void> refresh() async => _loadItem(arg);
}

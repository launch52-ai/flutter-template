// Template: Basic notifier with load and refresh
//
// Location: lib/features/{feature}/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Replace {Feature}/{feature} with feature name
// 3. Run build_runner

import 'package:riverpod_annotation/riverpod_annotation.dart';

// Import from core for repository provider
import '../../../../core/providers.dart';
// Import state - no data layer imports
import '{feature}_state.dart';

part '{feature}_notifier.g.dart';

/// {Feature} notifier with basic load and refresh.
///
/// Key patterns:
/// - _disposed flag prevents state updates after disposal
/// - _safeSetState checks disposal before updating
/// - Check _disposed after every await
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

  /// Safely update state only if not disposed.
  void _safeSetState({Feature}State newState) {
    if (!_disposed) state = newState;
  }

  /// Load items from repository.
  Future<void> _load() async {
    _safeSetState(const {Feature}State.loading());

    try {
      final repository = ref.read({feature}RepositoryProvider);
      final items = await repository.getAll();

      // Always check _disposed after await
      if (_disposed) return;

      _safeSetState({Feature}State.loaded(items: items));
    } catch (e) {
      if (_disposed) return;
      // Use i18n for error messages: t.errors.{errorType}
      _safeSetState({Feature}State.error(e.toString()));
    }
  }

  /// Refresh items from repository.
  Future<void> refresh() async => _load();
}

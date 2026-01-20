// Template: List state with sealed union
//
// Location: lib/features/{feature}/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Replace {Feature} with PascalCase feature name
// 3. Replace {Entity} with domain entity name
// 4. Run build_runner

import 'package:freezed_annotation/freezed_annotation.dart';

// Import domain entity only - no data layer imports
import '../../domain/entities/{entity}.dart';

part '{feature}_state.freezed.dart';

/// {Feature} list state.
///
/// Uses sealed union for exhaustive pattern matching in UI.
/// Only references domain entities - never data layer models.
@freezed
sealed class {Feature}State with _${Feature}State {
  /// Initial state before any data is loaded.
  const factory {Feature}State.initial() = {Feature}StateInitial;

  /// Loading state while fetching data.
  const factory {Feature}State.loading() = {Feature}StateLoading;

  /// Loaded state with items.
  const factory {Feature}State.loaded({
    required List<{Entity}> items,
  }) = {Feature}StateLoaded;

  /// Error state with user-friendly message.
  const factory {Feature}State.error(String message) = {Feature}StateError;
}

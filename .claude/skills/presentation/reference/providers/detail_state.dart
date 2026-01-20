// Template: Detail state with sealed union
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

part '{feature}_detail_state.freezed.dart';

/// {Feature} detail state.
///
/// Includes notFound state for when item doesn't exist.
@freezed
sealed class {Feature}DetailState with _${Feature}DetailState {
  /// Initial state before loading.
  const factory {Feature}DetailState.initial() = {Feature}DetailStateInitial;

  /// Loading state while fetching item.
  const factory {Feature}DetailState.loading() = {Feature}DetailStateLoading;

  /// Loaded state with single item.
  const factory {Feature}DetailState.loaded({
    required {Entity} item,
  }) = {Feature}DetailStateLoaded;

  /// Item not found state.
  const factory {Feature}DetailState.notFound() = {Feature}DetailStateNotFound;

  /// Error state with user-friendly message.
  const factory {Feature}DetailState.error(String message) = {Feature}DetailStateError;
}

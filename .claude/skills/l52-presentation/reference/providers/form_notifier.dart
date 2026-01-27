// Template: Form notifier with validation and submission
//
// Location: lib/features/{feature}/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Replace {Feature}/{feature} with feature name
// 3. Adjust validation rules and fields
// 4. Run build_runner

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/i18n/strings.g.dart';
import '../../../../core/providers.dart';
import '../../domain/entities/{entity}.dart';
import '{feature}_form_state.dart';

part '{feature}_form_notifier.g.dart';

/// {Feature} form notifier for create/edit operations.
///
/// Handles field updates, validation, and submission.
@riverpod
final class {Feature}FormNotifier extends _${Feature}FormNotifier {
  bool _disposed = false;

  @override
  {Feature}FormState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const {Feature}FormState();
  }

  void _safeSetState({Feature}FormState newState) {
    if (!_disposed) state = newState;
  }

  // --- Field Update Methods ---

  /// Update title field and clear its error.
  void updateTitle(String value) {
    _safeSetState(state.copyWith(title: value, titleError: null));
  }

  /// Update description field and clear its error.
  void updateDescription(String value) {
    _safeSetState(state.copyWith(description: value, descriptionError: null));
  }

  // --- Validation ---

  /// Validate all fields. Returns true if valid.
  bool _validate() {
    String? titleError;
    String? descriptionError;

    // Title validation
    if (state.title.trim().isEmpty) {
      titleError = t.{feature}.validation.titleRequired;
    } else if (state.title.trim().length < 3) {
      titleError = t.{feature}.validation.titleTooShort;
    }

    // Description validation (optional field example)
    // Add validation if needed

    _safeSetState(state.copyWith(
      titleError: titleError,
      descriptionError: descriptionError,
    ));

    return titleError == null && descriptionError == null;
  }

  // --- Submission ---

  /// Submit the form.
  Future<void> submit() async {
    if (!_validate()) return;

    _safeSetState(state.copyWith(isSubmitting: true, submitError: null));

    try {
      final repository = ref.read({feature}RepositoryProvider);

      // Create entity from form state
      final entity = {Entity}(
        id: const Uuid().v4(),
        title: state.title.trim(),
        description: state.description.trim().isEmpty
            ? null
            : state.description.trim(),
        createdAt: DateTime.now(),
      );

      await repository.create(entity);

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

  /// Reset form to initial state.
  void reset() {
    _safeSetState(const {Feature}FormState());
  }
}

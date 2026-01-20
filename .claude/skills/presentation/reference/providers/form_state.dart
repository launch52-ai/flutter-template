// Template: Form state with field-based structure
//
// Location: lib/features/{feature}/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Replace {Feature} with PascalCase feature name
// 3. Add/remove fields based on form requirements
// 4. Run build_runner

import 'package:freezed_annotation/freezed_annotation.dart';

part '{feature}_form_state.freezed.dart';

/// {Feature} form state for create/edit operations.
///
/// Uses field-based state (not sealed union) for form handling.
/// Each field has a corresponding error field for validation.
@freezed
abstract class {Feature}FormState with _${Feature}FormState {
  const factory {Feature}FormState({
    // Form fields
    @Default('') String title,
    @Default('') String description,

    // Validation errors (null = no error)
    @Default(null) String? titleError,
    @Default(null) String? descriptionError,

    // Submission state
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    @Default(null) String? submitError,
  }) = _{Feature}FormState;
}

// Extension for convenience getters
extension {Feature}FormStateX on {Feature}FormState {
  /// Whether the form has any validation errors.
  bool get hasErrors => titleError != null || descriptionError != null;

  /// Whether the form can be submitted.
  bool get canSubmit => !isSubmitting && !hasErrors;
}

// Template: Form Validators
//
// Location: lib/core/utils/validators.dart
//
// Features:
// - ValidationError enum for localization support
// - Common validators for email, password, phone, OTP, name
// - Returns enum instead of strings for i18n compatibility

import '../i18n/strings.g.dart';

/// Validation error types returned by validators.
enum ValidationError {
  required,
  invalidEmail,
  invalidPhone,
  invalidOtp,
  otpNotNumeric,
  passwordTooShort,
  nameTooShort,
}

/// Extension to convert ValidationError to localized string.
extension ValidationErrorX on ValidationError {
  /// Get localized error message.
  /// For [ValidationError.required], pass the field name.
  String message([String? fieldName]) {
    return switch (this) {
      ValidationError.required => t.validation.required(field: fieldName ?? ''),
      ValidationError.invalidEmail => t.validation.invalidEmail,
      ValidationError.invalidPhone => t.validation.invalidPhone,
      ValidationError.invalidOtp => t.validation.invalidOtp,
      ValidationError.otpNotNumeric => t.validation.invalidOtp,
      ValidationError.passwordTooShort => t.validation.passwordTooShort,
      ValidationError.nameTooShort => t.validation.nameTooShort,
    };
  }
}

/// Form validators for common input types.
///
/// Returns [ValidationError] enum instead of strings for localization support.
/// Use [ValidationErrorX.message] to get localized string.
///
/// Example:
/// ```dart
/// final error = Validators.validateEmail(value);
/// if (error != null) {
///   return error.message();
/// }
/// ```
final class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  /// Check if email format is valid.
  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }

  /// Validate email input.
  static ValidationError? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationError.required;
    }
    if (!isValidEmail(value)) {
      return ValidationError.invalidEmail;
    }
    return null;
  }

  /// Validate password strength.
  static ValidationError? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationError.required;
    }
    if (value.length < 8) {
      return ValidationError.passwordTooShort;
    }
    return null;
  }

  /// Validate phone number input.
  static ValidationError? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationError.required;
    }
    if (value.length < 10) {
      return ValidationError.invalidPhone;
    }
    return null;
  }

  /// Validate OTP input.
  static ValidationError? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationError.required;
    }
    if (value.length != 6) {
      return ValidationError.invalidOtp;
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return ValidationError.otpNotNumeric;
    }
    return null;
  }

  /// Validate name input (optional field).
  static ValidationError? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Name is optional
    }
    if (value.length < 2) {
      return ValidationError.nameTooShort;
    }
    return null;
  }

  /// Validate required field.
  static ValidationError? validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationError.required;
    }
    return null;
  }
}

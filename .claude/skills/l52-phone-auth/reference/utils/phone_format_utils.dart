// Template: Phone number utilities
//
// Location: lib/features/{feature}/data/utils/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

import 'country.dart';

/// Utility functions for phone number formatting and validation.
final class PhoneFormatUtils {
  PhoneFormatUtils._();

  /// Format phone number according to country pattern.
  ///
  /// [digits] - Raw digit string (e.g., "5551234567")
  /// [country] - Country with format pattern
  ///
  /// Returns formatted string (e.g., "555 123 4567")
  static String format(String digits, Country country) {
    return formatWithPattern(digits, country.format);
  }

  /// Format phone number with a specific pattern.
  ///
  /// [digits] - Raw digit string
  /// [pattern] - Format pattern where # = digit (e.g., "### ### ####")
  static String formatWithPattern(String digits, String pattern) {
    final buffer = StringBuffer();
    var digitIndex = 0;

    for (var i = 0; i < pattern.length && digitIndex < digits.length; i++) {
      if (pattern[i] == '#') {
        buffer.write(digits[digitIndex]);
        digitIndex++;
      } else {
        buffer.write(pattern[i]);
      }
    }

    return buffer.toString();
  }

  /// Convert local number + country to E.164 format.
  ///
  /// [localNumber] - Local phone number (may contain formatting)
  /// [country] - Country with dial code
  ///
  /// Returns E.164 format (e.g., "+15551234567")
  static String toE164(String localNumber, Country country) {
    final digits = extractDigits(localNumber);

    // Remove leading zero if present (common in many countries)
    final normalized = digits.startsWith('0') ? digits.substring(1) : digits;

    return '${country.dialCode}$normalized';
  }

  /// Extract only digits from a string.
  static String extractDigits(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }

  /// Validate E.164 format.
  ///
  /// E.164: + followed by 7-15 digits
  static bool isValidE164(String phone) {
    return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone);
  }

  /// Validate phone number length for a specific country.
  static bool isValidLength(String digits, Country country) {
    final cleanDigits = extractDigits(digits);
    return cleanDigits.length == country.phoneLength;
  }

  /// Validate phone number for a country (length check).
  static bool isValid(String localNumber, Country country) {
    final digits = extractDigits(localNumber);
    return digits.length == country.phoneLength;
  }
}

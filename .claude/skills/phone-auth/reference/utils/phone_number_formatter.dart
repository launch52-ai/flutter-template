// Template: Phone number utilities
//
// Location: lib/features/{feature}/data/utils/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

import 'package:flutter/services.dart';

import 'country.dart';
import 'phone_format_utils.dart';

/// TextInputFormatter that formats phone numbers in real-time.
///
/// Usage:
/// ```dart
/// TextField(
///   keyboardType: TextInputType.phone,
///   inputFormatters: [
///     FilteringTextInputFormatter.digitsOnly,
///     PhoneNumberFormatter(country: selectedCountry),
///   ],
/// )
/// ```
final class PhoneNumberFormatter extends TextInputFormatter {
  final Country country;

  const PhoneNumberFormatter({required this.country});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extract digits only
    final digits = PhoneFormatUtils.extractDigits(newValue.text);

    // Limit to expected length
    final limitedDigits = digits.length > country.phoneLength
        ? digits.substring(0, country.phoneLength)
        : digits;

    // Apply formatting
    final formatted = PhoneFormatUtils.format(limitedDigits, country);

    // Calculate cursor position
    final cursorOffset = _calculateCursorPosition(
      oldValue.text,
      formatted,
      newValue.selection.baseOffset,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: cursorOffset.clamp(0, formatted.length),
      ),
    );
  }

  int _calculateCursorPosition(
    String oldText,
    String newText,
    int oldCursor,
  ) {
    // Count digits before cursor in old text
    final oldDigitsBefore = PhoneFormatUtils.extractDigits(
      oldText.substring(0, oldCursor.clamp(0, oldText.length)),
    ).length;

    // Find position in new text after same number of digits
    var digitCount = 0;
    for (var i = 0; i < newText.length; i++) {
      if (RegExp(r'\d').hasMatch(newText[i])) {
        digitCount++;
        if (digitCount == oldDigitsBefore) {
          return i + 1;
        }
      }
    }

    return newText.length;
  }
}

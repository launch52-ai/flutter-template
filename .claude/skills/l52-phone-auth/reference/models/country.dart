// Template: Freezed DTO model for API serialization
//
// Location: lib/features/{feature}/data/models/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

import 'package:freezed_annotation/freezed_annotation.dart';

part 'country.freezed.dart';
part 'country.g.dart';

/// Country model for phone authentication.
///
/// Contains country information including phone number format pattern.
/// Can be loaded from local JSON asset or fetched from backend API.
@freezed
sealed class Country with _$Country {
  const factory Country({
    /// Country display name (e.g., "United States")
    required String name,

    /// ISO 3166-1 alpha-2 code (e.g., "US")
    required String code,

    /// International dial code with + (e.g., "+1")
    @JsonKey(name: 'dial_code') required String dialCode,

    /// Unicode flag emoji (e.g., "🇺🇸")
    required String flag,

    /// Phone number format pattern where # = digit (e.g., "### ### ####")
    required String format,

    /// Whether country is available for phone auth (for gradual rollout)
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _Country;

  const Country._();

  factory Country.fromJson(Map<String, dynamic> json) => _$CountryFromJson(json);

  /// Expected phone number length (digit count) based on format
  int get phoneLength => format.replaceAll(RegExp(r'[^#]'), '').length;

  /// Hint text for input field (replaces # with X)
  String get hint => format.replaceAll('#', 'X');
}

/// Extension methods for List<Country>
extension CountryListExtensions on List<Country> {
  /// Find country by ISO code (case-insensitive)
  Country? findByCode(String code) {
    final upperCode = code.toUpperCase();
    return where((c) => c.code.toUpperCase() == upperCode).firstOrNull;
  }

  /// Find country by dial code (handles +1 vs 1 variations)
  Country? findByDialCode(String dialCode) {
    final normalized = dialCode.startsWith('+') ? dialCode : '+$dialCode';
    return where((c) => c.dialCode == normalized).firstOrNull;
  }

  /// Get active countries only
  List<Country> get active => where((c) => c.isActive).toList();

  /// Get inactive countries (coming soon)
  List<Country> get inactive => where((c) => !c.isActive).toList();

  /// Search by name, code, or dial code
  List<Country> search(String query) {
    final q = query.toLowerCase();
    return where(
      (c) =>
          c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          c.dialCode.contains(q),
    ).toList();
  }
}

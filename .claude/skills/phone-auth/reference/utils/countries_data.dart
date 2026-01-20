// Template: Utility functions
//
// Location: lib/features/{feature}/data/utils/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

import 'dart:convert';

import 'package:flutter/services.dart';

import 'country.dart';

/// Provides access to countries data.
///
/// Usage:
/// ```dart
/// // Load from local JSON asset (one-time, at app start)
/// await CountriesData.loadFromAsset();
///
/// // Access countries
/// final all = CountriesData.all;
/// final usa = CountriesData.findByCode('US');
/// final results = CountriesData.search('united');
/// ```
final class CountriesData {
  CountriesData._();

  static List<Country> _countries = [];

  /// All loaded countries
  static List<Country> get all => _countries;

  /// Active countries only
  static List<Country> get active => _countries.active;

  /// Inactive countries (coming soon)
  static List<Country> get inactive => _countries.inactive;

  /// Load countries from local JSON asset.
  ///
  /// Call once at app startup (e.g., in main.dart before runApp).
  /// Asset path: assets/data/countries.json
  static Future<void> loadFromAsset({
    String assetPath = 'assets/data/countries.json',
  }) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final jsonList = json.decode(jsonString) as List<dynamic>;
    _countries = jsonList
        .map((e) => Country.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Load countries from a pre-parsed list (e.g., from backend API).
  static void loadFromList(List<Country> countries) {
    _countries = countries..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Find country by ISO code
  static Country? findByCode(String code) => _countries.findByCode(code);

  /// Find country by dial code
  static Country? findByDialCode(String dialCode) =>
      _countries.findByDialCode(dialCode);

  /// Search countries by name, code, or dial code
  static List<Country> search(String query) => _countries.search(query);

  /// Default country (US) - fallback if no country selected
  static Country get defaultCountry =>
      findByCode('US') ??
      const Country(
        name: 'United States',
        code: 'US',
        dialCode: '+1',
        flag: '🇺🇸',
        format: '### ### ####',
      );
}

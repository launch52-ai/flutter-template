// Template: Data source for API/local storage
//
// Location: lib/features/{feature}/data/data_sources/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Local Data Source (SharedPreferences)
// For simple key-value storage of non-sensitive data.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences_model.dart';

final class SettingsLocalDataSource {
  const SettingsLocalDataSource({required SharedPreferences prefs})
      : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _preferencesKey = 'user_preferences';
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale';

  Future<UserPreferencesModel?> getPreferences() async {
    final json = _prefs.getString(_preferencesKey);
    if (json == null) return null;
    return UserPreferencesModel.fromJson(jsonDecode(json));
  }

  Future<void> savePreferences(UserPreferencesModel preferences) async {
    final json = jsonEncode(preferences.toJson());
    await _prefs.setString(_preferencesKey, json);
  }

  Future<String?> getThemeMode() async {
    return _prefs.getString(_themeKey);
  }

  Future<void> saveThemeMode(String theme) async {
    await _prefs.setString(_themeKey, theme);
  }

  Future<void> clearPreferences() async {
    await _prefs.remove(_preferencesKey);
    await _prefs.remove(_themeKey);
    await _prefs.remove(_localeKey);
  }
}

// Template: Shared Preferences Service
//
// Location: lib/core/services/shared_prefs_service.dart
//
// Usage:
// 1. Copy to target location
// 2. Initialize in main.dart before runApp
// 3. Register provider in core/providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_prefs_service.g.dart';

/// Shared preferences for non-sensitive data (flags, settings).
/// Must be initialized before use.
///
/// Example:
/// ```dart
/// // In main.dart:
/// final prefs = await SharedPrefsService.init();
///
/// // Using provider:
/// final prefs = ref.watch(sharedPrefsProvider);
/// prefs.setBool('has_onboarded', true);
/// final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
/// ```
@riverpod
SharedPrefsService sharedPrefs(Ref ref) {
  // This requires initialization in main.dart
  // throw UnimplementedError('SharedPrefsService not initialized');
  return SharedPrefsService._instance!;
}

final class SharedPrefsService {
  SharedPrefsService._(this._prefs);

  final SharedPreferences _prefs;
  static SharedPrefsService? _instance;

  /// Initialize shared preferences.
  /// Call this in main.dart before runApp.
  static Future<SharedPrefsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = SharedPrefsService._(prefs);
    return _instance!;
  }

  /// Get the singleton instance.
  /// Throws if not initialized.
  static SharedPrefsService get instance {
    if (_instance == null) {
      throw StateError('SharedPrefsService not initialized. Call init() first.');
    }
    return _instance!;
  }

  // String
  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);

  // Bool
  bool? getBool(String key) => _prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  // Int
  int? getInt(String key) => _prefs.getInt(key);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  // Double
  double? getDouble(String key) => _prefs.getDouble(key);
  Future<bool> setDouble(String key, double value) => _prefs.setDouble(key, value);

  // String List
  List<String>? getStringList(String key) => _prefs.getStringList(key);
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  // Remove
  Future<bool> remove(String key) => _prefs.remove(key);

  // Clear all
  Future<bool> clear() => _prefs.clear();

  // Contains
  bool containsKey(String key) => _prefs.containsKey(key);

  // Get all keys
  Set<String> getKeys() => _prefs.getKeys();
}

// Template: Secure Storage Service
//
// Location: lib/core/services/secure_storage_service.dart
//
// Usage:
// 1. Copy to target location
// 2. Import storage_keys.dart
// 3. Register provider in core/providers.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_service.g.dart';

/// Secure storage for sensitive data (tokens, PII).
/// Uses platform keychain/keystore.
///
/// Example:
/// ```dart
/// final storage = ref.watch(secureStorageProvider);
/// await storage.write('token', 'abc123');
/// final token = await storage.read('token');
/// ```
@riverpod
SecureStorageService secureStorage(Ref ref) {
  return const SecureStorageService();
}

final class SecureStorageService {
  const SecureStorageService();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Write a value to secure storage.
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a value from secure storage.
  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  /// Delete a value from secure storage.
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Delete all values from secure storage.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if a key exists.
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key: key);
  }

  /// Get all keys.
  Future<Map<String, String>> readAll() async {
    return _storage.readAll();
  }
}

// Template: Data source for API/local storage
//
// Location: lib/features/{feature}/data/data_sources/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Local Data Source (Secure Storage)
// For sensitive data like tokens, credentials.

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

final class AuthLocalDataSource {
  const AuthLocalDataSource({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'current_user';

  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  Future<UserModel?> getCurrentUser() async {
    final json = await _secureStorage.read(key: _userKey);
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json));
  }

  Future<void> saveAuth({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) async {
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
      _secureStorage.write(key: _userKey, value: jsonEncode(user.toJson())),
    ]);
  }

  Future<void> clearAuth() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _userKey),
    ]);
  }

  Future<bool> hasValidAuth() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

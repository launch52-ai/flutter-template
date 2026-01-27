// Template: Push notification repository implementation
//
// Location: lib/features/notifications/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Adjust API endpoints to match your backend
// 3. Register provider in lib/core/providers.dart

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/shared_prefs_service.dart';
import '../../domain/failures/push_notification_failures.dart';
import '../../domain/repositories/push_notification_repository.dart';

/// Implementation of [PushNotificationRepository] with Dio HTTP client.
///
/// Handles:
/// - Token registration with backend API
/// - Topic subscriptions via FCM
/// - Preferences storage (local + backend sync)
final class PushNotificationRepositoryImpl implements PushNotificationRepository {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  final SharedPrefsService _prefs;
  final FirebaseMessaging _messaging;

  const PushNotificationRepositoryImpl(
    this._dio,
    this._secureStorage,
    this._prefs, {
    FirebaseMessaging? messaging,
  }) : _messaging = messaging ?? FirebaseMessaging.instance;

  // For testing
  PushNotificationRepositoryImpl.withMessaging(
    this._dio,
    this._secureStorage,
    this._prefs,
    this._messaging,
  );

  @override
  Future<void> registerToken(String token) async {
    try {
      await _dio.post<void>(
        '/users/push-token',
        data: {'token': token, 'platform': _platform},
      );

      // Cache token locally
      await _secureStorage.write(
        key: StorageKeys.fcmToken,
        value: token,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> unregisterToken() async {
    try {
      final token = await _secureStorage.read(key: StorageKeys.fcmToken);
      if (token == null) return;

      await _dio.delete<void>(
        '/users/push-token',
        data: {'token': token},
      );

      await _secureStorage.delete(key: StorageKeys.fcmToken);
    } on DioException catch (e) {
      // Log but don't throw on logout - best effort
      // Consider: analytics.logError('unregister_token_failed', e);
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);

      // Update local cache
      final topics = await getSubscribedTopics();
      if (!topics.contains(topic)) {
        topics.add(topic);
        await _prefs.setStringList(StorageKeys.subscribedTopics, topics);
      }
    } catch (e) {
      throw TopicSubscriptionFailure(topic);
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);

      // Update local cache
      final topics = await getSubscribedTopics();
      topics.remove(topic);
      await _prefs.setStringList(StorageKeys.subscribedTopics, topics);
    } catch (e) {
      throw TopicSubscriptionFailure(topic);
    }
  }

  @override
  Future<List<String>> getSubscribedTopics() async {
    return _prefs.getStringList(StorageKeys.subscribedTopics) ?? [];
  }

  @override
  Future<void> updatePreferences(Map<String, bool> preferences) async {
    try {
      await _dio.put<void>(
        '/users/notification-preferences',
        data: preferences,
      );

      // Cache locally
      for (final entry in preferences.entries) {
        await _prefs.setBool('pref_notif_${entry.key}', entry.value);
      }
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<Map<String, bool>> getPreferences() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/notification-preferences',
      );

      final prefs = <String, bool>{};
      for (final entry in (response.data ?? {}).entries) {
        if (entry.value is bool) {
          prefs[entry.key] = entry.value as bool;
          // Cache locally
          await _prefs.setBool('pref_notif_${entry.key}', entry.value as bool);
        }
      }
      return prefs;
    } on DioException catch (e) {
      // Return cached preferences on network error
      return _getCachedPreferences();
    }
  }

  Map<String, bool> _getCachedPreferences() {
    // Return default preferences from local cache
    // Adjust categories to match your app
    return {
      'marketing': _prefs.getBool('pref_notif_marketing') ?? true,
      'orders': _prefs.getBool('pref_notif_orders') ?? true,
      'chat': _prefs.getBool('pref_notif_chat') ?? true,
    };
  }

  String get _platform {
    // Platform detection
    // In real app, use dart:io Platform.isIOS / Platform.isAndroid
    return 'mobile'; // or 'ios' / 'android'
  }

  PushNotificationFailure _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NotificationNetworkFailure();
    }

    final statusCode = e.response?.statusCode;
    final errorCode = e.response?.data?['error'] as String?;

    return TokenRegistrationFailure(errorCode ?? 'status_$statusCode');
  }
}

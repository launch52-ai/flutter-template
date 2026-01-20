// Template: Push notification service for FCM initialization
//
// Location: lib/core/services/
//
// Usage:
// 1. Copy to target location
// 2. Initialize in main.dart before runApp
// 3. Adjust notification channel settings as needed

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../features/notifications/data/models/push_notification_payload.dart';

/// Service for managing Firebase Cloud Messaging.
///
/// Handles:
/// - FCM initialization
/// - Token management
/// - Notification display (foreground)
/// - Notification tap handling
///
/// Usage:
/// ```dart
/// // In main.dart
/// await PushNotificationService.initialize();
///
/// // Listen to notification taps
/// PushNotificationService.onNotificationTap.listen((payload) {
///   router.push(payload.deepLinkPath ?? '/');
/// });
/// ```
final class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Stream controller for notification tap events.
  static final _notificationTapController =
      StreamController<PushNotificationPayload>.broadcast();

  /// Stream controller for token refresh events.
  static final _tokenRefreshController = StreamController<String>.broadcast();

  /// Stream of notification tap events.
  ///
  /// Listen to handle deep linking when user taps a notification.
  static Stream<PushNotificationPayload> get onNotificationTap =>
      _notificationTapController.stream;

  /// Stream of FCM token refresh events.
  ///
  /// Listen to send updated token to backend.
  static Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  /// Android notification channel for high importance notifications.
  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  /// Initialize FCM and local notifications.
  ///
  /// Call in main.dart before runApp:
  /// ```dart
  /// await PushNotificationService.initialize();
  /// ```
  static Future<void> initialize() async {
    // Setup local notifications for foreground display
    await _setupLocalNotifications();

    // Setup FCM handlers
    await _setupFCMHandlers();

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  /// Get current FCM token.
  ///
  /// Returns null if permission denied or token unavailable.
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Request notification permission.
  ///
  /// Returns true if permission granted (authorized or provisional).
  static Future<bool> requestPermission({bool provisional = false}) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: provisional,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Check current permission status.
  static Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// Subscribe to a topic for broadcast notifications.
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic.
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Delete FCM token (e.g., on logout).
  static Future<void> deleteToken() async {
    await _messaging.deleteToken();
  }

  // ---------------------------------------------------------------------------
  // PRIVATE SETUP
  // ---------------------------------------------------------------------------

  static Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  static Future<void> _setupFCMHandlers() async {
    // Handle token refresh
    _messaging.onTokenRefresh.listen((token) {
      _tokenRefreshController.add(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay slightly to ensure app is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage);
      });
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Show local notification
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final payload = PushNotificationPayload.fromRemoteMessage(message);
    _notificationTapController.add(payload);
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    final payloadString = response.payload;
    if (payloadString == null) return;

    try {
      final data = jsonDecode(payloadString) as Map<String, dynamic>;
      final payload = PushNotificationPayload(
        type: data['type'] as String?,
        targetId: data['id'] as String? ?? data['target_id'] as String?,
        data: data,
      );
      _notificationTapController.add(payload);
    } catch (e) {
      debugPrint('Failed to parse notification payload: $e');
    }
  }

  /// Dispose resources (call on app termination if needed).
  static void dispose() {
    _notificationTapController.close();
    _tokenRefreshController.close();
  }
}

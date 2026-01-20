// Template: Push notification payload model
//
// Location: lib/features/notifications/data/models/
//
// Usage:
// 1. Copy to target location
// 2. Run build_runner if using Freezed

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'push_notification_payload.freezed.dart';
part 'push_notification_payload.g.dart';

/// Notification payload parsed from FCM message.
///
/// Use [PushNotificationPayload.fromRemoteMessage] to parse FCM messages.
@freezed
sealed class PushNotificationPayload with _$PushNotificationPayload {
  const factory PushNotificationPayload({
    /// Notification title (from notification object or data).
    String? title,

    /// Notification body text.
    String? body,

    /// Notification type for routing (e.g., "order", "chat", "promo").
    String? type,

    /// Target ID for deep linking (e.g., order ID, chat room ID).
    String? targetId,

    /// Additional custom data from the notification.
    @Default({}) Map<String, dynamic> data,

    /// Original message ID from FCM.
    String? messageId,

    /// When the notification was sent.
    DateTime? sentAt,
  }) = _PushNotificationPayload;

  const PushNotificationPayload._();

  factory PushNotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$PushNotificationPayloadFromJson(json);

  /// Parse from FCM [RemoteMessage].
  ///
  /// Extracts title/body from notification object if present,
  /// falls back to data payload fields.
  factory PushNotificationPayload.fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    return PushNotificationPayload(
      title: notification?.title ?? data['title'] as String?,
      body: notification?.body ?? data['body'] as String?,
      type: data['type'] as String?,
      targetId: data['id'] as String? ?? data['target_id'] as String?,
      data: data,
      messageId: message.messageId,
      sentAt: message.sentTime,
    );
  }

  /// Whether this notification has deep link data.
  bool get hasDeepLink => type != null && targetId != null;

  /// Build deep link path from type and targetId.
  ///
  /// Returns null if no deep link data available.
  String? get deepLinkPath {
    if (!hasDeepLink) return null;

    return switch (type) {
      'order' => '/orders/$targetId',
      'chat' => '/chat/$targetId',
      'promo' => '/promotions/$targetId',
      'user' => '/users/$targetId',
      _ => null,
    };
  }
}

/// Notification type enum for type-safe routing.
enum NotificationType {
  order,
  chat,
  promo,
  user,
  general;

  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.general,
    );
  }
}

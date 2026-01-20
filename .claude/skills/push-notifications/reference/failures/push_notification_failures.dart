// Template: Push notification failure types
//
// Location: lib/features/notifications/domain/failures/
//
// Usage:
// 1. Copy to target location
// 2. Import core Failure class

import '../../../../core/errors/failures.dart';

/// Base failure type for push notification errors.
///
/// Extends the core [Failure] type for consistency with the data layer pattern.
/// Map to localized strings in presentation layer using t.errors.notifications.*
sealed class PushNotificationFailure extends Failure {
  const PushNotificationFailure(super.message);
}

/// User denied notification permission.
///
/// Display: t.errors.notifications.permissionDenied
/// Action: Show explanation and link to Settings
final class PermissionDeniedFailure extends PushNotificationFailure {
  const PermissionDeniedFailure()
      : super('Notification permission denied. Enable in Settings.');
}

/// Permission request blocked (iOS: previously denied, Android: "Don't ask again").
///
/// Display: t.errors.notifications.permissionBlocked
/// Action: Direct user to app Settings
final class PermissionBlockedFailure extends PushNotificationFailure {
  const PermissionBlockedFailure()
      : super('Notification permission blocked. Enable in Settings.');
}

/// Failed to retrieve FCM token.
///
/// Display: Log error, retry silently
final class TokenRetrievalFailure extends PushNotificationFailure {
  const TokenRetrievalFailure()
      : super('Failed to get push notification token');
}

/// Failed to register token with backend.
///
/// Display: Silent retry, log error
/// Retry: Yes, with exponential backoff
final class TokenRegistrationFailure extends PushNotificationFailure {
  /// Optional error code from backend.
  final String? errorCode;

  const TokenRegistrationFailure([this.errorCode])
      : super('Failed to register push token with server');
}

/// Network error during token registration.
///
/// Display: Silent retry
/// Retry: Yes, when connectivity restored
final class NotificationNetworkFailure extends PushNotificationFailure {
  const NotificationNetworkFailure()
      : super('Network error. Will retry when connected.');
}

/// Invalid or malformed notification payload.
///
/// Display: Log and ignore
/// Action: None (defensive handling)
final class InvalidPayloadFailure extends PushNotificationFailure {
  /// The raw payload that failed to parse.
  final Map<String, dynamic>? rawPayload;

  const InvalidPayloadFailure([this.rawPayload])
      : super('Invalid notification payload');
}

/// Failed to show local notification (foreground).
///
/// Display: Log error
final class LocalNotificationFailure extends PushNotificationFailure {
  const LocalNotificationFailure()
      : super('Failed to show notification');
}

/// Topic subscription failed.
///
/// Display: Silent retry
final class TopicSubscriptionFailure extends PushNotificationFailure {
  final String topic;

  const TopicSubscriptionFailure(this.topic)
      : super('Failed to subscribe to topic: $topic');
}

// ===========================================================================
// FAILURE MAPPING HELPER
// ===========================================================================

/// Map [PushNotificationFailure] to localized string.
///
/// Usage in presentation layer:
/// ```dart
/// final message = mapPushNotificationFailure(failure, t);
/// ```
///
/// Example implementation:
///
/// ```dart
/// String mapPushNotificationFailure(PushNotificationFailure failure, Translations t) {
///   return switch (failure) {
///     PermissionDeniedFailure() => t.errors.notifications.permissionDenied,
///     PermissionBlockedFailure() => t.errors.notifications.permissionBlocked,
///     TokenRetrievalFailure() => t.errors.notifications.tokenError,
///     TokenRegistrationFailure() => t.errors.notifications.registrationError,
///     NotificationNetworkFailure() => t.errors.network,
///     InvalidPayloadFailure() => t.errors.notifications.invalidPayload,
///     LocalNotificationFailure() => t.errors.notifications.displayError,
///     TopicSubscriptionFailure(:final topic) =>
///       t.errors.notifications.topicError(topic: topic),
///   };
/// }
/// ```

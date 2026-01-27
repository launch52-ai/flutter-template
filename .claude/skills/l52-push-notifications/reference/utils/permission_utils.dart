// Template: Permission utility functions
//
// Location: lib/features/notifications/data/utils/
//
// Usage:
// 1. Copy to target location
// 2. Use for permission status checks and UI decisions

import 'package:firebase_messaging/firebase_messaging.dart';

/// Utility functions for notification permission handling.
final class PermissionUtils {
  PermissionUtils._();

  /// Check if permission allows sending notifications.
  ///
  /// Returns true for authorized or provisional status.
  static bool canSendNotifications(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  /// Check if permission was explicitly denied.
  ///
  /// Use to show "Enable in Settings" prompt.
  static bool isDenied(AuthorizationStatus status) {
    return status == AuthorizationStatus.denied;
  }

  /// Check if permission has not been requested yet.
  static bool isNotDetermined(AuthorizationStatus status) {
    return status == AuthorizationStatus.notDetermined;
  }

  /// Check if provisional permission was granted (iOS).
  ///
  /// Provisional = silent notifications, no permission prompt shown.
  static bool isProvisional(AuthorizationStatus status) {
    return status == AuthorizationStatus.provisional;
  }

  /// Get user-friendly description of permission status.
  ///
  /// Use for UI display or debugging.
  static String describeStatus(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized => 'Notifications enabled',
      AuthorizationStatus.provisional => 'Provisional notifications enabled',
      AuthorizationStatus.denied => 'Notifications disabled',
      AuthorizationStatus.notDetermined => 'Permission not requested',
    };
  }

  /// Get action hint based on permission status.
  ///
  /// Returns suggested action for UI.
  static PermissionAction suggestedAction(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized => PermissionAction.none,
      AuthorizationStatus.provisional => PermissionAction.upgradeToFull,
      AuthorizationStatus.denied => PermissionAction.openSettings,
      AuthorizationStatus.notDetermined => PermissionAction.requestPermission,
    };
  }
}

/// Suggested action based on permission status.
enum PermissionAction {
  /// No action needed - permission granted.
  none,

  /// Request permission (not yet determined).
  requestPermission,

  /// Upgrade from provisional to full (iOS).
  upgradeToFull,

  /// Direct user to app settings (denied).
  openSettings,
}

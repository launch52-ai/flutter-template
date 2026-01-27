// Template: Push notification Riverpod providers
//
// Location: lib/features/notifications/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Import in lib/core/providers.dart
// 3. Run build_runner

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/debug_constants.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../data/repositories/mock_push_notification_repository.dart';
import '../../data/repositories/push_notification_repository_impl.dart';
import '../../domain/repositories/push_notification_repository.dart';

part 'push_notification_providers.g.dart';

// ===========================================================================
// REPOSITORY PROVIDER
// ===========================================================================

/// Provides [PushNotificationRepository] instance.
///
/// Uses mock in debug mode with [DebugConstants.useMockNotifications].
@riverpod
PushNotificationRepository pushNotificationRepository(
  PushNotificationRepositoryRef ref,
) {
  if (DebugConstants.useMockNotifications) {
    return MockPushNotificationRepository();
  }

  return PushNotificationRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
    ref.watch(sharedPrefsProvider),
  );
}

// ===========================================================================
// FCM TOKEN PROVIDER
// ===========================================================================

/// Provides current FCM token.
///
/// Auto-refreshes when token changes.
/// Returns null if permission denied or unavailable.
@riverpod
class FcmToken extends _$FcmToken {
  StreamSubscription<String>? _subscription;

  @override
  Future<String?> build() async {
    // Listen to token refresh
    _subscription = PushNotificationService.onTokenRefresh.listen((token) {
      state = AsyncData(token);
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return PushNotificationService.getToken();
  }

  /// Force refresh token.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final token = await PushNotificationService.getToken();
    state = AsyncData(token);
  }
}

// ===========================================================================
// PERMISSION PROVIDER
// ===========================================================================

/// Provides current notification permission status.
@riverpod
class NotificationPermission extends _$NotificationPermission {
  @override
  Future<AuthorizationStatus> build() async {
    return PushNotificationService.getPermissionStatus();
  }

  /// Request notification permission.
  ///
  /// Returns true if granted.
  Future<bool> request({bool provisional = false}) async {
    final granted = await PushNotificationService.requestPermission(
      provisional: provisional,
    );

    // Refresh state
    state = AsyncData(await PushNotificationService.getPermissionStatus());

    return granted;
  }
}

// ===========================================================================
// TOKEN REGISTRATION NOTIFIER
// ===========================================================================

/// State for token registration.
sealed class TokenRegistrationState {
  const TokenRegistrationState();
}

final class TokenRegistrationInitial extends TokenRegistrationState {
  const TokenRegistrationInitial();
}

final class TokenRegistrationLoading extends TokenRegistrationState {
  const TokenRegistrationLoading();
}

final class TokenRegistrationSuccess extends TokenRegistrationState {
  const TokenRegistrationSuccess();
}

final class TokenRegistrationError extends TokenRegistrationState {
  final String message;
  const TokenRegistrationError(this.message);
}

/// Manages FCM token registration with backend.
///
/// Usage:
/// ```dart
/// // Register token (e.g., after login)
/// await ref.read(tokenRegistrationProvider.notifier).register();
///
/// // Unregister token (e.g., on logout)
/// await ref.read(tokenRegistrationProvider.notifier).unregister();
/// ```
@riverpod
class TokenRegistration extends _$TokenRegistration {
  @override
  TokenRegistrationState build() => const TokenRegistrationInitial();

  /// Register current FCM token with backend.
  Future<void> register() async {
    state = const TokenRegistrationLoading();

    try {
      final token = await ref.read(fcmTokenProvider.future);
      if (token == null) {
        state = const TokenRegistrationError('No FCM token available');
        return;
      }

      final repository = ref.read(pushNotificationRepositoryProvider);
      await repository.registerToken(token);

      state = const TokenRegistrationSuccess();
    } catch (e) {
      state = TokenRegistrationError(e.toString());
    }
  }

  /// Unregister token from backend (call on logout).
  Future<void> unregister() async {
    state = const TokenRegistrationLoading();

    try {
      final repository = ref.read(pushNotificationRepositoryProvider);
      await repository.unregisterToken();
      await PushNotificationService.deleteToken();

      state = const TokenRegistrationInitial();
    } catch (e) {
      state = TokenRegistrationError(e.toString());
    }
  }
}

// ===========================================================================
// TOPIC SUBSCRIPTION PROVIDER
// ===========================================================================

/// Manages topic subscriptions.
@riverpod
class TopicSubscriptions extends _$TopicSubscriptions {
  @override
  Future<List<String>> build() async {
    final repository = ref.watch(pushNotificationRepositoryProvider);
    return repository.getSubscribedTopics();
  }

  /// Subscribe to a topic.
  Future<void> subscribe(String topic) async {
    final repository = ref.read(pushNotificationRepositoryProvider);
    await repository.subscribeToTopic(topic);
    ref.invalidateSelf();
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribe(String topic) async {
    final repository = ref.read(pushNotificationRepositoryProvider);
    await repository.unsubscribeFromTopic(topic);
    ref.invalidateSelf();
  }
}

// ===========================================================================
// NOTIFICATION PREFERENCES PROVIDER
// ===========================================================================

/// Manages notification preferences.
@riverpod
class NotificationPreferences extends _$NotificationPreferences {
  @override
  Future<Map<String, bool>> build() async {
    final repository = ref.watch(pushNotificationRepositoryProvider);
    return repository.getPreferences();
  }

  /// Update a single preference.
  Future<void> setPreference(String category, {required bool enabled}) async {
    final repository = ref.read(pushNotificationRepositoryProvider);
    await repository.updatePreferences({category: enabled});
    ref.invalidateSelf();
  }

  /// Update multiple preferences.
  Future<void> updatePreferences(Map<String, bool> preferences) async {
    final repository = ref.read(pushNotificationRepositoryProvider);
    await repository.updatePreferences(preferences);
    ref.invalidateSelf();
  }
}

# Implementation Guide

Step-by-step push notifications setup with Firebase Cloud Messaging.

---

## Project Structure

Copy reference files to your project:

```
lib/features/notifications/
├── data/
│   ├── models/
│   │   └── push_notification_payload.dart  ← reference/models/
│   └── repositories/
│       └── push_notification_repository_impl.dart  ← implement (see below)
├── domain/
│   ├── failures/
│   │   └── push_notification_failures.dart  ← reference/failures/
│   └── repositories/
│       └── push_notification_repository.dart  ← reference/repositories/
└── presentation/
    └── providers/
        └── push_notification_providers.dart  ← reference/providers/

lib/core/services/
└── push_notification_service.dart  ← reference/services/
```

---

## Setup Steps

### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^3.9.0
  firebase_messaging: ^15.2.0
  flutter_local_notifications: ^18.0.1

dev_dependencies:
  # If not already present
  build_runner: ^2.4.13
```

### 2. iOS Configuration

**Info.plist additions:**

```xml
<!-- ios/Runner/Info.plist -->
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>

<!-- Optional: Disable Firebase swizzling for manual handling -->
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

**Add capabilities in Xcode:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Add "Push Notifications" capability
4. Add "Background Modes" capability → check "Remote notifications"

### 3. Android Configuration

**android/app/build.gradle:**

```gradle
dependencies {
    // Firebase BoM handles versions
    implementation platform('com.google.firebase:firebase-bom:33.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

**android/app/src/main/AndroidManifest.xml:**

```xml
<manifest>
    <application>
        <!-- Default notification channel (required for Android 8+) -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />

        <!-- Optional: Custom notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_notification" />

        <!-- Optional: Custom notification color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
</manifest>
```

### 4. Initialize in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/services/push_notification_service.dart';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message (e.g., update badge, log analytics)
  debugPrint('Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Register background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize push notification service
  await PushNotificationService.initialize();

  runApp(const ProviderScope(child: MyApp()));
}
```

### 5. Generate Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Backend Integration

### Token Registration

Send FCM token to your backend when:
- User logs in
- Token refreshes
- App launches (if user is logged in)

```dart
final class PushNotificationRepositoryImpl implements PushNotificationRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  const PushNotificationRepositoryImpl(this._dio, this._storage);

  @override
  Future<void> registerToken(String token) async {
    try {
      await _dio.post('/users/push-token', data: {'token': token});
      await _storage.write(key: StorageKeys.fcmToken, value: token);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> unregisterToken() async {
    final token = await _storage.read(key: StorageKeys.fcmToken);
    if (token != null) {
      await _dio.delete('/users/push-token', data: {'token': token});
      await _storage.delete(key: StorageKeys.fcmToken);
    }
  }
}
```

### API Contract

```
POST /users/push-token
Request:  { "token": "fcm_token_here" }
Success:  200 { "message": "Token registered" }
Errors:   401 unauthorized, 500 server_error

DELETE /users/push-token
Request:  { "token": "fcm_token_here" }
Success:  200 { "message": "Token removed" }
```

---

## Notification Handling

### Foreground Notifications

Use `flutter_local_notifications` to show notifications when app is in foreground:

```dart
// In PushNotificationService
static Future<void> _setupForegroundHandler() async {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Show local notification
    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      _notificationDetails,
      payload: jsonEncode(message.data),
    );
  });
}
```

### Background/Terminated Notifications

System handles display automatically. Handle tap:

```dart
// When app is in background and user taps notification
FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

// When app was terminated and opened via notification
final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
if (initialMessage != null) {
  _handleNotificationTap(initialMessage);
}
```

### Deep Linking

```dart
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  final type = data['type'];
  final id = data['id'];

  switch (type) {
    case 'order':
      router.push('/orders/$id');
    case 'chat':
      router.push('/chat/$id');
    case 'promo':
      router.push('/promotions/$id');
    default:
      // Open default screen or ignore
      break;
  }
}
```

---

## Permission Handling

Request permission with user-friendly flow:

```dart
Future<bool> requestPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,  // Set true for iOS provisional (silent) notifications
  );

  return settings.authorizationStatus == AuthorizationStatus.authorized ||
         settings.authorizationStatus == AuthorizationStatus.provisional;
}
```

**Best Practice:** Request permission at a contextually relevant moment, not on app launch:
- After user completes onboarding
- When user enables a feature that benefits from notifications
- Show explanation before system prompt

---

## Topic Subscriptions

For broadcasting to user segments:

```dart
// Subscribe to topic
await FirebaseMessaging.instance.subscribeToTopic('promotions');

// Unsubscribe
await FirebaseMessaging.instance.unsubscribeFromTopic('promotions');
```

Common topics:
- `all_users` - App-wide announcements
- `promotions` - Marketing notifications
- `news` - Content updates
- `{user_segment}` - Targeted groups

---

## Reference Files Overview

### Models

**push_notification_payload.dart** - Freezed payload model:
- Fields: `title`, `body`, `data`, `type`, `targetId`
- Factory: `fromRemoteMessage()`

### Services

**push_notification_service.dart** - Static service:
- `initialize()` - Setup FCM and local notifications
- `getToken()` - Get current FCM token
- `onTokenRefresh` - Stream of token updates
- `onNotificationTap` - Stream of tap events
- `requestPermission()` - Request notification permission

### Providers

**push_notification_providers.dart** - Riverpod providers:
- `pushNotificationServiceProvider` - Service instance
- `fcmTokenProvider` - Current token (auto-refresh)
- `notificationPermissionProvider` - Permission state

### Failures

**push_notification_failures.dart** - Sealed types:
- `PermissionDeniedFailure`
- `TokenRegistrationFailure`
- `NotificationNetworkFailure`
- `InvalidPayloadFailure`

---

## Testing

### Manual Testing

1. **Get FCM token:**
   ```dart
   final token = await FirebaseMessaging.instance.getToken();
   print('FCM Token: $token');
   ```

2. **Send test notification via Firebase Console:**
   - Firebase Console → Cloud Messaging → Send your first message
   - Enter title, body
   - Select target: Single device → paste token
   - Send

3. **Test all states:**
   - App in foreground
   - App in background
   - App terminated

### Automated Testing

```dart
// Mock the service
final mockService = MockPushNotificationService();
container = ProviderContainer(overrides: [
  pushNotificationServiceProvider.overrideWithValue(mockService),
]);

// Verify token registration
when(() => mockService.getToken()).thenAnswer((_) async => 'test_token');
await notifier.registerToken();
verify(() => repository.registerToken('test_token')).called(1);
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| No token on iOS | APNs not configured | Upload APNs key to Firebase |
| Token is null | Permission denied | Request permission first |
| No foreground notification | Not using local_notifications | Setup flutter_local_notifications |
| Background handler not called | Not registered before runApp | Move to top of main() |
| Deep link not working | Router not handling path | Check route configuration |

---

## Related

- [firebase-setup-guide.md](firebase-setup-guide.md) - Firebase Console setup
- [checklist.md](checklist.md) - Implementation verification
- `/release` - iOS capabilities
- `/design` - Notification UI patterns

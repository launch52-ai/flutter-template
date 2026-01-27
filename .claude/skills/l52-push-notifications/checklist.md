# Push Notifications Checklist

Verification checklist for push notifications implementation.

---

## Firebase Console

- [ ] Firebase project created
- [ ] iOS app added with correct bundle ID
- [ ] Android app added with correct package name
- [ ] APNs authentication key uploaded (iOS)
- [ ] SHA-1 fingerprints added (Android): debug, release, Play Store

## Config Files

- [ ] `GoogleService-Info.plist` added to `ios/Runner/`
- [ ] `google-services.json` added to `android/app/`
- [ ] Files added to Xcode project (not just filesystem)
- [ ] Files excluded from public git repos (if applicable)

## iOS Configuration

- [ ] Push Notifications capability added in Xcode
- [ ] Background Modes capability added
- [ ] "Remote notifications" checked in Background Modes
- [ ] `UIBackgroundModes` in Info.plist includes `remote-notification`
- [ ] `FirebaseAppDelegateProxyEnabled` set if needed

## Android Configuration

- [ ] Firebase BOM added to `android/app/build.gradle`
- [ ] `firebase-messaging` dependency added
- [ ] Default notification channel configured in AndroidManifest
- [ ] Notification icon configured (optional)
- [ ] `google-services` plugin applied

## Dependencies

- [ ] `firebase_core` added to pubspec.yaml
- [ ] `firebase_messaging` added to pubspec.yaml
- [ ] `flutter_local_notifications` added (for foreground display)
- [ ] `pub get` run successfully

## Code Implementation

- [ ] Firebase initialized in main.dart
- [ ] Background message handler registered before runApp
- [ ] `PushNotificationService.initialize()` called
- [ ] FCM token retrieval working
- [ ] Token refresh listener configured
- [ ] Token sent to backend on login
- [ ] Token removed on logout

## Notification Handling

- [ ] Foreground handler shows local notification
- [ ] Background notifications displayed by system
- [ ] Tap handler navigates correctly
- [ ] `getInitialMessage` checked on app launch
- [ ] Deep linking works from notification tap

## Permission Flow

- [ ] Permission requested at appropriate time
- [ ] Permission denied case handled
- [ ] Settings redirect available if needed
- [ ] Permission state persisted

## Testing

- [ ] FCM token logged/visible during development
- [ ] Test notification sent from Firebase Console
- [ ] Notification received with app in foreground
- [ ] Notification received with app in background
- [ ] Notification received with app terminated
- [ ] Tap opens correct screen (deep linking)
- [ ] Tested on physical iOS device
- [ ] Tested on physical Android device

## Production Readiness

- [ ] Production Firebase project configured
- [ ] Production APNs key uploaded
- [ ] Release SHA-1 added to Firebase
- [ ] Play Store SHA-1 added (if using Play App Signing)
- [ ] Error logging/analytics for notification failures
- [ ] Config files secured in CI/CD

---

## Quick Verification Commands

```bash
# Check iOS config file
ls ios/Runner/GoogleService-Info.plist

# Check Android config file
ls android/app/google-services.json

# Get debug SHA-1
cd android && ./gradlew signingReport | grep -A 1 "Variant: debug"

# Run build_runner
dart run build_runner build --delete-conflicting-outputs
```

## Test Notification Payload

Use this payload in Firebase Console "Additional options" → "Custom data":

```json
{
  "type": "test",
  "id": "12345",
  "screen": "home"
}
```

---

## Related

- [implementation-guide.md](implementation-guide.md) - Code setup
- [firebase-setup-guide.md](firebase-setup-guide.md) - Firebase configuration

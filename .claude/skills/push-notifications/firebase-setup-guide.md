# Firebase Setup Guide

Firebase Console and APNs configuration for push notifications.

---

## Firebase Project Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., "MyApp Production")
4. Enable/disable Google Analytics (recommended: enable)
5. Select or create Analytics account
6. Click "Create project"

### 2. Add iOS App

1. In Firebase Console, click iOS icon (or "+ Add app")
2. Enter iOS bundle ID (e.g., `com.company.myapp`)
   - Find in Xcode: Runner target → General → Bundle Identifier
3. Enter App nickname (optional)
4. Enter App Store ID (optional, add later)
5. Click "Register app"
6. Download `GoogleService-Info.plist`
7. Add to Xcode project:
   - Drag to `ios/Runner/` folder
   - Check "Copy items if needed"
   - Select "Runner" target
8. Skip SDK steps (Flutter handles this)

### 3. Add Android App

1. In Firebase Console, click Android icon (or "+ Add app")
2. Enter Android package name (e.g., `com.company.myapp`)
   - Find in `android/app/build.gradle`: `applicationId`
3. Enter App nickname (optional)
4. Enter SHA-1 fingerprint (required for some features):
   ```bash
   cd android && ./gradlew signingReport
   ```
   Copy the SHA-1 for `debug` variant
5. Click "Register app"
6. Download `google-services.json`
7. Place in `android/app/google-services.json`
8. Skip SDK steps (Flutter handles this)

---

## APNs Configuration (iOS)

Push notifications on iOS require Apple Push Notification service (APNs) authentication.

### Option 1: APNs Key (Recommended)

APNs keys never expire and work for all apps in your Apple Developer account.

**Create APNs Key:**

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to Certificates, Identifiers & Profiles → Keys
3. Click "+" to create new key
4. Enter Key Name (e.g., "FCM Push Key")
5. Check "Apple Push Notifications service (APNs)"
6. Click "Continue" → "Register"
7. **Download the .p8 file** (can only download once!)
8. Note the **Key ID** (10 characters)

**Upload to Firebase:**

1. Firebase Console → Project Settings → Cloud Messaging
2. Under "Apple app configuration", click "Upload" for APNs Authentication Key
3. Upload the .p8 file
4. Enter Key ID
5. Enter Team ID (found in Apple Developer Portal → Membership)

### Option 2: APNs Certificate (Legacy)

Certificates expire annually and are app-specific.

**Create APNs Certificate:**

1. Apple Developer Portal → Certificates, Identifiers & Profiles
2. Identifiers → Select your App ID
3. Under Capabilities, enable "Push Notifications"
4. Click "Configure" next to Push Notifications
5. Create Production SSL Certificate:
   - Open Keychain Access on Mac
   - Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority
   - Enter email, select "Saved to disk"
   - Upload CSR file to Apple
   - Download certificate
6. Double-click to install in Keychain
7. Export as .p12 (Keychain → right-click certificate → Export)

**Upload to Firebase:**

1. Firebase Console → Project Settings → Cloud Messaging
2. Under "Apple app configuration", click "Upload" for APNs Certificates
3. Upload .p12 file with password

---

## Android SHA-1 Fingerprints

### Debug SHA-1

Used for development builds:

```bash
cd android && ./gradlew signingReport
```

Look for `Variant: debug` section and copy SHA-1.

### Release SHA-1

Used for production builds. If using a keystore:

```bash
keytool -list -v -keystore /path/to/release-keystore.jks -alias alias_name
```

### Play Store SHA-1

If using Play App Signing (recommended):

1. Google Play Console → Your App → Setup → App integrity
2. Copy SHA-1 from "App signing key certificate"

**Add all SHA-1s to Firebase:**

1. Firebase Console → Project Settings → Your apps → Android app
2. Click "Add fingerprint"
3. Paste each SHA-1

---

## Environment Setup

### Multiple Environments

For separate development/staging/production:

**Option 1: Separate Firebase Projects (Recommended)**

Create separate Firebase projects:
- `myapp-dev`
- `myapp-staging`
- `myapp-prod`

Use `--dart-define` or flavor configuration to load correct config file.

**Option 2: Multiple Apps in One Project**

Add multiple iOS/Android apps with different bundle IDs:
- `com.company.myapp.dev`
- `com.company.myapp.staging`
- `com.company.myapp`

### FlutterFire CLI (Optional)

Automates Firebase configuration:

```bash
# Install
dart pub global activate flutterfire_cli

# Configure (generates firebase_options.dart)
flutterfire configure
```

---

## Verification

### Test Firebase Connection

```dart
// In your app
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('FCM Token: $token');  // Should print a token

  runApp(MyApp());
}
```

### Test Push Notification

1. Firebase Console → Cloud Messaging → Compose notification
2. Enter notification title and text
3. Click "Send test message"
4. Paste FCM token
5. Click "Test"

**Expected result:** Notification appears on device (may need app in background).

---

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| No FCM token on iOS | APNs not configured | Upload APNs key to Firebase |
| "FIRMessagingDevelopment" error | Using development profile | This is normal for debug builds |
| Token null on simulator | APNs unavailable | Test on physical device |
| Notifications not received | Permission denied | Check app settings on device |
| Android token works, iOS doesn't | APNs certificate issue | Re-upload APNs key |

---

## Security Notes

- **Never commit** `GoogleService-Info.plist` or `google-services.json` to public repos
- Add to `.gitignore` for open-source projects:
  ```
  ios/Runner/GoogleService-Info.plist
  android/app/google-services.json
  ```
- For CI/CD, store as encrypted secrets and inject during build

---

## Related

- [implementation-guide.md](implementation-guide.md) - Code setup
- [checklist.md](checklist.md) - Verification checklist
- `/release` - App signing and capabilities

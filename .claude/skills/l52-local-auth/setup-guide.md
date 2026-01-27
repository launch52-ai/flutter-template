# Local Auth - Platform Setup Guide

Complete platform configuration for iOS and Android.

---

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  local_auth: ^2.3.0
```

Run:

```bash
flutter pub get
```

---

## iOS Setup

### 1. Face ID Usage Description (Required)

Add to `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to securely unlock the app</string>
```

**Note:** This is required even if you only support Touch ID. The system shows this message when Face ID is used.

### 2. Capabilities (Optional)

For Keychain-based biometric state tracking (banking-grade security), ensure the app has Keychain Sharing capability enabled in Xcode.

### 3. Testing in Simulator

Face ID and Touch ID work in the simulator:

**Face ID:**
1. Simulator menu > Features > Face ID > Enrolled
2. To trigger: Features > Face ID > Matching Face / Non-matching Face

**Touch ID:**
1. Simulator menu > Features > Touch ID > Enrolled
2. Hardware > Touch ID > Simulate Finger Touch

---

## Android Setup

### 1. Permissions (Required)

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Biometric authentication -->
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>

    <!-- For older devices (API < 28) -->
    <uses-permission android:name="android.permission.USE_FINGERPRINT"/>

    <!-- ... rest of manifest -->
</manifest>
```

### 2. MainActivity Configuration

For banking-grade security with Keystore-backed keys, update `android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
package com.example.yourapp

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    // FlutterFragmentActivity is required for BiometricPrompt
}
```

**Important:** Use `FlutterFragmentActivity` instead of `FlutterActivity` for proper BiometricPrompt support.

### 3. Minimum SDK

Ensure `minSdkVersion` is at least 23 (Android 6.0) in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 23  // Required for fingerprint API
        // ...
    }
}
```

### 4. Testing in Emulator

1. Open Extended Controls (three dots in emulator toolbar)
2. Go to Fingerprint section
3. Click "Touch Sensor" to simulate fingerprint

---

## Verification

After setup, verify platform configuration:

```dart
import 'package:local_auth/local_auth.dart';

final localAuth = LocalAuthentication();

// Check if device supports any authentication
final isSupported = await localAuth.isDeviceSupported();
print('Device supported: $isSupported');

// Check what biometrics are available
final biometrics = await localAuth.getAvailableBiometrics();
print('Available biometrics: $biometrics');

// Check if any biometric is enrolled
final canCheck = await localAuth.canCheckBiometrics;
print('Can check biometrics: $canCheck');
```

### Expected Results

| Check | iOS (with Face ID) | Android (with fingerprint) |
|-------|-------------------|---------------------------|
| `isDeviceSupported` | true | true |
| `canCheckBiometrics` | true | true |
| `getAvailableBiometrics` | [face] | [fingerprint] |

---

## Troubleshooting

### "LocalAuthentication not available"

**iOS:** Ensure `NSFaceIDUsageDescription` is in Info.plist.

**Android:** Ensure permissions are in AndroidManifest.xml and using `FlutterFragmentActivity`.

### BiometricPrompt crashes on Android

Switch from `FlutterActivity` to `FlutterFragmentActivity` in MainActivity.

### "No biometrics enrolled"

User has device passcode but no biometric enrolled. This is normal - use `isDeviceSupported()` to check if device credentials are available as fallback.

### Simulator shows "Not Enrolled"

Enable biometrics in simulator settings before testing:
- iOS: Features > Face ID > Enrolled
- Android: Extended Controls > Fingerprint

---

## Platform-Specific Behavior

### iOS

| Scenario | Behavior |
|----------|----------|
| Face ID enrolled | Shows Face ID prompt |
| Touch ID enrolled | Shows Touch ID prompt |
| Only passcode | Falls back to passcode (if `biometricOnly: false`) |
| Multiple failures | System lockout with timer |

### Android

| Scenario | Behavior |
|----------|----------|
| Fingerprint enrolled | Shows BiometricPrompt with fingerprint |
| Face unlock enrolled | Shows BiometricPrompt with face |
| Only PIN/pattern | Falls back to device credential |
| Multiple failures | 30-second lockout after 5 attempts |

---

## Next Steps

After platform setup:
1. Read [security-guide.md](security-guide.md) for security level configuration
2. Read [patterns-guide.md](patterns-guide.md) for usage patterns
3. Copy reference files to project

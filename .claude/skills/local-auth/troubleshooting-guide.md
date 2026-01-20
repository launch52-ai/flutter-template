# Local Auth - Troubleshooting Guide

Common issues and solutions for local authentication.

---

## iOS Issues

### iOS Simulator - Biometrics Not Working

Face ID/Touch ID don't work in simulator by default.

**Face ID:**
1. Simulator menu > Features > Face ID > Enrolled
2. To trigger success: Features > Face ID > Matching Face
3. To trigger failure: Features > Face ID > Non-matching Face

**Touch ID:**
1. Simulator menu > Features > Touch ID > Enrolled
2. Hardware > Touch ID > Simulate Finger Touch

### "LocalAuthentication not available" on iOS

Ensure `NSFaceIDUsageDescription` is added to `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to securely unlock the app</string>
```

---

## Android Issues

### Android Emulator - Fingerprint Not Working

1. Open Extended Controls (three dots in emulator toolbar)
2. Go to Fingerprint section
3. Click "Touch Sensor" to simulate fingerprint

### BiometricPrompt Crashes on Android

Switch from `FlutterActivity` to `FlutterFragmentActivity` in MainActivity:

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    // FlutterFragmentActivity is required for BiometricPrompt
}
```

### "USE_BIOMETRIC" Permission Error

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

---

## Common Errors

### "Not Enrolled" Error

**Cause:** User has device passcode but no biometric enrolled.

**Solution:** Check both capabilities separately:

```dart
// Check if device supports any auth (including passcode)
final isSupported = await localAuth.isDeviceSupported();

// Check if biometrics specifically are available
final canBiometric = await localAuth.canCheckBiometrics;

// Use device credentials as fallback
final result = await localAuth.authenticate(
  localizedReason: 'Unlock',
  options: AuthenticationOptions(biometricOnly: false),
);
```

### Authentication Cancelled vs Failed

**Cancelled:** User tapped outside dialog or pressed back. This is NOT an error - handle silently.

**Failed:** User attempted auth but it didn't match. Show error with retry option.

```dart
final result = await localAuthService.authenticate(reason: 'Unlock');

if (result.isCancelled) {
  // Silent - user chose to cancel
  return;
}

if (!result.success) {
  // Show error
  showSnackBar('Authentication failed');
}
```

### Banking Apps: Biometric Change Detection

**Problem:** User adds new fingerprint and gains access to app.

**Solution:** Use `BiometricStateTracker` to detect enrollment changes:

```dart
final changed = await biometricStateTracker.didBiometricsChange();
if (changed) {
  // Force full re-login
  await authNotifier.signOut();
}
```

**iOS:** Track `LAContext.evaluatedPolicyDomainState` hash.

**Android:** Use Keystore key with `setInvalidatedByBiometricEnrollment(true)`.

See `reference/utils/biometric_state_tracker.dart` for full implementation.

---

## Platform-Specific Behavior

### iOS Lockout

- After 5 failed Face ID attempts: Falls back to passcode
- After multiple passcode failures: Device locks with increasing timeouts

### Android Lockout

- After 5 failed biometric attempts: 30-second lockout
- `permanentlyLockedOut`: Requires device unlock before biometrics work again

---

## Testing Checklist

- [ ] Test on real iOS device (not just simulator)
- [ ] Test on real Android device (not just emulator)
- [ ] Test with biometric enrolled
- [ ] Test without biometric (passcode only)
- [ ] Test cancellation (press back/outside)
- [ ] Test multiple failures
- [ ] Test lockout recovery
- [ ] Test app backgrounding and timeout

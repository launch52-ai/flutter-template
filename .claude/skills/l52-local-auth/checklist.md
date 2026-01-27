# Local Auth - Implementation Checklist

Complete checklist for local authentication implementation.

---

## Platform Setup

### iOS

- [ ] `local_auth: ^2.3.0` added to pubspec.yaml
- [ ] `NSFaceIDUsageDescription` added to Info.plist
- [ ] Usage description is user-friendly (not technical)
- [ ] Tested Face ID in simulator (Features > Face ID > Enrolled)
- [ ] Tested Touch ID in simulator (if supporting older devices)

### Android

- [ ] `USE_BIOMETRIC` permission in AndroidManifest.xml
- [ ] `USE_FINGERPRINT` permission (for API < 28)
- [ ] MainActivity extends `FlutterFragmentActivity`
- [ ] minSdkVersion is at least 23
- [ ] Tested fingerprint in emulator (Extended Controls > Fingerprint)

---

## Core Implementation

### LocalAuthService

- [ ] Created `LocalAuthService` class
- [ ] Implements `canAuthenticate()` check
- [ ] Implements `getAvailableBiometrics()`
- [ ] Implements `authenticate()` with proper options
- [ ] Handles `biometricOnly: false` for device credential fallback
- [ ] Returns structured result (success, cancelled, lockout, error)
- [ ] Cancellation is NOT treated as error

### LocalAuthNotifier

- [ ] Created provider with Riverpod
- [ ] Manages `LocalAuthState` transitions
- [ ] Tracks background duration
- [ ] Respects timeout settings
- [ ] Handles auth failures gracefully

### LocalAuthSettings

- [ ] Stores `enabled` preference
- [ ] Stores `timeout` preference (minutes)
- [ ] Uses SharedPreferences (not secure storage - not sensitive)
- [ ] Provides timeout options (immediate, 1m, 5m, 15m, 30m, never)

---

## Optional: Lock Screen

- [ ] Created `LockScreen` widget
- [ ] Shows biometric prompt automatically on appear
- [ ] Has manual "Unlock" button for retry
- [ ] Shows appropriate icon (Face ID vs Touch ID vs fingerprint)
- [ ] Shows error state with retry option
- [ ] Shows lockout state with message
- [ ] Handles "Use Passcode" fallback gracefully

---

## Optional: Settings Toggle

- [ ] Created `LocalAuthToggle` widget
- [ ] Checks if biometric is available before enabling toggle
- [ ] Requires successful auth before enabling
- [ ] Shows appropriate subtitle (available/not available)
- [ ] Created `LocalAuthTimeoutSelector` widget
- [ ] Shows timeout selector only when enabled

---

## Optional: App PIN

- [ ] Created `AppPinService`
- [ ] PIN hash stored in secure storage (not plain text!)
- [ ] Uses proper hashing (SHA-256 minimum, bcrypt preferred)
- [ ] Created PIN entry UI
- [ ] Created PIN setup flow
- [ ] Clears PIN on logout
- [ ] Rate limits PIN attempts

---

## Optional: Banking-Grade Security

- [ ] Created `BiometricStateTracker`
- [ ] iOS: Tracks `evaluatedPolicyDomainState` hash
- [ ] Android: Uses Keystore with `setInvalidatedByBiometricEnrollment(true)`
- [ ] Stores biometric state hash in secure storage
- [ ] Checks for changes on app launch
- [ ] Forces full re-login when biometrics change
- [ ] Clears stored state on logout

---

## App Lifecycle

- [ ] Created lifecycle observer (`WidgetsBindingObserver`)
- [ ] Tracks `DateTime` when app goes to background
- [ ] Calculates background duration on resume
- [ ] Triggers auth check based on timeout setting
- [ ] Observer properly disposed

---

## Integration

- [ ] App shell checks auth state before showing content
- [ ] Lock screen shown when `requiresAuth`
- [ ] Login screen shown when `requiresFullLogin`
- [ ] Sensitive actions use `withLocalAuth()` or similar
- [ ] Auth prompt strings are localized

---

## Error Handling

- [ ] `LocalAuthNotAvailable` - Shows setup prompt
- [ ] `LocalAuthNotEnrolled` - Links to device settings
- [ ] `LocalAuthFailed` - Shows retry option
- [ ] `LocalAuthCancelled` - Silent (not shown as error)
- [ ] `LocalAuthLockout` - Shows countdown/message
- [ ] `BiometricsChanged` - Forces full re-login (banking-grade)

---

## Testing

### Real Device

- [ ] Face ID works (iPhone X+)
- [ ] Touch ID works (older iPhones, iPads)
- [ ] Android fingerprint works
- [ ] Android face unlock works (if available)
- [ ] Device credential fallback works
- [ ] Cancellation works (no error shown)

### Edge Cases

- [ ] App backgrounded < timeout - no auth required
- [ ] App backgrounded > timeout - auth required
- [ ] First launch after install - auth based on settings
- [ ] User disables biometric in device settings - handled
- [ ] User adds new fingerprint/face - handled (banking-grade)

### Simulator/Emulator

- [ ] iOS simulator with enrolled Face ID works
- [ ] iOS simulator "Non-matching face" shows error
- [ ] Android emulator fingerprint works
- [ ] "Not enrolled" state handled gracefully

---

## Localization

- [ ] Unlock prompt string (e.g., "Unlock App Name")
- [ ] Enable reason string (e.g., "Verify to enable biometric login")
- [ ] Confirm action strings (e.g., "Confirm payment")
- [ ] Error messages localized
- [ ] Settings labels localized
- [ ] Timeout options localized

---

## Final Verification

```bash
# Run skill check script
dart run .claude/skills/local-auth/scripts/check.dart

# Run app tests
flutter test

# Test on real device
flutter run
```

---

## Common Mistakes to Avoid

| Mistake | Correct Approach |
|---------|------------------|
| Treating cancellation as error | Return silent, don't show error |
| Storing PIN in SharedPreferences | Use flutter_secure_storage with hash |
| Skipping `FlutterFragmentActivity` | Required for BiometricPrompt on Android |
| Only checking `canCheckBiometrics` | Also check `isDeviceSupported` for PIN fallback |
| Hardcoded auth prompt strings | Use i18n strings |
| Not disposing lifecycle observer | Dispose in `StatefulWidget.dispose()` |
| Checking biometrics before login | Only check after user is logged in |

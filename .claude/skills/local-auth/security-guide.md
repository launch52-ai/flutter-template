# Local Auth - Security Guide

Security levels and biometric change detection for different app requirements.

---

## Security Levels

### Level 1: Simple (Default)

Trust any enrolled biometric on the device. Suitable for:
- Social media apps
- Content apps
- Low-risk features

```dart
// Simple authentication - any enrolled biometric works
final success = await localAuthService.authenticate(
  reason: 'Unlock app',
  biometricOnly: false,
);
```

**Risk:** Device owner can add new fingerprint/face and access app.

### Level 2: Banking-Grade

Detect biometric changes and require full re-authentication. Suitable for:
- Banking/finance apps
- Healthcare apps
- Apps with PII/sensitive data
- Password managers

```dart
// Check if biometrics changed since last auth
final changed = await biometricStateTracker.didBiometricsChange();
if (changed) {
  // Force full re-login
  await authNotifier.signOut();
  // Navigate to login screen
}
```

---

## Biometric Change Detection

### How It Works

**iOS (LAContext):**
- `evaluatedPolicyDomainState` returns opaque data representing enrolled biometrics
- Changes when fingerprints/faces are added or removed
- Store hash and compare on app launch

**Android (Keystore):**
- Create a key with `setUserAuthenticationRequired(true)` and `setInvalidatedByBiometricEnrollment(true)`
- Key becomes invalid when biometrics change
- Attempting to use invalid key throws `KeyPermanentlyInvalidatedException`

### Implementation

```dart
/// Tracks biometric enrollment state for banking-grade security.
final class BiometricStateTracker {
  final SecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const _stateKey = 'biometric_state_hash';

  /// Check if biometrics changed since last successful auth.
  ///
  /// Returns true if:
  /// - New fingerprint/face was added
  /// - Existing fingerprint/face was removed
  /// - First time checking (no stored state)
  Future<bool> didBiometricsChange() async {
    if (Platform.isIOS) {
      return _checkiOSBiometricState();
    } else if (Platform.isAndroid) {
      return _checkAndroidBiometricState();
    }
    return false;
  }

  /// Store current biometric state after successful auth.
  Future<void> saveCurrentState() async {
    if (Platform.isIOS) {
      await _saveiOSBiometricState();
    }
    // Android uses Keystore which auto-invalidates
  }

  /// Clear stored state (call on logout).
  Future<void> clearState() async {
    await _storage.delete(_stateKey);
  }
}
```

### iOS Implementation

```dart
Future<bool> _checkiOSBiometricState() async {
  // Get current biometric state from LAContext
  // This requires platform channel - see reference implementation
  final currentState = await _getBiometricDomainState();

  if (currentState == null) {
    return false; // No biometrics enrolled
  }

  final storedHash = await _storage.read(_stateKey);
  if (storedHash == null) {
    return true; // First time - treat as "changed"
  }

  final currentHash = _hashState(currentState);
  return currentHash != storedHash;
}

Future<void> _saveiOSBiometricState() async {
  final currentState = await _getBiometricDomainState();
  if (currentState != null) {
    final hash = _hashState(currentState);
    await _storage.write(_stateKey, hash);
  }
}
```

### Android Implementation

```dart
Future<bool> _checkAndroidBiometricState() async {
  // Try to use the stored key
  // If biometrics changed, key is invalid
  try {
    await _useAuthBoundKey();
    return false; // Key valid - no change
  } on KeyPermanentlyInvalidatedException {
    return true; // Biometrics changed
  } catch (e) {
    return false; // Other error
  }
}
```

---

## Failure Behavior Configuration

### Option 1: Force Full Re-Login

After N failed attempts or lockout, clear session and require remote authentication.

```dart
final class LocalAuthNotifier extends _$LocalAuthNotifier {
  static const _maxAttempts = 3;
  int _failedAttempts = 0;

  Future<bool> authenticate() async {
    final result = await _localAuthService.authenticate(
      reason: t.localAuth.unlockReason,
    );

    if (!result.success) {
      _failedAttempts++;

      if (_failedAttempts >= _maxAttempts || result.isLockout) {
        // Force full re-login
        await ref.read(authNotifierProvider.notifier).signOut();
        state = const LocalAuthState.requiresFullLogin();
        return false;
      }

      state = LocalAuthState.failed(
        attemptsRemaining: _maxAttempts - _failedAttempts,
      );
      return false;
    }

    _failedAttempts = 0;
    state = const LocalAuthState.authenticated();
    return true;
  }
}
```

### Option 2: Let Device Handle Lockout

Trust the device's lockout mechanism (recommended for most apps).

```dart
Future<bool> authenticate() async {
  final result = await _localAuthService.authenticate(
    reason: t.localAuth.unlockReason,
  );

  if (result.isLockout) {
    state = LocalAuthState.lockedOut(
      message: t.localAuth.tooManyAttempts,
    );
    return false;
  }

  if (!result.success) {
    // Just show error, let user retry
    state = const LocalAuthState.failed();
    return false;
  }

  state = const LocalAuthState.authenticated();
  return true;
}
```

---

## Security Recommendations

### Do

- Use banking-grade security for apps with financial/health data
- Store biometric state hash in secure storage (not SharedPreferences)
- Clear biometric state on logout
- Test biometric change detection with real devices
- Show clear error messages for lockout states

### Don't

- Don't rely solely on biometrics for high-security operations
- Don't store sensitive data accessible without authentication
- Don't ignore `KeyPermanentlyInvalidatedException` on Android
- Don't skip re-auth after biometric enrollment changes in banking apps

---

## App PIN as Fallback

For devices without any lock screen, provide app-level PIN:

```dart
final class AppPinService {
  final SecureStorage _storage;

  static const _pinKey = 'app_pin_hash';

  /// Check if app PIN is set up.
  Future<bool> isPinEnabled() async {
    final hash = await _storage.read(_pinKey);
    return hash != null;
  }

  /// Set up app PIN.
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _storage.write(_pinKey, hash);
  }

  /// Verify app PIN.
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(_pinKey);
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    return storedHash == inputHash;
  }

  /// Clear app PIN (call on logout).
  Future<void> clearPin() async {
    await _storage.delete(_pinKey);
  }

  String _hashPin(String pin) {
    // Use proper hashing - bcrypt or similar
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
```

---

## Decision Matrix

| Requirement | Security Level | Components Needed |
|-------------|---------------|-------------------|
| Basic app lock | Simple | LocalAuthService only |
| Quick unlock | Simple | LocalAuthService + timeout |
| Sensitive actions | Simple | LocalAuthService + per-action |
| Banking app | Banking | + BiometricStateTracker |
| No device lock | Either | + AppPinService |
| Shared device | Banking | + AppPinService + BiometricStateTracker |

---

## Next Steps

1. Read [patterns-guide.md](patterns-guide.md) for timeout and lifecycle patterns
2. Copy appropriate reference files based on security level
3. Run `/i18n` for localized auth messages

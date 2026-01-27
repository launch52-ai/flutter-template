# Local Auth - Usage Patterns Guide

Common patterns for app unlock, sensitive actions, and lifecycle management.

---

## Pattern 1: App Unlock After Timeout

Re-authenticate when app returns from background after configurable timeout.

### Architecture

```
App Lifecycle Observer → Tracks background time
         ↓
LocalAuthNotifier → Decides if auth needed
         ↓
LockScreen → Shows auth prompt
         ↓
App Content → Shown after auth
```

### Implementation

```dart
/// Observes app lifecycle and tracks background duration.
final class AppLifecycleObserver with WidgetsBindingObserver {
  final LocalAuthNotifier _authNotifier;
  DateTime? _backgroundedAt;

  AppLifecycleObserver(this._authNotifier);

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _backgroundedAt = DateTime.now();
        break;

      case AppLifecycleState.resumed:
        _checkAuthRequired();
        break;

      default:
        break;
    }
  }

  void _checkAuthRequired() {
    if (_backgroundedAt == null) return;

    final backgroundDuration = DateTime.now().difference(_backgroundedAt!);
    _backgroundedAt = null;

    _authNotifier.checkAuthRequired(backgroundDuration);
  }
}
```

### Timeout Configuration

```dart
@riverpod
class LocalAuthSettings extends _$LocalAuthSettings {
  static const _timeoutKey = 'local_auth_timeout_minutes';
  static const _enabledKey = 'local_auth_enabled';

  @override
  Future<LocalAuthSettingsState> build() async {
    final prefs = await ref.read(sharedPrefsProvider.future);

    return LocalAuthSettingsState(
      enabled: prefs.getBool(_enabledKey) ?? false,
      timeoutMinutes: prefs.getInt(_timeoutKey) ?? 5,
    );
  }

  /// Update timeout (0 = immediate, -1 = never).
  Future<void> setTimeoutMinutes(int minutes) async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setInt(_timeoutKey, minutes);

    state = AsyncData(state.value!.copyWith(
      timeoutMinutes: minutes,
    ));
  }
}

/// Timeout options to show in UI.
enum AuthTimeout {
  immediate(0, 'Immediately'),
  oneMinute(1, '1 minute'),
  fiveMinutes(5, '5 minutes'),
  fifteenMinutes(15, '15 minutes'),
  thirtyMinutes(30, '30 minutes'),
  never(-1, 'Never');

  final int minutes;
  final String label;

  const AuthTimeout(this.minutes, this.label);
}
```

### Lock Screen Integration

```dart
final class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(localAuthNotifierProvider);

    return authState.when(
      authenticated: () => child,
      requiresAuth: () => const LockScreen(),
      requiresFullLogin: () => const LoginScreen(),
      checking: () => const SplashScreen(),
    );
  }
}
```

---

## Pattern 2: Secure Sensitive Actions

Require authentication before specific operations.

### Implementation

```dart
/// Mixin for screens with sensitive actions.
mixin SecureActionMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {

  /// Execute action after local auth.
  Future<void> withLocalAuth({
    required String reason,
    required Future<void> Function() action,
  }) async {
    final localAuth = ref.read(localAuthServiceProvider);

    final result = await localAuth.authenticate(reason: reason);

    if (result.success) {
      await action();
    } else if (!result.isCancelled) {
      // Show error only if not cancelled
      _showAuthError(result);
    }
  }

  void _showAuthError(AuthResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.errorMessage ?? t.localAuth.failed)),
    );
  }
}

// Usage in a screen
class PaymentScreen extends ConsumerStatefulWidget {
  // ...
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with SecureActionMixin {

  Future<void> _confirmPayment() async {
    await withLocalAuth(
      reason: t.localAuth.confirmPayment,
      action: () async {
        await ref.read(paymentNotifierProvider.notifier).processPayment();
      },
    );
  }
}
```

### Declarative Approach

```dart
/// Widget that requires auth before showing content.
final class SecureContent extends ConsumerWidget {
  final String reason;
  final Widget child;
  final Widget? placeholder;

  const SecureContent({
    required this.reason,
    required this.child,
    this.placeholder,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnlocked = ref.watch(secureContentUnlockedProvider(reason));

    if (isUnlocked) {
      return child;
    }

    return placeholder ?? SecureContentPlaceholder(
      reason: reason,
      onUnlock: () => ref.read(localAuthNotifierProvider.notifier)
          .authenticateForContent(reason),
    );
  }
}
```

---

## Pattern 3: Settings Toggle

Allow users to enable/disable local auth.

### Toggle Widget

```dart
final class LocalAuthToggle extends ConsumerWidget {
  const LocalAuthToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(localAuthSettingsProvider);
    final canAuth = ref.watch(canLocalAuthProvider);

    return settings.when(
      data: (state) => SwitchListTile(
        title: Text(t.settings.enableBiometric),
        subtitle: Text(_getSubtitle(canAuth)),
        value: state.enabled,
        onChanged: canAuth.maybeWhen(
          data: (can) => can ? (value) => _onToggle(ref, value) : null,
          orElse: () => null,
        ),
      ),
      loading: () => const ListTile(
        title: Text('Biometric unlock'),
        trailing: CircularProgressIndicator.adaptive(),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getSubtitle(AsyncValue<bool> canAuth) {
    return canAuth.when(
      data: (can) => can
          ? t.settings.biometricAvailable
          : t.settings.biometricNotAvailable,
      loading: () => t.settings.checkingBiometric,
      error: (_, __) => t.settings.biometricError,
    );
  }

  Future<void> _onToggle(WidgetRef ref, bool value) async {
    if (value) {
      // Verify user can authenticate before enabling
      final result = await ref.read(localAuthServiceProvider)
          .authenticate(reason: t.localAuth.enableReason);

      if (result.success) {
        await ref.read(localAuthSettingsProvider.notifier).setEnabled(true);
      }
    } else {
      await ref.read(localAuthSettingsProvider.notifier).setEnabled(false);
    }
  }
}
```

### Timeout Selector

```dart
final class LocalAuthTimeoutSelector extends ConsumerWidget {
  const LocalAuthTimeoutSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(localAuthSettingsProvider);

    return settings.when(
      data: (state) {
        if (!state.enabled) return const SizedBox.shrink();

        return ListTile(
          title: Text(t.settings.lockTimeout),
          subtitle: Text(_getTimeoutLabel(state.timeoutMinutes)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showTimeoutPicker(context, ref, state.timeoutMinutes),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getTimeoutLabel(int minutes) {
    return AuthTimeout.values
        .firstWhere((t) => t.minutes == minutes, orElse: () => AuthTimeout.fiveMinutes)
        .label;
  }

  void _showTimeoutPicker(BuildContext context, WidgetRef ref, int current) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: AuthTimeout.values.map((option) => RadioListTile<int>(
          title: Text(option.label),
          value: option.minutes,
          groupValue: current,
          onChanged: (value) {
            if (value != null) {
              ref.read(localAuthSettingsProvider.notifier)
                  .setTimeoutMinutes(value);
              Navigator.pop(context);
            }
          },
        )).toList(),
      ),
    );
  }
}
```

---

## Pattern 4: First-Time Setup

Guide users through enabling local auth after account creation.

```dart
final class LocalAuthSetupScreen extends ConsumerWidget {
  const LocalAuthSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAuth = ref.watch(canLocalAuthProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 80),
              const SizedBox(height: 24),
              Text(
                t.localAuth.setupTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                t.localAuth.setupDescription,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              canAuth.when(
                data: (can) => can
                    ? FilledButton(
                        onPressed: () => _enableAndContinue(context, ref),
                        child: Text(t.localAuth.enableButton),
                      )
                    : OutlinedButton(
                        onPressed: () => _openDeviceSettings(),
                        child: Text(t.localAuth.setupDeviceFirst),
                      ),
                loading: () => const CircularProgressIndicator.adaptive(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _skip(context, ref),
                child: Text(t.common.skip),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enableAndContinue(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(localAuthServiceProvider)
        .authenticate(reason: t.localAuth.enableReason);

    if (result.success) {
      await ref.read(localAuthSettingsProvider.notifier).setEnabled(true);
      if (context.mounted) {
        context.go('/home');
      }
    }
  }

  void _skip(BuildContext context, WidgetRef ref) {
    ref.read(localAuthSettingsProvider.notifier).setEnabled(false);
    context.go('/home');
  }

  void _openDeviceSettings() {
    // Platform-specific settings URL
    // Android: android.settings.SECURITY_SETTINGS
    // iOS: App-Prefs:PASSCODE
  }
}
```

---

## Pattern 5: Combine with App PIN

For devices without biometric/device lock.

```dart
final class LocalAuthNotifier extends _$LocalAuthNotifier {
  Future<bool> authenticate({required String reason}) async {
    final localAuth = ref.read(localAuthServiceProvider);
    final pinService = ref.read(appPinServiceProvider);

    // Try biometric/device credential first
    final canUseBiometric = await localAuth.canAuthenticate();

    if (canUseBiometric) {
      final result = await localAuth.authenticate(reason: reason);
      return result.success;
    }

    // Fall back to app PIN
    final hasPin = await pinService.isPinEnabled();

    if (hasPin) {
      // Show PIN entry dialog
      final pin = await _showPinDialog();
      if (pin != null) {
        return await pinService.verifyPin(pin);
      }
    }

    // No auth method available
    return false;
  }
}
```

---

## State Management

### LocalAuthState

```dart
@freezed
sealed class LocalAuthState with _$LocalAuthState {
  /// Initial state - checking if auth is needed.
  const factory LocalAuthState.checking() = LocalAuthChecking;

  /// Auth required - show lock screen.
  const factory LocalAuthState.requiresAuth() = LocalAuthRequired;

  /// Authenticated - show app content.
  const factory LocalAuthState.authenticated() = LocalAuthAuthenticated;

  /// Failed attempt with remaining tries.
  const factory LocalAuthState.failed({
    int? attemptsRemaining,
  }) = LocalAuthFailed;

  /// Locked out - too many failures.
  const factory LocalAuthState.lockedOut({
    required String message,
    Duration? retryAfter,
  }) = LocalAuthLockedOut;

  /// Requires full remote login (biometrics changed or max failures).
  const factory LocalAuthState.requiresFullLogin() = LocalAuthRequiresFullLogin;
}
```

---

## Next Steps

1. Copy reference files matching your patterns
2. Integrate with your app's navigation
3. Run `/i18n` for localized strings
4. Run `/testing` for auth flow tests

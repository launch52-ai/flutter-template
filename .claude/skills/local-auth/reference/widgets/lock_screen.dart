// Template: Lock screen widget
//
// Location: lib/core/widgets/lock_screen.dart
//
// Usage:
// 1. Copy to target location
// 2. Update imports
// 3. Customize UI as needed

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../providers/local_auth_provider.dart';
import '../providers/local_auth_state.dart';
import '../services/local_auth_service.dart';

/// Full-screen lock screen for local authentication.
///
/// Shows appropriate biometric icon and prompts user to authenticate.
/// Automatically triggers auth on appear.
final class LockScreen extends ConsumerStatefulWidget {
  /// Custom app name/logo to display.
  final Widget? header;

  /// Reason shown in biometric prompt.
  final String? reason;

  const LockScreen({
    this.header,
    this.reason,
    super.key,
  });

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

final class _LockScreenState extends ConsumerState<LockScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger auth after frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    final notifier = ref.read(localAuthNotifierProvider.notifier);
    await notifier.authenticate(
      reason: widget.reason ?? 'Unlock to continue', // TODO: Use i18n
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(localAuthNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header (app logo or name)
                if (widget.header != null) ...[
                  widget.header!,
                  const SizedBox(height: 48),
                ],

                // Biometric icon
                FutureBuilder<List<BiometricType>>(
                  future: ref
                      .read(localAuthServiceProvider)
                      .getAvailableBiometrics(),
                  builder: (context, snapshot) {
                    return _BiometricIcon(
                      biometrics: snapshot.data ?? [],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Status message
                _StatusMessage(state: authState),

                const SizedBox(height: 48),

                // Unlock button
                _UnlockButton(
                  state: authState,
                  onPressed: _authenticate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays appropriate biometric icon based on available types.
final class _BiometricIcon extends StatelessWidget {
  final List<BiometricType> biometrics;

  const _BiometricIcon({required this.biometrics});

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();
    final color = Theme.of(context).colorScheme.primary;

    return Icon(
      icon,
      size: 80,
      color: color,
    );
  }

  IconData _getIcon() {
    // Check for face recognition first
    if (biometrics.contains(BiometricType.face)) {
      return Platform.isIOS ? Icons.face : Icons.face_unlock_outlined;
    }

    // Then fingerprint
    if (biometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    }

    // Iris (rare)
    if (biometrics.contains(BiometricType.iris)) {
      return Icons.remove_red_eye_outlined;
    }

    // Strong biometric (generic)
    if (biometrics.contains(BiometricType.strong)) {
      return Icons.security;
    }

    // Fallback to lock icon (device credentials)
    return Icons.lock_outline;
  }
}

/// Shows status message based on auth state.
final class _StatusMessage extends StatelessWidget {
  final LocalAuthState state;

  const _StatusMessage({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (message, isError) = state.when(
      checking: () => ('Checking...', false),
      requiresAuth: () => ('Tap to unlock', false),
      authenticated: () => ('Unlocked', false),
      failed: (message, remaining) {
        if (remaining != null) {
          return ('$message\n$remaining attempts remaining', true);
        }
        return (message ?? 'Authentication failed', true);
      },
      lockedOut: (message, _) => (message, true),
      requiresFullLogin: () => ('Please sign in again', true),
      disabled: () => ('', false),
    );

    if (message.isEmpty) return const SizedBox.shrink();

    return Text(
      message,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: isError ? theme.colorScheme.error : null,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Unlock button with appropriate state handling.
final class _UnlockButton extends StatelessWidget {
  final LocalAuthState state;
  final VoidCallback onPressed;

  const _UnlockButton({
    required this.state,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = state is LocalAuthChecking;
    final isLockedOut = state is LocalAuthLockedOut;

    return FilledButton.icon(
      onPressed: isLoading || isLockedOut ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.lock_open),
      label: Text(isLockedOut ? 'Locked' : 'Unlock'), // TODO: Use i18n
    );
  }
}

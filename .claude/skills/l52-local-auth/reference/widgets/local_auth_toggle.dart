// Template: Settings toggle widget for local auth
//
// Location: lib/core/widgets/local_auth_toggle.dart
//
// Usage:
// 1. Copy to target location
// 2. Update imports
// 3. Add to settings screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/local_auth_provider.dart';
import '../providers/local_auth_settings.dart';
import '../services/local_auth_service.dart';

/// Toggle switch for enabling/disabling local authentication.
///
/// Shows biometric availability status and requires successful
/// authentication before enabling.
final class LocalAuthToggle extends ConsumerWidget {
  const LocalAuthToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(localAuthSettingsProvider);
    final canAuth = ref.watch(canLocalAuthProvider);

    return settings.when(
      data: (state) => SwitchListTile(
        title: const Text('Biometric unlock'), // TODO: Use i18n
        subtitle: Text(_getSubtitle(canAuth)),
        secondary: const Icon(Icons.fingerprint),
        value: state.enabled,
        onChanged: canAuth.maybeWhen(
          data: (can) => can ? (value) => _onToggle(context, ref, value) : null,
          orElse: () => null,
        ),
      ),
      loading: () => const ListTile(
        leading: Icon(Icons.fingerprint),
        title: Text('Biometric unlock'),
        trailing: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getSubtitle(AsyncValue<bool> canAuth) {
    return canAuth.when(
      data: (can) => can
          ? 'Use Face ID or fingerprint to unlock' // TODO: Use i18n
          : 'Not available on this device',
      loading: () => 'Checking availability...',
      error: (_, __) => 'Error checking availability',
    );
  }

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    if (value) {
      // Verify user can authenticate before enabling
      final service = ref.read(localAuthServiceProvider);
      final result = await service.authenticate(
        reason: 'Verify to enable biometric unlock', // TODO: Use i18n
      );

      if (result.success) {
        await ref.read(localAuthSettingsProvider.notifier).setEnabled(true);
      } else if (!result.isCancelled && context.mounted) {
        // Show error if not cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Authentication failed'),
          ),
        );
      }
    } else {
      await ref.read(localAuthSettingsProvider.notifier).setEnabled(false);
    }
  }
}

/// Timeout selector for when to require re-authentication.
///
/// Only visible when biometric unlock is enabled.
final class LocalAuthTimeoutSelector extends ConsumerWidget {
  const LocalAuthTimeoutSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(localAuthSettingsProvider);

    return settings.when(
      data: (state) {
        if (!state.enabled) return const SizedBox.shrink();

        final timeout = AuthTimeout.fromMinutes(state.timeoutMinutes);

        return ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: const Text('Require unlock'), // TODO: Use i18n
          subtitle: Text(timeout.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showTimeoutPicker(context, ref, state.timeoutMinutes),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showTimeoutPicker(
    BuildContext context,
    WidgetRef ref,
    int currentMinutes,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Require unlock after', // TODO: Use i18n
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ...AuthTimeout.values.map(
              (option) => RadioListTile<int>(
                title: Text(option.label),
                value: option.minutes,
                groupValue: currentMinutes,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(localAuthSettingsProvider.notifier)
                        .setTimeoutMinutes(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

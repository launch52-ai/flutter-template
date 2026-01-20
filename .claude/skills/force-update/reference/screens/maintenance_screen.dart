// Template: MaintenanceScreen - server maintenance blocker UI
//
// Location: lib/features/force_update/presentation/screens/
//
// Usage:
// 1. Copy to target location
// 2. Update import paths
// 3. Run /i18n to localize hardcoded strings
// 4. Run /a11y to add accessibility support

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/update_notifier.dart';

/// Full-screen maintenance mode screen.
/// Automatically retries checking for maintenance end.
final class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

final class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  Timer? _retryTimer;
  bool _isRetrying = false;
  int _retryCount = 0;

  static const _retryInterval = Duration(seconds: 30);
  static const _maxAutoRetries = 20; // Stop after ~10 minutes

  @override
  void initState() {
    super.initState();
    _startAutoRetry();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _startAutoRetry() {
    _retryTimer = Timer.periodic(_retryInterval, (_) {
      if (_retryCount < _maxAutoRetries) {
        _checkMaintenanceStatus();
        _retryCount++;
      } else {
        _retryTimer?.cancel();
      }
    });
  }

  Future<void> _checkMaintenanceStatus() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);

    try {
      await ref.read(updateNotifierProvider.notifier).checkForUpdates();
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final versionInfo = ref.watch(versionInfoProvider);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Maintenance Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.construction,
                    size: 48,
                    color: AppColors.warning,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Under Maintenance',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  versionInfo?.maintenanceMessage ??
                      "We're making some improvements. "
                          'Please check back soon.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Auto-retry indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRetrying)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _isRetrying
                          ? 'Checking status...'
                          : 'Checking again in 30 seconds',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Manual retry button
                TextButton.icon(
                  onPressed: _isRetrying ? null : _checkMaintenanceStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Now'),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

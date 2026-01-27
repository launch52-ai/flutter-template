// Template: ForceUpdateScreen - full-screen blocking update UI
//
// Location: lib/features/force_update/presentation/screens/
//
// Usage:
// 1. Copy to target location
// 2. Update import paths
// 3. Run /i18n to localize hardcoded strings
// 4. Run /a11y to add accessibility support

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/update_notifier.dart';

/// Full-screen blocking update screen.
/// User cannot dismiss or navigate away.
final class ForceUpdateScreen extends ConsumerStatefulWidget {
  const ForceUpdateScreen({super.key});

  @override
  ConsumerState<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

final class _ForceUpdateScreenState extends ConsumerState<ForceUpdateScreen> {
  bool _isLoading = false;

  Future<void> _openStore() async {
    final versionInfo = ref.read(versionInfoProvider);
    if (versionInfo == null) return;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(versionInfo.storeUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to browser
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open app store'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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

                // App Icon placeholder
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.system_update,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Update Required',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'A new version of the app is available. '
                  'Please update to continue using the app.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (versionInfo?.releaseNotes != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's new in ${versionInfo!.currentVersion}:",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          versionInfo.releaseNotes!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Update Button
                // TODO: Run /i18n to localize strings
                // TODO: Run /a11y to add semantic labels
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _openStore,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Update Now'),
                  ),
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

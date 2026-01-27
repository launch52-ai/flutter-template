// Template: SoftUpdateDialog - dismissible update prompt bottom sheet
//
// Location: lib/features/force_update/presentation/widgets/
//
// Usage:
// 1. Copy to target location
// 2. Update import paths
// 3. Run /i18n to localize hardcoded strings
// 4. Run /a11y to add accessibility support

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/version_info.dart';

/// Dismissible bottom sheet for soft update prompts.
final class SoftUpdateDialog extends ConsumerStatefulWidget {
  const SoftUpdateDialog({
    super.key,
    required this.versionInfo,
    this.onDismiss,
  });

  final VersionInfo versionInfo;
  final VoidCallback? onDismiss;

  /// Show the soft update dialog as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required VersionInfo versionInfo,
    VoidCallback? onDismiss,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SoftUpdateDialog(
        versionInfo: versionInfo,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  ConsumerState<SoftUpdateDialog> createState() => _SoftUpdateDialogState();
}

final class _SoftUpdateDialogState extends ConsumerState<SoftUpdateDialog> {
  bool _isLoading = false;

  static const _lastPromptKey = 'soft_update_last_prompt';
  static const _skippedVersionKey = 'soft_update_skipped_version';

  Future<void> _openStore() async {
    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(widget.versionInfo.storeUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _remindLater() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPromptKey, DateTime.now().millisecondsSinceEpoch);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onDismiss?.call();
    }
  }

  Future<void> _skipVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _skippedVersionKey,
      widget.versionInfo.currentVersion,
    );

    if (mounted) {
      Navigator.of(context).pop();
      widget.onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'Update Available',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Version ${widget.versionInfo.currentVersion} is now available!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          if (widget.versionInfo.releaseNotes != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.versionInfo.releaseNotes!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Update button
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

          const SizedBox(height: 12),

          // Remind later button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _remindLater,
              child: const Text('Remind Me Later'),
            ),
          ),

          const SizedBox(height: 8),

          // Skip button
          TextButton(
            onPressed: _skipVersion,
            child: Text(
              'Skip This Version',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Manager to handle soft update prompt frequency.
final class SoftUpdatePromptManager {
  SoftUpdatePromptManager(this._prefs);

  final SharedPreferences _prefs;

  static const _lastPromptKey = 'soft_update_last_prompt';
  static const _skippedVersionKey = 'soft_update_skipped_version';
  static const _promptCooldown = Duration(hours: 24);

  /// Returns true if we should show the soft update prompt.
  bool shouldShowPrompt(String newVersion) {
    // Never prompt for a version user explicitly skipped
    final skippedVersion = _prefs.getString(_skippedVersionKey);
    if (skippedVersion == newVersion) {
      return false;
    }

    // Check cooldown period
    final lastPrompt = _prefs.getInt(_lastPromptKey);
    if (lastPrompt != null) {
      final lastPromptTime = DateTime.fromMillisecondsSinceEpoch(lastPrompt);
      if (DateTime.now().difference(lastPromptTime) < _promptCooldown) {
        return false;
      }
    }

    return true;
  }

  /// Clear skipped version (call when new version is released).
  Future<void> clearSkippedVersion() async {
    await _prefs.remove(_skippedVersionKey);
  }
}

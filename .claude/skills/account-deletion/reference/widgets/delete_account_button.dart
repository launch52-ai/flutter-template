// Template: Delete Account Button Widget
//
// Location: lib/features/settings/presentation/widgets/delete_account_button.dart
//
// Usage:
// 1. Copy to target location
// 2. Adjust imports for your project structure
// 3. Add to settings screen in "Danger Zone" section

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/account_deletion_notifier.dart';
import 'delete_account_dialog.dart';
// Import your theme and i18n
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/i18n/translations.g.dart';

/// Button to initiate account deletion flow.
///
/// Shows danger styling (red outline) to indicate destructive action.
/// Opens confirmation dialog when tapped.
final class DeleteAccountButton extends ConsumerWidget {
  const DeleteAccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorColor = Theme.of(context).colorScheme.error;

    // Listen for state changes to handle navigation
    ref.listen(accountDeletionNotifierProvider, (_, state) {
      state.whenOrNull(
        success: () {
          // Navigate to login and clear navigation stack
          context.go('/login');
        },
        error: (failure) {
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: errorColor,
        side: BorderSide(color: errorColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: () => _showDeleteDialog(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_forever, size: 20),
          const SizedBox(width: 8),
          // TODO: Use t.settings.deleteAccount.button
          const Text('Delete My Account'),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Require explicit action
      builder: (context) => const DeleteAccountDialog(),
    );
  }
}

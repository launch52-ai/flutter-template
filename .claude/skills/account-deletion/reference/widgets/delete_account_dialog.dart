// Template: Delete Account Confirmation Dialog
//
// Location: lib/features/settings/presentation/widgets/delete_account_dialog.dart
//
// Usage:
// 1. Copy to target location
// 2. Adjust imports for your project structure
// 3. Customize confirmation method as needed (type DELETE, password, checkbox)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/account_deletion_notifier.dart';
// Import your theme and i18n
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/i18n/translations.g.dart';

/// Confirmation dialog for account deletion.
///
/// Features:
/// - Clear warning about consequences
/// - Type "DELETE" confirmation (configurable)
/// - Loading state during deletion
/// - Cancel and Delete buttons
final class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

final class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _confirmationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountDeletionNotifierProvider);
    final isLoading = state is _Loading;
    final errorColor = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: errorColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          // TODO: Use t.settings.deleteAccount.title
          const Text('Delete Account'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning text
              // TODO: Use t.settings.deleteAccount.warning
              const Text(
                'This will permanently delete your account and all associated data. '
                'This action cannot be undone.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),

              // What will be deleted
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: errorColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The following will be permanently deleted:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDeleteItem('Your profile and account data', errorColor),
                    _buildDeleteItem('Your preferences and settings', errorColor),
                    _buildDeleteItem('Your usage history', errorColor),
                    // Add more items as needed for your app
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Confirmation input
              // TODO: Use t.settings.deleteAccount.confirmationPrompt
              const Text(
                'Type "DELETE" to confirm:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmationController,
                enabled: !isLoading,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  // TODO: Use t.settings.deleteAccount.confirmationPlaceholder
                  hintText: 'Type DELETE',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().toUpperCase() != 'DELETE') {
                    // TODO: Use t.settings.wrongConfirmation
                    return 'Please type "DELETE" exactly to confirm';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          // TODO: Use t.settings.deleteAccount.cancel
          child: const Text('Cancel'),
        ),

        // Delete button
        ElevatedButton(
          onPressed: isLoading ? null : _onDeletePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: errorColor,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onError,
                    ),
                  ),
                )
              // TODO: Use t.settings.deleteAccount.delete
              : const Text('Delete Account'),
        ),
      ],
    );
  }

  Widget _buildDeleteItem(String text, Color errorColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.remove, size: 14, color: errorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _onDeletePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(accountDeletionNotifierProvider.notifier).deleteAccount(
            confirmation: _confirmationController.text,
          );
    }
  }
}

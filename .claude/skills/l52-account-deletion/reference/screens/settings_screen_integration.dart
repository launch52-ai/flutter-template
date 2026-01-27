// Template: Settings Screen Integration
//
// Location: lib/features/settings/presentation/screens/settings_screen.dart
//
// Usage:
// 1. This shows how to integrate DeleteAccountButton into existing settings screen
// 2. Add the "Danger Zone" section at the bottom of your settings
// 3. Adjust styling to match your app's design

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/delete_account_button.dart';
// Import your theme and i18n
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/i18n/translations.g.dart';

/// Example settings screen with account deletion integration.
///
/// Your actual settings screen may have different sections.
/// The key is to add the "Danger Zone" section at the bottom.
final class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        // TODO: Use t.settings.title
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === Your existing settings sections ===

          // Example: Account section
          _buildSectionHeader(context, 'Account'),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: 'Profile',
            onTap: () {
              // Navigate to profile
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              // Navigate to notifications settings
            },
          ),

          const SizedBox(height: 24),

          // Example: Preferences section
          _buildSectionHeader(context, 'Preferences'),
          _buildSettingsTile(
            context,
            icon: Icons.palette_outlined,
            title: 'Theme',
            onTap: () {
              // Open theme picker
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'Language',
            onTap: () {
              // Open language picker
            },
          ),

          const SizedBox(height: 24),

          // Example: Support section
          _buildSectionHeader(context, 'Support'),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () {
              // Open help
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              // Open privacy policy
            },
          ),

          // === Danger Zone Section ===
          // This is where account deletion goes

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // TODO: Use t.settings.dangerZone
          Text(
            'Danger Zone',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actions in this section are permanent and cannot be undone.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          // Delete Account Button
          const DeleteAccountButton(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

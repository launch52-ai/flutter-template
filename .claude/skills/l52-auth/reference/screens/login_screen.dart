// Template: Login Screen Scaffold
//
// Location: lib/features/auth/presentation/screens/login_screen.dart
//
// Usage:
// 1. Copy to target location
// 2. Add auth method buttons (social, phone) based on your configuration
// 3. Run /i18n to add localized strings
// 4. Run /design to polish the UI

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// Login screen scaffold.
///
/// This is a base scaffold that shows:
/// - App logo/branding
/// - Auth method buttons (add based on your selection)
/// - Error handling
/// - Loading state
///
/// Add auth buttons based on which methods you selected:
/// - Social login: Use SocialLoginButton from /social-login skill
/// - Phone auth: Add "Continue with Phone" button that navigates to phone input
/// - Email auth: Add email/password form
final class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    // Listen for errors and show snackbar
    ref.listen<AuthState>(
      authNotifierProvider,
      (previous, next) {
        if (next case AuthError(:final message)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              action: SnackBarAction(
                label: 'Dismiss', // TODO: Use t.common.dismiss
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).clearError();
                },
              ),
            ),
          );
        }
      },
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo / Branding
              _buildLogo(context),

              const Spacer(),

              // Welcome text
              _buildWelcomeText(context),

              const SizedBox(height: 48),

              // Auth buttons - add based on your configuration
              _buildAuthButtons(context, ref, isLoading),

              const Spacer(flex: 2),

              // Terms and privacy
              _buildTermsText(context),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    // TODO: Replace with your app logo
    return Icon(
      Icons.lock_outline,
      size: 80,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome', // TODO: Use t.auth.welcome
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue', // TODO: Use t.auth.signInToContinue
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildAuthButtons(BuildContext context, WidgetRef ref, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // =================================================================
        // ADD YOUR AUTH BUTTONS HERE
        // =================================================================

        // SOCIAL LOGIN BUTTONS (if using /social-login)
        // Import: import '../../../../core/widgets/social_login_button.dart';
        //
        // SocialLoginButton(
        //   provider: SocialProvider.google,
        //   label: t.auth.buttons.continueWithGoogle,
        //   isLoading: isLoading,
        //   onPressed: () {
        //     ref.read(authNotifierProvider.notifier).signInWithGoogle();
        //   },
        // ),
        // const SizedBox(height: 12),
        // SocialLoginButton(
        //   provider: SocialProvider.apple,
        //   label: t.auth.buttons.continueWithApple,
        //   isLoading: isLoading,
        //   onPressed: () {
        //     ref.read(authNotifierProvider.notifier).signInWithApple();
        //   },
        // ),

        // PHONE AUTH BUTTON (if using /phone-auth)
        // OutlinedButton.icon(
        //   onPressed: isLoading ? null : () {
        //     context.push('/login/phone');
        //   },
        //   icon: const Icon(Icons.phone),
        //   label: Text(t.auth.buttons.continueWithPhone),
        //   style: OutlinedButton.styleFrom(
        //     minimumSize: const Size.fromHeight(52),
        //   ),
        // ),

        // EMAIL AUTH BUTTON/FORM (if using email)
        // TextButton(
        //   onPressed: isLoading ? null : () {
        //     context.push('/login/email');
        //   },
        //   child: Text(t.auth.buttons.continueWithEmail),
        // ),

        // =================================================================
        // PLACEHOLDER - Remove once you add your auth buttons
        // =================================================================
        _buildPlaceholderButton(context),
      ],
    );
  }

  Widget _buildPlaceholderButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 32,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            'Add auth buttons here',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Run /social-login or /phone-auth',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsText(BuildContext context) {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      // TODO: Use t.auth.termsAndPrivacy with links
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

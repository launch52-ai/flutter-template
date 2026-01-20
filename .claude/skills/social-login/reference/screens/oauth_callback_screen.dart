// Template: Authentication related
//
// Location: lib/features/{feature}/presentation/screens/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Template: OAuth Callback Screen
//
// Location: lib/features/auth/presentation/screens/oauth_callback_screen.dart
//
// Handles the deep link callback for Apple Sign-In on Android.
// Polls for session completion and navigates accordingly.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/app_router.dart';

/// Screen that handles OAuth callback for Apple Sign-In on Android.
///
/// When Apple Sign-In completes in the browser, the app receives a
/// deep link that navigates here. This screen polls for the Supabase
/// session and navigates to the appropriate destination.
///
/// Flow:
/// 1. User taps Apple Sign-In on Android
/// 2. Browser opens to Apple authentication
/// 3. After auth, browser redirects to deep link
/// 4. App opens this screen
/// 5. Screen polls for Supabase session
/// 6. Navigates to dashboard (success) or login (timeout)
final class OAuthCallbackScreen extends ConsumerStatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  ConsumerState<OAuthCallbackScreen> createState() =>
      _OAuthCallbackScreenState();
}

final class _OAuthCallbackScreenState
    extends ConsumerState<OAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _pollForSession();
  }

  /// Polls for Supabase session completion.
  ///
  /// Supabase processes the OAuth callback and creates a session.
  /// We poll until the session is available or timeout.
  Future<void> _pollForSession() async {
    const maxPolls = 20;
    const pollInterval = Duration(milliseconds: 250);

    for (var i = 0; i < maxPolls; i++) {
      await Future.delayed(pollInterval);

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // Session found - navigate to dashboard
        if (mounted) {
          context.go(AppRouter.dashboard);
        }
        return;
      }
    }

    // Timeout - return to login
    if (mounted) {
      context.go(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use localized string: t.auth.social.completingSignIn
    // Run /i18n to add the string
    const message = 'Completing sign in...';

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

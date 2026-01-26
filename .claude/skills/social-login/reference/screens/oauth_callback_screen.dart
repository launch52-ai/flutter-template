// Template: OAuth Callback Screen
//
// Location: lib/features/auth/presentation/screens/oauth_callback_screen.dart
//
// Handles the deep link callback for Apple Sign-In on Android.
// Processes the OAuth callback, stores user data, and navigates accordingly.
//
// IMPORTANT: This screen must:
// 1. Reconstruct the deep link URI from query params (passed by router redirect)
// 2. Call Supabase getSessionFromUrl() to exchange the code for a session
// 3. Store user data in SecureStorage
// 4. Update SharedPrefs flags for routing
// 5. Navigate to dashboard or profile completion

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Update these imports to match your project structure
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/providers.dart';
import '../../../../core/router/app_router.dart';

/// Screen that handles OAuth callback for Apple Sign-In on Android.
///
/// When Apple Sign-In completes in the browser, the app receives a
/// deep link that the router redirects here with query params.
/// This screen processes the OAuth callback and navigates accordingly.
///
/// Flow:
/// 1. User taps Apple Sign-In on Android
/// 2. Browser opens to Apple authentication
/// 3. After auth, browser redirects to deep link with code
/// 4. Router redirect passes query params to this screen
/// 5. Screen calls Supabase getSessionFromUrl() to exchange code
/// 6. Stores user data and navigates to dashboard/profile completion
final class OAuthCallbackScreen extends ConsumerStatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  ConsumerState<OAuthCallbackScreen> createState() =>
      _OAuthCallbackScreenState();
}

final class _OAuthCallbackScreenState
    extends ConsumerState<OAuthCallbackScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Process after first frame to ensure GoRouter state is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processOAuthCallback();
    });
  }

  /// Processes the OAuth callback from the deep link.
  Future<void> _processOAuthCallback() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Check if session already exists (might have been processed)
      var session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        // Get query params from current route (passed by router redirect)
        final uri = GoRouterState.of(context).uri;
        if (uri.queryParameters.containsKey('code')) {
          // Reconstruct the full callback URL for Supabase
          // Replace 'your.bundle.id' with your actual bundle ID
          final callbackUri = Uri(
            scheme: 'your.bundle.id', // TODO: Replace with AppConstants.deepLinkScheme
            host: 'login-callback',
            queryParameters: uri.queryParameters,
          );
          final response = await Supabase.instance.client.auth
              .getSessionFromUrl(callbackUri);
          session = response.session;
        }
      }

      if (session != null && mounted) {
        await _storeUserAndNavigate(session);
      } else if (mounted) {
        // No session - return to login
        context.go(AppRouter.login);
      }
    } catch (e) {
      // Error processing callback - return to login
      if (mounted) {
        context.go(AppRouter.login);
      }
    }
  }

  /// Stores user data and navigates to appropriate screen.
  Future<void> _storeUserAndNavigate(Session session) async {
    final user = session.user;
    final secureStorage = ref.read(secureStorageProvider);
    final prefs = ref.read(sharedPrefsProvider);

    // Store user data in secure storage
    await secureStorage.write(key: StorageKeys.userId, value: user.id);
    await secureStorage.write(
      key: StorageKeys.accessToken,
      value: session.accessToken,
    );
    if (session.refreshToken != null) {
      await secureStorage.write(
        key: StorageKeys.refreshToken,
        value: session.refreshToken!,
      );
    }

    // Store email if available
    final email = user.email ?? user.userMetadata?['email'] as String?;
    if (email != null) {
      await secureStorage.write(key: StorageKeys.userEmail, value: email);
    }

    // Store name if available
    final fullName = user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String?;
    if (fullName != null) {
      await secureStorage.write(key: StorageKeys.userFullName, value: fullName);
    }

    // Store phone if available
    final phoneNumber = user.phone;
    if (phoneNumber != null) {
      await secureStorage.write(
        key: StorageKeys.userPhoneNumber,
        value: phoneNumber,
      );
    }

    // Update SharedPrefs flags for routing
    await prefs.setBool(StorageKeys.hasUser, true);

    // Profile is complete if user has phone number (adjust based on your requirements)
    final hasCompletedProfile = phoneNumber != null && phoneNumber.isNotEmpty;
    await prefs.setBool(StorageKeys.hasCompletedProfile, hasCompletedProfile);

    if (!mounted) return;

    // Navigate to appropriate screen
    if (hasCompletedProfile) {
      context.go(AppRouter.dashboard);
    } else {
      context.go(AppRouter.profileCompletion);
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

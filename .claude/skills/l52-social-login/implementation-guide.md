# Social Login Implementation Guide

Flutter code patterns for implementing Google and Apple Sign-In with Supabase.

---

## Reference Files

Copy reference files to your project:

```
lib/features/auth/
├── data/
│   └── repositories/
│       ├── auth_repository_social_methods.dart  ← reference/repositories/
│       └── mock_auth_social_methods.dart        ← reference/repositories/
├── domain/
│   ├── failures/
│   │   └── social_auth_failures.dart            ← reference/failures/
│   └── repositories/
│       └── social_auth_repository.dart          ← reference/repositories/
└── presentation/
    ├── providers/
    │   └── auth_provider_social_methods.dart    ← reference/providers/
    ├── screens/
    │   └── oauth_callback_screen.dart           ← reference/screens/
    └── widgets/
        └── social_login_button.dart             ← reference/widgets/

lib/core/
├── constants/
│   └── app_constants.dart                       ← add from reference/utils/app_constants_social.dart
├── router/
│   └── app_router.dart                          ← add route from reference/router/
└── utils/
    └── nonce_helpers.dart                       ← reference/utils/

ios/Runner/
├── Info.plist                                   ← add from templates/info_plist_additions.xml
└── Runner.entitlements                          ← templates/Runner.entitlements

android/app/src/main/
└── AndroidManifest.xml                          ← add from templates/android_manifest_additions.xml
```

---

## Architecture Overview

Social login follows Clean Architecture with separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                          │
│  ├── LoginScreen (UI with social buttons)                   │
│  ├── OAuthCallbackScreen (handles Android Apple callback)   │
│  └── AuthNotifier (state management)                        │
├─────────────────────────────────────────────────────────────┤
│  DOMAIN LAYER                                                │
│  └── SocialAuthRepository (interface)                       │
├─────────────────────────────────────────────────────────────┤
│  DATA LAYER                                                  │
│  ├── AuthRepositoryImpl (Supabase implementation)           │
│  └── MockAuthRepository (testing/development)               │
└─────────────────────────────────────────────────────────────┘
```

---

## Step 1: Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  google_sign_in: ^7.2.0      # Required: 7.x has nonce support for Supabase
  sign_in_with_apple: ^7.0.1
  crypto: ^3.0.6
  supabase_flutter: ^2.12.0
  flutter_dotenv: ^6.0.0
```

**Important:** google_sign_in 7.x is required for proper Supabase integration:
- Uses singleton pattern: `GoogleSignIn.instance.initialize()` / `.authenticate()`
- Supports `nonce` parameter (required by Supabase to prevent replay attacks)
- `authenticate()` throws `GoogleSignInException` on cancel (check `e.code == GoogleSignInExceptionCode.canceled`)
- `authentication` is a getter, not a Future

---

## Step 2: Environment Variables

```env
# .env
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx

# Google Sign-In
GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=xxx.apps.googleusercontent.com
```

---

## Step 3: Add Constants

Add deep link scheme constant for OAuth callbacks.

**Template:** [reference/utils/app_constants_social.dart](reference/utils/app_constants_social.dart)

**Location:** `lib/core/constants/app_constants.dart`

---

## Step 4: Add OAuth Exception

Add exception for handling pending OAuth flows (Apple Sign-In on Android).

**Template:** [reference/exceptions/oauth_pending_exception.dart](reference/exceptions/oauth_pending_exception.dart)

**Location:** `lib/core/errors/exceptions.dart`

---

## Step 5: Domain Layer - Repository Interface

Create the interface for social authentication methods.

**Template:** [reference/repositories/social_auth_repository.dart](reference/repositories/social_auth_repository.dart)

**Location:** `lib/features/auth/domain/repositories/social_auth_repository.dart`

---

## Step 6: Data Layer - Repository Implementation

Add social sign-in methods to your existing AuthRepositoryImpl.

**Template:** [reference/repositories/auth_repository_social_methods.dart](reference/repositories/auth_repository_social_methods.dart)

**Location:** `lib/features/auth/data/repositories/auth_repository_impl.dart`

Key points:
- Add `SocialAuthRepository` to implements clause
- Google uses native SDK on both platforms
- Apple uses native SDK on iOS, OAuth browser flow on Android
- Both use PKCE with nonce for security

**Nonce helpers:** [reference/utils/nonce_helpers.dart](reference/utils/nonce_helpers.dart)

---

## Step 7: Mock Repository

Add mock implementations for development and testing.

**Template:** [reference/repositories/mock_auth_social_methods.dart](reference/repositories/mock_auth_social_methods.dart)

**Location:** `lib/features/auth/data/repositories/mock_auth_repository.dart`

---

## Step 8: Presentation Layer - Provider

Add provider and notifier methods for social login state management.

**Template:** [reference/providers/auth_provider_social_methods.dart](reference/providers/auth_provider_social_methods.dart)

**Location:** `lib/features/auth/presentation/providers/auth_provider.dart`

---

## Step 9: Social Login Button Widget

Create a reusable branded button for social providers.

**Template:** [reference/widgets/social_login_button.dart](reference/widgets/social_login_button.dart)

**Location:** `lib/core/widgets/social_login_button.dart`

---

## Step 10: Login Screen Integration

Add social login buttons to your login screen.

> **Important:** Show BOTH buttons on BOTH platforms. Do NOT wrap Apple button in `if (Platform.isIOS)`. Users switching devices need to sign in with the same provider. Platform detection is only for choosing the auth flow (native vs OAuth), not for hiding UI.

```dart
// In your LoginScreen build method:

// Divider
Row(
  children: [
    const Expanded(child: Divider()),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(t.auth.social.or),  // Run /i18n
    ),
    const Expanded(child: Divider()),
  ],
),

const SizedBox(height: 24),

// Google Sign-In
SocialLoginButton(
  provider: SocialProvider.google,
  label: t.auth.buttons.continueWithGoogle,  // Run /i18n
  isLoading: isLoading,
  onPressed: () {
    ref.read(authNotifierProvider.notifier).signInWithGoogle();
  },
),

const SizedBox(height: 12),

// Apple Sign-In
SocialLoginButton(
  provider: SocialProvider.apple,
  label: t.auth.buttons.continueWithApple,  // Run /i18n
  isLoading: isLoading,
  onPressed: () {
    ref.read(authNotifierProvider.notifier).signInWithApple();
  },
),
```

---

## Step 11: Router Configuration (CRITICAL for Android Apple Sign-In)

**IMPORTANT:** GoRouter receives deep links as full URLs (e.g., `io.zangy://login-callback?code=...`) which don't match standard route paths. You MUST add a redirect to handle this.

**Template:** [reference/router/router_oauth_callback.dart](reference/router/router_oauth_callback.dart)

**Location:** `lib/core/router/app_router.dart`

Add both the redirect AND the route:

```dart
GoRouter(
  // REQUIRED: Handle deep link OAuth callbacks
  redirect: (context, state) {
    final uri = state.uri;

    // Handle deep link OAuth callbacks
    if (uri.scheme == 'your.bundle.id' && uri.host == 'login-callback') {
      return '$oauthCallback?${uri.query}';
    }

    // Fallback for path-style deep links
    final path = uri.path;
    if (path.startsWith('your.bundle.id://login-callback')) {
      final deepLinkUri = Uri.parse(path);
      return '$oauthCallback?${deepLinkUri.query}';
    }

    return null;
  },
  routes: [
    // ... other routes ...
    GoRoute(
      path: '/login-callback',
      builder: (context, state) => const OAuthCallbackScreen(),
    ),
  ],
)
```

Replace `your.bundle.id` with your actual bundle ID (e.g., `io.zangy`, `com.example.myapp`).

---

## Step 12: OAuth Callback Screen

Handle the deep link callback for Apple Sign-In on Android.

**Template:** [reference/screens/oauth_callback_screen.dart](reference/screens/oauth_callback_screen.dart)

**Location:** `lib/features/auth/presentation/screens/oauth_callback_screen.dart`

The callback screen must:
1. Reconstruct the deep link URI from query params (passed by router redirect)
2. Call `Supabase.getSessionFromUrl()` to exchange the code for a session
3. Store user data in SecureStorage (userId, tokens, email, name)
4. Update SharedPrefs flags (`hasUser`, `hasCompletedProfile`) for routing
5. Navigate to dashboard or profile completion

---

## Step 13: Add i18n Strings

Run the `/i18n` skill to add localized strings for social login:

```bash
/i18n auth
```

Required string keys:
- `t.auth.buttons.continueWithGoogle`
- `t.auth.buttons.continueWithApple`
- `t.auth.social.or`
- `t.auth.social.completingSignIn`
- `t.auth.errors.socialLoginFailed`

See `/i18n` skill for UX writing guidelines.

---

## Testing Checklist

| Scenario | iOS | Android |
|----------|-----|---------|
| Google Sign-In - Success | Test | Test |
| Google Sign-In - Cancel | Test | Test |
| Apple Sign-In - Success | Test | Test (browser flow) |
| Apple Sign-In - Cancel | Test | Test |
| Network error during sign-in | Test | Test |
| Session persists after app restart | Test | Test |
| Sign out clears session | Test | Test |

---

## Common Patterns

### Handling User Cancellation

```dart
final result = await repository.signInWithGoogle();
if (result == null) {
  // User cancelled - don't show error, just return to previous state
  return;
}
```

### Detecting First-Time Users

```dart
final isNewUser = response.user?.createdAt == response.user?.updatedAt;
if (isNewUser) {
  context.go('/complete-profile');
} else {
  context.go('/dashboard');
}
```

### Storing Apple's Name

Apple only sends the user's name on first sign-in. Store it immediately:

```dart
if (credential.givenName != null || credential.familyName != null) {
  final fullName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
  await secureStorage.write(key: StorageKeys.userFullName, value: fullName);
}
```

---

## Troubleshooting

### Nonce Mismatch Error

**Error:** `Passed nonce and nonce in id_token should either both exist or not`

**Cause:** Cached Google credentials or missing nonce configuration.

**Solution:**
1. Ensure you're using `google_sign_in: ^7.2.0` (has nonce support)
2. Call `GoogleSignIn.instance.signOut()` before `authenticate()` to clear cached state
3. Pass hashed nonce to `initialize()` and raw nonce to Supabase `signInWithIdToken()`

```dart
final rawNonce = _generateRawNonce();
final hashedNonce = _sha256ofString(rawNonce);

await GoogleSignIn.instance.signOut();  // Clear cached credentials
await GoogleSignIn.instance.initialize(nonce: hashedNonce, ...);
final user = await GoogleSignIn.instance.authenticate();

await supabase.auth.signInWithIdToken(
  provider: OAuthProvider.google,
  idToken: idToken,
  nonce: rawNonce,  // Raw nonce, not hashed
);
```

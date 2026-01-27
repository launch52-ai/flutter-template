# Supabase Social Auth Configuration

Guide for configuring Google and Apple providers in Supabase Authentication.

---

## Overview

Supabase acts as the authentication backend, validating tokens from social providers and creating user sessions.

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Flutter    │────▶│   Provider   │────▶│   Supabase   │
│     App      │     │ Google/Apple │     │    Auth      │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │                     │
       │              ID Token +              Session
       │                Nonce                 + User
       │                    │                     │
       └────────────────────┴─────────────────────┘
```

---

## Prerequisites

Before configuring Supabase, complete:

1. **Google Setup** - See [google-guide.md](google-guide.md)
   - Web Client ID and Secret

2. **Apple Setup** - See [apple-guide.md](apple-guide.md)
   - Service ID
   - Team ID
   - Key ID
   - Private Key (.p8 file)

---

## Step 1: Access Auth Providers

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Authentication** → **Providers**

---

## Step 2: Configure Google Provider

1. Find **Google** in the providers list
2. Toggle to **Enabled**

### Configuration Values

| Field | Value | Source |
|-------|-------|--------|
| Client ID | `xxx.apps.googleusercontent.com` | Google Cloud Console → Web Client |
| Client Secret | `GOCSPX-xxx` | Google Cloud Console → Web Client |

### Get Client Secret

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to **APIs & Services** → **Credentials**
3. Click on your **Web Client** OAuth client
4. Copy the **Client Secret**

> **Note:** Only the Web Client has a secret. iOS and Android clients don't have secrets.

---

## Step 3: Configure Apple Provider

1. Find **Apple** in the providers list
2. Toggle to **Enabled**

### Configuration Values

| Field | Value | Source |
|-------|-------|--------|
| Service ID | `com.company.myapp.android` | Apple Developer → Service IDs |
| Team ID | `TEAM123456` | Apple Developer portal (top-right) |
| Key ID | `ABC123DEFG` | Apple Developer → Keys |
| Private Key | `-----BEGIN PRIVATE KEY-----...` | Downloaded .p8 file |

### Private Key Format

Copy the **entire contents** of the `.p8` file:

```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
...multiple lines...
...
-----END PRIVATE KEY-----
```

Include the `-----BEGIN` and `-----END` lines.

---

## Step 4: Configure Redirect URLs

1. Go to **Authentication** → **URL Configuration**
2. Add redirect URLs:

### Site URL

Your app's main URL (for web) or leave as default for mobile.

### Redirect URLs

Add these URLs:

```
https://{your-project}.supabase.co/auth/v1/callback
{your.bundle.id}://login-callback
```

Replace `{your.bundle.id}` with your actual bundle ID (e.g., `com.company.myapp`).

### Example

```
https://abcdefghijk.supabase.co/auth/v1/callback
com.company.myapp://login-callback
```

---

## Understanding the Flow

### Google Sign-In Flow

```
1. User taps "Sign in with Google"
2. Flutter app calls GoogleSignIn.instance.signIn()
3. Google SDK shows native picker
4. User selects account
5. Google returns idToken to app
6. App sends idToken + nonce to Supabase
7. Supabase validates token with Google
8. Supabase creates/updates user
9. Supabase returns session to app
```

### Apple Sign-In Flow (iOS)

```
1. User taps "Sign in with Apple"
2. Flutter app calls SignInWithApple.getAppleIDCredential()
3. iOS shows native Apple Sign-In sheet
4. User authenticates (Face ID/Touch ID/Password)
5. Apple returns identityToken to app
6. App sends identityToken + nonce to Supabase
7. Supabase validates token with Apple
8. Supabase creates/updates user
9. Supabase returns session to app
```

### Apple Sign-In Flow (Android)

```
1. User taps "Sign in with Apple"
2. Flutter app calls supabase.auth.signInWithOAuth()
3. Browser opens to Apple sign-in page
4. User authenticates on Apple's website
5. Apple redirects to Supabase callback
6. Supabase creates/updates user
7. Supabase redirects to app's deep link
8. App receives deep link, retrieves session
```

---

## Supabase API Usage

See [reference/repositories/auth_repository_social_methods.dart](reference/repositories/auth_repository_social_methods.dart) for full implementation.

### Sign In with ID Token (Google/Apple iOS)

```dart
final response = await supabase.auth.signInWithIdToken(
  provider: OAuthProvider.google, // or OAuthProvider.apple
  idToken: idToken,
  nonce: rawNonce, // Raw nonce, NOT hashed
);
```

### Sign In with OAuth (Apple Android)

```dart
await supabase.auth.signInWithOAuth(
  OAuthProvider.apple,
  redirectTo: 'com.company.myapp://login-callback',
);
// Browser opens, app waits for deep link callback
```

### Get Current Session

```dart
final session = supabase.auth.currentSession;
if (session != null) {
  final accessToken = session.accessToken;
  final user = session.user;
}
```

### Listen to Auth State Changes

```dart
supabase.auth.onAuthStateChange.listen((data) {
  final event = data.event;
  final session = data.session;

  switch (event) {
    case AuthChangeEvent.signedIn:
      // User signed in
      break;
    case AuthChangeEvent.signedOut:
      // User signed out
      break;
    case AuthChangeEvent.tokenRefreshed:
      // Token was refreshed
      break;
  }
});
```

---

## User Data in Supabase

### Auth User Object

After social sign-in, the user object contains provider-specific metadata including email, name, avatar URL, and provider information.

### Accessing User Metadata

```dart
final user = supabase.auth.currentUser;
if (user != null) {
  final email = user.email;
  final fullName = user.userMetadata?['full_name'];
  final avatarUrl = user.userMetadata?['avatar_url'];
  final provider = user.appMetadata['provider'];
}
```

---

## Multiple Providers

Users can link multiple social accounts:

```dart
// User signed in with Google, now linking Apple
await supabase.auth.linkIdentity(OAuthProvider.apple);
```

Check linked providers:

```dart
final providers = user.appMetadata['providers'] as List;
// ['google', 'apple']
```

---

## Troubleshooting

### "Invalid token" Error

**Causes:**
1. Client ID mismatch between app and Supabase
2. Nonce mismatch (hashed vs raw)
3. Token expired

**Solutions:**
1. Verify Supabase Google Client ID matches Web Client ID
2. Send **raw** nonce to Supabase, **hashed** to provider
3. Retry sign-in (tokens expire quickly)

### "Provider not enabled"

**Cause:** Provider not toggled on in Supabase

**Solution:** Go to Authentication → Providers → Enable the provider

### "Redirect URL mismatch"

**Cause:** Redirect URL not in allowed list

**Solution:**
1. Go to Authentication → URL Configuration
2. Add your redirect URL to the list

### User Created but No Session

**Cause:** Redirect URL handling issue

**Solution:**
1. Check deep link is correctly configured
2. Verify app handles the callback URL
3. Check Supabase logs for errors

---

## Security Notes

### Token Validation

Supabase validates:
1. Token signature (from Google/Apple)
2. Token expiration
3. Token audience (your Client ID)
4. Nonce (prevents replay attacks)

### Nonce Best Practices

See [reference/utils/nonce_helpers.dart](reference/utils/nonce_helpers.dart) for implementation.

Key points:
- Generate cryptographically secure nonce with `Random.secure()`
- Hash nonce with SHA-256 for provider
- Send raw nonce to Supabase for validation

---

## Checklist

**Google Provider:**
- [ ] Enabled in Supabase
- [ ] Client ID is Web Client ID (not iOS/Android)
- [ ] Client Secret entered
- [ ] Tested sign-in works

**Apple Provider:**
- [ ] Enabled in Supabase
- [ ] Service ID matches Apple exactly
- [ ] Team ID correct
- [ ] Key ID correct
- [ ] Private key pasted (including BEGIN/END lines)
- [ ] Tested sign-in works

**Redirect URLs:**
- [ ] Supabase callback URL added
- [ ] App deep link URL added
- [ ] URLs match exactly (no trailing slashes)

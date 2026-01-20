# Social Login Setup Checklist

Comprehensive checklist for verifying social login configuration.

---

## Prerequisites

- [ ] Supabase project created and configured
- [ ] Flutter project has Supabase SDK integrated
- [ ] Apple Developer Program membership ($99/year) - for Apple Sign-In
- [ ] Google Cloud Console access

---

## 1. Flutter Dependencies

```bash
flutter pub deps | grep -E "google_sign_in|sign_in_with_apple|crypto"
```

- [ ] `google_sign_in: ^7.2.0` in pubspec.yaml
- [ ] `sign_in_with_apple: ^7.0.1` in pubspec.yaml
- [ ] `crypto: ^3.0.6` in pubspec.yaml
- [ ] `flutter pub get` executed

---

## 2. Environment Variables

Check `.env` file:

- [ ] `SUPABASE_URL` configured
- [ ] `SUPABASE_ANON_KEY` configured
- [ ] `GOOGLE_WEB_CLIENT_ID` configured
- [ ] `GOOGLE_IOS_CLIENT_ID` configured

Check `.gitignore`:

- [ ] `.env` is gitignored
- [ ] `.env.*` patterns gitignored
- [ ] `.env.example` exists (without secrets)

---

## 3. Google Cloud Console

### OAuth Consent Screen

- [ ] Consent screen created
- [ ] App name set
- [ ] User support email set
- [ ] Scopes include: `email`, `profile`, `openid`
- [ ] Test users added (if in testing mode)

### OAuth Clients

**Web Client:**
- [ ] Web Client ID created
- [ ] Redirect URI includes Supabase callback
- [ ] Client Secret obtained

**iOS Client:**
- [ ] iOS Client ID created
- [ ] Bundle ID matches app

**Android Clients:**
- [ ] Debug client with debug SHA-1
- [ ] Release client with release SHA-1
- [ ] Play Store client with Play Store SHA-1 (if publishing)

### SHA-1 Verification

```bash
cd android && ./gradlew signingReport
```

- [ ] Debug SHA-1 matches Cloud Console
- [ ] Release SHA-1 matches Cloud Console (if applicable)

---

## 4. Apple Developer Portal

### App ID

- [ ] App ID created
- [ ] Bundle ID matches app
- [ ] "Sign in with Apple" capability enabled

### Service ID (for Android OAuth)

- [ ] Service ID created
- [ ] Identifier noted (e.g., `com.company.myapp.android`)
- [ ] Domain configured: `{project}.supabase.co`
- [ ] Return URL: `https://{project}.supabase.co/auth/v1/callback`

### Key

- [ ] Key created with "Sign in with Apple"
- [ ] `.p8` file downloaded and stored securely
- [ ] Key ID noted
- [ ] Team ID noted

---

## 5. Supabase Configuration

### Google Provider

- [ ] Google provider enabled
- [ ] Client ID = Web Client ID
- [ ] Client Secret entered

### Apple Provider

- [ ] Apple provider enabled
- [ ] Service ID matches Apple Service ID exactly
- [ ] Team ID correct
- [ ] Key ID correct
- [ ] Private Key pasted (including BEGIN/END lines)

### Redirect URLs

- [ ] `https://{project}.supabase.co/auth/v1/callback` added
- [ ] `{bundle.id}://login-callback` added

---

## 6. iOS Configuration

### Info.plist

```bash
grep -A5 "CFBundleURLTypes" ios/Runner/Info.plist
```

- [ ] `CFBundleURLTypes` includes reversed Google iOS Client ID
- [ ] `LSApplicationQueriesSchemes` includes `google`, `googlechrome`

### Xcode Capabilities

```bash
cat ios/Runner/Runner.entitlements 2>/dev/null || echo "No entitlements file"
```

- [ ] "Sign in with Apple" capability added in Xcode
- [ ] `Runner.entitlements` exists with `com.apple.developer.applesignin`

### Signing

- [ ] Team selected in Xcode
- [ ] Bundle ID matches App ID

---

## 7. Android Configuration

### AndroidManifest.xml

```bash
grep -A4 "login-callback" android/app/src/main/AndroidManifest.xml
```

- [ ] Deep link intent-filter added
- [ ] Scheme matches bundle ID
- [ ] Host is `login-callback`

### Internet Permission

```bash
grep "INTERNET" android/app/src/main/AndroidManifest.xml
```

- [ ] `android.permission.INTERNET` present

---

## 8. Flutter Code

### Domain Layer

```bash
ls lib/features/auth/domain/repositories/
```

- [ ] `social_auth_repository.dart` exists
- [ ] Interface has `signInWithGoogle()` method
- [ ] Interface has `signInWithApple()` method

### Domain Layer - Failures

```bash
ls lib/features/auth/domain/failures/
```

- [ ] `social_auth_failures.dart` exists
- [ ] Uses sealed `SocialAuthFailure` class (matches data layer pattern)
- [ ] Includes cancellation failures (for silent handling)
- [ ] Includes retryable failures (for retry UI)

### Data Layer

```bash
grep -l "SocialAuthRepository" lib/features/auth/data/repositories/
```

- [ ] `AuthRepositoryImpl` implements `SocialAuthRepository`
- [ ] `MockSocialAuthRepository` exists for testing
- [ ] Nonce generation implemented
- [ ] Platform detection for Apple Sign-In
- [ ] Errors mapped to `SocialAuthFailure` types

### Presentation Layer

- [ ] `socialAuthRepositoryProvider` exists
- [ ] `signInWithGoogle()` method in AuthNotifier
- [ ] `signInWithApple()` method in AuthNotifier
- [ ] `OAuthPendingException` handled

### UI

- [ ] Social login buttons in LoginScreen
- [ ] `OAuthCallbackScreen` for Android callback

### Router

- [ ] `/login-callback` route configured
- [ ] Route points to `OAuthCallbackScreen`

---

## 9. i18n Strings

Run `/i18n` skill to add localized strings:

```bash
/i18n auth
```

Required string keys:
- [ ] `t.auth.buttons.continueWithGoogle`
- [ ] `t.auth.buttons.continueWithApple`
- [ ] `t.auth.social.or`
- [ ] `t.auth.social.completingSignIn`
- [ ] `t.auth.errors.socialLoginFailed`

---

## 10. Testing Matrix

### Google Sign-In

| Platform | Environment | Status |
|----------|-------------|--------|
| iOS Simulator | Debug | [ ] |
| iOS Device | Debug | [ ] |
| iOS Device | Release | [ ] |
| Android Emulator | Debug | [ ] |
| Android Device | Debug | [ ] |
| Android Device | Release | [ ] |
| Play Store | Production | [ ] |

### Apple Sign-In

| Platform | Environment | Status |
|----------|-------------|--------|
| iOS Simulator | Debug | [ ] |
| iOS Device | Debug | [ ] |
| iOS Device | Release | [ ] |
| Android Device | Debug (OAuth) | [ ] |
| Android Device | Release (OAuth) | [ ] |

### Edge Cases

- [ ] User cancels Google Sign-In (silent, no error shown)
- [ ] User cancels Apple Sign-In (silent, no error shown)
- [ ] Network error during sign-in (retry button shown)
- [ ] Token refresh works
- [ ] Sign out clears all data
- [ ] App restart maintains session
- [ ] First-time user detection works (`isNewUser` flag)
- [ ] Apple "Hide My Email" handled (email may be null)

### Unit Tests with Mock Repository

```dart
// Test Google sign-in
final mockRepo = createSuccessMock();
await mockRepo.signInWithGoogle();
expect(mockRepo.wasGoogleSignInCalled, isTrue);

// Test cancellation handling
final cancelledMock = createGoogleCancelledMock();
expect(() => cancelledMock.signInWithGoogle(),
  throwsA(isA<GoogleSignInCancelledFailure>()));

// Test new user flow
final newUserMock = createNewUserMock();
final result = await newUserMock.signInWithGoogle();
expect(result?.isNewUser, isTrue);
```

- [ ] Success scenarios tested
- [ ] Cancellation scenarios tested
- [ ] Error scenarios tested
- [ ] New user flow tested

---

## 11. Security Verification

### Sensitive Files Not Committed

```bash
git status --porcelain | grep -E "\.env|\.p8|\.jks|key\.properties"
```

- [ ] `.env` not in git
- [ ] `.p8` files not in git
- [ ] `key.properties` not in git
- [ ] `.jks` / `.keystore` not in git

### Nonce Implementation

- [ ] Using `Random.secure()` for nonce generation
- [ ] Hashed nonce sent to provider
- [ ] Raw nonce sent to Supabase

---

## Quick Diagnostic Commands

```bash
# Check all social login related files
find . -name "*.dart" | xargs grep -l "signInWithGoogle\|signInWithApple" 2>/dev/null

# Check environment variables
cat .env | grep -E "GOOGLE|APPLE|SUPABASE"

# Check iOS config
plutil -p ios/Runner/Info.plist | grep -A3 "CFBundleURLSchemes"

# Check Android config
grep -B2 -A6 "login-callback" android/app/src/main/AndroidManifest.xml

# Get SHA-1 fingerprints
cd android && ./gradlew signingReport 2>/dev/null | grep SHA1

# Verify packages
flutter pub deps | grep -E "google_sign_in|sign_in_with_apple|crypto|supabase"
```

---

## Troubleshooting Quick Reference

| Issue | Check |
|-------|-------|
| Google: DEVELOPER_ERROR | SHA-1 fingerprint mismatch |
| Google: No idToken | Missing serverClientId |
| Apple: No callback (Android) | Deep link intent-filter |
| Apple: invalid_client | Supabase Apple config |
| Both: Token validation fails | Nonce handling (raw vs hashed) |

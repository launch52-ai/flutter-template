# Apple Sign-In Setup Guide

Complete guide for configuring Sign in with Apple for iOS native and Android OAuth flows.

---

## Overview

Apple Sign-In works differently on each platform:

| Platform | Flow | User Experience |
|----------|------|-----------------|
| **iOS** | Native SDK | Face ID/Touch ID, seamless |
| **Android** | OAuth Browser | Opens Safari/Chrome, redirects back |

Both flows use Supabase as the backend to validate tokens and create sessions.

---

## Prerequisites

- Apple Developer Program membership ($99/year)
- Supabase project created
- Bundle ID decided (e.g., `com.company.myapp`)

---

## Step 1: Create App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers)
2. Click **Identifiers** → **+** button
3. Select **App IDs** → **Continue**
4. Select **App** type → **Continue**

### Configure App ID

| Field | Value |
|-------|-------|
| Description | Your app name |
| Bundle ID | Explicit: `com.company.myapp` |

### Enable Capabilities

Scroll down and check:
- [x] **Sign in with Apple**

Click **Continue** → **Register**

---

## Step 2: Create Service ID (for Android)

The Service ID is used for OAuth flows (Android, web).

1. Go to **Identifiers** → **+** button
2. Select **Services IDs** → **Continue**

### Configure Service ID

| Field | Value |
|-------|-------|
| Description | `{App Name} Android` or `{App Name} Web` |
| Identifier | `com.company.myapp.android` |

### Configure Sign in with Apple

1. Check **Sign in with Apple**
2. Click **Configure**

| Field | Value |
|-------|-------|
| Primary App ID | Select your App ID |
| Domains | `{your-project}.supabase.co` |
| Return URLs | `https://{your-project}.supabase.co/auth/v1/callback` |

3. Click **Save** → **Continue** → **Register**

> **Important:** The Service ID identifier (e.g., `com.company.myapp.android`) is what you'll configure in Supabase as the "Service ID".

---

## Step 3: Create Key for Sign in with Apple

1. Go to **Keys** → **+** button
2. Configure:

| Field | Value |
|-------|-------|
| Key Name | `{App Name} Sign in with Apple` |
| Sign in with Apple | Checked |

3. Click **Configure** next to Sign in with Apple
4. Select your **Primary App ID**
5. Click **Save** → **Continue** → **Register**

### Download Key File

**Critical:** Download the `.p8` key file immediately. You can only download it once!

Note these values:
- **Key ID**: Shown on the key details page (e.g., `ABC123DEFG`)
- **Team ID**: Found in top-right of Apple Developer portal (e.g., `TEAM123456`)

---

## Step 4: Configure Supabase

See [supabase-guide.md](supabase-guide.md) for detailed Supabase configuration.

1. Go to Supabase Dashboard → **Authentication** → **Providers**
2. Enable **Apple**

| Field | Value | Where to Find |
|-------|-------|---------------|
| Service ID | `com.company.myapp.android` | Service ID identifier from Step 2 |
| Team ID | `TEAM123456` | Apple Developer portal, top-right |
| Key ID | `ABC123DEFG` | Key details page from Step 3 |
| Private Key | Contents of `.p8` file | Downloaded file from Step 3 |

---

## Step 5: Configure iOS

### Add Capability in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Sign in with Apple**

This creates `ios/Runner/Runner.entitlements`. See template: [templates/Runner.entitlements](templates/Runner.entitlements)

### Verify Signing

Ensure your Team is selected in **Signing & Capabilities** and the Bundle ID matches your App ID.

---

## Step 6: Configure Android

Android uses OAuth browser flow, which requires a deep link to return to the app.

### Add Deep Link Intent Filter

Use template: [templates/android_manifest_additions.xml](templates/android_manifest_additions.xml)

Add to `android/app/src/main/AndroidManifest.xml` inside `<activity>`.

Replace the scheme with your actual bundle ID.

### Ensure Internet Permission

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## Flutter Implementation

See [reference/repositories/auth_repository_social_methods.dart](reference/repositories/auth_repository_social_methods.dart) for the full implementation.

Key points:

1. **Platform detection** - Use native SDK on iOS, OAuth on Android
2. **iOS native flow** - Uses `SignInWithApple.getAppleIDCredential()`
3. **Android OAuth flow** - Opens browser, throws `OAuthPendingException`
4. **Store Apple's name** - Only provided on first sign-in

See also:
- [reference/screens/oauth_callback_screen.dart](reference/screens/oauth_callback_screen.dart) - Handles Android callback
- [reference/exceptions/oauth_pending_exception.dart](reference/exceptions/oauth_pending_exception.dart) - Exception class

---

## Important Notes

### Apple Only Provides Name Once

Apple sends the user's name **only on first sign-in**. After that, it's never sent again.

**Solution:** Store the name immediately when received. See implementation in [reference/repositories/auth_repository_social_methods.dart](reference/repositories/auth_repository_social_methods.dart).

### Email Can Be Hidden

Users can choose "Hide My Email" which gives a relay address like:
```
abc123@privaterelay.appleid.com
```

Your app should handle this gracefully.

### Simulator Limitations

Apple Sign-In on iOS Simulator:
- Works in iOS 13+ simulators
- May require signing in to iCloud on the simulator
- Best tested on real devices

---

## Troubleshooting

### "Authorization failed" on iOS

**Causes:**
1. Sign in with Apple capability not added in Xcode
2. Bundle ID mismatch
3. App ID not registered with Sign in with Apple

**Solutions:**
1. Add capability in Xcode → Signing & Capabilities
2. Verify Bundle ID matches App ID exactly
3. Check Apple Developer portal App ID configuration

### No Callback on Android

**Causes:**
1. Deep link intent filter incorrect
2. Scheme/host mismatch
3. Return URL not configured in Service ID

**Solutions:**
1. Verify AndroidManifest.xml intent filter
2. Check scheme matches your bundle ID
3. Verify Supabase callback URL in Service ID

### "invalid_client" Error

**Causes:**
1. Service ID not configured correctly
2. Private key mismatch
3. Team ID incorrect

**Solutions:**
1. Verify Service ID in Supabase matches Apple exactly
2. Re-download and re-paste private key
3. Double-check Team ID from Apple Developer portal

### User Cancelled

This is normal - user closed the sign-in dialog. Handle gracefully by checking for null result.

---

## Security Best Practices

1. **Never commit `.p8` files** - Store securely, use secrets management
2. **Use PKCE with nonce** - Prevents token replay attacks
3. **Validate server-side** - Supabase validates tokens
4. **Store name securely** - Use SecureStorage, not SharedPreferences

---

## Checklist

**Apple Developer Portal:**
- [ ] App ID created with Sign in with Apple
- [ ] Service ID created and configured
- [ ] Key created and `.p8` file downloaded
- [ ] Team ID noted

**Supabase:**
- [ ] Apple provider enabled
- [ ] Service ID configured
- [ ] Team ID configured
- [ ] Key ID configured
- [ ] Private key pasted

**iOS:**
- [ ] Sign in with Apple capability added in Xcode
- [ ] Bundle ID matches App ID
- [ ] Tested on simulator
- [ ] Tested on device

**Android:**
- [ ] Deep link intent filter added
- [ ] Scheme matches bundle ID
- [ ] OAuth callback screen implemented
- [ ] Tested browser flow on device

**Code:**
- [ ] Platform detection (iOS vs Android)
- [ ] Native flow for iOS
- [ ] OAuth flow for Android
- [ ] Name storage on first sign-in
- [ ] Cancel handling

# Google Sign-In Setup Guide

Complete guide for configuring Google Sign-In with Google Cloud Console.

---

## Overview

Google Sign-In requires OAuth 2.0 client IDs for each platform:

| Client Type | Purpose | Used By |
|-------------|---------|---------|
| **Web Client** | Server-side validation, Android serverClientId | Android (for idToken) |
| **iOS Client** | Native iOS sign-in | iOS app |
| **Android Client** | Native Android sign-in | Android app (per SHA-1) |

**Important:** Android requires BOTH a Web Client ID (for serverClientId) AND Android Client IDs (for each SHA-1 fingerprint).

---

## Step 1: Create OAuth Consent Screen

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select or create a project
3. Navigate to **APIs & Services** → **OAuth consent screen**

### Configure Consent Screen

| Field | Value |
|-------|-------|
| User Type | External |
| App name | Your app name |
| User support email | Your email |
| Developer contact email | Your email |

### Add Scopes

Click **Add or Remove Scopes** and select:
- `email`
- `profile`
- `openid`

### Test Users (Development)

While in testing mode, add test users who can sign in:
- Your email
- Team member emails

> **Note:** Move to "In production" before public release.

---

## Step 2: Create Web Client ID

This is required for Android to receive an `idToken`.

1. Navigate to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**

| Field | Value |
|-------|-------|
| Application type | Web application |
| Name | `{App Name} Web Client` |

### Authorized Redirect URIs

Add your Supabase callback URL:
```
https://{your-project}.supabase.co/auth/v1/callback
```

### Save Client ID

After creation, copy the **Client ID**. This is your `GOOGLE_WEB_CLIENT_ID`.

Example format:
```
123456789012-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com
```

---

## Step 3: Create iOS Client ID

1. Click **Create Credentials** → **OAuth client ID**

| Field | Value |
|-------|-------|
| Application type | iOS |
| Name | `{App Name} iOS` |
| Bundle ID | Your iOS bundle ID (e.g., `com.company.myapp`) |

### Save Client ID

Copy the **Client ID**. This is your `GOOGLE_IOS_CLIENT_ID`.

### Reversed Client ID for URL Scheme

For Info.plist, you need the reversed client ID:

| Original | Reversed |
|----------|----------|
| `123456789-abc.apps.googleusercontent.com` | `com.googleusercontent.apps.123456789-abc` |

---

## Step 4: Create Android Client IDs

Android requires separate OAuth clients for each signing key (SHA-1 fingerprint).

### Required SHA-1 Fingerprints

| Environment | Source | When Used |
|-------------|--------|-----------|
| **Debug** | Local debug keystore | `flutter run` development |
| **Release** | Your upload keystore | Manual APK/AAB builds |
| **Play Store** | Google Play signing key | Production from Play Store |

### Get Debug SHA-1

```bash
cd android && ./gradlew signingReport
```

Look for output like:
```
Variant: debug
Config: debug
Store: /Users/{user}/.android/debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

### Get Release SHA-1

If you have a release keystore:
```bash
keytool -list -v -keystore /path/to/{project_name}.jks -alias {alias_name}
```

### Get Play Store SHA-1

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Navigate to **Setup** → **App signing**
4. Copy **SHA-1 certificate fingerprint** under "App signing key certificate"

### Create Android Clients

For each SHA-1, create a separate OAuth client:

1. Click **Create Credentials** → **OAuth client ID**

| Field | Value |
|-------|-------|
| Application type | Android |
| Name | `{App Name} Android {Environment}` |
| Package name | Your package name (e.g., `com.company.myapp`) |
| SHA-1 certificate fingerprint | The SHA-1 for this environment |

Create clients named like:
- `{App Name} Android Debug`
- `{App Name} Android Release`
- `{App Name} Android Play Store`

---

## Step 5: Configure Environment Variables

Add to your `.env` file:

```env
# Google Sign-In
GOOGLE_WEB_CLIENT_ID=123456789012-xxxxx.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=123456789012-yyyyy.apps.googleusercontent.com
```

---

## Step 6: Configure iOS Info.plist

Use template: [templates/info_plist_additions.xml](templates/info_plist_additions.xml)

Add to `ios/Runner/Info.plist` with your reversed iOS Client ID.

---

## Flutter Implementation

See [reference/repositories/auth_repository_social_methods.dart](reference/repositories/auth_repository_social_methods.dart) for the full implementation.

Key points:

1. **Initialize with both client IDs:**
   - `serverClientId`: Web Client ID (required for Android idToken)
   - `clientId`: iOS Client ID (required for iOS)

2. **Use PKCE with nonce** for security - see [reference/utils/nonce_helpers.dart](reference/utils/nonce_helpers.dart)

3. **Send raw nonce to Supabase**, hashed nonce to Google

---

## Troubleshooting

### DEVELOPER_ERROR (Error 10)

**Cause:** SHA-1 fingerprint mismatch

**Solutions:**
1. Verify package name matches exactly (case-sensitive)
2. Check which keystore is being used:
   ```bash
   ./gradlew signingReport
   ```
3. Add the correct SHA-1 to Google Cloud Console
4. Wait 5-10 minutes (Google caches configurations)

### sign_in_failed

**Cause:** Missing or incorrect Web Client ID

**Solutions:**
1. Verify `GOOGLE_WEB_CLIENT_ID` is set in `.env`
2. Ensure it's the **Web Client** ID, not Android or iOS
3. Check that Web Client has Supabase callback URL

### No idToken Returned

**Cause:** Missing serverClientId parameter

**Solution:** Pass Web Client ID to `initialize()`:
```dart
await GoogleSignIn.instance.initialize(
  serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'], // Required!
);
```

### "Access blocked: This app's request is invalid"

**Cause:** OAuth consent screen not configured properly

**Solutions:**
1. Complete OAuth consent screen setup
2. Add test users if in testing mode
3. Verify redirect URIs include Supabase callback

### Works in Debug, Fails in Release

**Cause:** Release SHA-1 not registered

**Solution:**
Add release keystore SHA-1 to Google Cloud Console as a new Android OAuth client.

### Works Locally, Fails from Play Store

**Cause:** Play Store uses different signing key

**Solution:**
1. Get SHA-1 from Play Console → Setup → App signing
2. Create new Android OAuth client with Play Store SHA-1

---

## Security Best Practices

1. **Never commit client IDs to public repos** - Use `.env` files
2. **Use PKCE with nonce** - Prevents token replay attacks
3. **Validate on server** - Supabase validates the nonce
4. **Restrict OAuth clients** - Each client should have minimal permissions

---

## Checklist

- [ ] OAuth consent screen configured
- [ ] Web Client ID created
- [ ] iOS Client ID created
- [ ] Android Client ID (Debug) created
- [ ] Android Client ID (Release) created
- [ ] Android Client ID (Play Store) created - if publishing
- [ ] GOOGLE_WEB_CLIENT_ID in .env
- [ ] GOOGLE_IOS_CLIENT_ID in .env
- [ ] iOS Info.plist URL scheme added
- [ ] iOS Info.plist query schemes added
- [ ] Google Sign-In tested on iOS simulator
- [ ] Google Sign-In tested on iOS device
- [ ] Google Sign-In tested on Android emulator
- [ ] Google Sign-In tested on Android device

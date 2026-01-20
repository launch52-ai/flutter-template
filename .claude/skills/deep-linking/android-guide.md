# Android Guide - App Links

App Links configuration for Android to handle HTTPS deep links without disambiguation dialogs.

---

## Overview

Android App Links allow your app to handle `https://` URLs directly. When `autoVerify="true"` is set and verification succeeds, your app opens immediately without showing an app chooser.

**Requirements:**
- Android 6.0+ (API 23+) for App Links
- Android 7.0+ (API 24) for project minimum
- HTTPS domain with valid SSL certificate
- Digital Asset Links file on server

---

## Step 1: Create assetlinks.json

Create a file named `assetlinks.json` and host it at:

```
https://yourdomain.com/.well-known/assetlinks.json
```

**File content:**

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.yourapp",
      "sha256_cert_fingerprints": [
        "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
      ]
    }
  }
]
```

**Multiple fingerprints** (debug + release + Play Store):

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.yourapp",
      "sha256_cert_fingerprints": [
        "DEBUG_SHA256_FINGERPRINT",
        "RELEASE_SHA256_FINGERPRINT",
        "PLAY_STORE_SHA256_FINGERPRINT"
      ]
    }
  }
]
```

---

## Step 2: Get SHA-256 Fingerprints

### Debug Keystore

```bash
cd android && ./gradlew signingReport
```

Look for `SHA-256` under the debug variant.

Or manually:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Release Keystore

```bash
keytool -list -v -keystore /path/to/release.keystore -alias your-alias
```

### Play Store (App Signing)

1. Go to Google Play Console
2. Select your app
3. **Setup** > **App signing**
4. Copy **SHA-256 certificate fingerprint** under "App signing key certificate"

**Important:** If using Play App Signing, the Play Store re-signs your app. You need BOTH:
- Your upload key fingerprint (for local testing)
- Play Store signing key fingerprint (for production)

---

## Step 3: Server Configuration

### Hosting Requirements

1. **HTTPS required** - Valid SSL certificate
2. **No redirects** - Direct access to file
3. **Correct MIME type** - `application/json`
4. **No authentication** - Publicly accessible

### Nginx Configuration

```nginx
location /.well-known/assetlinks.json {
    default_type application/json;
    add_header Content-Type application/json;
}
```

### Verify Hosting

```bash
# Check file is accessible
curl -I https://yourdomain.com/.well-known/assetlinks.json

# Check content
curl https://yourdomain.com/.well-known/assetlinks.json
```

---

## Step 4: AndroidManifest Configuration

Add intent filters to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <application>
        <activity
            android:name=".MainActivity"
            android:launchMode="singleTop"
            android:exported="true">

            <!-- Existing intent filter for main launcher -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- App Links intent filter -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data
                    android:scheme="https"
                    android:host="yourdomain.com"
                    android:pathPrefix="/products"/>
                <data
                    android:scheme="https"
                    android:host="yourdomain.com"
                    android:pathPrefix="/users"/>
            </intent-filter>

        </activity>
    </application>
</manifest>
```

**See:** `templates/android/android_manifest_deeplinks.xml` for template.

### Intent Filter Attributes

| Attribute | Description |
|-----------|-------------|
| `android:autoVerify="true"` | Enables App Links verification |
| `android:scheme` | `https` (or `http`, but prefer HTTPS) |
| `android:host` | Your domain without `https://` |
| `android:pathPrefix` | Matches paths starting with value |
| `android:path` | Exact path match |
| `android:pathPattern` | Regex-like pattern |

### Path Matching

| Attribute | Pattern | Matches |
|-----------|---------|---------|
| `pathPrefix` | `/products` | `/products`, `/products/123`, `/products/abc/details` |
| `path` | `/products/list` | Only `/products/list` |
| `pathPattern` | `/products/.*` | `/products/123`, `/products/abc` |

**Note:** `pathPattern` uses `.*` for wildcards, `\\` to escape dots.

---

## Step 5: Testing

### ADB Commands

```bash
# Test App Link
adb shell am start -a android.intent.action.VIEW \
  -c android.intent.category.BROWSABLE \
  -d "https://yourdomain.com/products/123" \
  com.example.yourapp

# Check App Links verification status
adb shell pm get-app-links com.example.yourapp

# Force re-verification
adb shell pm verify-app-links --re-verify com.example.yourapp
```

### Verification Status Output

```
com.example.yourapp:
    ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    Signatures: [AA:BB:CC:...]
    Domain verification state:
        yourdomain.com: verified
```

States:
- `verified` - App Links work without chooser
- `none` - Verification not attempted
- `legacy_failure` - Verification failed
- `always` - User set app as default (not auto-verified)

### Debug on Device

1. Install app
2. Open Chrome/browser
3. Navigate to your deep link URL
4. App should open directly (no chooser)

---

## Multiple Domains

### Same App, Multiple Domains

Add multiple `<data>` elements:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="https" android:host="yourdomain.com"/>
    <data android:scheme="https" android:host="www.yourdomain.com"/>
    <data android:scheme="https" android:host="staging.yourdomain.com"/>
</intent-filter>
```

Create `assetlinks.json` on each domain (can be identical).

### Separate Intent Filters

For different path patterns per domain:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="https" android:host="yourdomain.com" android:pathPrefix="/products"/>
</intent-filter>

<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="https" android:host="api.yourdomain.com" android:pathPrefix="/share"/>
</intent-filter>
```

---

## Custom URL Schemes (Fallback)

For backwards compatibility:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="myapp"/>
</intent-filter>
```

This handles `myapp://path` URLs.

**Note:** Custom schemes always show chooser if multiple apps handle the scheme. App Links with `autoVerify` do not.

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| App chooser shows | Verification failed | Check `assetlinks.json` and fingerprints |
| `legacy_failure` status | Wrong fingerprint | Use correct SHA-256 (debug/release/Play) |
| Works debug, not release | Different signing key | Add release fingerprint |
| Works locally, not Play Store | Play App Signing | Add Play Store fingerprint |
| Verification takes time | Android caches | Wait or force re-verify |

### Validation Tools

- [Google Digital Asset Links Tester](https://developers.google.com/digital-asset-links/tools/generator)
- Statement list API: `https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://yourdomain.com&relation=delegate_permission/common.handle_all_urls`

---

## Related

- [ios-guide.md](ios-guide.md) - iOS Universal Links setup
- [implementation-guide.md](implementation-guide.md) - GoRouter integration
- [checklist.md](checklist.md) - Verification checklist

# iOS Guide - Universal Links

Universal Links configuration for iOS to handle HTTPS deep links.

---

## Overview

Universal Links allow your app to handle `https://` URLs directly, bypassing Safari. When a user taps a Universal Link, iOS opens your app if installed, or falls back to the website.

**Requirements:**
- iOS 13.0+ (project minimum)
- HTTPS domain with valid SSL certificate
- Associated Domains capability

---

## Step 1: Create apple-app-site-association

Create a file named `apple-app-site-association` (no extension) and host it at:

```
https://yourdomain.com/.well-known/apple-app-site-association
```

**File content:**

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.example.yourapp",
        "paths": [
          "/products/*",
          "/users/*",
          "/orders/*",
          "NOT /admin/*"
        ]
      }
    ]
  }
}
```

**Field reference:**

| Field | Description |
|-------|-------------|
| `appID` | `TEAM_ID.BUNDLE_ID` - Find Team ID in Apple Developer Portal |
| `paths` | URL paths the app handles. Use `*` for wildcard, `NOT` to exclude |

### Path Patterns

| Pattern | Matches |
|---------|---------|
| `/products/*` | `/products/123`, `/products/abc/details` |
| `/users/*/profile` | `/users/123/profile` |
| `NOT /admin/*` | Excludes admin paths |
| `*` | All paths (use carefully) |

---

## Step 2: Server Configuration

### Hosting Requirements

1. **HTTPS required** - No HTTP, no self-signed certificates
2. **No redirects** - File must be accessible directly at the URL
3. **Correct MIME type** - `application/json`
4. **No authentication** - File must be publicly accessible

### Nginx Configuration

```nginx
location /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Content-Type application/json;
}
```

### Apache Configuration

```apache
<Directory "/.well-known">
    <Files "apple-app-site-association">
        Header set Content-Type "application/json"
    </Files>
</Directory>
```

### CloudFront/S3

Set metadata on the file:
- `Content-Type: application/json`

### Verify Hosting

```bash
# Check file is accessible
curl -I https://yourdomain.com/.well-known/apple-app-site-association

# Should return:
# HTTP/2 200
# content-type: application/json

# Check content
curl https://yourdomain.com/.well-known/apple-app-site-association
```

---

## Step 3: Xcode Configuration

### Add Associated Domains Capability

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Associated Domains**

### Add Domain to Entitlements

Add your domain with `applinks:` prefix:

```
applinks:yourdomain.com
```

For multiple environments:

```
applinks:yourdomain.com
applinks:staging.yourdomain.com
```

**Note:** Do NOT include `https://` or paths.

### Entitlements File

The capability creates `Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:yourdomain.com</string>
    </array>
</dict>
</plist>
```

**See:** `templates/ios/Runner.entitlements` for template.

---

## Step 4: Find Your Team ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Click **Membership** in sidebar
3. Find **Team ID** (10-character string)

Or in Xcode:
1. Select Runner target
2. Go to Signing & Capabilities
3. Team ID is shown under the team name

---

## Step 5: Testing

### Simulator Testing

```bash
# Open Universal Link in simulator
xcrun simctl openurl booted "https://yourdomain.com/products/123"
```

### Physical Device Testing

1. Install app on device
2. Send yourself a link via Notes, Messages, or Mail
3. Tap the link - should open app directly

### Debug Mode

In Xcode, add launch argument to debug:

```
-com.apple.CoreSimulator.IndigoFramebufferServices 1
```

### Verify Association

Apple validates the association file when:
- App is installed
- App is updated
- Device restarts

Force re-validation by reinstalling the app.

### CDN Cache Issues

If using a CDN, the AASA file may be cached. Apple also caches the file. Changes can take 24-48 hours to propagate.

For faster testing during development, use the `?mode=developer` query parameter (iOS 14+):

```
applinks:yourdomain.com?mode=developer
```

This bypasses Apple's CDN cache but still requires your server to serve the file.

---

## Multiple Domains

### Same App, Multiple Domains

Add all domains to entitlements:

```xml
<array>
    <string>applinks:yourdomain.com</string>
    <string>applinks:www.yourdomain.com</string>
    <string>applinks:app.yourdomain.com</string>
</array>
```

Create AASA file for each domain (can be identical content).

### Staging/Production Environments

```xml
<array>
    <string>applinks:yourdomain.com</string>
    <string>applinks:staging.yourdomain.com</string>
</array>
```

Use different paths or conditions in your app to handle each environment.

---

## Custom URL Schemes (Fallback)

For backwards compatibility or when Universal Links aren't possible:

### Info.plist

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

This handles `myapp://path` URLs.

**Note:** Custom schemes show a confirmation dialog. Universal Links do not.

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Link opens Safari | AASA not found | Check URL and MIME type |
| Link opens Safari | App not installed | Expected behavior |
| Link opens Safari | Wrong Team ID | Verify `TEAM_ID.BUNDLE_ID` |
| Link opens Safari after reinstall | Cache issue | Wait 24h or use developer mode |
| Works in dev, not TestFlight | Different bundle ID | Check AASA has correct bundle ID |
| Works in TestFlight, not App Store | Release signing | Verify Team ID matches |

### Validation Tools

- [Apple App Search API Validation Tool](https://search.developer.apple.com/appsearch-validation-tool/)
- [Branch.io AASA Validator](https://branch.io/resources/aasa-validator/)

---

## Related

- [android-guide.md](android-guide.md) - Android App Links setup
- [implementation-guide.md](implementation-guide.md) - GoRouter integration
- [checklist.md](checklist.md) - Verification checklist

# Deep Linking Checklist

Verification checklist for deep linking implementation.

---

## Server Setup

- [ ] Domain has valid HTTPS certificate
- [ ] `.well-known` directory exists and is accessible
- [ ] Files return `Content-Type: application/json`
- [ ] No redirects on `.well-known` files
- [ ] Files are publicly accessible (no auth)

### iOS: apple-app-site-association

- [ ] File hosted at `https://domain.com/.well-known/apple-app-site-association`
- [ ] `appID` format is correct: `TEAM_ID.BUNDLE_ID`
- [ ] `paths` array includes all deep link paths
- [ ] File validates at [Apple AASA Validator](https://search.developer.apple.com/appsearch-validation-tool/)

```bash
# Verify file is accessible
curl -I https://yourdomain.com/.well-known/apple-app-site-association
# Should return: HTTP/2 200, content-type: application/json
```

### Android: assetlinks.json

- [ ] File hosted at `https://domain.com/.well-known/assetlinks.json`
- [ ] `package_name` matches app's `applicationId`
- [ ] Debug SHA-256 fingerprint added
- [ ] Release SHA-256 fingerprint added
- [ ] Play Store SHA-256 fingerprint added (if using Play App Signing)
- [ ] File validates at [Google DAL Tester](https://developers.google.com/digital-asset-links/tools/generator)

```bash
# Verify file is accessible
curl -I https://yourdomain.com/.well-known/assetlinks.json
# Should return: HTTP/2 200, content-type: application/json
```

---

## iOS Configuration

### Xcode

- [ ] Associated Domains capability added
- [ ] Domain added to entitlements: `applinks:yourdomain.com`
- [ ] No `https://` prefix in domain
- [ ] No trailing slash or path in domain

### Entitlements File

- [ ] `ios/Runner/Runner.entitlements` exists
- [ ] Contains `com.apple.developer.associated-domains` key
- [ ] Domain string format: `applinks:domain.com`

### Testing

- [ ] Universal Link opens app on simulator
- [ ] Universal Link opens app on physical device
- [ ] App handles link when already running
- [ ] App handles link when terminated

```bash
# Test on simulator
xcrun simctl openurl booted "https://yourdomain.com/products/123"
```

---

## Android Configuration

### AndroidManifest.xml

- [ ] Intent filter has `android:autoVerify="true"`
- [ ] Action is `android.intent.action.VIEW`
- [ ] Categories include `DEFAULT` and `BROWSABLE`
- [ ] Scheme is `https`
- [ ] Host matches domain exactly
- [ ] Path patterns match deep link paths

### Build Configuration

- [ ] MainActivity has `android:launchMode="singleTop"`
- [ ] Activity is exported (`android:exported="true"`)

### Testing

- [ ] App Link opens app without chooser (verified domain)
- [ ] `adb shell pm get-app-links` shows `verified` status
- [ ] Works with debug build
- [ ] Works with release build

```bash
# Test App Link
adb shell am start -a android.intent.action.VIEW \
  -d "https://yourdomain.com/products/123" com.example.app

# Check verification status
adb shell pm get-app-links com.example.app
```

---

## GoRouter Configuration

### Routes

- [ ] Routes defined for all deep link paths
- [ ] Path parameters extracted correctly (`:id`)
- [ ] Query parameters handled where needed
- [ ] Nested routes work within shell (if applicable)

### Error Handling

- [ ] Unknown routes show error page
- [ ] Invalid parameters handled gracefully
- [ ] Deep links logged for analytics

### Authentication

- [ ] Protected routes redirect to login with `?redirect=` param
- [ ] Deep link URL preserved in redirect query parameter
- [ ] After login, router detects redirect param and navigates to original deep link
- [ ] Direct navigation to `/login` (no redirect param) goes to home after login
- [ ] Tested full flow: tap deep link → login → arrives at deep link destination

---

## Integration

### Push Notifications

- [ ] Notification tap navigates to correct screen
- [ ] Deep link from terminated state works
- [ ] Deep link from background state works

### Analytics

- [ ] Deep link opens tracked
- [ ] Path and parameters logged
- [ ] Errors/failures logged

---

## Cross-Platform Testing

### Test Matrix

| Link | iOS Sim | iOS Device | Android Emu | Android Device |
|------|---------|------------|-------------|----------------|
| `/products/123` | [ ] | [ ] | [ ] | [ ] |
| `/users/456` | [ ] | [ ] | [ ] | [ ] |
| `/orders/789` | [ ] | [ ] | [ ] | [ ] |
| Unknown path | [ ] | [ ] | [ ] | [ ] |

### States Tested

- [ ] App in foreground
- [ ] App in background
- [ ] App terminated
- [ ] User logged in
- [ ] User logged out

---

## Production Readiness

- [ ] All fingerprints in `assetlinks.json` (debug, release, Play Store)
- [ ] Production domain in entitlements
- [ ] Staging domain removed (or separate build)
- [ ] Error tracking configured
- [ ] Deep link analytics working

---

## Common Issues Resolved

| Issue | Status |
|-------|--------|
| iOS: Link opens Safari | [ ] Fixed |
| Android: App chooser shown | [ ] Fixed |
| Path not matched | [ ] Fixed |
| Auth redirect loop | [ ] Fixed |
| Works dev, not prod | [ ] Fixed |

# iOS Release Guide

Complete guide for iOS app signing and App Store deployment.

---

## Prerequisites

| Requirement | Cost | Purpose |
|-------------|------|---------|
| **Mac with Xcode** | Free | Build iOS apps |
| **Apple Developer Account** | $99/year | Distribute to App Store |
| **Apple ID** | Free | Sign into Xcode |

---

## Overview

| Step | Purpose | Time |
|------|---------|------|
| 1. Xcode Signing | Configure Team & certificates | 10 min |
| 2. App ID | Register on Apple Developer | 5 min |
| 3. Capabilities | Add Sign in with Apple, Push, etc. | 10 min |
| 4. App Store Connect | Create app listing | 30 min |
| 5. Build & Upload | Create release IPA | 15 min |

> **Using CI/CD?** This guide covers manual Xcode signing. For automated CI/CD releases, use Fastlane `match` which stores certificates in a private Git repo and handles signing automatically. See `/ci-cd` skill for that approach.

---

## 1. Xcode Signing Configuration

### 1.1 Open Xcode Project

```bash
open ios/Runner.xcworkspace
```

> **Important:** Always open `.xcworkspace` (not `.xcodeproj`) for Flutter projects.

### 1.2 Select Team

1. Select **Runner** in the project navigator (left sidebar)
2. Select **Runner** target under TARGETS
3. Go to **Signing & Capabilities** tab
4. Check **Automatically manage signing**
5. Select your **Team** from dropdown

If no team appears:
1. Go to Xcode > **Settings** > **Accounts**
2. Click **+** to add Apple ID
3. Select your account > **Download Manual Profiles**

### 1.3 Bundle Identifier

Verify Bundle Identifier matches your intended ID:
- Should be unique (e.g., `com.yourcompany.appname`)
- Cannot be changed after app is live on App Store

### 1.4 Minimum Deployment Target

Set iOS deployment target:
1. Select **Runner** project
2. Go to **Info** tab
3. Set **iOS Deployment Target** to `13.0` (or your minimum)

---

## 2. Apple Developer Portal Setup

### 2.1 Create App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** > **+**
4. Select **App IDs** > **Continue**
5. Select **App** type > **Continue**
6. Configure:
   - **Description:** Your App Name
   - **Bundle ID:** Explicit (e.g., `com.yourcompany.appname`)
7. Enable required **Capabilities** (see section 3)
8. Click **Continue** > **Register**

### 2.2 Certificates

Xcode manages certificates automatically with "Automatically manage signing" enabled.

**Manual setup (if needed):**

1. **Identifiers** > **Certificates** > **+**
2. Select certificate type:
   - **Apple Distribution** - For App Store
   - **Apple Development** - For testing
3. Upload CSR (Certificate Signing Request)
4. Download and double-click to install

### 2.3 Provisioning Profiles

Usually automatic with Xcode. Manual if needed:

1. **Profiles** > **+**
2. Select **App Store** (for distribution)
3. Select your App ID
4. Select your distribution certificate
5. Download and double-click to install

---

## 3. Capabilities Configuration

### 3.1 Enable Capabilities in Xcode

1. Select **Runner** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add required capabilities

### 3.2 Common Capabilities

| Capability | When Needed | Configuration |
|------------|-------------|---------------|
| **Sign in with Apple** | Social login | Enable in Developer Portal + Xcode |
| **Push Notifications** | Remote notifications | Requires APNs key |
| **Associated Domains** | Deep links | Add `applinks:domain.com` |
| **Background Modes** | Background processing | Select specific modes |
| **App Groups** | Share data between apps | Create group in portal |

### 3.3 Sign in with Apple Setup

1. Enable capability in Xcode
2. Enable in Developer Portal (App ID > Edit > Enable)
3. Configure return URLs for OAuth (if using)

This creates/updates `ios/Runner/Runner.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
</dict>
</plist>
```

### 3.4 Push Notifications Setup

1. Enable capability in Xcode
2. Enable in Developer Portal
3. Create APNs Key:
   - **Keys** > **+**
   - Enable **Apple Push Notifications service (APNs)**
   - Download `.p8` file (can only download once!)
   - Note Key ID and Team ID

---

## 4. App Store Connect Setup

### 4.1 Create App

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** > **+** > **New App**
3. Configure:
   - **Platform:** iOS
   - **Name:** App display name
   - **Primary Language:** Your language
   - **Bundle ID:** Select from dropdown
   - **SKU:** Unique identifier (e.g., `com.company.app.v1`)
   - **User Access:** Full Access (usually)

### 4.2 App Information

Navigate to **App Information**:

| Field | Requirement |
|-------|-------------|
| **Name** | 30 characters max |
| **Subtitle** | 30 characters max (optional) |
| **Category** | Primary + Secondary |
| **Content Rights** | Declare if using third-party content |
| **Age Rating** | Complete questionnaire |

### 4.3 Pricing and Availability

1. Go to **Pricing and Availability**
2. Set price tier (or Free)
3. Select available countries

### 4.4 App Privacy

1. Go to **App Privacy**
2. Click **Get Started**
3. Answer data collection questions:
   - Does your app collect data?
   - What data types?
   - How is data used?
   - Is data linked to user?

### 4.5 Store Listing Requirements

| Asset | Specification |
|-------|---------------|
| **Screenshots** | See below |
| **Description** | Up to 4000 characters |
| **Keywords** | 100 characters max |
| **Support URL** | Required |
| **Marketing URL** | Optional |
| **Privacy Policy URL** | Required |
| **App Preview** | Video up to 30 seconds (optional) |

**Screenshot Requirements (2025):**

| Device | Dimensions | Required? |
|--------|------------|-----------|
| **iPhone 6.9"** | 1290 x 2796 px | **Yes** (or 6.5") |
| iPhone 6.5" | 1284 x 2778 px | Only if no 6.9" |
| iPhone 6.3", 6.1", 5.5" | Various | No - auto-scaled |
| **iPad 13"** | 2064 x 2752 px | **Yes** (if iPad) |
| iPad 12.9", 11" | Various | No - auto-scaled |

> **Simplified:** You only need **one iPhone size** (6.9" recommended) and **one iPad size** (13") if supporting iPad. Apple auto-scales for other devices.

---

## 5. Build and Upload

### 5.1 Archive Build

```bash
flutter build ipa --release
```

Output: `build/ios/ipa/*.ipa`

### 5.2 Alternative: Archive from Xcode

1. Open Xcode > **Product** > **Archive**
2. Wait for archive to complete
3. Opens Organizer automatically

### 5.3 Upload to App Store Connect

**Option A: Using Xcode (Organizer)**

1. Open Xcode > **Window** > **Organizer**
2. Select your archive
3. Click **Distribute App**
4. Select **App Store Connect**
5. Select **Upload**
6. Follow prompts

**Option B: Using Transporter**

1. Download [Transporter](https://apps.apple.com/app/transporter/id1450874784) from Mac App Store
2. Sign in with Apple ID
3. Drag `.ipa` file to Transporter
4. Click **Deliver**

**Option C: Using xcrun**

```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/*.ipa \
  --username "your@email.com" \
  --password "@keychain:AC_PASSWORD"
```

### 5.4 Submit for Review

1. Go to App Store Connect
2. Select your app
3. Click **+ Version or Platform** if needed
4. Select the uploaded build
5. Complete version information
6. Click **Submit for Review**

---

## 6. TestFlight

### 6.1 Internal Testing

1. Go to **TestFlight** tab
2. Click **Internal Testing** > **+**
3. Add team members (up to 100)
4. No review required

### 6.2 External Testing

1. Click **External Testing** > **+**
2. Create a group
3. Add testers (up to 10,000)
4. Submit build for Beta App Review
5. Review takes ~24-48 hours

### 6.3 TestFlight Feedback

- Testers can send feedback/screenshots from TestFlight app
- View feedback in App Store Connect > TestFlight > Feedback

---

## 7. Info.plist Configuration

### 7.1 Required Keys

Check `ios/Runner/Info.plist` for:

```xml
<!-- Required for App Store -->
<key>CFBundleDisplayName</key>
<string>Your App Name</string>

<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

<key>CFBundleVersion</key>
<string>$(FLUTTER_BUILD_NUMBER)</string>

<key>CFBundleShortVersionString</key>
<string>$(FLUTTER_BUILD_NAME)</string>
```

### 7.2 Export Compliance (Skip Encryption Question)

Add this to skip the export compliance question on every upload:

```bash
/usr/libexec/PlistBuddy -c "Add :ITSAppUsesNonExemptEncryption bool false" ios/Runner/Info.plist
```

Or manually add to `ios/Runner/Info.plist`:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

> **When to use:** Most Flutter apps only use HTTPS (exempt encryption). Set to `false` unless your app uses custom encryption algorithms.

### 7.3 Permission Descriptions

If your app uses protected features:

```xml
<!-- Camera -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos</string>

<!-- Photo Library -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select photos</string>

<!-- Location -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need location access to show nearby places</string>

<!-- Microphone -->
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice messages</string>

<!-- Face ID -->
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID for secure authentication</string>
```

**Important:** Missing permission descriptions cause App Store rejection!

---

## Checklist

**Xcode Configuration:**
- [ ] Team selected in Signing & Capabilities
- [ ] Bundle Identifier matches intended ID
- [ ] Automatically manage signing enabled
- [ ] Deployment target set correctly

**Developer Portal:**
- [ ] App ID registered
- [ ] Required capabilities enabled
- [ ] Provisioning profiles valid

**App Store Connect:**
- [ ] App created
- [ ] Store listing complete
- [ ] Screenshots uploaded (6.9" iPhone, 13" iPad if applicable)
- [ ] Privacy policy URL added
- [ ] Age rating completed
- [ ] App Privacy questionnaire completed

**Build:**
- [ ] `flutter build ipa --release` succeeds
- [ ] Build uploaded to App Store Connect
- [ ] Build appears in TestFlight

---

## Troubleshooting

### "No signing certificate 'iOS Distribution' found"

1. Xcode > Settings > Accounts
2. Select team > Download Manual Profiles
3. Or: Revoke and regenerate certificate

### "This bundle is invalid" on upload

Common causes:
- Missing required Info.plist keys
- Invalid icon sizes
- Bundle identifier mismatch

Run validation in Xcode before uploading.

### App rejected for missing permission description

Add `NS*UsageDescription` keys to Info.plist for every permission used.

### "The provisioning profile is not valid"

1. Xcode > Settings > Accounts
2. Download profiles again
3. Or manually download from Developer Portal

### Build succeeds but crashes on device

1. Check for debug-only code (assert statements, etc.)
2. Verify all dependencies support release builds
3. Test on physical device with release config

### "Version number has been used before"

Increment version in pubspec.yaml:
```yaml
version: 1.0.1+2  # format: versionName+buildNumber
```

---

## App Store Review Guidelines

### Common Rejection Reasons

| Issue | Solution |
|-------|----------|
| **Broken links** | Test all URLs before submission |
| **Placeholder content** | Remove Lorem ipsum, test data |
| **Incomplete features** | All buttons/features must work |
| **Missing login credentials** | Provide demo account in review notes |
| **Privacy issues** | Complete App Privacy, add policy URL |
| **Guideline 4.3** | App looks like template or web wrapper |

### Review Timeline

- **First submission:** 24-48 hours typically
- **Expedited:** Request if critical bug fix
- **Rejection response:** Usually 24 hours after resubmission

### Review Notes

Add helpful notes for reviewers:
- Demo credentials if login required
- How to access specific features
- Any special setup required

---

## 8. Privacy Manifest (iOS 17+)

Starting with iOS 17 (Spring 2024), Apple requires apps to declare their use of certain APIs via a Privacy Manifest file. **This is now enforced and missing manifests cause App Store rejection.**

### 8.1 When Required

You need a Privacy Manifest if your app (or any SDK) uses:

| API Category | Common Flutter Uses |
|--------------|---------------------|
| **File timestamp APIs** | File modification dates, caching |
| **System boot time APIs** | Rarely used directly |
| **Disk space APIs** | Storage checks |
| **Active keyboard APIs** | Keyboard visibility detection |
| **User defaults APIs** | SharedPreferences, any UserDefaults |

> **Note:** Most Flutter apps use SharedPreferences, which requires User Defaults declaration.

### 8.2 Create PrivacyInfo.xcprivacy

Create `ios/Runner/PrivacyInfo.xcprivacy`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- User Defaults (SharedPreferences) -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyTracking</key>
    <false/>
</dict>
</plist>
```

### 8.3 Common API Reasons

Add additional entries to `NSPrivacyAccessedAPITypes` array as needed:

**File Timestamp (if checking file modification dates):**
```xml
<dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array>
        <string>C617.1</string>
    </array>
</dict>
```

**Disk Space (if checking available storage):**
```xml
<dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array>
        <string>E174.1</string>
    </array>
</dict>
```

### 8.4 Add to Xcode Project

1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click **Runner** folder in Project Navigator
3. Select **Add Files to "Runner"...**
4. Select `PrivacyInfo.xcprivacy`
5. Ensure:
   - **Copy items if needed** is checked
   - **Add to targets: Runner** is selected
6. Click **Add**

### 8.5 Third-Party SDK Manifests

SDKs must provide their own privacy manifests. Check that your dependencies are updated:

| Package | Manifest Status |
|---------|-----------------|
| firebase_core | Included in latest |
| google_sign_in | Included in latest |
| flutter_secure_storage | Check latest version |
| shared_preferences | Uses UserDefaults - declare in your manifest |

Run `flutter pub outdated` and update packages to get SDK privacy manifests.

### 8.6 Verify Privacy Manifest

```bash
# Build the app
flutter build ios --release

# Check the .app bundle contains privacy manifest
find build/ios/iphoneos -name "PrivacyInfo.xcprivacy"
```

---

## 9. App Tracking Transparency (ATT)

If your app collects data for tracking users across apps/websites, you must implement ATT.

### 9.1 When Required

ATT is **required** if you:
- Use IDFA (Identifier for Advertisers)
- Use advertising SDKs (AdMob, Facebook Ads, etc.)
- Track users across apps owned by other companies
- Share user data with data brokers

ATT is **NOT required** for:
- First-party analytics (Firebase Analytics without linking)
- Crash reporting
- A/B testing within your own app
- Fraud detection

### 9.2 Implementation

**Add to Info.plist:**

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

**Request permission in code:**

```dart
// pubspec.yaml
dependencies:
  app_tracking_transparency: ^2.0.6

// In your app (before showing ads)
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

Future<void> requestTrackingPermission() async {
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
}
```

### 9.3 Best Practices

1. **Request at the right time** - Not immediately on launch. Wait until user understands app value.
2. **Explain the benefit** - Show a pre-prompt explaining why tracking helps.
3. **Handle denial gracefully** - App must work fully without tracking permission.
4. **Update Privacy Manifest** - Set `NSPrivacyTracking` to `true` if tracking.

### 9.4 If Not Using Tracking

If your app doesn't track users, ensure:

1. `NSPrivacyTracking` is `false` in Privacy Manifest
2. No ATT permission request in code
3. No `NSUserTrackingUsageDescription` in Info.plist (unless SDKs require it)

---

## 10. Deep Links (Universal Links)

If your app handles deep links, verify Universal Links are configured correctly.

### 10.1 When Needed

Configure Universal Links if:
- App opens from web links (https://yourapp.com/path)
- Using OAuth redirects back to app
- Handoff between app and website
- Sharing content links

### 10.2 Add Associated Domains Capability

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target > **Signing & Capabilities**
3. Click **+ Capability** > **Associated Domains**
4. Add domain: `applinks:yourapp.com`

This creates/updates `ios/Runner/Runner.entitlements`:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:yourapp.com</string>
</array>
```

### 10.3 Apple App Site Association (AASA)

Host the AASA file on your domain:

**Location:** `https://yourapp.com/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.yourcompany.yourapp",
        "paths": ["*"]
      }
    ]
  }
}
```

**Or with specific paths:**

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.yourcompany.yourapp",
        "paths": [
          "/product/*",
          "/user/*",
          "NOT /admin/*"
        ]
      }
    ]
  }
}
```

### 10.4 Find Your Team ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Click your name (top right) > **View Account**
3. Team ID is listed under **Membership Details**

Or from Xcode:
1. Xcode > **Settings** > **Accounts**
2. Select your account > **View Details**

### 10.5 AASA File Requirements

| Requirement | Value |
|-------------|-------|
| **Path** | `/.well-known/apple-app-site-association` |
| **Content-Type** | `application/json` |
| **HTTPS** | Required (no HTTP) |
| **No extension** | File has no `.json` extension |
| **Redirects** | Not allowed |
| **Valid SSL** | Certificate must be trusted |

### 10.6 Verify Configuration

**Test on simulator:**
```bash
xcrun simctl openurl booted "https://yourapp.com/path"
```

**Apple's AASA validator:**
```
https://app-site-association.cdn-apple.com/a/v1/yourapp.com
```

**Check AASA is accessible:**
```bash
curl -I https://yourapp.com/.well-known/apple-app-site-association
# Should return 200 OK with application/json
```

### 10.7 Troubleshooting

**Links open Safari instead of app:**
- Verify Associated Domains capability is enabled
- Check domain in entitlements matches exactly
- Verify AASA file is accessible and valid
- Team ID must match your app's signing team

**"Invalid AASA" error:**
- No redirects allowed on AASA URL
- Content-Type must be `application/json`
- JSON must be valid (use jsonlint.com)
- appID format: `TEAMID.bundleIdentifier`

**Changes not taking effect:**
- iOS caches AASA aggressively
- Delete app, restart device, reinstall
- Or wait 24+ hours for cache expiry

### 10.8 Custom URL Schemes (Fallback)

For OAuth callbacks or non-HTTPS links, also add custom scheme:

Add to `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

This enables `yourapp://callback` links.

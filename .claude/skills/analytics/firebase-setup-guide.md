# Firebase Setup Guide

Configure Firebase Analytics and Crashlytics in the Firebase Console.

---

## Prerequisites

- Google account
- Firebase project (create new or use existing)
- iOS Bundle ID and Android Package Name

---

## Step 1: Create or Select Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or select existing project
3. Enter project name
4. Enable Google Analytics (recommended)
5. Select or create Google Analytics account
6. Click "Create project"

---

## Step 2: Add iOS App

1. In Firebase Console, click "Add app" → iOS
2. Enter **Bundle ID** (must match `ios/Runner.xcodeproj` → Runner → Bundle Identifier)
3. Enter **App nickname** (optional, for Console display)
4. Enter **App Store ID** (optional, add later)
5. Click "Register app"

### Download Config File

1. Download `GoogleService-Info.plist`
2. Open `ios/Runner.xcworkspace` in Xcode
3. Right-click on Runner folder → "Add Files to Runner"
4. Select `GoogleService-Info.plist`
5. Ensure "Copy items if needed" is checked
6. Ensure Runner target is selected
7. Click "Add"

**Verify:** File should appear in Xcode project navigator under Runner.

---

## Step 3: Add Android App

1. In Firebase Console, click "Add app" → Android
2. Enter **Package name** (from `android/app/build.gradle.kts` → `applicationId`)
3. Enter **App nickname** (optional)
4. Enter **Debug signing certificate SHA-1** (optional for analytics, required for some features)

### Get SHA-1 (if needed)

```bash
# Debug certificate
cd android && ./gradlew signingReport
# Look for SHA1 under "Variant: debug"

# Or manually
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Download Config File

1. Download `google-services.json`
2. Place in `android/app/google-services.json`

**Verify:** Run `flutter build apk --debug` - should not show Firebase config errors.

---

## Step 4: Enable Analytics

Analytics is enabled by default when you create a Firebase project with Google Analytics.

**Verify:**
1. Firebase Console → Analytics → Dashboard
2. Should show "Waiting for data" or existing data

### Configure Data Retention

1. Analytics → Settings (gear icon)
2. Data retention → Set to 14 months (max) or as needed
3. Enable "Reset on new activity" for user properties

### Enable User-ID Tracking (Optional)

1. Analytics → Settings → User-ID
2. Enable to track users across devices

---

## Step 5: Enable Crashlytics

1. Firebase Console → Crashlytics
2. Click "Enable Crashlytics"
3. Follow setup prompts

**First Crash:**
Crashlytics requires a crash to verify setup. In development:

```dart
// Add temporary button
ElevatedButton(
  onPressed: () => FirebaseCrashlytics.instance.crash(),
  child: Text('Test Crash'),
)
```

1. Run app on real device (not simulator for iOS)
2. Tap button to crash
3. Reopen app (uploads crash report on next launch)
4. Wait 5-10 minutes, check Console

**Remove test crash code before production!**

---

## Step 6: Configure Debug View

DebugView shows events in real-time during development.

### Enable Debug Mode

**iOS Simulator:**
1. Edit scheme in Xcode
2. Run → Arguments → Arguments Passed On Launch
3. Add `-FIRDebugEnabled`

**Android:**
```bash
adb shell setprop debug.firebase.analytics.app your.package.name
```

### View Debug Events

1. Firebase Console → Analytics → DebugView
2. Select your device from dropdown
3. Events appear in real-time

### Disable Debug Mode

**iOS:** Remove `-FIRDebugEnabled` from scheme

**Android:**
```bash
adb shell setprop debug.firebase.analytics.app .none.
```

---

## Step 7: Configure Audiences (Optional)

Create user segments for targeted analysis:

1. Analytics → Audiences → Create audience
2. Define conditions (e.g., "Premium Users" where `subscription_tier` equals "premium")
3. Save

Use audiences in:
- Analytics filtering
- Firebase Remote Config
- Firebase Cloud Messaging targeting

---

## Step 8: Set Up Conversions (Optional)

Mark important events as conversions:

1. Analytics → Events
2. Find your event (e.g., `purchase_completed`)
3. Toggle "Mark as conversion"

Conversions:
- Appear prominently in reports
- Can be used for Google Ads optimization
- Limited to 30 custom conversions

---

## Console Navigation

| Section | Use For |
|---------|---------|
| **Dashboard** | Overview metrics, active users |
| **Realtime** | Current activity (last 30 min) |
| **Events** | All logged events, mark conversions |
| **Conversions** | Conversion funnel analysis |
| **Audiences** | User segments |
| **User Properties** | Property values distribution |
| **DebugView** | Real-time development testing |
| **Crashlytics** | Crash reports, trends, issues |

---

## Data Export (Optional)

For advanced analysis, export to BigQuery:

1. Project Settings → Integrations → BigQuery
2. Link your project
3. Enable "Export to BigQuery"
4. Select datasets (Analytics, Crashlytics)

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "No data" in Analytics | Wait 24-48 hours for processing |
| Events in DebugView but not Reports | Normal delay, check after 24h |
| Crashlytics shows "Waiting for crash" | Trigger test crash, reopen app |
| Config file not found | Verify file location, clean build |
| SHA-1 mismatch | Re-add SHA-1 in Console, re-download config |

---

## Security Notes

- `GoogleService-Info.plist` and `google-services.json` are safe to commit
- They contain project identifiers, not secrets
- Access is controlled by Firebase Security Rules and API restrictions
- For sensitive apps, restrict API keys in Google Cloud Console

---

## Related

- [implementation-guide.md](implementation-guide.md) - Code setup
- [checklist.md](checklist.md) - Verification steps
- [Firebase Analytics Documentation](https://firebase.google.com/docs/analytics)
- [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)

# Fastlane Guide

Concepts for iOS and Android deployment with Fastlane.

> **Note:** The setup script generates all Fastlane files automatically.
> Run: `dart run .claude/skills/ci-cd/scripts/setup.dart`

---

## 1. Overview

| Platform | What Fastlane Does |
|----------|-------------------|
| **iOS** | Code signing (match), build (gym), upload (pilot) |
| **Android** | Build (gradle), upload (supply) |

**Template location:** `templates/fastlane/`

---

## 2. Directory Structure

After setup:

```
ios/
├── fastlane/
│   ├── Fastfile      # Lane definitions
│   ├── Appfile       # App identifiers
│   └── Matchfile     # Code signing config
└── Gemfile           # Ruby dependencies

android/
├── fastlane/
│   ├── Fastfile      # Lane definitions
│   └── Appfile       # App identifiers
└── Gemfile           # Ruby dependencies
```

---

## 3. iOS Code Signing with Match

Match stores certificates in a private git repo, shared across team/CI.

### Initial Setup (run once by admin)

```bash
cd ios
fastlane match init                    # Create Matchfile
fastlane match development             # Generate dev certs
fastlane match appstore                # Generate distribution certs
```

### Sync (team members / CI)

```bash
fastlane match appstore --readonly     # Download, don't modify
```

### Match Repository

Create a **private** repo for certificates:
- `github.com/yourorg/certificates`
- Only give access to team members

---

## 4. iOS Lanes

```bash
cd ios

# Sync certificates
bundle exec fastlane sync_appstore

# Build release IPA
bundle exec fastlane build_release

# Deploy to TestFlight
bundle exec fastlane beta
```

---

## 5. Android Lanes

```bash
cd android

# Build release AAB
bundle exec fastlane build_release

# Deploy to Play Store (internal track)
bundle exec fastlane deploy track:internal

# Deploy to beta
bundle exec fastlane deploy track:beta
```

---

## 6. Play Store Setup

### Prerequisites

1. Upload first AAB manually to Play Console
2. Create Google Cloud service account
3. Grant service account access in Play Console

### Service Account Setup

1. [Google Cloud Console](https://console.cloud.google.com/) → Create project
2. Enable "Google Play Android Developer API"
3. IAM → Service Accounts → Create
4. Download JSON key
5. Play Console → Users & Permissions → Invite user
6. Add service account email with "Release manager" role

---

## 7. App Store Connect API

### Create API Key

1. [App Store Connect](https://appstoreconnect.apple.com/) → Users → Keys
2. Generate key with "App Manager" access
3. Download `.p8` file (only once!)
4. Note Key ID and Issuer ID

### Encode for CI

```bash
base64 -i AuthKey_XXXXXXXX.p8
```

Store as `APP_STORE_CONNECT_API_KEY` secret.

---

## 8. CI Secrets Reference

### iOS Secrets

| Secret | How to Get |
|--------|-----------|
| `MATCH_PASSWORD` | Password you set when creating match |
| `MATCH_GIT_BASIC_AUTHORIZATION` | `echo -n "user:token" \| base64` |
| `APP_STORE_CONNECT_API_KEY` | Base64 encoded .p8 file |
| `APP_STORE_CONNECT_ISSUER_ID` | From App Store Connect Keys page |
| `APP_STORE_CONNECT_KEY_ID` | From App Store Connect Keys page |

### Android Secrets

| Secret | How to Get |
|--------|-----------|
| `GOOGLE_SERVICE_ACCOUNT_KEY` | Service account JSON content |
| `KEYSTORE_BASE64` | `base64 -i keystore.jks` |
| `KEYSTORE_PASSWORD` | Your keystore password |
| `KEY_ALIAS` | Key alias in keystore |
| `KEY_PASSWORD` | Key password |

---

## 9. Firebase App Distribution

Alternative to GitHub Action - use Fastlane plugin:

```bash
# Add to Gemfile
gem "fastlane-plugin-firebase_app_distribution"

# Then run
bundle install
```

Add lane to Fastfile:

```ruby
lane :firebase_beta do
  build_release_apk

  firebase_app_distribution(
    app: ENV["FIREBASE_APP_ID"],
    groups: "testers",
    release_notes: "Build #{lane_context[SharedValues::BUILD_NUMBER]}"
  )
end
```

---

## 10. Metadata Management

### iOS (deliver)

```bash
# Download existing metadata
fastlane deliver download_metadata

# Upload metadata and screenshots
fastlane deliver --skip_binary_upload
```

### Android (supply)

```bash
# Download existing metadata
fastlane supply init

# Upload metadata only
fastlane supply --skip_upload_apk --skip_upload_aab
```

---

## 11. Common Issues

### iOS

| Error | Solution |
|-------|----------|
| "No signing certificate" | Run `fastlane match appstore` |
| "Profile doesn't include certificate" | `fastlane match appstore --force` |

### Android

| Error | Solution |
|-------|----------|
| "Only draft releases allowed" | Add `release_status: "draft"` |
| "Not authorized" | Check service account permissions |

---

## 12. Local Testing

Always test locally before CI:

```bash
# iOS
cd ios && bundle exec fastlane beta

# Android
cd android && bundle exec fastlane deploy track:internal
```

---

## Summary

1. Run `setup.dart` to generate Fastlane files
2. Set up Match repo (iOS) or service account (Android)
3. Add secrets to GitHub
4. Test locally before relying on CI

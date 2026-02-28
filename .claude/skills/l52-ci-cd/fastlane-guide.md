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

## 3. iOS Code Signing

### Option A: Xcode Automatic Signing (simplest, solo/small team)

If you use Xcode's automatic code signing, Fastlane can use `flutter build ipa` directly — no Match needed. This is the recommended approach for solo developers or small teams deploying from a local machine.

The Fastfile simply calls:

```ruby
lane :build do
  Dir.chdir("..") do
    sh("flutter", "build", "ipa", "--release")
  end
end
```

Xcode handles all signing automatically. The IPA output is at `build/ios/ipa/YourApp.ipa`.

### Option B: Match (team/CI)

Match stores certificates in a private git repo, shared across team/CI. Use this when multiple developers or CI need to sign builds.

#### Initial Setup (run once by admin)

```bash
cd ios
fastlane match init                    # Create Matchfile
fastlane match development             # Generate dev certs
fastlane match appstore                # Generate distribution certs
```

#### Sync (team members / CI)

```bash
fastlane match appstore --readonly     # Download, don't modify
```

#### Match Repository

Create a **private** repo for certificates:
- `github.com/yourorg/certificates`
- Only give access to team members

---

## 4. iOS Lanes

```bash
cd ios

# Build release IPA
bundle exec fastlane build

# Deploy to TestFlight (builds + uploads)
bundle exec fastlane beta

# Deploy to App Store (builds + uploads)
bundle exec fastlane release

# If using Match, sync certificates first
bundle exec fastlane sync_appstore
```

---

## 5. Android Lanes

```bash
cd android

# Build release AAB
bundle exec fastlane build

# Deploy to Play Store internal testing
bundle exec fastlane internal

# Deploy to Play Store beta (open testing)
bundle exec fastlane beta

# Promote internal to production
bundle exec fastlane release
```

---

## 6. Play Store Setup

### Prerequisites

1. Upload first AAB manually to Play Console (required before API uploads work)
2. Create Google Cloud service account
3. Grant service account access in Play Console

### Service Account Setup (detailed)

1. **Google Play Console** → [Setup → API access](https://play.google.com/console/developers/api-access)
2. If prompted, link to a Google Cloud project (or create one)
3. Under **Service accounts**, click **Create new service account** — this opens Google Cloud Console
4. In **Google Cloud Console**:
   - Name the service account (e.g., "fastlane")
   - Skip the optional role/permissions steps, click **Done**
   - Click the new service account → **Keys** tab → **Add Key** → **Create new key** → select **JSON** → **Create**
   - A `.json` file downloads — save it as `android/fastlane/service-account.json`
5. Back in **Play Console** → Setup → API access → click **Grant access** next to the new service account
6. Set permissions: **Admin** (or at minimum: Manage releases, Manage app information)
7. Click **Invite user** → confirm
8. **Important:** It can take up to 24 hours for the service account to be fully active

### Verify Service Account

```bash
cd android && bundle exec fastlane run validate_play_store_json_key json_key:fastlane/service-account.json
```

### Security

- Add `**/service-account*.json` to `.gitignore` — never commit this file
- For CI, store the JSON contents as a GitHub secret (`GOOGLE_SERVICE_ACCOUNT_KEY`)

---

## 7. App Store Connect API

### Create API Key (detailed)

1. Go to [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
2. Click **Generate API Key**
3. Name it (e.g., "Fastlane") and give it **App Manager** role
4. Click **Generate**
5. **Download the `.p8` file immediately** — you can only download it **once**
6. Note the **Key ID** (shown in the table) and **Issuer ID** (shown above the table)

### Store the Key

Save the `.p8` file somewhere persistent outside the project:

```bash
mkdir -p ~/.appstoreconnect
mv ~/Downloads/AuthKey_XXXXXXXXXX.p8 ~/.appstoreconnect/
```

### Local Usage

Create `ios/fastlane/.env` (gitignored) with:

```
APP_STORE_CONNECT_KEY_ID=YOUR_KEY_ID
APP_STORE_CONNECT_ISSUER_ID=YOUR_ISSUER_ID
APP_STORE_CONNECT_KEY_PATH=/Users/you/.appstoreconnect/AuthKey_YOUR_KEY_ID.p8
```

The Fastfile reads these via `ENV["..."]`. Fastlane automatically loads `.env` files.

### Encode for CI

For CI environments, base64-encode the key and store as a secret:

```bash
base64 -i ~/.appstoreconnect/AuthKey_XXXXXXXXXX.p8
```

Store as `APP_STORE_CONNECT_API_KEY` GitHub secret. Use `key_content` + `is_key_content_base64: true` instead of `key_filepath` in CI Fastfile.

### Security

- Add `*.p8` and `ios/fastlane/.env*` to `.gitignore`
- Never commit API keys or `.p8` files

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

## 12. Required .gitignore Entries

Add these to your project `.gitignore`:

```gitignore
# Fastlane
*/fastlane/report.xml
*/fastlane/README.md
*/fastlane/screenshots
*/fastlane/test_output

# Credentials (never commit)
*.p8
**/service-account*.json
android/fastlane/.env*
ios/fastlane/.env*
```

---

## 13. Local Testing

Always test locally before CI:

```bash
# iOS - build only (verify signing works)
cd ios && bundle exec fastlane build

# iOS - build + upload to TestFlight
cd ios && bundle exec fastlane beta

# Android - build only
cd android && bundle exec fastlane build

# Android - build + upload to internal track
cd android && bundle exec fastlane internal
```

---

## Summary

1. Run `setup.dart` or create Fastlane files manually from templates
2. Set up App Store Connect API key (iOS) and Play Store service account (Android)
3. Create `.env` files for local credentials (gitignored)
4. For CI, add secrets to GitHub
5. Test locally before relying on CI

# Debug Symbols Upload Guide

How to integrate dSYM and mapping file uploads into CI/CD pipelines for crash reporting.

---

## Overview

Debug symbols (dSYMs on iOS, mapping files on Android) are required for readable crash reports. Without them, stack traces show only memory addresses.

| Platform | File | Provider | Source |
|----------|------|----------|--------|
| iOS | dSYM | Crashlytics | `/analytics` skill scripts |
| iOS | dSYM | Sentry | `/analytics` skill scripts |
| Android | mapping.txt | Crashlytics | Automatic via Gradle |
| Android | mapping.txt | Sentry | `/analytics` skill scripts |

**Scripts location:** `.claude/skills/analytics/scripts/`

---

## GitHub Actions Integration

### Firebase Crashlytics (iOS)

Add after the build step in your iOS deployment workflow:

```yaml
# .github/workflows/deploy-testflight.yml

- name: Build iOS
  run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

- name: Upload dSYMs to Crashlytics
  run: |
    chmod +x scripts/upload_dsyms_crashlytics.sh
    ./scripts/upload_dsyms_crashlytics.sh
```

**Alternative - Fastlane:**

```ruby
# ios/fastlane/Fastfile
lane :beta do
  # ... build steps ...

  upload_symbols_to_crashlytics(
    gsp_path: "Runner/GoogleService-Info.plist"
  )
end
```

### Sentry (iOS)

```yaml
- name: Install sentry-cli
  run: brew install getsentry/tools/sentry-cli

- name: Build iOS
  run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

- name: Upload dSYMs to Sentry
  env:
    SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
    SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
    SENTRY_PROJECT: ${{ secrets.SENTRY_PROJECT }}
  run: |
    chmod +x scripts/upload_dsyms_sentry.sh
    ./scripts/upload_dsyms_sentry.sh
```

### Firebase Crashlytics (Android)

**Automatic** - no CI step needed. Ensure `build.gradle.kts` has:

```kotlin
android {
    buildTypes {
        release {
            firebaseCrashlytics {
                mappingFileUploadEnabled = true
            }
        }
    }
}
```

### Sentry (Android)

```yaml
- name: Build Android
  run: flutter build appbundle --release

- name: Upload mapping to Sentry
  env:
    SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
    SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
    SENTRY_PROJECT: ${{ secrets.SENTRY_PROJECT }}
  run: |
    brew install getsentry/tools/sentry-cli
    chmod +x scripts/upload_mapping_android.sh
    ./scripts/upload_mapping_android.sh sentry
```

---

## Required Secrets

### Firebase Crashlytics

No additional secrets - uses config files already in repo.

### Sentry

| Secret | Description | Where to find |
|--------|-------------|---------------|
| `SENTRY_AUTH_TOKEN` | API token | Sentry → Settings → Auth Tokens |
| `SENTRY_ORG` | Organization slug | URL path |
| `SENTRY_PROJECT` | Project slug | URL path |

---

## Complete Workflow Examples

### iOS + Crashlytics

```yaml
name: Deploy iOS

on:
  push:
    tags: ['v*']

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.0'
          cache: true

      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: cd ios && pod install

      - name: Build iOS
        run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

      - name: Upload dSYMs to Crashlytics
        run: ./scripts/upload_dsyms_crashlytics.sh

      - name: Deploy to TestFlight
        run: cd ios && bundle exec fastlane beta
```

### iOS + Sentry

```yaml
name: Deploy iOS

on:
  push:
    tags: ['v*']

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.0'
          cache: true

      - name: Install sentry-cli
        run: brew install getsentry/tools/sentry-cli

      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: cd ios && pod install

      - name: Build iOS
        run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

      - name: Upload dSYMs to Sentry
        env:
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
          SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
          SENTRY_PROJECT: ${{ secrets.SENTRY_PROJECT }}
        run: ./scripts/upload_dsyms_sentry.sh

      - name: Deploy to TestFlight
        run: cd ios && bundle exec fastlane beta
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "dSYMs not found" | Build in Release mode first |
| "upload-symbols not found" | Run `pod install` |
| "sentry-cli not found" | `brew install getsentry/tools/sentry-cli` |
| Crashes not symbolicated | Verify symbols match build version |
| "Permission denied" | `chmod +x scripts/*.sh` |

---

## Related

- `/analytics` skill - Scripts and local Xcode setup
- [workflows-guide.md](workflows-guide.md) - Full workflow documentation
- [fastlane-guide.md](fastlane-guide.md) - Fastlane configuration

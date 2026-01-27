# Flavors Implementation Checklist

Use this checklist to verify your flavor setup is complete.

## Pre-requisites

- [ ] Project created with `/init`
- [ ] Core infrastructure created with `/core`
- [ ] Decided on flavor count (2 or 3)
- [ ] Base bundle ID determined (e.g., `com.example.myapp`)

## Environment Files

### Required Files

- [ ] `.env.dev` created with all required variables
- [ ] `.env.staging` created (if using 3 flavors)
- [ ] `.env.prod` created with production values
- [ ] `.env.example` updated with all variable keys (no values)

### File Contents

Each `.env.{flavor}` should contain:

```bash
# Core
FLAVOR=dev|staging|prod
APP_NAME=My App (Dev)|My App (Staging)|My App

# API
API_URL=https://dev-api.example.com|https://staging-api.example.com|https://api.example.com

# Supabase (if using)
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

### Security

- [ ] All `.env.*` files added to `.gitignore`
- [ ] `.env.example` does NOT contain secrets
- [ ] No secrets committed to git history

## Android Configuration

### build.gradle

- [ ] `flavorDimensions "environment"` added
- [ ] `productFlavors` block with dev, staging (optional), prod
- [ ] Each flavor has correct `applicationIdSuffix`
- [ ] Each flavor has `resValue "string", "app_name", "..."` for display name

### AndroidManifest.xml

- [ ] `android:label="@string/app_name"` (not hardcoded)

### Firebase (if using)

- [ ] `android/app/src/dev/google-services.json` exists
- [ ] `android/app/src/staging/google-services.json` exists (if staging)
- [ ] `android/app/src/prod/google-services.json` exists
- [ ] Each file is from the correct Firebase project

### Build Test

- [ ] `flutter build apk --flavor dev --dart-define-from-file=.env.dev` succeeds
- [ ] `flutter build apk --flavor prod --dart-define-from-file=.env.prod` succeeds
- [ ] APK installs as separate app (check app drawer shows both if installed)

## iOS Configuration

### xcconfig Files

- [ ] `ios/Flutter/Dev.xcconfig` exists
- [ ] `ios/Flutter/Staging.xcconfig` exists (if staging)
- [ ] `ios/Flutter/Prod.xcconfig` exists
- [ ] Each xcconfig includes correct base (`#include "Debug.xcconfig"` or `"Release.xcconfig"`)
- [ ] Each xcconfig sets `PRODUCT_BUNDLE_IDENTIFIER`
- [ ] Each xcconfig sets `DISPLAY_NAME`
- [ ] Each xcconfig sets `FLAVOR` (for Firebase script)

### Xcode Schemes

- [ ] `dev` scheme exists and is shared
- [ ] `staging` scheme exists and is shared (if staging)
- [ ] `prod` scheme exists and is shared
- [ ] Schemes appear in `ios/Runner.xcodeproj/xcshareddata/xcschemes/`

### Info.plist

- [ ] `CFBundleDisplayName` uses `$(DISPLAY_NAME)`
- [ ] `CFBundleIdentifier` uses `$(PRODUCT_BUNDLE_IDENTIFIER)`

### Firebase (if using)

- [ ] `ios/config/dev/GoogleService-Info.plist` exists
- [ ] `ios/config/staging/GoogleService-Info.plist` exists (if staging)
- [ ] `ios/config/prod/GoogleService-Info.plist` exists
- [ ] Build phase script copies correct plist
- [ ] Script runs BEFORE "Copy Bundle Resources" phase

### Build Test

- [ ] `flutter build ios --flavor dev --dart-define-from-file=.env.dev --no-codesign` succeeds
- [ ] `flutter build ios --flavor prod --dart-define-from-file=.env.prod --no-codesign` succeeds

## Dart Configuration

### FlavorConfig

- [ ] `lib/core/config/flavor_config.dart` exists
- [ ] Reads `FLAVOR` from `String.fromEnvironment`
- [ ] Reads `API_URL` from `String.fromEnvironment`
- [ ] Provides `isDev`, `isStaging`, `isProd` getters
- [ ] Used in `main.dart` for conditional logic

### main.dart

- [ ] Does NOT use `flutter_dotenv` (using compile-time variables instead)
- [ ] Uses `FlavorConfig` for environment checks
- [ ] Conditionally enables debug features based on flavor

## VS Code Configuration (Optional)

- [ ] `.vscode/launch.json` exists
- [ ] Has configuration for each flavor
- [ ] Each configuration includes `--flavor` and `--dart-define-from-file` args

## Verification

### Runtime Checks

- [ ] Run dev flavor: correct API URL used
- [ ] Run prod flavor: correct API URL used
- [ ] Run dev flavor: debug banner shows (or other dev indicator)
- [ ] Run prod flavor: debug banner hidden

### Firebase Checks (if using)

- [ ] Dev build connects to dev Firebase project (check projectId in logs)
- [ ] Prod build connects to prod Firebase project

### App Identity Checks

- [ ] Dev app shows "(Dev)" in app name
- [ ] Prod app shows clean name
- [ ] Dev and prod can be installed side-by-side on same device

## Post-Setup Tasks

- [ ] Team knows how to run each flavor
- [ ] CI/CD updated for multi-flavor builds (see `/ci-cd`)
- [ ] Documentation updated with flavor commands
- [ ] Production signing configured (see `/release`)

## Quick Validation Command

```bash
# Run the flavor validation script
dart run .claude/skills/flavors/scripts/check.dart
```

Expected output: All checks pass with no errors.

# iOS Flavors Guide

Configuring iOS build schemes and xcconfig files for Flutter flavors.

## Overview

iOS uses Xcode schemes and xcconfig files to configure different app variants. Each flavor has:

- Different bundle identifier
- Different display name
- Different xcconfig file
- Different provisioning profile (for signing)
- Different Firebase config (optional)

## Setup Methods

There are two approaches:

1. **xcconfig files** (Recommended) - Manual but more control
2. **Xcode schemes** - Created via Xcode UI

This guide covers the xcconfig approach as it's more reliable for Flutter.

## Directory Structure

```
ios/
├── Flutter/
│   ├── Debug.xcconfig
│   ├── Release.xcconfig
│   ├── Dev.xcconfig           # NEW
│   ├── Staging.xcconfig       # NEW
│   └── Prod.xcconfig          # NEW
├── Runner/
│   ├── Info.plist
│   └── Assets.xcassets/
├── Runner.xcodeproj/
│   ├── project.pbxproj
│   └── xcshareddata/
│       └── xcschemes/
│           ├── dev.xcscheme    # NEW
│           ├── staging.xcscheme # NEW
│           └── prod.xcscheme   # NEW
└── config/                     # NEW (for Firebase)
    ├── dev/
    │   └── GoogleService-Info.plist
    ├── staging/
    │   └── GoogleService-Info.plist
    └── prod/
        └── GoogleService-Info.plist
```

## Step-by-Step Configuration

### Step 1: Create Flavor xcconfig Files

#### ios/Flutter/Dev.xcconfig

```
#include "Debug.xcconfig"

FLUTTER_TARGET=lib/main.dart
PRODUCT_BUNDLE_IDENTIFIER=com.example.myapp.dev
DISPLAY_NAME=My App (Dev)
FLAVOR=dev
```

#### ios/Flutter/Staging.xcconfig

```
#include "Release.xcconfig"

FLUTTER_TARGET=lib/main.dart
PRODUCT_BUNDLE_IDENTIFIER=com.example.myapp.staging
DISPLAY_NAME=My App (Staging)
FLAVOR=staging
```

#### ios/Flutter/Prod.xcconfig

```
#include "Release.xcconfig"

FLUTTER_TARGET=lib/main.dart
PRODUCT_BUNDLE_IDENTIFIER=com.example.myapp
DISPLAY_NAME=My App
FLAVOR=prod
```

### Step 2: Update Info.plist

Update `ios/Runner/Info.plist` to use variables:

```xml
<key>CFBundleDisplayName</key>
<string>$(DISPLAY_NAME)</string>

<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
```

The bundle identifier should already be using `$(PRODUCT_BUNDLE_IDENTIFIER)` by default.

### Step 3: Create Xcode Schemes

#### Option A: Manual Creation via Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Product → Scheme → Manage Schemes
3. Select "Runner" scheme → Click gear icon → Duplicate
4. Rename to "dev", "staging", "prod"
5. For each scheme:
   - Edit scheme → Build → Pre-actions
   - Add script to copy correct xcconfig

#### Option B: Create Scheme Files Directly

Create scheme files in `ios/Runner.xcodeproj/xcshareddata/xcschemes/`:

**dev.xcscheme** (see templates/ios/ for full file)

Key parts:
```xml
<BuildableProductRunnable>
   <BuildableReference
      BuildableName = "Runner.app"
      BlueprintIdentifier = "..."
      ReferencedContainer = "container:Runner.xcodeproj">
   </BuildableReference>
</BuildableProductRunnable>
<LaunchAction
   buildConfiguration = "Debug"
   ...>
</LaunchAction>
```

### Step 4: Configure Build Configurations

In Xcode:

1. Open `Runner.xcworkspace`
2. Select Runner project → Runner target → Build Settings
3. Add User-Defined settings or modify existing:
   - `PRODUCT_BUNDLE_IDENTIFIER` = `$(inherited)`
   - `INFOPLIST_KEY_CFBundleDisplayName` = `$(DISPLAY_NAME)`

### Step 5: Update Podfile (if needed)

If using CocoaPods with per-flavor configs:

```ruby
# ios/Podfile

# After flutter_install_all_ios_pods, add:
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

## Firebase Per Flavor

### Directory Structure

```
ios/
├── config/
│   ├── dev/GoogleService-Info.plist
│   ├── staging/GoogleService-Info.plist
│   └── prod/GoogleService-Info.plist
└── Runner/
    └── GoogleService-Info.plist  # Copied at build time
```

### Build Phase Script

Add a Run Script build phase in Xcode:

1. Select Runner target → Build Phases
2. Click + → New Run Script Phase
3. Drag it before "Copy Bundle Resources"
4. Add this script:

```bash
# Copy environment-specific GoogleService-Info.plist
ENV_DIR="${PROJECT_DIR}/config/${FLAVOR}"
PLIST_SOURCE="${ENV_DIR}/GoogleService-Info.plist"
PLIST_DEST="${PROJECT_DIR}/Runner/GoogleService-Info.plist"

if [ -f "$PLIST_SOURCE" ]; then
    cp "$PLIST_SOURCE" "$PLIST_DEST"
    echo "Copied GoogleService-Info.plist for ${FLAVOR}"
else
    echo "warning: GoogleService-Info.plist not found at ${PLIST_SOURCE}"
fi
```

## Signing Per Flavor

### Provisioning Profiles

Each flavor with different bundle ID needs:
- Development provisioning profile
- Distribution provisioning profile (for App Store/TestFlight)

Naming convention:
- `com.example.myapp.dev` → `My App Dev Development`, `My App Dev Distribution`
- `com.example.myapp.staging` → `My App Staging Development`, `My App Staging Distribution`
- `com.example.myapp` → `My App Development`, `My App Distribution`

### Fastlane Match Configuration

If using Fastlane match:

```ruby
# ios/fastlane/Matchfile
git_url("git@github.com:company/certificates.git")
storage_mode("git")
type("development")
app_identifier([
  "com.example.myapp",
  "com.example.myapp.dev",
  "com.example.myapp.staging"
])
```

```ruby
# ios/fastlane/Fastfile
lane :sync_certificates do
  match(type: "development", app_identifier: "com.example.myapp.dev")
  match(type: "development", app_identifier: "com.example.myapp.staging")
  match(type: "development", app_identifier: "com.example.myapp")

  match(type: "appstore", app_identifier: "com.example.myapp")
end
```

## Build Commands

### Debug Builds

```bash
# Dev flavor
flutter run --flavor dev --dart-define-from-file=.env.dev

# Staging flavor
flutter run --flavor staging --dart-define-from-file=.env.staging

# Prod flavor
flutter run --flavor prod --dart-define-from-file=.env.prod
```

### Release Builds

```bash
# Build IPA
flutter build ipa --flavor prod --dart-define-from-file=.env.prod

# Build without codesign (for CI before signing)
flutter build ios --flavor prod --dart-define-from-file=.env.prod --no-codesign
```

### Output Location

```
build/ios/
├── iphoneos/
│   └── Runner.app
└── ipa/
    └── My App.ipa
```

## Troubleshooting

### "Scheme not found"

Ensure:
1. Scheme file exists in `ios/Runner.xcodeproj/xcshareddata/xcschemes/`
2. Scheme name matches flavor name exactly (case-sensitive)
3. Scheme is marked as "Shared" in Xcode

### "Provisioning profile doesn't match"

1. Check bundle ID in scheme matches provisioning profile
2. Re-download provisioning profiles in Xcode
3. Clean build folder: Product → Clean Build Folder

### "Code signing error"

```bash
# Reset signing
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

### xcconfig Not Applied

1. Verify xcconfig includes base config (`#include "Release.xcconfig"`)
2. Check Xcode project references correct xcconfig
3. Clean and rebuild

### Firebase Crash: "Default app not configured"

1. Verify GoogleService-Info.plist copy script runs
2. Check FLAVOR variable is set in xcconfig
3. Verify plist exists at source path

## Xcode Project Structure

When set up correctly, Xcode should show:

```
Runner.xcodeproj/
├── Build Configurations:
│   ├── Debug
│   ├── Release
│   └── Profile
├── Schemes:
│   ├── dev (shared)
│   ├── staging (shared)
│   └── prod (shared)
└── Runner Target:
    └── Build Settings:
        ├── PRODUCT_BUNDLE_IDENTIFIER = $(inherited)
        └── DISPLAY_NAME = (varies by config)
```

## CI/CD Integration

In GitHub Actions:

```yaml
- name: Build iOS (Prod)
  run: flutter build ipa --flavor prod --dart-define-from-file=.env.prod --export-options-plist=ios/ExportOptions.plist

- name: Build iOS (Dev - no codesign)
  run: flutter build ios --flavor dev --dart-define-from-file=.env.dev --no-codesign
```

See `/ci-cd` skill for complete workflow templates with signing.

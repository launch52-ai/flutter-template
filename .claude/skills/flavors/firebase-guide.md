# Firebase Per-Flavor Guide

Configuring separate Firebase projects for each environment flavor.

> **Prerequisite:** For basic Firebase setup (single project), see `/analytics` skill → `firebase-setup-guide.md`. This guide covers **multi-project** configuration only.

## Why Separate Firebase Projects?

Using separate Firebase projects per flavor provides:

1. **Data isolation** - Dev data doesn't pollute production
2. **Crash grouping** - Dev crashes separated from prod crashes
3. **Auth isolation** - Test users separate from real users
4. **Billing clarity** - Track costs per environment

## Recommended Setup

| Flavor | Firebase Project | Purpose |
|--------|------------------|---------|
| dev | `myapp-dev` | Local development |
| staging | `myapp-staging` | QA testing (optional) |
| prod | `myapp-prod` | Production users |

## Step 1: Create Firebase Projects

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create projects: `myapp-dev`, `myapp-staging` (optional), `myapp-prod`

## Step 2: Register Apps in Each Project

For each Firebase project, register both Android and iOS apps with the **flavor-specific bundle ID**:

| Flavor | Android Package | iOS Bundle ID |
|--------|-----------------|---------------|
| dev | `com.example.myapp.dev` | `com.example.myapp.dev` |
| staging | `com.example.myapp.staging` | `com.example.myapp.staging` |
| prod | `com.example.myapp` | `com.example.myapp` |

Download config files from each project.

## Step 3: Place Config Files

### Android

```
android/app/src/
├── dev/google-services.json       # From myapp-dev
├── staging/google-services.json   # From myapp-staging
├── prod/google-services.json      # From myapp-prod
└── main/AndroidManifest.xml
```

Gradle automatically selects the correct file based on build flavor.

### iOS

```
ios/
├── config/
│   ├── dev/GoogleService-Info.plist
│   ├── staging/GoogleService-Info.plist
│   └── prod/GoogleService-Info.plist
└── Runner/GoogleService-Info.plist    # Copied at build time
```

## Step 4: iOS Build Phase Script

Add a Run Script build phase to copy the correct plist:

1. Xcode → Runner target → Build Phases
2. Add Run Script Phase (before "Copy Bundle Resources")
3. Add script:

```bash
#!/bin/bash
set -e
FLAVOR="${FLAVOR:-prod}"
CONFIG_DIR="${PROJECT_DIR}/config/${FLAVOR}"
PLIST_SOURCE="${CONFIG_DIR}/GoogleService-Info.plist"
PLIST_DEST="${PROJECT_DIR}/Runner/GoogleService-Info.plist"

if [ ! -f "$PLIST_SOURCE" ]; then
    echo "error: GoogleService-Info.plist not found at ${PLIST_SOURCE}"
    exit 1
fi
cp "$PLIST_SOURCE" "$PLIST_DEST"
```

**Important:** Ensure `FLAVOR` is defined in your xcconfig files (see [ios-guide.md](ios-guide.md)).

## Step 5: Verify Connection

```dart
if (kDebugMode) {
  final app = Firebase.app();
  print('Firebase project: ${app.options.projectId}');
  // Should print: myapp-dev, myapp-staging, or myapp-prod
}
```

## Troubleshooting

### "Default app has not been configured"

1. Verify config file exists in correct flavor directory
2. Check iOS build script copied the file
3. Clean and rebuild: `flutter clean && flutter pub get`

### Wrong Firebase Project Connected

1. Verify correct config file is in place for the flavor
2. Check iOS build phase script runs correctly
3. Clean build folder and rebuild

### Config File Not Found (Android)

Ensure directory matches flavor name exactly:
- `android/app/src/dev/` not `android/app/src/Dev/`

## Related Skills

- `/analytics` - Basic Firebase setup, Crashlytics, dSYM uploads
- `/push-notifications` - FCM configuration per flavor
- `/ci-cd` - Per-flavor secrets and workflows

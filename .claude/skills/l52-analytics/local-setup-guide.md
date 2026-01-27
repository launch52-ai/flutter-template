# Local Setup Guide

Configure debug symbol uploads for local development builds (Xcode Build Phases).

---

## Overview

For local development, dSYM upload happens automatically via Xcode Build Phases. This ensures crash reports are symbolicated even for debug/ad-hoc builds.

**For CI/CD pipeline setup, see:** `/ci-cd` skill → [debug-symbols-guide.md](../.claude/skills/ci-cd/debug-symbols-guide.md)

---

## Scripts

The analytics skill provides these scripts in `scripts/`:

| Script | Provider | Usage |
|--------|----------|-------|
| `upload_dsyms_crashlytics.sh` | Firebase | Xcode Build Phase or CI |
| `upload_dsyms_sentry.sh` | Sentry | Xcode Build Phase or CI |
| `upload_mapping_android.sh` | Both | CI only (Android) |

Copy scripts to your project's `scripts/` directory.

---

## Xcode Build Phase Setup

### Firebase Crashlytics

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target → **Build Phases**
3. Click **+** → **New Run Script Phase**
4. Name it "Upload dSYMs to Crashlytics"
5. Move it **after** the "Run Script" phase that runs Flutter
6. Add script:

```bash
"${PODS_ROOT}/FirebaseCrashlytics/run"
```

7. Add **Input Files**:
```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist
$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist
$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)
```

8. Uncheck "Based on dependency analysis" (ensures it always runs)

### Sentry

1. Install sentry-cli:
```bash
brew install getsentry/tools/sentry-cli
```

2. Create `.sentryclirc` in project root:
```ini
[defaults]
org=your-org-slug
project=your-project-slug

[auth]
token=your-auth-token
```

3. Add to `.gitignore`:
```
.sentryclirc
```

4. In Xcode, add **New Run Script Phase** after Flutter build:

```bash
if which sentry-cli >/dev/null; then
  export SENTRY_ORG="your-org"
  export SENTRY_PROJECT="your-project"
  ERROR=$(sentry-cli debug-files upload --include-sources "$DWARF_DSYM_FOLDER_PATH" 2>&1 >/dev/null)
  if [ ! $? -eq 0 ]; then
    echo "warning: sentry-cli - $ERROR"
  fi
else
  echo "warning: sentry-cli not installed, skipping dSYM upload"
fi
```

**Note:** Using `warning:` prefix shows in Xcode without failing the build.

---

## Android Local Setup

### Firebase Crashlytics

No local setup needed. The Gradle plugin handles mapping file upload automatically when you build release:

```bash
cd android && ./gradlew assembleRelease
```

Ensure `android/app/build.gradle.kts` has:

```kotlin
firebaseCrashlytics {
    mappingFileUploadEnabled = true
}
```

### Sentry

For local Android release builds:

```bash
# Build release
flutter build apk --release

# Upload mapping manually
./scripts/upload_mapping_android.sh sentry
```

---

## Verify Setup

### Crashlytics

1. Build app in Release mode
2. Check Xcode build log for "Uploading dSYM"
3. Force a test crash (see implementation-guide.md)
4. Check Firebase Console → Crashlytics for symbolicated stack trace

### Sentry

1. Build app in Release mode
2. Check Xcode build log for sentry-cli output
3. Check Sentry dashboard → Releases for uploaded symbols
4. Force a test error and verify symbolication

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "run: No such file" | Run `pod install` first |
| dSYMs not uploading | Check Input Files paths |
| "sentry-cli not found" | Install: `brew install getsentry/tools/sentry-cli` |
| Build fails on script | Use `warning:` prefix to not fail build |
| Wrong symbols uploaded | Clean build folder, rebuild |

---

## Related

- [implementation-guide.md](implementation-guide.md) - Full code setup
- [providers-guide.md](providers-guide.md) - Provider comparison
- `/ci-cd` skill - Automated pipeline setup

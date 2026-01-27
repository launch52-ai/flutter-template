# Release Checklist

Comprehensive pre-release checklist for Flutter apps. Complete all items before submitting to stores.

> **Using CI/CD?** Many of these manual steps (signing, uploading) are automated with `/ci-cd`. This checklist covers manual releases. For automated releases, focus on Phase 1 (Code Quality) and Phase 4 (Assets) - CI handles the rest.

---

## Quick Status Check

```bash
# Run automated audit
dart run .claude/skills/release/scripts/check.dart

# Build release (both platforms)
flutter build appbundle --release && flutter build ipa --release
```

---

## Phase 1: Code Quality

### 1.1 Testing

- [ ] All unit tests pass: `flutter test`
- [ ] Widget tests pass for key screens
- [ ] Integration tests pass (if applicable)
- [ ] Manual QA completed on physical devices
- [ ] No console errors or warnings in release build

### 1.2 Code Cleanup

- [ ] No `print()` statements (use proper logging)
- [ ] No `// TODO:` comments for critical features
- [ ] No hardcoded test/debug URLs
- [ ] No placeholder content visible
- [ ] Debug menu disabled/removed for release
- [ ] All features fully implemented (no stub functions)

### 1.3 Performance

- [ ] App launches in < 3 seconds
- [ ] Smooth scrolling (60fps)
- [ ] No memory leaks (check with DevTools)
- [ ] Images optimized (appropriate sizes)
- [ ] API calls have proper loading states

### 1.4 Security

- [ ] No hardcoded API keys in code
- [ ] Secrets in `.env` file (not committed)
- [ ] No sensitive data logged
- [ ] All network calls use HTTPS
- [ ] Input validation on all user inputs

---

## Phase 2: Android Configuration

### 2.1 Signing

- [ ] Keystore generated
- [ ] Keystore backed up securely (not in repo)
- [ ] `key.properties` created
- [ ] `key.properties` in `.gitignore`
- [ ] `build.gradle.kts` has signing config

### 2.2 Build Configuration

- [ ] `proguard-rules.pro` created
- [ ] `minifyEnabled = true` in release
- [ ] `shrinkResources = true` in release
- [ ] Package name correct in `build.gradle.kts`
- [ ] Version code incremented: `pubspec.yaml` → `version: x.y.z+N`

### 2.3 Manifest

- [ ] Internet permission: `<uses-permission android:name="android.permission.INTERNET"/>`
- [ ] All required permissions declared
- [ ] No unnecessary permissions
- [ ] Intent filters correct (deep links)

### 2.4 Build Test

```bash
flutter build appbundle --release
```

- [ ] Build completes without errors
- [ ] No ProGuard warnings for app classes
- [ ] AAB size reasonable (< 50MB recommended)

---

## Phase 3: iOS Configuration

### 3.1 Xcode Signing

- [ ] Team selected in Xcode
- [ ] Bundle Identifier correct
- [ ] Automatically manage signing enabled (or manual profiles set)
- [ ] Required capabilities enabled

### 3.2 Info.plist

- [ ] Display name correct: `CFBundleDisplayName`
- [ ] Bundle ID correct: `CFBundleIdentifier`
- [ ] Version correct: `CFBundleShortVersionString`
- [ ] `ITSAppUsesNonExemptEncryption` set (skip export question)
- [ ] All permission descriptions included:
  - [ ] `NSCameraUsageDescription` (if using camera)
  - [ ] `NSPhotoLibraryUsageDescription` (if using photos)
  - [ ] `NSLocationWhenInUseUsageDescription` (if using location)
  - [ ] `NSMicrophoneUsageDescription` (if using microphone)
  - [ ] `NSFaceIDUsageDescription` (if using Face ID)

### 3.3 Privacy Manifest (iOS 17+)

- [ ] `PrivacyInfo.xcprivacy` created in ios/Runner/
- [ ] Added to Xcode project
- [ ] NSPrivacyAccessedAPITypes declared (UserDefaults, etc.)
- [ ] NSPrivacyTracking set correctly

### 3.5 Capabilities

- [ ] Sign in with Apple (if using)
- [ ] Push Notifications (if using)
- [ ] Associated Domains (if using deep links)

### 3.6 Build Test

```bash
flutter build ipa --release
```

- [ ] Build completes without errors
- [ ] No signing errors
- [ ] IPA size reasonable

---

## Phase 4: App Assets

### 4.1 App Icon

- [ ] Source icon: 1024x1024 PNG
- [ ] No transparency (iOS requirement)
- [ ] iOS: AppIcon configured in Xcode Assets
- [ ] Android: Launcher icons generated (all mipmap sizes)
- [ ] Android: Adaptive icon configured (Android 8+)

### 4.2 Splash Screen

- [ ] Splash logo created
- [ ] `flutter_native_splash` configured in pubspec.yaml
- [ ] Splash generated: `dart run flutter_native_splash:create`
- [ ] Android 12+ splash configured (`android_12` section)
- [ ] Dark mode splash (optional)

---

## Phase 5: App Store Connect (iOS)

### 5.1 App Setup

- [ ] App created in App Store Connect
- [ ] Bundle ID matches Xcode
- [ ] Primary category selected
- [ ] Age rating questionnaire completed

### 5.2 Store Listing

- [ ] App name (30 chars max)
- [ ] Subtitle (30 chars max, optional)
- [ ] Description (4000 chars max)
- [ ] Keywords (100 chars max)
- [ ] Screenshots uploaded:
  - [ ] 6.9" iPhone (1290x2796) - **required** (other sizes auto-scaled)
  - [ ] 13" iPad (2064x2752) - if supporting iPad
- [ ] App preview video (optional)

### 5.3 Privacy & Legal

- [ ] Privacy policy URL provided
- [ ] Support URL provided
- [ ] App Privacy questionnaire completed
- [ ] Terms of service URL (if applicable)

### 5.4 Build Upload

- [ ] `ITSAppUsesNonExemptEncryption` added to Info.plist (skips export question)
- [ ] Build uploaded to App Store Connect
- [ ] Build appears in TestFlight
- [ ] Internal testing verified

---

## Phase 6: Google Play Console (Android)

### 6.1 App Setup

- [ ] App created in Play Console
- [ ] Package name matches build.gradle.kts
- [ ] App category selected
- [ ] Content rating questionnaire completed

### 6.2 Store Listing

- [ ] App title (50 chars max)
- [ ] Short description (80 chars max)
- [ ] Full description (4000 chars max)
- [ ] Feature graphic (1024x500)
- [ ] Phone screenshots (min 2)
- [ ] Tablet screenshots (if supporting tablets)

### 6.3 Data Safety Declaration

- [ ] Data safety form started (Policy > App content > Data safety)
- [ ] All collected data types declared
- [ ] Third-party SDK data collection reviewed
- [ ] Data sharing declared accurately
- [ ] Security practices completed

### 6.4 Privacy & Legal

- [ ] Privacy policy URL provided
- [ ] Ads declaration completed (if showing ads)

### 6.5 App Signing

- [ ] Google Play App Signing enabled (recommended)
- [ ] Or: own key configured correctly

### 6.6 Build Upload

- [ ] AAB uploaded to track (internal/closed/open/production)
- [ ] Release name added
- [ ] Release notes added

---

## Phase 7: Security Verification

### 7.1 Sensitive Files Check

```bash
# Check these are NOT in git history
git log --all --full-history -- "**/key.properties"
git log --all --full-history -- "**/*.jks"
git log --all --full-history -- "**/*.keystore"
git log --all --full-history -- "**/.env"
git log --all --full-history -- "**/*.p8"
```

- [ ] No sensitive files in git history
- [ ] `.gitignore` has all sensitive file patterns

### 7.2 Gitignore Contents

Verify `.gitignore` includes:

```gitignore
# Environment
.env
.env.*
!.env.example

# Android signing
android/key.properties
*.jks
*.keystore

# Apple keys
*.p8
*.p12
*.mobileprovision

# IDE
.idea/
*.iml
.vscode/
*.swp

# Build
build/
*.apk
*.aab
*.ipa
```

---

## Phase 8: Final Verification

### 8.1 Device Testing

- [ ] Tested on iOS physical device (release build)
- [ ] Tested on Android physical device (release build)
- [ ] Tested on multiple screen sizes
- [ ] Tested with slow network (3G simulation)
- [ ] Tested offline behavior
- [ ] Tested app kill/restore
- [ ] Tested deep links (if applicable)

### 8.2 User Flow Testing

- [ ] Onboarding flow completes
- [ ] Sign up works
- [ ] Login works
- [ ] Logout works
- [ ] All main features accessible
- [ ] Error states display correctly
- [ ] Loading states display correctly
- [ ] Empty states display correctly

### 8.3 Accessibility

- [ ] VoiceOver (iOS) announces controls correctly
- [ ] TalkBack (Android) announces controls correctly
- [ ] Touch targets ≥ 48dp
- [ ] Text readable at 2x scale
- [ ] Color contrast adequate

---

## Pre-Submission Checklist

### Final Items

- [ ] Version number correct: `pubspec.yaml`
- [ ] Build number incremented: `pubspec.yaml`
- [ ] Changelog/release notes written
- [ ] Marketing materials ready
- [ ] Support channels ready (email, help center)
- [ ] Analytics configured (if using)
- [ ] Crash reporting configured (if using)

### Store Submission

**App Store (iOS):**
- [ ] Build selected in App Store Connect
- [ ] Version information complete
- [ ] What's New section filled
- [ ] Review notes added (if needed)
- [ ] Submit for Review clicked

**Play Store (Android):**
- [ ] Release created in chosen track
- [ ] Release notes added
- [ ] Countries selected
- [ ] Rollout percentage set (staged rollout recommended)
- [ ] Review release clicked

---

## Post-Release

### Monitor

- [ ] Check crash reports (Crashlytics/Sentry)
- [ ] Monitor user reviews
- [ ] Check analytics for issues
- [ ] Respond to initial feedback

### Backup

- [ ] Keystore backed up securely
- [ ] Release notes documented
- [ ] Version tagged in git: `git tag v1.0.0`

---

## Automated Check

Run the release audit script:

```bash
dart run .claude/skills/release/scripts/check.dart
```

This checks:
- Keystore configuration
- Gitignore contents
- Build file configuration
- Asset presence
- Environment file security

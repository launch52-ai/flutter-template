# Analytics & Crashlytics Checklist

Comprehensive verification checklist for analytics and crash reporting implementation.

---

## Firebase Console Setup

- [ ] Firebase project created
- [ ] Google Analytics enabled for project
- [ ] iOS app added with correct Bundle ID
- [ ] Android app added with correct Package Name
- [ ] Crashlytics enabled in Console

## iOS Configuration

- [ ] `GoogleService-Info.plist` downloaded
- [ ] File added to Xcode project (not just file system)
- [ ] File is in Runner target
- [ ] Crashlytics dSYM upload script added to Build Phases
- [ ] Input files configured for dSYM script
- [ ] Privacy manifest entries added (iOS 17+)
- [ ] `flutter build ios --release` succeeds

## Android Configuration

- [ ] `google-services.json` downloaded
- [ ] File placed in `android/app/`
- [ ] Google Services plugin added to project `build.gradle.kts`
- [ ] Google Services plugin applied in app `build.gradle.kts`
- [ ] Crashlytics plugin added and applied
- [ ] `mappingFileUploadEnabled = true` for release builds
- [ ] `flutter build apk --release` succeeds

## Code Implementation

### Initialization

- [ ] `Firebase.initializeApp()` called in `main()`
- [ ] `CrashlyticsService.initialize()` called
- [ ] `AnalyticsService.initialize()` called
- [ ] `FlutterError.onError` catches Flutter errors
- [ ] `PlatformDispatcher.instance.onError` catches async errors

### Screen Tracking

- [ ] `AnalyticsRouteObserver` added to GoRouter
- [ ] Screen names are descriptive and consistent
- [ ] Screens without routes tracked manually

### Event Tracking

- [ ] Standard events used where applicable (login, sign_up, purchase)
- [ ] Custom events follow naming conventions (snake_case, <40 chars)
- [ ] Event parameters are meaningful and typed correctly
- [ ] No reserved event names used
- [ ] Key user actions have corresponding events

### User Properties

- [ ] User ID set on login
- [ ] User ID cleared on logout
- [ ] Subscription tier tracked
- [ ] Account type tracked
- [ ] No reserved property names used

### Error Tracking

- [ ] Non-fatal errors recorded to Crashlytics
- [ ] Error context provided (reason parameter)
- [ ] Breadcrumbs added for key user actions
- [ ] Custom keys set for crash context
- [ ] API errors logged to both Analytics and Crashlytics

## Privacy & Consent

- [ ] Analytics disabled in debug builds (optional)
- [ ] Consent check before enabling collection (if GDPR required)
- [ ] Consent dialog implemented (if required)
- [ ] Opt-out mechanism in settings (if required)
- [ ] Privacy policy mentions analytics usage

## Testing

### Debug Verification

- [ ] DebugView enabled for development
- [ ] Events appear in DebugView
- [ ] Screen views tracked correctly
- [ ] User properties visible in DebugView

### Crash Testing

- [ ] Test crash triggered on real device
- [ ] App reopened after crash (to upload report)
- [ ] Crash appears in Crashlytics Console
- [ ] Stack trace is symbolicated
- [ ] Breadcrumbs visible in crash report

### Production Verification

- [ ] Wait 24-48 hours after release
- [ ] Events appear in Analytics Dashboard
- [ ] User counts match expectations
- [ ] Crashes appear in Crashlytics (if any)
- [ ] dSYMs uploaded for release builds

## Common Issues to Check

| Issue | Verification |
|-------|--------------|
| Events delayed | Normal - wait 24-48h |
| Crashes not symbolicated | Check dSYM upload script |
| User properties missing | Set before logging events |
| Duplicate events | Check for double initialization |
| Debug events in production | Remove debug flags |

---

## Quick Validation Commands

```bash
# Build and check for Firebase errors
flutter build apk --debug 2>&1 | grep -i firebase
flutter build ios --debug --no-codesign 2>&1 | grep -i firebase

# Check config files exist
ls -la android/app/google-services.json
ls -la ios/Runner/GoogleService-Info.plist

# Android debug - enable analytics debug
adb shell setprop debug.firebase.analytics.app your.package.name
```

---

## Before Release

- [ ] Remove test crash code
- [ ] Disable debug logging
- [ ] Verify dSYM upload in Xcode build settings
- [ ] Verify mapping file upload for Android release
- [ ] Test on real devices (both platforms)
- [ ] Verify events in DebugView before publishing

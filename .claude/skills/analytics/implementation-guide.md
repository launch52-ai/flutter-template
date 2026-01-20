# Implementation Guide

Step-by-step analytics and crash reporting setup with Firebase Analytics and Crashlytics.

---

## Project Structure

Copy reference files to your project:

```
lib/core/services/
├── analytics_service.dart       ← reference/services/
└── crashlytics_service.dart     ← reference/services/

lib/features/analytics/
├── data/
│   ├── models/
│   │   └── analytics_event.dart        ← reference/models/
│   └── repositories/
│       └── analytics_repository_impl.dart
├── domain/
│   ├── failures/
│   │   └── analytics_failures.dart     ← reference/failures/
│   └── repositories/
│       └── analytics_repository.dart   ← reference/repositories/
└── presentation/
    └── providers/
        └── analytics_providers.dart    ← reference/providers/

lib/core/router/
└── analytics_observer.dart      ← reference/utils/
```

---

## Setup Steps

### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^3.9.0
  firebase_analytics: ^11.4.0
  firebase_crashlytics: ^4.3.0

dev_dependencies:
  build_runner: ^2.4.13
```

### 2. iOS Configuration

**Add GoogleService-Info.plist:**
1. Download from Firebase Console
2. Add to `ios/Runner/` in Xcode (not just file system)
3. Ensure it's in the Runner target

**Info.plist additions (Privacy Manifest for iOS 17+):**

```xml
<!-- ios/Runner/Info.plist -->
<!-- Required for App Store submission -->
<key>NSPrivacyTracking</key>
<false/>
<key>NSPrivacyTrackingUsageDescription</key>
<string>We use analytics to improve your experience.</string>
```

**Configure dSYM upload for Crashlytics:**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Build Phases
3. Add New Run Script Phase (after "Run Script" for Flutter)
4. Add script:

```bash
"${PODS_ROOT}/FirebaseCrashlytics/run"
```

5. Add input files:
```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist
$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist
$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)
```

### 3. Android Configuration

**android/app/build.gradle.kts:**

```kotlin
plugins {
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    buildTypes {
        release {
            // Enable Crashlytics mapping file upload
            firebaseCrashlytics {
                mappingFileUploadEnabled = true
            }
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-crashlytics")
}
```

**android/build.gradle.kts:**

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
}
```

### 4. Initialize in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'core/services/analytics_service.dart';
import 'core/services/crashlytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Initialize Crashlytics
  await CrashlyticsService.initialize();

  // Catch Flutter errors
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Analytics
  await AnalyticsService.initialize();

  runApp(const ProviderScope(child: MyApp()));
}
```

### 5. Add Router Observer for Screen Tracking

```dart
// lib/core/router/router.dart
import 'analytics_observer.dart';

final router = GoRouter(
  observers: [
    AnalyticsRouteObserver(),
  ],
  routes: [...],
);
```

### 6. Generate Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Event Tracking Patterns

### Standard Events (Use Firebase Predefined)

Firebase Analytics has predefined events with standard parameters. Use these when possible:

```dart
// Login
await AnalyticsService.logLogin(loginMethod: 'email');

// Sign up
await AnalyticsService.logSignUp(signUpMethod: 'google');

// Purchase
await AnalyticsService.logPurchase(
  currency: 'USD',
  value: 9.99,
  items: [AnalyticsEventItem(itemId: 'sku_123', itemName: 'Premium')],
);

// Screen view (automatic via observer, but manual if needed)
await AnalyticsService.logScreenView(screenName: 'ProductDetails');
```

### Custom Events

For app-specific actions not covered by standard events:

```dart
// Feature usage
await AnalyticsService.logEvent(
  name: 'feature_used',
  parameters: {
    'feature_name': 'dark_mode',
    'enabled': true,
  },
);

// Content interaction
await AnalyticsService.logEvent(
  name: 'content_shared',
  parameters: {
    'content_type': 'article',
    'content_id': 'abc123',
    'share_method': 'twitter',
  },
);

// Error tracking (non-fatal)
await AnalyticsService.logEvent(
  name: 'error_occurred',
  parameters: {
    'error_type': 'api_error',
    'error_code': '500',
    'endpoint': '/users',
  },
);
```

### Event Naming Rules

| Rule | Good | Bad |
|------|------|-----|
| Snake_case | `purchase_completed` | `PurchaseCompleted` |
| Max 40 chars | `item_added_to_cart` | `item_was_successfully_added_to_shopping_cart` |
| No reserved prefixes | `app_purchase` | `firebase_purchase`, `ga_purchase` |
| Descriptive | `checkout_started` | `event1` |

---

## User Properties

Set user properties to segment your analytics:

```dart
// On login or profile update
await AnalyticsService.setUserProperty(
  name: 'subscription_tier',
  value: user.subscriptionTier, // 'free', 'premium', 'enterprise'
);

await AnalyticsService.setUserProperty(
  name: 'account_type',
  value: user.accountType, // 'personal', 'business'
);

// Set user ID for cross-device tracking
await AnalyticsService.setUserId(user.id);

// Clear on logout
await AnalyticsService.setUserId(null);
await AnalyticsService.setUserProperty(name: 'subscription_tier', value: null);
```

### Reserved User Properties

Don't use these names (reserved by Firebase):
- `Age`, `Gender`, `Interest` (use Demographics in Console)
- `first_open_time`, `first_visit_time`
- Any starting with `firebase_`, `google_`, `ga_`

---

## Crash Reporting

### Record Non-Fatal Errors

```dart
try {
  await apiService.fetchData();
} catch (error, stackTrace) {
  // Record to Crashlytics without crashing
  await CrashlyticsService.recordError(
    error,
    stackTrace,
    reason: 'Failed to fetch user data',
  );

  // Also log to Analytics for correlation
  await AnalyticsService.logEvent(
    name: 'api_error',
    parameters: {'endpoint': '/data', 'error': error.toString()},
  );
}
```

### Add Breadcrumbs

Breadcrumbs help understand the user journey before a crash:

```dart
// Log key user actions
await CrashlyticsService.log('User opened settings');
await CrashlyticsService.log('User tapped "Delete Account"');
await CrashlyticsService.log('Confirmation dialog shown');
// If crash occurs here, you'll see these logs in Console
```

### Set Custom Keys

Add context that appears in crash reports:

```dart
// Set on login
await CrashlyticsService.setCustomKey('user_tier', 'premium');
await CrashlyticsService.setCustomKey('feature_flags', 'dark_mode,beta_features');

// Update on state change
await CrashlyticsService.setCustomKey('cart_items', '3');
await CrashlyticsService.setCustomKey('last_screen', 'CheckoutScreen');
```

### Test Crash Reporting

```dart
// Force a test crash (DO NOT ship to production)
// Add a debug button or use debug menu
if (kDebugMode) {
  ElevatedButton(
    onPressed: () => FirebaseCrashlytics.instance.crash(),
    child: Text('Test Crash'),
  );
}
```

---

## Privacy & Consent

### GDPR Compliance Pattern

```dart
final class ConsentService {
  static const _analyticsConsentKey = 'analytics_consent';

  static Future<bool> hasAnalyticsConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_analyticsConsentKey) ?? false;
  }

  static Future<void> setAnalyticsConsent(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsConsentKey, granted);

    // Enable/disable collection based on consent
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(granted);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(granted);
  }
}
```

### Consent Dialog

```dart
Future<void> showConsentDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(t.consent.title),
      content: Text(t.consent.analyticsDescription),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.consent.decline),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(t.consent.accept),
        ),
      ],
    ),
  );

  await ConsentService.setAnalyticsConsent(result ?? false);
}
```

---

## Debug Mode

### Disable in Debug Builds

```dart
Future<void> initializeAnalytics() async {
  if (kDebugMode) {
    // Disable Crashlytics in debug to avoid noise
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  } else {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }
}
```

### Enable Debug View (Firebase Console)

```bash
# iOS Simulator
adb shell setprop debug.firebase.analytics.app your.package.name

# Android
adb shell setprop debug.firebase.analytics.app your.package.name

# Disable debug mode
adb shell setprop debug.firebase.analytics.app .none.
```

Then view real-time events in Firebase Console → Analytics → DebugView.

---

## Reference Files Overview

### Services

**analytics_service.dart** - Static service:
- `initialize()` - Setup Analytics
- `logEvent()` - Log custom event
- `logScreenView()` - Log screen view
- `setUserProperty()` - Set user property
- `setUserId()` - Set user ID

**crashlytics_service.dart** - Static service:
- `initialize()` - Setup Crashlytics
- `recordError()` - Record non-fatal error
- `log()` - Add breadcrumb
- `setCustomKey()` - Set crash context
- `setUserIdentifier()` - Set user ID

### Providers

**analytics_providers.dart** - Riverpod providers:
- `analyticsServiceProvider` - Service instance
- `analyticsEnabledProvider` - Consent state

### Failures

**analytics_failures.dart** - Sealed types:
- `AnalyticsDisabledFailure`
- `EventValidationFailure`
- `CrashlyticsUploadFailure`
- `ConsentRequiredFailure`

---

## Testing

### Mock Analytics in Tests

```dart
final class MockAnalyticsService implements AnalyticsService {
  final List<Map<String, dynamic>> loggedEvents = [];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    loggedEvents.add({'name': name, 'parameters': parameters});
  }
}

// In test
final mockAnalytics = MockAnalyticsService();
container = ProviderContainer(overrides: [
  analyticsServiceProvider.overrideWithValue(mockAnalytics),
]);

// Verify
await notifier.completePurchase();
expect(
  mockAnalytics.loggedEvents,
  contains({'name': 'purchase_completed', 'parameters': {...}}),
);
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Events not appearing | Debug mode not enabled | Enable DebugView in Console |
| Crashes not uploading | dSYM not configured | Add build phase script |
| User properties missing | Set after event | Set properties before logging events |
| Too many custom events | >500 unique event names | Consolidate into fewer events with parameters |
| Data delayed | Normal processing time | Wait 24-48 hours for reports |

---

## Related

- [firebase-setup-guide.md](firebase-setup-guide.md) - Firebase Console setup
- [checklist.md](checklist.md) - Implementation verification
- `/push-notifications` - Firebase project (shared)
- `/release` - iOS build phases
- `/i18n` - Consent dialog strings

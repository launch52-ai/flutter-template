# Analytics Providers Guide

Comparison and setup instructions for different analytics and error tracking providers.

---

## Quick Decision

| Need | Recommended | Why |
|------|-------------|-----|
| **Just get started** | Firebase | Free, easy setup, good enough |
| **Better product analytics** | PostHog | Funnels, retention, session replay |
| **Better error tracking** | Sentry | Superior debugging, performance |
| **Data ownership** | PostHog (self-hosted) | Your servers, your data |
| **Enterprise/compliance** | Mixpanel + Sentry | Audit trails, SOC2 |

---

## Provider Comparison

### Product Analytics

| Feature | Firebase | PostHog | Mixpanel |
|---------|----------|---------|----------|
| **Price** | Free | Free tier / Self-host | Free tier, paid scales |
| **Event limits** | 500 types | Unlimited | 1M events/mo free |
| **Retention analysis** | Basic | Excellent | Excellent |
| **Funnels** | Basic | Excellent | Excellent |
| **Session replay** | No | Yes | Yes (paid) |
| **Feature flags** | Remote Config | Built-in | No |
| **Self-hostable** | No | Yes | No |
| **Flutter SDK** | Official | Official | Official |
| **GDPR friendly** | Moderate | Excellent | Good |

### Error Tracking

| Feature | Crashlytics | Sentry |
|---------|-------------|--------|
| **Price** | Free | Free tier, paid scales |
| **Stack traces** | Good | Excellent |
| **Performance monitoring** | No | Yes |
| **Release tracking** | Basic | Excellent |
| **Issue grouping** | Basic | Intelligent |
| **Breadcrumbs** | Via log() | Native support |
| **Self-hostable** | No | Yes |
| **Flutter SDK** | Official | Official |

---

## Recommended Combinations

### Startup / MVP
```
Firebase Analytics + Crashlytics
```
- Free, quick to set up
- Good enough for early stage
- Upgrade later when needed

### Product-Focused
```
PostHog + Sentry
```
- Best-in-class for each concern
- Better insights for product decisions
- Worth the setup complexity

### Privacy-First / Enterprise
```
PostHog (self-hosted) + Sentry (self-hosted)
```
- Full data ownership
- GDPR compliant by design
- Higher operational cost

### Budget with Better Insights
```
PostHog + Crashlytics
```
- PostHog free tier is generous
- Crashlytics is free
- Good middle ground

---

## Setup Instructions

### Firebase Analytics + Crashlytics

**Dependencies:**
```yaml
dependencies:
  firebase_core: ^3.9.0
  firebase_analytics: ^11.4.0
  firebase_crashlytics: ^4.3.0
```

**main.dart:**
```dart
import 'package:firebase_core/firebase_core.dart';
import 'core/services/firebase_analytics_service.dart';
import 'core/services/firebase_crashlytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseAnalyticsService.instance.initialize();
  await FirebaseCrashlyticsService.instance.initialize();

  FlutterError.onError = (details) {
    FirebaseCrashlyticsService.instance.recordFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlyticsService.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());
}
```

See [firebase-setup-guide.md](firebase-setup-guide.md) for Console setup.

---

### Sentry

**Dependencies:**
```yaml
dependencies:
  sentry_flutter: ^8.12.0
```

**main.dart:**
```dart
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/services/sentry_error_tracking_service.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
      options.environment = const String.fromEnvironment(
        'ENV',
        defaultValue: 'development',
      );
    },
    appRunner: () => runApp(const MyApp()),
  );
}
```

**Get DSN:**
1. Create project at [sentry.io](https://sentry.io)
2. Go to Settings → Projects → Your Project → Client Keys (DSN)
3. Add to `.env`: `SENTRY_DSN=https://xxx@sentry.io/xxx`

**dSYM Upload (iOS):**
```bash
# Install sentry-cli
brew install getsentry/tools/sentry-cli

# Add to Xcode Build Phases
sentry-cli debug-files upload --include-sources \
  $DWARF_DSYM_FOLDER_PATH
```

---

### PostHog

**Dependencies:**
```yaml
dependencies:
  posthog_flutter: ^4.0.0
```

**main.dart:**
```dart
import 'package:posthog_flutter/posthog_flutter.dart';
import 'core/services/posthog_analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = PostHogConfig(
    const String.fromEnvironment('POSTHOG_API_KEY'),
  );
  config.host = 'https://app.posthog.com'; // or your self-hosted URL
  config.captureApplicationLifecycleEvents = true;
  config.debug = kDebugMode;

  await Posthog().setup(config);
  await PostHogAnalyticsService.instance.initialize();

  runApp(const MyApp());
}
```

**Get API Key:**
1. Create project at [posthog.com](https://posthog.com)
2. Go to Project Settings → Project API Key
3. Add to `.env`: `POSTHOG_API_KEY=phc_xxx`

---

### Mixed: PostHog + Sentry

**Dependencies:**
```yaml
dependencies:
  sentry_flutter: ^8.12.0
  posthog_flutter: ^4.0.0
```

**main.dart:**
```dart
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize PostHog first (analytics)
  final posthogConfig = PostHogConfig(
    const String.fromEnvironment('POSTHOG_API_KEY'),
  );
  await Posthog().setup(posthogConfig);

  // Initialize Sentry (error tracking)
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(const MyApp()),
  );
}
```

---

## Provider Selection in Code

The skill generates provider-agnostic interfaces. Swap implementations via Riverpod:

```dart
// providers.dart
@riverpod
ProductAnalyticsService analyticsService(AnalyticsServiceRef ref) {
  // Change this line to swap providers
  return FirebaseAnalyticsService.instance;
  // return PostHogAnalyticsService.instance;
}

@riverpod
ErrorTrackingService errorTrackingService(ErrorTrackingServiceRef ref) {
  // Change this line to swap providers
  return FirebaseCrashlyticsService.instance;
  // return SentryErrorTrackingService.instance;
}
```

---

## Migration Guide

### Firebase → PostHog

1. Install `posthog_flutter`
2. Copy `posthog_analytics_service.dart`
3. Update provider to return PostHog implementation
4. Update `main.dart` initialization
5. Event names are compatible (snake_case)
6. Verify events in PostHog dashboard

### Crashlytics → Sentry

1. Install `sentry_flutter`
2. Copy `sentry_error_tracking_service.dart`
3. Update provider to return Sentry implementation
4. Replace `SentryFlutter.init()` wrapper in main.dart
5. Update dSYM upload script (see below)
6. Remove Firebase Crashlytics dependencies

---

## Related

- [implementation-guide.md](implementation-guide.md) - Detailed setup
- [firebase-setup-guide.md](firebase-setup-guide.md) - Firebase Console
- [checklist.md](checklist.md) - Verification steps

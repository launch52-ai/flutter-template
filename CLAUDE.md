# Flutter Template - Claude Instructions

## Creating a New App

Run skills in order:

```bash
/init                    # Initialize project, gather requirements, flutter create
/core                    # Generate core infrastructure (theme, services, router)
/auth                    # Generate authentication feature
/social-login            # Add social login (if needed)
/phone-auth              # Add phone auth (if needed)
/local-auth              # Add biometric unlock (if needed)
/push-notifications      # Add push notifications (if needed)
/deep-linking            # Add deep linking (if needed)
/network-connectivity    # Add offline banner (if needed)
/offline                 # Add offline-first architecture (if needed)
/force-update            # Add force update prompts (if needed)
/flavors                 # Add dev/staging/prod environments (if needed)
/analytics               # Add analytics & crash reporting
/in-app-purchases        # Add subscriptions/purchases (if needed)
/feature-init dashboard  # Initialize dashboard scaffold
/feature-init settings   # Initialize settings scaffold
/account-deletion        # Add account deletion (App Store & Play Store required)
/i18n                    # Add localization
/release                 # When ready for app stores
```

---

## Available Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| **init** | `/init` | **Start here** - Project setup, flutter create, dependencies, main.dart |
| **core** | `/core` | Generate core infrastructure (theme, services, router, errors) |
| **auth** | `/auth` | Generate authentication feature (login screen, providers, repositories) |
| **plan** | `/plan` | Comprehensive feature planning before implementation |
| **feature-init** | `/feature-init` | Initialize feature scaffold (folder structure, skeleton files) |
| **domain** | `/domain` | Fill in domain layer details (entities, enums, repository interfaces) |
| **data** | `/data` | Fill in data layer details (DTOs, repositories, data sources) |
| **presentation** | `/presentation` | Fill in presentation layer (states, notifiers, screens, widgets) |
| **i18n** | `/i18n` | Audit hardcoded strings, write UX-friendly text, migrate to i18n |
| **testing** | `/testing` | Write unit, widget, golden tests following project patterns |
| **design** | `/design` | UI/UX implementation with proper feedback, loading states, touch targets |
| **a11y** | `/a11y` | Accessibility - Semantics widgets, WCAG compliance, screen reader support |
| **ci-cd** | `/ci-cd` | GitHub Actions workflows, Fastlane deployment, versioning automation |
| **release** | `/release` | App Store & Play Store preparation (signing, icons, splash) |
| **social-login** | `/social-login` | Google & Apple Sign-In with Supabase - OAuth setup, platform config |
| **phone-auth** | `/phone-auth` | Phone OTP - E.164 formats, country codes, rate limiting, Flutter patterns |
| **local-auth** | `/local-auth` | Biometric + device credentials - app unlock, timeout, optional app PIN, banking-grade security |
| **push-notifications** | `/push-notifications` | FCM setup, APNs config, foreground/background handling, deep linking |
| **deep-linking** | `/deep-linking` | Universal Links (iOS), App Links (Android), GoRouter integration |
| **analytics** | `/analytics` | Firebase Analytics, Crashlytics - event tracking, user properties, crash reporting |
| **network-connectivity** | `/network-connectivity` | Network connectivity monitoring with global offline banner - connectivity_plus, auto-display |
| **offline** | `/offline` | Offline-first architecture - local storage (Drift/Hive), sync queue, conflict resolution |
| **account-deletion** | `/account-deletion` | GDPR/App Store/Play Store compliant account deletion - confirmation flow, data cleanup, auth sign-out |
| **force-update** | `/force-update` | Version checking, force/soft updates, maintenance mode, Android In-App Updates |
| **flavors** | `/flavors` | Environment flavors (dev/staging/prod) - flutter_dotenv, Gradle/Xcode schemes, per-env config |
| **in-app-purchases** | `/in-app-purchases` | RevenueCat subscriptions, one-time purchases, paywalls, entitlements |

---

## Workflow

### New App Creation

1. `/init` - Initialize project, gather requirements
2. `/core` - Generate core/ infrastructure
3. `/auth` - Generate auth feature (asks which methods)
4. `/social-login` or `/phone-auth` - Add specific auth methods
5. `/feature-init dashboard` - Initialize dashboard scaffold
6. `/feature-init settings` - Initialize settings scaffold

### Adding Features

1. `/plan {feature}` - **Plan first**: Gather requirements, design all layers
2. `/feature-init {feature}` - Initialize folder structure and skeleton files
3. `/domain {feature}` - Fill in domain layer details (entities, enums, interfaces)
4. `/data {feature}` - Fill in data layer details (DTOs, repository impl, API calls)
5. `/presentation {feature}` - Fill in presentation layer (states, notifiers, screens)
6. `/i18n {feature}` - Add localized strings
7. `/testing {feature}` - Create test files
8. `/design` - Polish the UI
9. `/a11y` - Audit accessibility

---

## Architecture

Architecture patterns defined in `.claude/skills/plan/architecture.md`:

- Clean Architecture + DDD
- Riverpod 3.x with AsyncNotifier
- Freezed + JSON Serializable
- GoRouter with StatefulShellRoute
- Dio with auth interceptors
- SecureStorage (PII) + SharedPrefs (flags)

---

## Minimum Versions (Flutter 3.38.5)

- iOS: 13.0
- Android: 24 (Android 7.0)

---

## Code Style Rules

- Keep classes `final` where possible
- Keep functions `private` where possible
- Use `final` for variables where possible
- Screen files: 100-200 lines max
- No hardcoded strings → use slang (`t.feature.key`)
- No hardcoded colors → use `AppColors`
- All TextFields: `autocorrect: false`

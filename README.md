# Flutter Template

> **AI-powered Flutter project scaffolding with Claude Code**

A collection of 27 specialized skills that Claude Code uses to generate production-ready Flutter applications. Instead of a static boilerplate, this is a **meta-template** — describe what you need, and Claude builds it following Clean Architecture + DDD patterns.

## Why This Template?

| Traditional Boilerplate | This Template |
|------------------------|---------------|
| Copy-paste, then modify | Tell Claude what you need |
| Outdated dependencies | Always current patterns |
| One-size-fits-all | Customized to your requirements |
| Manual feature additions | `/feature-init` scaffolds instantly |

**Build a production-ready app in minutes:**
```
/init → /core → /auth → /push-notifications → /analytics → /release
```

## Features

### Core Infrastructure
- **Clean Architecture + DDD** — Scalable, testable code structure
- **Riverpod 3.x** — Type-safe state management with AsyncNotifier
- **GoRouter** — Declarative routing with StatefulShellRoute
- **Material 3** — Modern theming with light/dark mode
- **Slang** — Type-safe localization per feature

### Authentication
- **Email/Password** — Standard auth flow
- **Social Login** — Google + Apple Sign-In
- **Phone OTP** — E.164 formatting, rate limiting
- **Biometric** — Face ID, Touch ID, device credentials

### Production Essentials
- **Push Notifications** — FCM + APNs setup
- **Deep Linking** — Universal Links + App Links
- **Analytics** — Firebase Analytics + Crashlytics
- **In-App Purchases** — RevenueCat subscriptions
- **Offline Support** — Drift/Hive with sync queue
- **Force Update** — Version checking, maintenance mode
- **Account Deletion** — GDPR/App Store compliant

### Developer Experience
- **CI/CD** — GitHub Actions + Fastlane
- **Testing** — Unit, widget, golden tests
- **Accessibility** — WCAG compliance, screen readers
- **Environment Flavors** — dev/staging/prod

## Quick Start

**Prerequisites:** [Claude Code CLI](https://claude.ai/download)

1. **Fork & clone**
   - Click **Fork** on GitHub to create your own copy
   - Or clone directly:
   ```bash
   git clone https://github.com/launch52-ai/flutter-template.git my-app
   cd my-app
   ```

2. **Start Claude Code**
   ```bash
   claude
   ```

3. **Create your app**
   ```
   /init
   ```
   Claude will ask about your app name, auth methods, and preferences.

4. **Add features as needed**
   ```
   /core                    # Theme, router, services
   /auth                    # Authentication
   /push-notifications      # FCM setup
   /analytics               # Crashlytics + Analytics
   /release                 # App store preparation
   ```

## Available Skills

| Category | Skills |
|----------|--------|
| **Setup** | `/init`, `/core` |
| **Auth** | `/auth`, `/social-login`, `/phone-auth`, `/local-auth` |
| **Features** | `/plan`, `/feature-init`, `/domain`, `/data`, `/presentation` |
| **Infrastructure** | `/push-notifications`, `/deep-linking`, `/analytics`, `/offline`, `/network-connectivity` |
| **Monetization** | `/in-app-purchases`, `/force-update` |
| **Compliance** | `/account-deletion`, `/flavors` |
| **Quality** | `/i18n`, `/testing`, `/design`, `/a11y` |
| **Release** | `/release`, `/ci-cd` |

## Architecture

```
lib/
├── core/                 # Shared infrastructure
│   ├── theme/            # Colors, typography
│   ├── router/           # GoRouter config
│   ├── services/         # Storage, network
│   └── widgets/          # Reusable components
└── features/             # Feature modules
    └── {feature}/
        ├── data/         # DTOs, repositories
        ├── domain/       # Entities, interfaces
        └── presentation/ # Screens, providers
```

## Adding a Feature

```
/plan checkout           # Design the feature
/feature-init checkout   # Create folder structure
/domain checkout         # Add entities, interfaces
/data checkout           # Implement repositories
/presentation checkout   # Build screens, state
/i18n checkout           # Add translations
/testing checkout        # Write tests
```

## Documentation

| File | Description |
|------|-------------|
| [`CLAUDE.md`](CLAUDE.md) | Full skill reference and workflows |
| [`.claude/SKILL_STRUCTURE.md`](.claude/SKILL_STRUCTURE.md) | Skill registry and delegation rules |

## Requirements

- Flutter 3.38.5+
- iOS 13.0+ / Android 7.0+ (API 24)
- Claude Code CLI

## License

MIT

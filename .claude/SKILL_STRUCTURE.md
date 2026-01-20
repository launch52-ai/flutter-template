# Skill Registry

Central registry of all Claude Code skills, their relationships, and delegation rules.

> **Creating or validating skills?** Use `/skill-create` - it has comprehensive checklists, templates, and validation scripts.

---

## Complete Skill Reference

| Skill | Category | Purpose | Run After |
|-------|----------|---------|-----------|
| `/init` | Orchestration | Project setup, flutter create, dependencies | — (first) |
| `/core` | Orchestration | Theme, router, services, errors, providers | `/init` |
| `/plan` | Orchestration | Feature planning, requirements gathering | `/init` |
| `/feature-init` | Orchestration | Initialize feature scaffold (folders, skeleton files) | `/plan` |
| `/domain` | Code-Heavy | Fill in domain layer (entities, enums, interfaces) | `/feature-init` |
| `/data` | Code-Heavy | Fill in data layer (DTOs, repository impl, data sources) | `/domain` |
| `/presentation` | Code-Heavy | Fill in presentation layer (states, notifiers, screens, widgets) | `/data` |
| `/auth` | Auth | Base auth scaffold (AuthRepository, AuthNotifier) | `/core` |
| `/social-login` | Auth | Google + Apple Sign-In | `/auth` |
| `/phone-auth` | Auth | Phone OTP verification | `/auth` |
| `/local-auth` | Auth | Biometric + device credentials, app unlock, timeout | `/auth` |
| `/push-notifications` | Config | FCM setup, APNs, foreground/background handling | `/core` |
| `/deep-linking` | Config | Universal Links (iOS), App Links (Android), GoRouter integration | `/core` |
| `/analytics` | Config | Firebase Analytics, Crashlytics, event tracking, crash reporting | `/core` |
| `/in-app-purchases` | Config | RevenueCat subscriptions, paywalls, entitlements | `/core` |
| `/network-connectivity` | Config | Network monitoring with global offline banner | `/core` |
| `/offline` | Config | Offline-first architecture, local storage, sync, conflict resolution | `/core`, `/network-connectivity` |
| `/force-update` | Config | Version checking, force/soft updates, maintenance mode | `/core` |
| `/account-deletion` | Config | GDPR/App Store compliant account deletion | `/auth` |
| `/i18n` | Knowledge | Localized strings, UX writing | `/data` or any feature |
| `/design` | Knowledge | UI/UX patterns, loading states | Any feature |
| `/testing` | Knowledge | Unit tests, widget tests, mocks | `/data` or any feature |
| `/a11y` | Knowledge | Accessibility, Semantics widgets | Any feature |
| `/release` | Config | App signing, icons, store setup | Before release |
| `/ci-cd` | Config | GitHub Actions, Fastlane | After `/release` |
| `/skill-create` | Meta | Create and validate Claude Code skills | — (standalone) |

---

## Skill Flow Diagrams

```
NEW APP FLOW:
/init → /core → /auth → /social-login ──┐
                        └→ /phone-auth ──┼→ /local-auth → /push-notifications → /deep-linking → /analytics → /in-app-purchases → /i18n → /testing → /release → /ci-cd
                        └→ /local-auth ──┘
                                         │
NEW FEATURE FLOW:                        │
/plan → /feature-init → /domain → /data → /presentation ─┴→ /i18n → /testing → /design → /a11y
```

### Common Sequences

**New App:**
```
/init → /core → /auth → /social-login → /phone-auth → /local-auth → /push-notifications → /deep-linking → /analytics → /in-app-purchases → /network-connectivity → /offline → /force-update → /feature-init dashboard → /i18n → /release
```

**New Feature:**
```
/plan {feature} → /feature-init {feature} → /domain {feature} → /data {feature} → /presentation {feature} → /i18n {feature} → /testing {feature}
```

**Polish Feature:**
```
/i18n {feature} → /design → /a11y → /testing {feature}
```

**Prepare Release:**
```
/release → /ci-cd
```

---

## Cross-Cutting Concerns

| Concern | Owner Skill | What It Handles |
|---------|-------------|-----------------|
| **Localization** | `/i18n` | All user-facing strings, error messages, button labels |
| **Accessibility** | `/a11y` | Semantic labels, screen reader support, WCAG compliance |
| **UI/UX Patterns** | `/design` | Loading states, error handling, touch targets, feedback |
| **Testing** | `/testing` | Unit tests, widget tests, mocks, test patterns |
| **Error Types** | `/data` | Failure classes, error mapping, Dio error handling |
| **Skill Development** | `/skill-create` | Creating, validating, and maintaining Claude Code skills |

---

## Delegation Rules

Skills focus on their core responsibility and delegate cross-cutting concerns.

### Code Generation Rules

**User-facing strings:**
```
DON'T: Text('Welcome back')
DO: Text(t.feature.welcomeBack) + note "Run /i18n to add strings"
```

**UI components:**
```
DON'T: Define loading/error patterns inline
DO: Reference /design patterns
```

**Accessibility:**
```
DON'T: Add Semantics widgets inline
DO: Note "Run /a11y to add accessibility"
```

**Tests:**
```
DON'T: Write tests inline with implementation
DO: Note "Run /testing to create tests"
```

### What Each Skill Should NOT Do

| Skill | Should NOT Handle | Delegate To |
|-------|-------------------|-------------|
| `/plan` | Generate actual code | `/feature-init`, `/domain`, `/data`, `/presentation` |
| `/init` | Feature code, auth, core | `/core`, `/auth`, `/feature-init` |
| `/core` | Auth logic, features, i18n | `/auth`, `/feature-init`, `/i18n` |
| `/feature-init` | Detailed implementation | `/domain`, `/data`, `/presentation`, `/i18n` |
| `/domain` | JSON serialization, API calls | `/data` |
| `/data` | UI components, screens | `/presentation`, `/design`, `/i18n` |
| `/presentation` | Data layer code | `/data`, `/i18n` |
| `/auth` | Specific auth methods | `/social-login`, `/phone-auth`, `/local-auth` |
| `/design` | Full screens, tests | `/feature-init`, `/testing` |
| `/i18n` | Widgets, logic | `/feature-init`, `/design` |
| `/testing` | Implementations | `/domain`, `/data` |
| `/a11y` | UI components | `/feature-init`, `/design` |
| `/release` | CI/CD pipelines | `/ci-cd` |
| `/ci-cd` | Manual signing | `/release` |
| `/network-connectivity` | NetworkFailure types, retry logic, caching | `/data`, `/core` |
| `/offline` | Simple in-memory caching, network detection, NetworkFailure types | `/data`, `/network-connectivity` |

---

## Skill Handoff Pattern

End skill workflows with "Next Steps":

```markdown
## Next Steps

After running this skill:
1. `/i18n {feature}` - Add localized strings
2. `/testing {feature}` - Create test files
3. `/design` - Review UI patterns
4. `/a11y` - Add accessibility support
```

---

## Validating Skills

```bash
# Validate all skills
dart run .claude/skills/skill-create/scripts/validate.dart --all

# Validate specific skill
dart run .claude/skills/skill-create/scripts/validate.dart --skill {name}
```

See `/skill-create` for full validation and creation workflow.

---

## Statistics

- **27 skills** with comprehensive SKILL.md files
- **250+ files** in .claude/skills directory
- **120+ reference code files** with copy-ready patterns

---

## Future Skills

Potential additions to expand the template.

| Priority | Skill | Purpose |
|----------|-------|---------|
| Medium | `/image-caching` | cached_network_image patterns, placeholder loading |
| Medium | `/password-reset` | Password reset flow UI, email verification |
| Low | `/feature-flags` | Firebase Remote Config, feature toggles |
| Low | `/onboarding` | Onboarding carousel, permission requests |
| Low | `/settings` | Common settings patterns (theme, notifications) |
| Low | `/profile` | Profile screen, avatar upload, edit flow |
| Low | `/search` | Search UI, debounce, history, filters |
| Low | `/maps` | Google Maps integration, location picker |
| Low | `/media` | Image/video picker, camera, compression |
| Low | `/chat` | Real-time chat, WebSocket, message bubbles |

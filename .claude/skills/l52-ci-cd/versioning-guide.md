# Versioning Guide

Concepts and patterns for version management in Flutter projects.

> **Note:** The setup script generates version bump scripts automatically.
> Run: `dart run .claude/skills/ci-cd/scripts/setup.dart`

---

## 1. Flutter Version Format

```yaml
version: 1.2.3+45
#        │ │ │  │
#        │ │ │  └── Build number (versionCode/CFBundleVersion)
#        │ │ └───── Patch
#        │ └─────── Minor
#        └───────── Major
```

| Part | iOS | Android | When to Increment |
|------|-----|---------|-------------------|
| Major | CFBundleShortVersionString | versionName | Breaking changes |
| Minor | CFBundleShortVersionString | versionName | New features |
| Patch | CFBundleShortVersionString | versionName | Bug fixes |
| Build | CFBundleVersion | versionCode | Every build |

---

## 2. Semantic Versioning (SemVer)

Follow [SemVer 2.0.0](https://semver.org/):

| Change | Example | When |
|--------|---------|------|
| `1.0.0` → `2.0.0` | Major | Breaking API changes |
| `1.0.0` → `1.1.0` | Minor | New features (backward compatible) |
| `1.0.0` → `1.0.1` | Patch | Bug fixes |

**Pre-release versions:**
- `1.0.0-alpha.1` - Alpha
- `1.0.0-beta.1` - Beta
- `1.0.0-rc.1` - Release candidate

---

## 3. Version Bump Scripts

Generated scripts are in `scripts/`:

```bash
# Bump patch (1.0.0 → 1.0.1)
dart run scripts/bump_version.dart patch

# Bump minor (1.0.1 → 1.1.0)
dart run scripts/bump_version.dart minor

# Bump major (1.1.0 → 2.0.0)
dart run scripts/bump_version.dart major

# Bump and create git tag
dart run scripts/bump_version.dart patch --tag
```

**Template location:** `templates/bump_version.dart` and `templates/bump_version.sh`

---

## 4. CI Build Numbers

In GitHub Actions, use run number for automatic incrementing:

```yaml
flutter build apk --build-number=${{ github.run_number }}
```

Or timestamp-based:
```yaml
BUILD_NUMBER=$(date +%Y%m%d%H%M)
```

---

## 5. Git Tag Strategy

| Tag Pattern | Purpose | Triggers |
|-------------|---------|----------|
| `v1.2.3` | Production | Play Store, App Store |
| `v1.2.3-beta.1` | Beta | TestFlight, Firebase |
| `v1.2.3-alpha.1` | Alpha | Internal testing |

```bash
# Create and push tag
git tag -a v1.2.3 -m "Release 1.2.3"
git push origin v1.2.3
```

---

## 6. Pre-Release Workflow

Typical release flow with pre-release versions:

```
1.0.0-alpha.1  →  Internal testing
1.0.0-alpha.2  →  Fix issues
1.0.0-beta.1   →  Wider testing (Firebase App Distribution)
1.0.0-beta.2   →  Fix issues
1.0.0-rc.1     →  Release candidate (TestFlight/Internal Play Store)
1.0.0          →  Production release
```

### Tag Triggers

| Tag | Deploys To |
|-----|-----------|
| `v1.0.0-alpha.1` | Firebase App Distribution |
| `v1.0.0-beta.1` | Firebase App Distribution |
| `v1.0.0-rc.1` | TestFlight (iOS), Internal track (Android) |
| `v1.0.0` | App Store, Play Store production |

### Creating Pre-Release Tags

```bash
# Create beta tag
git tag -a v1.0.0-beta.1 -m "Beta 1"
git push origin v1.0.0-beta.1

# Create release candidate
git tag -a v1.0.0-rc.1 -m "Release candidate 1"
git push origin v1.0.0-rc.1
```

---

## 7. Changelog Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Changelog Section |
|--------|-------------------|
| `feat:` | Added |
| `fix:` | Fixed |
| `docs:` | Documentation |
| `refactor:` | Changed |

Example: `feat: Add user profile screen`

---

## 8. Display Version in App

```dart
import 'package:package_info_plus/package_info_plus.dart';

final info = await PackageInfo.fromPlatform();
print('${info.version} (${info.buildNumber})'); // 1.2.3 (45)
```

---

## Summary

| Task | Command |
|------|---------|
| Bump patch | `dart run scripts/bump_version.dart patch` |
| Bump + tag | `dart run scripts/bump_version.dart patch --tag` |
| Push tag | `git push origin --tags` |

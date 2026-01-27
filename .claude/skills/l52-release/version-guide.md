# Version Management for Releases

Quick reference for version-related release requirements.

> **For version bump scripts and CI integration:** See `/ci-cd` skill's [versioning-guide.md](../ci-cd/versioning-guide.md)

---

## Flutter Version Format

```yaml
version: 1.2.3+45
         │ │ │  │
         │ │ │  └── Build number (must always increase)
         │ │ └───── Patch (bug fixes)
         │ └─────── Minor (new features)
         └───────── Major (breaking changes)
```

| Part | Android | iOS |
|------|---------|-----|
| 1.2.3 | versionName | CFBundleShortVersionString |
| +45 | versionCode | CFBundleVersion |

---

## Store Version Requirements

### Play Store

| Requirement | Details |
|-------------|---------|
| **versionCode** | Must always increase (never reuse) |
| **Maximum** | 2100000000 |
| **Per track** | Same versionCode can't exist in multiple tracks |
| **Promotion** | Version must be ≥ when promoting between tracks |

### App Store

| Requirement | Details |
|-------------|---------|
| **CFBundleVersion** | Must increase for each build within a version |
| **CFBundleShortVersionString** | Marketing version shown to users |
| **TestFlight** | Can reset build number when version changes |
| **Recommendation** | Always increment build number globally |

---

## Pre-Release Checklist

Before submitting to stores:

- [ ] Version incremented from last release
- [ ] Build number never used before
- [ ] What's New / Release Notes updated
- [ ] Changelog entry added
- [ ] Git tag created: `git tag v1.2.3`

---

## Common Errors

### "Version code has already been used" (Play Store)

versionCode was used in a previous upload.

**Fix:** Increment build number in pubspec.yaml:
```yaml
version: 1.0.0+2  # Was +1
```

### "Build number must be higher" (App Store)

CFBundleVersion didn't increase.

**Fix:** Same as above - increment the +N part.

### Version mismatch between platforms

Android and iOS showing different versions.

**Fix:** Run `flutter clean` and rebuild. Both platforms read from pubspec.yaml.

---

## Version Bump Scripts

Use the ci-cd skill's scripts:

```bash
# Bump patch (1.0.0 → 1.0.1)
dart run scripts/bump_version.dart patch

# Bump minor (1.0.1 → 1.1.0)
dart run scripts/bump_version.dart minor

# Bump and tag
dart run scripts/bump_version.dart patch --tag
```

> **Setup:** Run `dart run .claude/skills/ci-cd/scripts/setup.dart` to generate scripts.

---

## Related

- `/ci-cd` - Version bump scripts, CI integration, tag-based deployment

# GitHub Actions Workflows Guide

Concepts for GitHub Actions CI/CD with Flutter.

> **Note:** The setup script generates all workflow files automatically.
> Run: `dart run .claude/skills/ci-cd/scripts/setup.dart`

---

## 1. Workflow Types

| File | Trigger | Purpose |
|------|---------|---------|
| `ci.yml` | PR, push | Lint, test, analyze |
| `build-android.yml` | Push to main | Build APK/AAB artifacts |
| `build-ios.yml` | Push to main | Build iOS artifacts |
| `deploy-firebase-android.yml` | Beta tags | Firebase App Distribution |
| `deploy-testflight.yml` | Release tags | TestFlight |
| `deploy-playstore.yml` | Release tags | Play Store |
| `release.yml` | Manual | Bump version, create tag |

**Template location:** `templates/workflows/`

---

## 2. Trigger Patterns

```yaml
on:
  push:
    branches: [main]           # Push to main
    tags: ['v*']               # Any version tag

  pull_request:
    branches: [main]           # PRs targeting main

  workflow_dispatch:           # Manual trigger
    inputs:
      track:
        type: choice
        options: [internal, beta, production]
```

### Tag Patterns

| Pattern | Matches |
|---------|---------|
| `v*` | v1.0.0, v1.0.0-beta |
| `v[0-9]+.[0-9]+.[0-9]+` | v1.0.0 (exact) |
| `v*-beta*` | v1.0.0-beta.1 |

---

## 3. Flutter Setup Action

Use `subosito/flutter-action` with caching:

```yaml
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.32.0'
    cache: true
```

---

## 4. Caching Strategy

| What | Key Pattern |
|------|-------------|
| Flutter SDK | Built into flutter-action |
| Pub cache | `pub-${{ hashFiles('**/pubspec.lock') }}` |
| Gradle | `gradle-${{ hashFiles('**/*.gradle*') }}` |
| CocoaPods | `pods-${{ hashFiles('**/Podfile.lock') }}` |

---

## 5. Concurrency

Cancel in-progress runs when new commits push:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

---

## 6. Permissions

Restrict permissions for security:

```yaml
permissions:
  contents: read           # Read repo
  contents: write          # Push tags (release workflow)
```

---

## 7. Job Dependencies

```yaml
jobs:
  analyze:
    runs-on: ubuntu-latest
    # ...

  test:
    needs: analyze         # Only run if analyze passes
    # ...

  build:
    needs: test
    if: github.ref == 'refs/heads/main'  # Only on main
```

---

## 8. Secrets

Configure in: **Settings → Secrets and variables → Actions**

| Secret | Purpose |
|--------|---------|
| `CODECOV_TOKEN` | Coverage upload |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase deployment |
| `MATCH_PASSWORD` | iOS signing |
| `APP_STORE_CONNECT_API_KEY` | TestFlight |
| `GOOGLE_SERVICE_ACCOUNT_KEY` | Play Store |

---

## 9. Artifacts

Upload build outputs:

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: android-apk
    path: build/app/outputs/flutter-apk/*.apk
    retention-days: 14
```

---

## 10. Matrix Builds

Test multiple Flutter versions:

```yaml
strategy:
  matrix:
    flutter-version: ['3.32.0', '3.29.0']
```

---

## 11. Environment Variables

Pass secrets and config to Flutter builds:

```yaml
- name: Build with env
  env:
    API_URL: ${{ secrets.API_URL }}
  run: |
    echo "API_URL=$API_URL" > .env
    flutter build apk --release
```

Or use `--dart-define`:

```yaml
- run: flutter build apk --dart-define=API_URL=${{ secrets.API_URL }}
```

---

## 12. Build Numbers

Use `github.run_number` for auto-incrementing build numbers:

```yaml
- run: flutter build apk --build-number=${{ github.run_number }}
```

Or timestamp-based:

```yaml
- run: |
    BUILD_NUM=$(date +%Y%m%d%H%M)
    flutter build apk --build-number=$BUILD_NUM
```

---

## 13. Status Badges

Add to README.md:

```markdown
![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)
```

---

## 14. Path Filters

Only run on relevant changes:

```yaml
on:
  push:
    paths:
      - 'lib/**'
      - 'test/**'
      - 'pubspec.yaml'
    paths-ignore:
      - '**.md'
      - 'docs/**'
```

---

## Summary

1. Run `setup.dart` to generate workflow files
2. Add required secrets to GitHub
3. Push to trigger CI
4. Create tags to trigger deployments

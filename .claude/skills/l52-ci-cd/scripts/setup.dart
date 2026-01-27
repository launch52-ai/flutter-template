#!/usr/bin/env dart
// CI/CD Setup Script
//
// Usage:
//   dart run .claude/skills/ci-cd/scripts/setup.dart
//
// This script:
// 1. Creates a ci-cd-config.yaml if it doesn't exist
// 2. Opens it for you to fill in
// 3. Run again to generate all CI/CD files from your config

import 'dart:io';

const String configFileName = 'ci-cd-config.yaml';
const String skillPath = '.claude/skills/ci-cd';

void main(List<String> args) async {
  print('');
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║              CI/CD Setup for Flutter                         ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');

  final configFile = File(configFileName);

  if (!configFile.existsSync()) {
    // Step 1: Create config file
    _createConfigFile(configFile);
    print('Created: $configFileName');
    print('');
    print('Next steps:');
    print('  1. Open $configFileName and fill in your values');
    print('  2. Run this script again to generate CI/CD files');
    print('');
    print('Opening config file...');

    // Try to open in default editor
    await _openInEditor(configFileName);
    return;
  }

  // Step 2: Read config and generate files
  print('Found: $configFileName');
  print('');

  final config = _parseConfig(configFile.readAsStringSync());

  if (!_validateConfig(config)) {
    print('');
    print('Please fill in all required fields and run again.');
    return;
  }

  print('Generating CI/CD files...');
  print('');

  _generateFiles(config);

  print('');
  print('✓ CI/CD setup complete!');
  print('');
  print('Next steps:');
  print('  1. Review generated files in .github/workflows/');
  print('  2. Add secrets to GitHub repository settings');
  print('  3. Push to trigger CI workflow');
  print('');
  _printSecretsReminder(config);
}

// ============================================================================
// Config File Creation
// ============================================================================

void _createConfigFile(File file) {
  file.writeAsStringSync('''
# CI/CD Configuration
# Fill in the values below, then run the setup script again.
#
# Usage:
#   dart run .claude/skills/ci-cd/scripts/setup.dart
#
# Tips:
#   - Required fields are marked with (required)
#   - Set enabled: false to skip a section
#   - Values with CHANGE_THIS need your input

# ============================================================================
# Project Information (required)
# ============================================================================

project:
  # Display name of your app
  name: "My App"  # CHANGE_THIS

  # Package/Bundle ID (e.g., com.company.myapp)
  bundle_id: "com.example.myapp"  # CHANGE_THIS

  # Flutter version to use in CI
  flutter_version: "3.38.0"

# ============================================================================
# GitHub Actions - Basic CI (required)
# ============================================================================

ci:
  enabled: true

  # Branches to run CI on
  branches:
    - main
    - develop

  # Run these checks
  checks:
    format: true
    analyze: true
    test: true
    coverage: true

  # Codecov token (optional - leave empty to skip coverage upload)
  # Get from: https://codecov.io
  codecov_token_secret_name: "CODECOV_TOKEN"

# ============================================================================
# Firebase App Distribution (optional)
# ============================================================================

firebase:
  enabled: false  # Set to true to enable

  # Firebase App IDs (from Firebase Console → Project Settings)
  android_app_id: "1:123456789:android:abc123"  # CHANGE_THIS
  ios_app_id: "1:123456789:ios:abc123"  # CHANGE_THIS

  # Tester group name in Firebase
  tester_group: "testers"

  # Secret names (these will be the GitHub secret names)
  service_account_secret_name: "FIREBASE_SERVICE_ACCOUNT"

# ============================================================================
# iOS Deployment - TestFlight (optional)
# ============================================================================

ios:
  enabled: false  # Set to true to enable

  # Apple Developer Account
  apple_id: "developer@example.com"  # CHANGE_THIS
  team_id: "XXXXXXXXXX"  # Developer Portal Team ID - CHANGE_THIS
  itc_team_id: "123456789"  # App Store Connect Team ID - CHANGE_THIS

  # Fastlane Match - Certificate Repository
  # Create a private repo for certificates (e.g., github.com/yourorg/certificates)
  match_repo: "git@github.com:yourorg/certificates.git"  # CHANGE_THIS

  # Secret names
  match_password_secret_name: "MATCH_PASSWORD"
  match_git_auth_secret_name: "MATCH_GIT_BASIC_AUTHORIZATION"
  app_store_api_key_secret_name: "APP_STORE_CONNECT_API_KEY"
  app_store_issuer_id_secret_name: "APP_STORE_CONNECT_ISSUER_ID"
  app_store_key_id_secret_name: "APP_STORE_CONNECT_KEY_ID"

# ============================================================================
# Android Deployment - Play Store (optional)
# ============================================================================

android:
  enabled: false  # Set to true to enable

  # Default track for deployment
  default_track: "internal"  # internal, alpha, beta, production

  # Secret names
  service_account_secret_name: "GOOGLE_SERVICE_ACCOUNT_KEY"
  keystore_secret_name: "KEYSTORE_BASE64"
  keystore_password_secret_name: "KEYSTORE_PASSWORD"
  key_alias_secret_name: "KEY_ALIAS"
  key_password_secret_name: "KEY_PASSWORD"

# ============================================================================
# Version Management (optional but recommended)
# ============================================================================

versioning:
  enabled: true

  # Create bump script
  create_bump_script: true

  # Preferred script type
  script_type: "dart"  # "bash" or "dart"

  # Create automated release workflow
  create_release_workflow: true
''');
}

// ============================================================================
// Config Parsing
// ============================================================================

Map<String, dynamic> _parseConfig(String content) {
  final config = <String, dynamic>{};

  String? currentSection;
  String? currentSubsection;

  for (final line in content.split('\n')) {
    final trimmed = line.trim();

    // Skip comments and empty lines
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

    // Check for section (no indentation)
    if (!line.startsWith(' ') && !line.startsWith('\t') && trimmed.endsWith(':')) {
      currentSection = trimmed.substring(0, trimmed.length - 1);
      currentSubsection = null;
      config[currentSection] = <String, dynamic>{};
      continue;
    }

    // Check for subsection or value
    if (currentSection != null && trimmed.contains(':')) {
      final colonIndex = trimmed.indexOf(':');
      final key = trimmed.substring(0, colonIndex).trim();
      var value = trimmed.substring(colonIndex + 1).trim();

      // Handle different value types
      if (value.isEmpty) {
        // Start of a subsection or list
        currentSubsection = key;
        (config[currentSection] as Map)[key] = <String, dynamic>{};
      } else {
        // Remove quotes
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1);
        }

        // Parse booleans
        dynamic parsedValue = value;
        if (value == 'true') parsedValue = true;
        if (value == 'false') parsedValue = false;

        // Handle list items
        if (value.startsWith('-')) {
          // This is a list continuation - skip for simplicity
          continue;
        }

        if (currentSubsection != null &&
            config[currentSection] is Map &&
            (config[currentSection] as Map)[currentSubsection] is Map) {
          ((config[currentSection] as Map)[currentSubsection] as Map)[key] = parsedValue;
        } else {
          (config[currentSection] as Map)[key] = parsedValue;
        }
      }
    }

    // Handle list items
    if (trimmed.startsWith('- ') && currentSection != null) {
      final value = trimmed.substring(2).trim();
      final section = config[currentSection] as Map;

      // Find which key this belongs to (last key that's a list)
      if (currentSubsection != null) {
        if (section[currentSubsection] is! List) {
          section[currentSubsection] = <String>[];
        }
        (section[currentSubsection] as List).add(value);
      } else if (section['branches'] == null) {
        section['branches'] = <String>[value];
      } else if (section['branches'] is List) {
        (section['branches'] as List).add(value);
      }
    }
  }

  return config;
}

// ============================================================================
// Validation
// ============================================================================

bool _validateConfig(Map<String, dynamic> config) {
  var valid = true;

  // Check project section
  final project = config['project'] as Map<String, dynamic>?;
  if (project == null) {
    print('✗ Missing project section');
    valid = false;
  } else {
    if (_isPlaceholder(project['bundle_id'])) {
      print('✗ project.bundle_id: Please set your bundle ID');
      valid = false;
    }
  }

  // Check iOS if enabled
  final ios = config['ios'] as Map<String, dynamic>?;
  if (ios != null && ios['enabled'] == true) {
    if (_isPlaceholder(ios['apple_id'])) {
      print('✗ ios.apple_id: Please set your Apple ID');
      valid = false;
    }
    if (_isPlaceholder(ios['team_id'])) {
      print('✗ ios.team_id: Please set your Team ID');
      valid = false;
    }
    if (_isPlaceholder(ios['match_repo'])) {
      print('✗ ios.match_repo: Please set your match repository URL');
      valid = false;
    }
  }

  // Check Firebase if enabled
  final firebase = config['firebase'] as Map<String, dynamic>?;
  if (firebase != null && firebase['enabled'] == true) {
    if (_isPlaceholder(firebase['android_app_id'])) {
      print('✗ firebase.android_app_id: Please set your Firebase App ID');
      valid = false;
    }
  }

  if (valid) {
    print('✓ Configuration validated');
  }

  return valid;
}

bool _isPlaceholder(dynamic value) {
  if (value == null) return true;
  final str = value.toString();
  return str.contains('CHANGE_THIS') ||
         str.contains('example.com') ||
         str.contains('XXXXXXXXXX') ||
         str.contains('yourorg');
}

// ============================================================================
// File Generation
// ============================================================================

void _generateFiles(Map<String, dynamic> config) {
  final project = config['project'] as Map<String, dynamic>;
  final ci = config['ci'] as Map<String, dynamic>?;
  final firebase = config['firebase'] as Map<String, dynamic>?;
  final ios = config['ios'] as Map<String, dynamic>?;
  final android = config['android'] as Map<String, dynamic>?;
  final versioning = config['versioning'] as Map<String, dynamic>?;

  final bundleId = project['bundle_id'] as String;
  final flutterVersion = project['flutter_version'] as String? ?? '3.38.0';

  // Create directories
  Directory('.github/workflows').createSync(recursive: true);

  // 1. CI Workflow (always created)
  if (ci == null || ci['enabled'] != false) {
    _generateCIWorkflow(flutterVersion, ci);
    print('  ✓ .github/workflows/ci.yml');
  }

  // 2. Firebase workflows
  if (firebase != null && firebase['enabled'] == true) {
    _generateFirebaseAndroidWorkflow(flutterVersion, firebase);
    print('  ✓ .github/workflows/deploy-firebase-android.yml');

    // iOS Firebase requires iOS to be enabled (needs match for signing)
    if (ios != null && ios['enabled'] == true) {
      _generateFirebaseIOSWorkflow(flutterVersion, firebase, ios);
      print('  ✓ .github/workflows/deploy-firebase-ios.yml');
    }
  }

  // 3. iOS workflows and Fastlane
  if (ios != null && ios['enabled'] == true) {
    _generateTestFlightWorkflow(flutterVersion, ios);
    print('  ✓ .github/workflows/deploy-testflight.yml');

    _generateIOSFastlane(bundleId, ios);
    print('  ✓ ios/fastlane/Fastfile');
    print('  ✓ ios/fastlane/Appfile');
    print('  ✓ ios/fastlane/Matchfile');
    print('  ✓ ios/Gemfile');
  }

  // 4. Android workflows and Fastlane
  if (android != null && android['enabled'] == true) {
    _generatePlayStoreWorkflow(flutterVersion, android);
    print('  ✓ .github/workflows/deploy-playstore.yml');

    _generateAndroidFastlane(bundleId, android);
    print('  ✓ android/fastlane/Fastfile');
    print('  ✓ android/fastlane/Appfile');
    print('  ✓ android/Gemfile');
  }

  // 5. Version bump script
  if (versioning != null && versioning['enabled'] == true) {
    if (versioning['create_bump_script'] == true) {
      Directory('scripts').createSync(recursive: true);
      final scriptType = versioning['script_type'] as String? ?? 'dart';

      if (scriptType == 'bash') {
        _copyTemplate('bump_version.sh', 'scripts/bump_version.sh');
        Process.runSync('chmod', ['+x', 'scripts/bump_version.sh']);
        print('  ✓ scripts/bump_version.sh');
      } else {
        _copyTemplate('bump_version.dart', 'scripts/bump_version.dart');
        print('  ✓ scripts/bump_version.dart');
      }
    }

    if (versioning['create_release_workflow'] == true) {
      _generateReleaseWorkflow(flutterVersion);
      print('  ✓ .github/workflows/release.yml');
    }
  }
}

void _generateCIWorkflow(String flutterVersion, Map<String, dynamic>? ci) {
  final codecovSecret = ci?['codecov_token_secret_name'] ?? 'CODECOV_TOKEN';
  final branches = (ci?['branches'] as List?)?.cast<String>() ?? ['main'];

  final content = '''
name: CI

on:
  push:
    branches: [${branches.join(', ')}]
  pull_request:
    branches: [${branches.join(', ')}]

concurrency:
  group: \${{ github.workflow }}-\${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '$flutterVersion'
          cache: true

      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze --fatal-infos

  test:
    name: Test
    runs-on: ubuntu-latest
    timeout-minutes: 15
    needs: analyze

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '$flutterVersion'
          cache: true

      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter test --coverage

      - uses: codecov/codecov-action@v4
        with:
          files: coverage/lcov.info
          fail_ci_if_error: false
        env:
          CODECOV_TOKEN: \${{ secrets.$codecovSecret }}
''';

  File('.github/workflows/ci.yml').writeAsStringSync(content);
}

void _generateFirebaseAndroidWorkflow(String flutterVersion, Map<String, dynamic> firebase) {
  final appIdSecret = 'FIREBASE_APP_ID_ANDROID';
  final serviceAccountSecret = firebase['service_account_secret_name'] ?? 'FIREBASE_SERVICE_ACCOUNT';
  final testerGroup = firebase['tester_group'] ?? 'testers';

  final content = '''
name: Deploy Android to Firebase

on:
  push:
    tags:
      - 'v*-beta*'
      - 'v*-alpha*'
  workflow_dispatch:
    inputs:
      release_notes:
        description: 'Release notes'
        required: false
        default: 'New build available'

jobs:
  deploy:
    name: Deploy to Firebase
    runs-on: ubuntu-latest
    timeout-minutes: 25

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
          cache: 'gradle'

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '$flutterVersion'
          cache: true

      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter build apk --release

      - uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: \${{ secrets.$appIdSecret }}
          serviceCredentialsFileContent: \${{ secrets.$serviceAccountSecret }}
          groups: $testerGroup
          file: build/app/outputs/flutter-apk/app-release.apk
          releaseNotes: \${{ github.event.inputs.release_notes || 'Automated build' }}
''';

  File('.github/workflows/deploy-firebase-android.yml').writeAsStringSync(content);
}

void _generateFirebaseIOSWorkflow(String flutterVersion, Map<String, dynamic> firebase, Map<String, dynamic> ios) {
  final appIdSecret = 'FIREBASE_APP_ID_IOS';
  final serviceAccountSecret = firebase['service_account_secret_name'] ?? 'FIREBASE_SERVICE_ACCOUNT';
  final matchPasswordSecret = ios['match_password_secret_name'] ?? 'MATCH_PASSWORD';
  final matchGitAuthSecret = ios['match_git_auth_secret_name'] ?? 'MATCH_GIT_BASIC_AUTHORIZATION';
  final testerGroup = firebase['tester_group'] ?? 'testers';

  final content = '''
name: Deploy iOS to Firebase

on:
  push:
    tags:
      - 'v*-beta*'
      - 'v*-alpha*'
  workflow_dispatch:
    inputs:
      release_notes:
        description: 'Release notes'
        required: false
        default: 'New build available'

concurrency:
  group: \${{ github.workflow }}-\${{ github.ref }}
  cancel-in-progress: false

permissions:
  contents: read

jobs:
  deploy:
    name: Deploy iOS to Firebase
    runs-on: macos-latest
    timeout-minutes: 60

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '$flutterVersion'
          cache: true

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
          working-directory: ios

      - uses: actions/cache@v4
        with:
          path: ios/Pods
          key: pods-\${{ hashFiles('**/Podfile.lock') }}

      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: cd ios && pod install

      - name: Build ad-hoc IPA
        env:
          MATCH_PASSWORD: \${{ secrets.$matchPasswordSecret }}
          MATCH_GIT_BASIC_AUTHORIZATION: \${{ secrets.$matchGitAuthSecret }}
        run: cd ios && bundle exec fastlane build_adhoc

      - uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: \${{ secrets.$appIdSecret }}
          serviceCredentialsFileContent: \${{ secrets.$serviceAccountSecret }}
          groups: $testerGroup
          file: ios/Runner.ipa
          releaseNotes: \${{ github.event.inputs.release_notes || 'Automated build' }}
''';

  File('.github/workflows/deploy-firebase-ios.yml').writeAsStringSync(content);
}

void _generateTestFlightWorkflow(String flutterVersion, Map<String, dynamic> ios) {
  final matchPasswordSecret = ios['match_password_secret_name'] ?? 'MATCH_PASSWORD';
  final matchGitAuthSecret = ios['match_git_auth_secret_name'] ?? 'MATCH_GIT_BASIC_AUTHORIZATION';
  final apiKeySecret = ios['app_store_api_key_secret_name'] ?? 'APP_STORE_CONNECT_API_KEY';
  final issuerIdSecret = ios['app_store_issuer_id_secret_name'] ?? 'APP_STORE_CONNECT_ISSUER_ID';
  final keyIdSecret = ios['app_store_key_id_secret_name'] ?? 'APP_STORE_CONNECT_KEY_ID';

  final content = '''
name: Deploy to TestFlight

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
      - 'v[0-9]+.[0-9]+.[0-9]+-rc*'
  workflow_dispatch:

jobs:
  deploy:
    name: Deploy to TestFlight
    runs-on: macos-latest
    timeout-minutes: 60

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '$flutterVersion'
          cache: true

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
          working-directory: ios

      - uses: actions/cache@v4
        with:
          path: ios/Pods
          key: pods-\${{ hashFiles('**/Podfile.lock') }}

      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: cd ios && pod install

      - name: Deploy to TestFlight
        env:
          MATCH_PASSWORD: \${{ secrets.$matchPasswordSecret }}
          MATCH_GIT_BASIC_AUTHORIZATION: \${{ secrets.$matchGitAuthSecret }}
          APP_STORE_CONNECT_API_KEY: \${{ secrets.$apiKeySecret }}
          APP_STORE_CONNECT_ISSUER_ID: \${{ secrets.$issuerIdSecret }}
          APP_STORE_CONNECT_KEY_ID: \${{ secrets.$keyIdSecret }}
        run: cd ios && bundle exec fastlane beta
''';

  File('.github/workflows/deploy-testflight.yml').writeAsStringSync(content);
}

void _generatePlayStoreWorkflow(String flutterVersion, Map<String, dynamic> android) {
  final serviceAccountSecret = android['service_account_secret_name'] ?? 'GOOGLE_SERVICE_ACCOUNT_KEY';
  final keystoreSecret = android['keystore_secret_name'] ?? 'KEYSTORE_BASE64';
  final keystorePasswordSecret = android['keystore_password_secret_name'] ?? 'KEYSTORE_PASSWORD';
  final keyAliasSecret = android['key_alias_secret_name'] ?? 'KEY_ALIAS';
  final keyPasswordSecret = android['key_password_secret_name'] ?? 'KEY_PASSWORD';
  final defaultTrack = android['default_track'] ?? 'internal';

  final content = '''
name: Deploy to Play Store

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
  workflow_dispatch:
    inputs:
      track:
        description: 'Play Store track'
        required: true
        default: '$defaultTrack'
        type: choice
        options:
          - internal
          - alpha
          - beta
          - production

jobs:
  deploy:
    name: Deploy to Play Store
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
          cache: 'gradle'

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '$flutterVersion'
          cache: true

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
          working-directory: android

      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs

      - name: Decode keystore
        run: echo "\${{ secrets.$keystoreSecret }}" | base64 --decode > android/app/keystore.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=\${{ secrets.$keystorePasswordSecret }}
          keyPassword=\${{ secrets.$keyPasswordSecret }}
          keyAlias=\${{ secrets.$keyAliasSecret }}
          storeFile=keystore.jks
          EOF

      - run: flutter build appbundle --release

      - name: Deploy to Play Store
        env:
          GOOGLE_SERVICE_ACCOUNT_KEY: \${{ secrets.$serviceAccountSecret }}
        run: |
          cd android
          echo "\$GOOGLE_SERVICE_ACCOUNT_KEY" > service-account.json
          bundle exec fastlane deploy track:\${{ github.event.inputs.track || '$defaultTrack' }}
          rm service-account.json
''';

  File('.github/workflows/deploy-playstore.yml').writeAsStringSync(content);
}

void _generateReleaseWorkflow(String flutterVersion) {
  final content = '''
name: Create Release

on:
  workflow_dispatch:
    inputs:
      bump_type:
        description: 'Version bump type'
        required: true
        type: choice
        options:
          - patch
          - minor
          - major
      release_notes:
        description: 'Release notes'
        required: true
        type: string

permissions:
  contents: write

jobs:
  release:
    name: Create Release
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Configure Git
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

      - name: Bump version
        id: bump
        run: |
          CURRENT=\$(grep '^version:' pubspec.yaml | sed 's/version: //')
          VERSION=\$(echo \$CURRENT | cut -d'+' -f1)
          BUILD=\$(echo \$CURRENT | cut -d'+' -f2)

          MAJOR=\$(echo \$VERSION | cut -d'.' -f1)
          MINOR=\$(echo \$VERSION | cut -d'.' -f2)
          PATCH=\$(echo \$VERSION | cut -d'.' -f3)

          case "\${{ inputs.bump_type }}" in
            major) MAJOR=\$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
            minor) MINOR=\$((MINOR + 1)); PATCH=0 ;;
            patch) PATCH=\$((PATCH + 1)) ;;
          esac

          NEW_BUILD=\$((BUILD + 1))
          echo "version=\$MAJOR.\$MINOR.\$PATCH" >> \$GITHUB_OUTPUT
          echo "tag=v\$MAJOR.\$MINOR.\$PATCH" >> \$GITHUB_OUTPUT

          sed -i "s/^version: .*/version: \$MAJOR.\$MINOR.\$PATCH+\$NEW_BUILD/" pubspec.yaml

      - name: Commit and tag
        run: |
          git add pubspec.yaml
          git commit -m "Release \${{ steps.bump.outputs.tag }}"
          git tag -a "\${{ steps.bump.outputs.tag }}" -m "Release \${{ steps.bump.outputs.version }}"
          git push origin main --tags

      - uses: softprops/action-gh-release@v2
        with:
          tag_name: \${{ steps.bump.outputs.tag }}
          name: \${{ steps.bump.outputs.tag }}
          body: \${{ inputs.release_notes }}
''';

  File('.github/workflows/release.yml').writeAsStringSync(content);
}

void _generateIOSFastlane(String bundleId, Map<String, dynamic> ios) {
  Directory('ios/fastlane').createSync(recursive: true);

  final appleId = ios['apple_id'];
  final teamId = ios['team_id'];
  final itcTeamId = ios['itc_team_id'];
  final matchRepo = ios['match_repo'];

  // Fastfile
  File('ios/fastlane/Fastfile').writeAsStringSync('''
default_platform(:ios)

platform :ios do
  desc "Sync certificates (app-store)"
  lane :sync_appstore do
    match(type: "appstore", readonly: is_ci)
  end

  desc "Sync certificates (ad-hoc for Firebase)"
  lane :sync_adhoc do
    match(type: "adhoc", readonly: is_ci)
  end

  desc "Build release IPA (App Store)"
  lane :build_release do
    sync_appstore

    Dir.chdir("..") do
      sh("flutter build ios --release --no-codesign")
    end

    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
  end

  desc "Build ad-hoc IPA (Firebase distribution)"
  lane :build_adhoc do
    setup_ci if is_ci
    sync_adhoc

    Dir.chdir("..") do
      sh("flutter build ios --release --no-codesign")
    end

    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "ad-hoc",
      output_name: "Runner.ipa"
    )
  end

  desc "Deploy to TestFlight"
  lane :beta do
    setup_ci if is_ci

    if is_ci
      app_store_connect_api_key(
        key_id: ENV["APP_STORE_CONNECT_KEY_ID"],
        issuer_id: ENV["APP_STORE_CONNECT_ISSUER_ID"],
        key_content: ENV["APP_STORE_CONNECT_API_KEY"],
        is_key_content_base64: true
      )
    end

    build_release

    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end
end
''');

  // Appfile
  File('ios/fastlane/Appfile').writeAsStringSync('''
app_identifier("$bundleId")
apple_id("$appleId")
itc_team_id("$itcTeamId")
team_id("$teamId")
''');

  // Matchfile
  File('ios/fastlane/Matchfile').writeAsStringSync('''
git_url("$matchRepo")
storage_mode("git")
app_identifier(["$bundleId"])
type("appstore")
''');

  // Gemfile
  File('ios/Gemfile').writeAsStringSync('''
source "https://rubygems.org"
gem "fastlane", "~> 2.225"
''');
}

void _generateAndroidFastlane(String bundleId, Map<String, dynamic> android) {
  Directory('android/fastlane').createSync(recursive: true);

  // Fastfile
  File('android/fastlane/Fastfile').writeAsStringSync('''
default_platform(:android)

platform :android do
  desc "Build release AAB"
  lane :build_release do
    Dir.chdir("..") do
      sh("flutter build appbundle --release")
    end
  end

  desc "Deploy to Play Store"
  lane :deploy do |options|
    track = options[:track] || "internal"

    upload_to_play_store(
      track: track,
      aab: "../build/app/outputs/bundle/release/app-release.aab",
      json_key: "service-account.json",
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
end
''');

  // Appfile
  File('android/fastlane/Appfile').writeAsStringSync('''
json_key_file("service-account.json")
package_name("$bundleId")
''');

  // Gemfile
  File('android/Gemfile').writeAsStringSync('''
source "https://rubygems.org"
gem "fastlane", "~> 2.225"
''');
}

void _copyTemplate(String templateName, String destination) {
  final templatePath = '$skillPath/templates/$templateName';
  final templateFile = File(templatePath);

  if (templateFile.existsSync()) {
    templateFile.copySync(destination);
  } else {
    print('  ⚠ Template not found: $templatePath');
  }
}

// ============================================================================
// Secrets Reminder
// ============================================================================

void _printSecretsReminder(Map<String, dynamic> config) {
  final secrets = <String, String>{};

  final ci = config['ci'] as Map<String, dynamic>?;
  if (ci != null) {
    secrets['CODECOV_TOKEN'] = 'Codecov upload token (optional)';
  }

  final firebase = config['firebase'] as Map<String, dynamic>?;
  if (firebase != null && firebase['enabled'] == true) {
    secrets['FIREBASE_APP_ID_ANDROID'] = 'Firebase Android App ID';
    secrets['FIREBASE_APP_ID_IOS'] = 'Firebase iOS App ID';
    secrets['FIREBASE_SERVICE_ACCOUNT'] = 'Firebase service account JSON';
  }

  final ios = config['ios'] as Map<String, dynamic>?;
  if (ios != null && ios['enabled'] == true) {
    secrets[ios['match_password_secret_name'] ?? 'MATCH_PASSWORD'] = 'Fastlane match encryption password';
    secrets[ios['match_git_auth_secret_name'] ?? 'MATCH_GIT_BASIC_AUTHORIZATION'] = 'Base64: echo -n "user:token" | base64';
    secrets[ios['app_store_api_key_secret_name'] ?? 'APP_STORE_CONNECT_API_KEY'] = 'App Store Connect API key (base64)';
    secrets[ios['app_store_issuer_id_secret_name'] ?? 'APP_STORE_CONNECT_ISSUER_ID'] = 'API key issuer ID';
    secrets[ios['app_store_key_id_secret_name'] ?? 'APP_STORE_CONNECT_KEY_ID'] = 'API key ID';
  }

  final android = config['android'] as Map<String, dynamic>?;
  if (android != null && android['enabled'] == true) {
    secrets[android['service_account_secret_name'] ?? 'GOOGLE_SERVICE_ACCOUNT_KEY'] = 'Play Store service account JSON';
    secrets[android['keystore_secret_name'] ?? 'KEYSTORE_BASE64'] = 'Base64 encoded keystore: base64 -i keystore.jks';
    secrets[android['keystore_password_secret_name'] ?? 'KEYSTORE_PASSWORD'] = 'Keystore password';
    secrets[android['key_alias_secret_name'] ?? 'KEY_ALIAS'] = 'Key alias';
    secrets[android['key_password_secret_name'] ?? 'KEY_PASSWORD'] = 'Key password';
  }

  if (secrets.isNotEmpty) {
    print('GitHub Secrets to configure:');
    print('(Settings → Secrets and variables → Actions → New repository secret)');
    print('');
    for (final entry in secrets.entries) {
      print('  ${entry.key}');
      print('    └─ ${entry.value}');
    }
    print('');
  }
}

// ============================================================================
// Utilities
// ============================================================================

Future<void> _openInEditor(String filePath) async {
  try {
    if (Platform.isMacOS) {
      await Process.run('open', [filePath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [filePath]);
    } else if (Platform.isWindows) {
      await Process.run('start', [filePath], runInShell: true);
    }
  } catch (e) {
    // Ignore errors - user can open manually
  }
}

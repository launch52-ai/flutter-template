#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// Release readiness audit script for Flutter projects.
///
/// Checks for common release preparation issues:
/// - Android signing configuration
/// - iOS configuration
/// - Security (sensitive files in git)
/// - App assets (icons, splash)
/// - Build configuration
///
/// Usage:
///   dart run .claude/skills/release/scripts/check.dart
///   dart run .claude/skills/release/scripts/check.dart --platform android
///   dart run .claude/skills/release/scripts/check.dart --platform ios
///   dart run .claude/skills/release/scripts/check.dart --checklist
///   dart run .claude/skills/release/scripts/check.dart --keytool-command
///   dart run .claude/skills/release/scripts/check.dart --capabilities
///   dart run .claude/skills/release/scripts/check.dart --json
///   dart run .claude/skills/release/scripts/check.dart --fix
///   dart run .claude/skills/release/scripts/check.dart --help
void main(List<String> args) async {
  final help = args.contains('--help') || args.contains('-h');
  final checklist = args.contains('--checklist');
  final keytoolCommand = args.contains('--keytool-command');
  final capabilities = args.contains('--capabilities');
  final jsonOutput = args.contains('--json');
  final fix = args.contains('--fix');
  final platform = _getArgValue(args, '--platform');

  if (help) {
    _printHelp();
    return;
  }

  if (keytoolCommand) {
    _printKeytoolCommand();
    return;
  }

  if (capabilities) {
    _printDetectedCapabilities();
    return;
  }

  if (checklist) {
    _printChecklist();
    return;
  }

  if (!jsonOutput) {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('  Release Readiness Audit');
    print('═══════════════════════════════════════════════════════');
    print('');
  }

  final issues = <ReleaseIssue>[];
  final warnings = <ReleaseIssue>[];
  final passed = <String>[];

  // Run checks based on platform filter
  if (platform == null || platform == 'android') {
    _checkAndroid(issues, warnings, passed, verbose: !jsonOutput);
  }

  if (platform == null || platform == 'ios') {
    _checkIOS(issues, warnings, passed, verbose: !jsonOutput);
  }

  if (platform == null) {
    _checkSecurity(issues, warnings, passed, verbose: !jsonOutput);
    _checkAssets(issues, warnings, passed, verbose: !jsonOutput);
    _checkPubspec(issues, warnings, passed, verbose: !jsonOutput);
    _checkFirebase(issues, warnings, passed, verbose: !jsonOutput);
    _checkLegal(issues, warnings, passed, verbose: !jsonOutput);
  }

  // Auto-fix issues if requested
  if (fix) {
    _autoFix(issues, warnings);
  }

  // Output results
  if (jsonOutput) {
    _printJsonResults(issues, warnings, passed);
  } else {
    _printResults(issues, warnings, passed);
  }
}

// ============================================================
// ANDROID CHECKS
// ============================================================

void _checkAndroid(
  List<ReleaseIssue> issues,
  List<ReleaseIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) {
  if (verbose) print('📱 Checking Android configuration...\n');

  // Check for android directory
  if (!_directoryExists('android')) {
    warnings.add(ReleaseIssue(
      category: 'Android',
      message: 'No android/ directory found',
      fix: 'Run: flutter create . --platforms=android',
    ));
    return;
  }

  // Check key.properties
  if (_fileExists('android/key.properties')) {
    passed.add('Android: key.properties exists');

    // Verify key.properties content
    final content = _readFile('android/key.properties');
    if (!content.contains('storeFile')) {
      issues.add(ReleaseIssue(
        category: 'Android',
        message: 'key.properties missing storeFile',
        fix: 'Add storeFile=/path/to/your.jks to key.properties',
      ));
    }
    if (!content.contains('keyAlias')) {
      issues.add(ReleaseIssue(
        category: 'Android',
        message: 'key.properties missing keyAlias',
        fix: 'Add keyAlias=your_alias to key.properties',
      ));
    }
  } else {
    issues.add(ReleaseIssue(
      category: 'Android',
      message: 'key.properties not found',
      fix: 'Create android/key.properties with keystore details',
    ));
  }

  // Check build.gradle.kts
  final buildGradle = _findFile([
    'android/app/build.gradle.kts',
    'android/app/build.gradle',
  ]);

  if (buildGradle != null) {
    final content = _readFile(buildGradle);

    // Check for signing config
    if (content.contains('signingConfigs')) {
      passed.add('Android: Signing config present in build.gradle');
    } else {
      issues.add(ReleaseIssue(
        category: 'Android',
        message: 'No signingConfigs in build.gradle',
        fix: 'Add signingConfigs block. See android-guide.md',
      ));
    }

    // Check for release signing config usage
    if (content.contains('signingConfig') &&
        content.contains('release')) {
      passed.add('Android: Release uses signing config');
    } else {
      warnings.add(ReleaseIssue(
        category: 'Android',
        message: 'Release build type may not use signing config',
        fix: 'Add signingConfig to release buildType',
      ));
    }

    // Check for minifyEnabled
    if (content.contains('isMinifyEnabled = true') ||
        content.contains('minifyEnabled true')) {
      passed.add('Android: Code minification enabled');
    } else {
      warnings.add(ReleaseIssue(
        category: 'Android',
        message: 'Code minification not enabled for release',
        fix: 'Add isMinifyEnabled = true to release buildType',
      ));
    }
  } else {
    issues.add(ReleaseIssue(
      category: 'Android',
      message: 'build.gradle(.kts) not found',
      fix: 'Ensure android/app/build.gradle.kts exists',
    ));
  }

  // Check proguard-rules.pro
  if (_fileExists('android/app/proguard-rules.pro')) {
    passed.add('Android: proguard-rules.pro exists');
  } else {
    warnings.add(ReleaseIssue(
      category: 'Android',
      message: 'proguard-rules.pro not found',
      fix: 'Create android/app/proguard-rules.pro for R8 rules',
    ));
  }

  // Check for keystore in repo (security issue)
  if (_hasFilesMatching('android', '.jks') ||
      _hasFilesMatching('android', '.keystore')) {
    issues.add(ReleaseIssue(
      category: 'Security',
      message: 'Keystore file found in android/ directory',
      fix: 'Move keystore outside repo and update key.properties path',
    ));
  } else {
    passed.add('Android: No keystore files in repo');
  }

  // Check AndroidManifest for internet permission
  final manifestPath = 'android/app/src/main/AndroidManifest.xml';
  if (_fileExists(manifestPath)) {
    final manifest = _readFile(manifestPath);
    if (manifest.contains('android.permission.INTERNET')) {
      passed.add('Android: Internet permission declared');
    } else {
      issues.add(ReleaseIssue(
        category: 'Android',
        message: 'Internet permission not found in AndroidManifest.xml',
        fix: 'Add <uses-permission android:name="android.permission.INTERNET"/> to manifest',
      ));
    }
  }

  if (verbose) print('');
}

// ============================================================
// iOS CHECKS
// ============================================================

void _checkIOS(
  List<ReleaseIssue> issues,
  List<ReleaseIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) {
  if (verbose) print('🍎 Checking iOS configuration...\n');

  // Check for ios directory
  if (!_directoryExists('ios')) {
    warnings.add(ReleaseIssue(
      category: 'iOS',
      message: 'No ios/ directory found',
      fix: 'Run: flutter create . --platforms=ios',
    ));
    return;
  }

  // Check for xcworkspace
  if (_directoryExists('ios/Runner.xcworkspace')) {
    passed.add('iOS: Runner.xcworkspace exists');
  } else {
    issues.add(ReleaseIssue(
      category: 'iOS',
      message: 'Runner.xcworkspace not found',
      fix: 'Run: cd ios && pod install',
    ));
  }

  // Check Info.plist
  if (_fileExists('ios/Runner/Info.plist')) {
    passed.add('iOS: Info.plist exists');

    final content = _readFile('ios/Runner/Info.plist');

    // Check for common permission descriptions
    final permissions = [
      ('NSCameraUsageDescription', 'Camera'),
      ('NSPhotoLibraryUsageDescription', 'Photo Library'),
      ('NSLocationWhenInUseUsageDescription', 'Location'),
      ('NSMicrophoneUsageDescription', 'Microphone'),
    ];

    // Only warn if permission key exists without description value
    for (final (key, name) in permissions) {
      if (content.contains('<key>$key</key>')) {
        // Check if it has a proper string value after the key
        final keyIndex = content.indexOf('<key>$key</key>');
        final afterKey = content.substring(keyIndex);
        if (afterKey.contains('<string></string>') ||
            afterKey.contains('<string/>')) {
          warnings.add(ReleaseIssue(
            category: 'iOS',
            message: '$name permission declared but empty',
            fix: 'Add description for $key in Info.plist',
          ));
        }
      }
    }
  } else {
    issues.add(ReleaseIssue(
      category: 'iOS',
      message: 'Info.plist not found',
      fix: 'Ensure ios/Runner/Info.plist exists',
    ));
  }

  // Check for Runner.entitlements (Sign in with Apple, etc.)
  if (_fileExists('ios/Runner/Runner.entitlements')) {
    passed.add('iOS: Runner.entitlements exists (capabilities configured)');
  }

  // Check for provisioning profiles in repo (security issue)
  if (_hasFilesMatching('ios', '.mobileprovision')) {
    warnings.add(ReleaseIssue(
      category: 'Security',
      message: 'Provisioning profile found in ios/ directory',
      fix: 'Remove .mobileprovision files from repo',
    ));
  }

  // Check for Privacy Manifest (iOS 17+ requirement)
  if (_fileExists('ios/Runner/PrivacyInfo.xcprivacy')) {
    passed.add('iOS: Privacy Manifest exists (iOS 17+)');

    // Verify it has required content
    final privacyManifest = _readFile('ios/Runner/PrivacyInfo.xcprivacy');
    if (!privacyManifest.contains('NSPrivacyAccessedAPITypes')) {
      warnings.add(ReleaseIssue(
        category: 'iOS',
        message: 'Privacy Manifest missing NSPrivacyAccessedAPITypes',
        fix: 'Add API declarations to PrivacyInfo.xcprivacy',
      ));
    }
  } else {
    issues.add(ReleaseIssue(
      category: 'iOS',
      message: 'Privacy Manifest not found (required for iOS 17+)',
      fix: 'Create ios/Runner/PrivacyInfo.xcprivacy. See ios-guide.md section 8',
    ));
  }

  // Check for Export Compliance (skip encryption question on upload)
  if (_fileExists('ios/Runner/Info.plist')) {
    final infoPlist = _readFile('ios/Runner/Info.plist');
    if (infoPlist.contains('ITSAppUsesNonExemptEncryption')) {
      passed.add('iOS: Export compliance declared');
    } else {
      warnings.add(ReleaseIssue(
        category: 'iOS',
        message: 'ITSAppUsesNonExemptEncryption not set in Info.plist',
        fix: 'Add ITSAppUsesNonExemptEncryption to skip export question on upload',
      ));
    }
  }

  if (verbose) print('');
}

// ============================================================
// SECURITY CHECKS
// ============================================================

void _checkSecurity(
  List<ReleaseIssue> issues,
  List<ReleaseIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) {
  if (verbose) print('🔒 Checking security configuration...\n');

  // Check .gitignore exists
  if (!_fileExists('.gitignore')) {
    issues.add(ReleaseIssue(
      category: 'Security',
      message: '.gitignore not found',
      fix: 'Create .gitignore with sensitive file patterns',
    ));
    return;
  }

  final gitignore = _readFile('.gitignore');

  // Check for key.properties in gitignore
  if (gitignore.contains('key.properties')) {
    passed.add('Security: key.properties in .gitignore');
  } else if (_fileExists('android/key.properties')) {
    issues.add(ReleaseIssue(
      category: 'Security',
      message: 'key.properties not in .gitignore',
      fix: 'Add "android/key.properties" to .gitignore',
    ));
  }

  // Check for keystore files in gitignore
  if (gitignore.contains('.jks') || gitignore.contains('.keystore')) {
    passed.add('Security: Keystore files in .gitignore');
  } else {
    warnings.add(ReleaseIssue(
      category: 'Security',
      message: 'Keystore patterns not in .gitignore',
      fix: 'Add "*.jks" and "*.keystore" to .gitignore',
    ));
  }

  // Check for .env in gitignore
  if (gitignore.contains('.env')) {
    passed.add('Security: .env files in .gitignore');
  } else if (_fileExists('.env')) {
    issues.add(ReleaseIssue(
      category: 'Security',
      message: '.env not in .gitignore',
      fix: 'Add ".env" to .gitignore',
    ));
  }

  // Check for Apple private keys
  if (gitignore.contains('.p8') || gitignore.contains('.p12')) {
    passed.add('Security: Apple key files in .gitignore');
  } else {
    warnings.add(ReleaseIssue(
      category: 'Security',
      message: 'Apple key patterns not in .gitignore',
      fix: 'Add "*.p8" and "*.p12" to .gitignore',
    ));
  }

  // Check for actual .env file
  if (_fileExists('.env')) {
    passed.add('Security: .env file exists for environment variables');
  } else if (_fileExists('.env.example')) {
    warnings.add(ReleaseIssue(
      category: 'Security',
      message: '.env file not found (only .env.example)',
      fix: 'Create .env from .env.example with actual values',
    ));
  }

  if (verbose) print('');
}

// ============================================================
// ASSET CHECKS
// ============================================================

void _checkAssets(
  List<ReleaseIssue> issues,
  List<ReleaseIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) {
  if (verbose) print('🎨 Checking app assets...\n');

  // Check for app icon source
  final iconPaths = [
    'assets/icons/app_icon.png',
    'assets/icon/app_icon.png',
    'assets/app_icon.png',
  ];

  final hasIcon = iconPaths.any(_fileExists);
  if (hasIcon) {
    passed.add('Assets: App icon source exists');
  } else {
    warnings.add(ReleaseIssue(
      category: 'Assets',
      message: 'No app icon source found in assets/',
      fix: 'Add 1024x1024 app icon to assets/icons/app_icon.png',
    ));
  }

  // Check iOS app icon
  if (_directoryExists('ios/Runner/Assets.xcassets/AppIcon.appiconset')) {
    final contents =
        _readFile('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json');
    if (contents.isNotEmpty) {
      passed.add('Assets: iOS AppIcon configured');
    }
  } else {
    warnings.add(ReleaseIssue(
      category: 'Assets',
      message: 'iOS AppIcon not configured',
      fix: 'Add app icon via Xcode Assets.xcassets',
    ));
  }

  // Check Android launcher icons
  if (_directoryExists('android/app/src/main/res/mipmap-xxxhdpi')) {
    if (_hasFilesMatching('android/app/src/main/res/mipmap-xxxhdpi', '.webp') ||
        _hasFilesMatching('android/app/src/main/res/mipmap-xxxhdpi', '.png')) {
      passed.add('Assets: Android launcher icons exist');
    }
  } else {
    warnings.add(ReleaseIssue(
      category: 'Assets',
      message: 'Android launcher icons may be default Flutter icons',
      fix: 'Generate icons via Android Studio Image Asset wizard',
    ));
  }

  // Check for splash screen configuration
  if (_fileExists('pubspec.yaml')) {
    final pubspec = _readFile('pubspec.yaml');
    if (pubspec.contains('flutter_native_splash')) {
      passed.add('Assets: Splash screen configured (flutter_native_splash)');
    } else {
      warnings.add(ReleaseIssue(
        category: 'Assets',
        message: 'No splash screen configuration found',
        fix: 'Add flutter_native_splash to pubspec.yaml',
      ));
    }
  }

  if (verbose) print('');
}

// ============================================================
// PUBSPEC CHECKS
// ============================================================

void _checkPubspec(
  List<ReleaseIssue> issues,
  List<ReleaseIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) {
  if (verbose) print('📦 Checking pubspec.yaml...\n');

  if (!_fileExists('pubspec.yaml')) {
    issues.add(ReleaseIssue(
      category: 'Build',
      message: 'pubspec.yaml not found',
      fix: 'Ensure pubspec.yaml exists in project root',
    ));
    return;
  }

  final pubspec = _readFile('pubspec.yaml');

  // Check version format
  final versionMatch = RegExp(r'version:\s*(\d+\.\d+\.\d+\+\d+)').firstMatch(pubspec);
  if (versionMatch != null) {
    passed.add('Build: Version format correct (${versionMatch.group(1)})');
  } else {
    final simpleVersion = RegExp(r'version:\s*(\d+\.\d+\.\d+)').firstMatch(pubspec);
    if (simpleVersion != null) {
      warnings.add(ReleaseIssue(
        category: 'Build',
        message: 'Version missing build number',
        fix: 'Change version: ${simpleVersion.group(1)} to version: ${simpleVersion.group(1)}+1',
      ));
    } else {
      warnings.add(ReleaseIssue(
        category: 'Build',
        message: 'Version format may be incorrect',
        fix: 'Use format: version: 1.0.0+1',
      ));
    }
  }

  // Check for description
  if (pubspec.contains('description:')) {
    final descMatch = RegExp(r'description:\s*(.+)').firstMatch(pubspec);
    if (descMatch != null && descMatch.group(1)!.trim().isNotEmpty) {
      if (!descMatch.group(1)!.contains('A new Flutter project')) {
        passed.add('Build: Custom description set');
      } else {
        warnings.add(ReleaseIssue(
          category: 'Build',
          message: 'Using default Flutter project description',
          fix: 'Update description in pubspec.yaml',
        ));
      }
    }
  }

  if (verbose) print('');
}

// ============================================================
// FIREBASE CHECKS
// ============================================================

void _checkFirebase(
  List<ReleaseIssue> issues,
  List<ReleaseIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) {
  // Check if Firebase is likely being used
  final pubspec = _fileExists('pubspec.yaml') ? _readFile('pubspec.yaml') : '';
  final usesFirebase = pubspec.contains('firebase_core') ||
      pubspec.contains('firebase_messaging') ||
      pubspec.contains('firebase_crashlytics');

  if (!usesFirebase) return;

  if (verbose) print('🔥 Checking Firebase configuration...\n');

  // Check Android google-services.json
  if (_fileExists('android/app/google-services.json')) {
    passed.add('Firebase: google-services.json exists (Android)');
  } else {
    issues.add(ReleaseIssue(
      category: 'Firebase',
      message: 'google-services.json not found (Android)',
      fix: 'Download from Firebase Console > Project Settings > Your apps',
    ));
  }

  // Check iOS GoogleService-Info.plist
  if (_fileExists('ios/Runner/GoogleService-Info.plist')) {
    passed.add('Firebase: GoogleService-Info.plist exists (iOS)');
  } else {
    issues.add(ReleaseIssue(
      category: 'Firebase',
      message: 'GoogleService-Info.plist not found (iOS)',
      fix: 'Download from Firebase Console > Project Settings > Your apps',
    ));
  }

  if (verbose) print('');
}

// ============================================================
// LEGAL CHECKS
// ============================================================

void _checkLegal(
  List<ReleaseIssue> issues,
  List<ReleaseIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) {
  if (verbose) print('⚖️  Checking legal configuration...\n');

  // Check if legal_constants.dart exists
  final legalConstantsPath = 'lib/core/constants/legal_constants.dart';
  if (!_fileExists(legalConstantsPath)) {
    issues.add(ReleaseIssue(
      category: 'Legal',
      message: 'legal_constants.dart not found',
      fix: 'Run /core to generate legal constants, or create $legalConstantsPath',
    ));
    return;
  }

  final legalConstants = _readFile(legalConstantsPath);

  // Check Privacy Policy URL is not placeholder
  if (legalConstants.contains('privacyPolicyUrl')) {
    if (legalConstants.contains('yourapp.com') ||
        legalConstants.contains('example.com') ||
        legalConstants.contains('TODO') ||
        legalConstants.contains('placeholder')) {
      issues.add(ReleaseIssue(
        category: 'Legal',
        message: 'Privacy Policy URL is still a placeholder',
        fix: 'Update privacyPolicyUrl in $legalConstantsPath with actual URL',
      ));
    } else {
      passed.add('Legal: Privacy Policy URL configured');
    }
  } else {
    issues.add(ReleaseIssue(
      category: 'Legal',
      message: 'privacyPolicyUrl not found in legal_constants.dart',
      fix: 'Add privacyPolicyUrl to $legalConstantsPath',
    ));
  }

  // Check Terms of Service URL is not placeholder
  if (legalConstants.contains('termsOfServiceUrl')) {
    if (legalConstants.contains('yourapp.com') ||
        legalConstants.contains('example.com')) {
      warnings.add(ReleaseIssue(
        category: 'Legal',
        message: 'Terms of Service URL is still a placeholder',
        fix: 'Update termsOfServiceUrl in $legalConstantsPath with actual URL',
      ));
    } else {
      passed.add('Legal: Terms of Service URL configured');
    }
  }

  // Check legal links usage in auth screens
  final authDir = Directory('lib/features/auth');
  if (authDir.existsSync()) {
    final authUsesLegal = _directoryContainsLegalReference(authDir);
    if (authUsesLegal) {
      passed.add('Legal: Links found in auth screens');
    } else {
      issues.add(ReleaseIssue(
        category: 'Legal',
        message: 'Legal links not found in auth screens',
        fix: 'Add "By continuing, you agree to our Privacy Policy and Terms" to login/signup screen',
      ));
    }
  } else {
    // Auth feature might not exist yet, just warn
    warnings.add(ReleaseIssue(
      category: 'Legal',
      message: 'Auth feature not found - cannot verify legal links in login',
      fix: 'Ensure legal links are shown on login/signup screens',
    ));
  }

  // Check legal links usage in settings screens
  final settingsDir = Directory('lib/features/settings');
  if (settingsDir.existsSync()) {
    final settingsUsesLegal = _directoryContainsLegalReference(settingsDir);
    if (settingsUsesLegal) {
      passed.add('Legal: Links found in settings screens');
    } else {
      issues.add(ReleaseIssue(
        category: 'Legal',
        message: 'Legal links not found in settings screens',
        fix: 'Add Privacy Policy and Terms of Service links to settings screen',
      ));
    }
  } else {
    // Settings feature might not exist yet, just warn
    warnings.add(ReleaseIssue(
      category: 'Legal',
      message: 'Settings feature not found - cannot verify legal links',
      fix: 'Ensure legal links are accessible in settings',
    ));
  }

  if (verbose) print('');
}

/// Check if a directory contains references to legal utilities or constants.
bool _directoryContainsLegalReference(Directory dir) {
  final legalPatterns = [
    'LegalUtils',
    'LegalConstants',
    'openPrivacyPolicy',
    'openTermsOfService',
    'privacyPolicyUrl',
    'termsOfServiceUrl',
    'privacy_policy',
    'terms_of_service',
    'Privacy Policy',
    'Terms of Service',
    'legal_utils',
    'legal_constants',
  ];

  try {
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final content = entity.readAsStringSync();
      for (final pattern in legalPatterns) {
        if (content.contains(pattern)) {
          return true;
        }
      }
    }
  } catch (_) {
    return false;
  }

  return false;
}

// ============================================================
// AUTO-FIX
// ============================================================

void _autoFix(List<ReleaseIssue> issues, List<ReleaseIssue> warnings) {
  print('');
  print('🔧 Attempting auto-fixes...\n');

  var fixedCount = 0;

  // Fix: Add missing gitignore patterns
  if (_fileExists('.gitignore')) {
    final gitignore = _readFile('.gitignore');
    final additions = <String>[];

    // Check for missing patterns
    final patternsToAdd = {
      'key.properties': 'android/key.properties',
      '.jks': '*.jks',
      '.keystore': '*.keystore',
      '.env': '.env',
      '.p8': '*.p8',
      '.p12': '*.p12',
    };

    for (final entry in patternsToAdd.entries) {
      final hasPattern = gitignore.contains(entry.key) ||
          gitignore.contains(entry.value);

      if (!hasPattern) {
        // Check if this was flagged as an issue
        final isIssue = issues.any((i) =>
                i.category == 'Security' && i.message.contains(entry.key)) ||
            warnings.any((w) =>
                w.category == 'Security' && w.message.contains(entry.key));

        if (isIssue) {
          additions.add(entry.value);
        }
      }
    }

    if (additions.isNotEmpty) {
      final newContent = '$gitignore\n# Auto-added by release check\n${additions.join('\n')}\n';
      File('.gitignore').writeAsStringSync(newContent);
      print('   ✓ Added to .gitignore: ${additions.join(', ')}');
      fixedCount++;
    }
  }

  // Note: Privacy Manifest requires manual creation (complex XML)
  // Note: Keystore requires manual creation (security)
  // Note: Signing config requires manual editing

  if (fixedCount == 0) {
    print('   No automatic fixes available. Remaining issues require manual action.');
  } else {
    print('\n   Fixed $fixedCount issue(s). Re-run check to verify.');
  }

  print('');
}

// ============================================================
// JSON OUTPUT
// ============================================================

void _printJsonResults(
  List<ReleaseIssue> issues,
  List<ReleaseIssue> warnings,
  List<String> passed,
) {
  final result = {
    'readyForRelease': issues.isEmpty,
    'summary': {
      'passed': passed.length,
      'warnings': warnings.length,
      'issues': issues.length,
    },
    'passed': passed,
    'warnings': warnings.map((w) => {
      return {
        'category': w.category,
        'message': w.message,
        'fix': w.fix,
      };
    }).toList(),
    'issues': issues.map((i) => {
      return {
        'category': i.category,
        'message': i.message,
        'fix': i.fix,
      };
    }).toList(),
  };

  print(_jsonEncode(result));
}

String _jsonEncode(Object obj) {
  if (obj is String) return '"${obj.replaceAll('"', '\\"')}"';
  if (obj is num || obj is bool) return '$obj';
  if (obj is List) return '[${obj.map(_jsonEncode).join(',')}]';
  if (obj is Map) {
    final pairs = obj.entries.map((e) => '"${e.key}":${_jsonEncode(e.value)}');
    return '{${pairs.join(',')}}';
  }
  return 'null';
}

// ============================================================
// OUTPUT
// ============================================================

void _printResults(
  List<ReleaseIssue> issues,
  List<ReleaseIssue> warnings,
  List<String> passed,
) {
  print('═══════════════════════════════════════════════════════');
  print('  Results');
  print('═══════════════════════════════════════════════════════');
  print('');

  // Print passed items
  if (passed.isNotEmpty) {
    print('✅ Passed (${passed.length}):');
    for (final item in passed) {
      print('   ✓ $item');
    }
    print('');
  }

  // Print warnings
  if (warnings.isNotEmpty) {
    print('⚠️  Warnings (${warnings.length}):');
    for (final warning in warnings) {
      print('   ⚠ [${warning.category}] ${warning.message}');
      print('     Fix: ${warning.fix}');
    }
    print('');
  }

  // Print issues
  if (issues.isNotEmpty) {
    print('❌ Issues (${issues.length}):');
    for (final issue in issues) {
      print('   ✗ [${issue.category}] ${issue.message}');
      print('     Fix: ${issue.fix}');
    }
    print('');
  }

  // Summary
  print('───────────────────────────────────────────────────────');
  if (issues.isEmpty && warnings.isEmpty) {
    print('');
    print('🎉 All checks passed! Ready for release.');
    print('');
    print('Next steps:');
    print('  flutter build appbundle --release  # Android');
    print('  flutter build ipa --release        # iOS');
  } else if (issues.isEmpty) {
    print('');
    print('⚠️  ${warnings.length} warning(s). Review before release.');
  } else {
    print('');
    print('❌ ${issues.length} issue(s) must be fixed before release.');
    print('');
    print('See guides:');
    print('  .claude/skills/release/android-guide.md');
    print('  .claude/skills/release/ios-guide.md');
    print('  .claude/skills/release/checklist.md');
  }
  print('');
}

// ============================================================
// CHECKLIST OUTPUT
// ============================================================

void _printChecklist() {
  print('''
Release Preparation Checklist
═════════════════════════════

ANDROID
  [ ] Keystore created and backed up
  [ ] key.properties configured (not committed)
  [ ] build.gradle.kts has signing config
  [ ] proguard-rules.pro created
  [ ] flutter build appbundle --release succeeds

iOS
  [ ] Xcode Team selected
  [ ] Bundle ID correct
  [ ] Required capabilities enabled
  [ ] Info.plist permissions complete
  [ ] flutter build ipa --release succeeds

ASSETS
  [ ] App icon 1024x1024 (no transparency)
  [ ] iOS icons configured in Xcode
  [ ] Android icons generated
  [ ] Splash screen configured

SECURITY
  [ ] .gitignore has sensitive files
  [ ] No secrets in git history
  [ ] .env file not committed

STORE
  [ ] App Store Connect app created
  [ ] Play Console app created
  [ ] Privacy policy URL ready
  [ ] Screenshots prepared

Run full audit: dart run .claude/skills/release/scripts/check.dart
''');
}

// ============================================================
// HELP
// ============================================================

void _printKeytoolCommand() {
  final projectName = _getProjectName();
  if (projectName == null) {
    print('Error: Could not read project name from pubspec.yaml');
    return;
  }

  print('');
  print('Keytool command for "$projectName":');
  print('');
  print('keytool -genkey -v \\');
  print('  -keystore ~/$projectName.jks \\');
  print('  -keyalg RSA \\');
  print('  -keysize 2048 \\');
  print('  -validity 10000 \\');
  print('  -alias $projectName');
  print('');
  print('After creating the keystore, create android/key.properties:');
  print('');
  print('storePassword=YOUR_PASSWORD');
  print('keyPassword=YOUR_PASSWORD');
  print('keyAlias=$projectName');
  print('storeFile=/path/to/$projectName.jks');
  print('');
}

void _printDetectedCapabilities() {
  print('');
  print('═══════════════════════════════════════════════════════');
  print('  Detected iOS Capabilities');
  print('═══════════════════════════════════════════════════════');
  print('');

  final pubspec = _readFile('pubspec.yaml');
  final detected = <String, bool>{};

  // Check for Sign in with Apple
  detected['Sign in with Apple'] = pubspec.contains('sign_in_with_apple');

  // Check for Push Notifications (Firebase or other)
  detected['Push Notifications'] = pubspec.contains('firebase_messaging') ||
      pubspec.contains('flutter_local_notifications') ||
      pubspec.contains('onesignal');

  // Check for Google Sign-In (may need associated domains for OAuth)
  detected['Google Sign-In'] = pubspec.contains('google_sign_in');

  // Check for Deep Links / Universal Links
  detected['Associated Domains'] = pubspec.contains('uni_links') ||
      pubspec.contains('app_links') ||
      pubspec.contains('flutter_branch_sdk');

  // Check for Background processing
  detected['Background Modes'] = pubspec.contains('workmanager') ||
      pubspec.contains('background_fetch') ||
      pubspec.contains('flutter_background_service');

  // Check for App Groups (sharing data)
  detected['App Groups'] = pubspec.contains('shared_preferences_foundation') ||
      pubspec.contains('app_group_directory');

  // Check for In-App Purchases
  detected['In-App Purchase'] = pubspec.contains('in_app_purchase') ||
      pubspec.contains('purchases_flutter');

  // Check for HealthKit
  detected['HealthKit'] = pubspec.contains('health');

  // Check for HomeKit
  detected['HomeKit'] = pubspec.contains('homekit');

  // Check for Siri
  detected['Siri'] = pubspec.contains('flutter_siri_suggestions');

  print('Based on pubspec.yaml dependencies:\n');

  final needed = detected.entries.where((e) => e.value).toList();
  final notNeeded = detected.entries.where((e) => !e.value).toList();

  if (needed.isNotEmpty) {
    print('✅ Required capabilities (enable in Xcode):');
    for (final entry in needed) {
      print('   • ${entry.key}');
    }
    print('');
  }

  if (notNeeded.isNotEmpty) {
    print('⏭️  Not detected (skip unless needed):');
    for (final entry in notNeeded) {
      print('   • ${entry.key}');
    }
    print('');
  }

  print('Note: This detection is based on common packages.');
  print('Review your app\'s actual requirements.');
  print('');
}

String? _getProjectName() {
  if (!_fileExists('pubspec.yaml')) return null;

  final pubspec = _readFile('pubspec.yaml');
  final match = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(pubspec);
  return match?.group(1);
}

void _printHelp() {
  print('''
Release Readiness Audit Tool

Checks your Flutter project for common release preparation issues.

USAGE:
  dart run .claude/skills/release/scripts/check.dart [options]

OPTIONS:
  --platform <name>   Only check specific platform (android, ios)
  --checklist         Print release checklist
  --keytool-command   Generate keytool command with project name
  --capabilities      Detect required iOS capabilities from dependencies
  --json              Output results as JSON (for CI integration)
  --fix               Auto-fix simple issues (gitignore patterns)
  -h, --help          Show this help

EXAMPLES:
  dart run .claude/skills/release/scripts/check.dart
  dart run .claude/skills/release/scripts/check.dart --platform android
  dart run .claude/skills/release/scripts/check.dart --checklist
  dart run .claude/skills/release/scripts/check.dart --keytool-command
  dart run .claude/skills/release/scripts/check.dart --capabilities
  dart run .claude/skills/release/scripts/check.dart --json
  dart run .claude/skills/release/scripts/check.dart --fix

CHECKS PERFORMED:

  Android:
    • key.properties exists and has required fields
    • build.gradle.kts has signing configuration
    • proguard-rules.pro exists
    • No keystore files in repository
    • Internet permission in AndroidManifest.xml

  iOS:
    • Runner.xcworkspace exists
    • Info.plist has required permission descriptions
    • Privacy Manifest exists (iOS 17+ requirement)
    • Export compliance declared
    • No provisioning profiles in repository

  Security:
    • .gitignore has sensitive file patterns
    • .env file handling

  Assets:
    • App icon exists
    • Splash screen configured

  Firebase (if used):
    • google-services.json exists
    • GoogleService-Info.plist exists

  Build:
    • Version format correct in pubspec.yaml

SEE ALSO:
  .claude/skills/release/android-guide.md
  .claude/skills/release/ios-guide.md
  .claude/skills/release/assets-guide.md
  .claude/skills/release/checklist.md
  .claude/skills/release/version-guide.md
''');
}

// ============================================================
// UTILITIES
// ============================================================

String? _getArgValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  final value = args[index + 1];
  if (value.startsWith('-')) return null;
  return value;
}

bool _fileExists(String path) {
  return File(path).existsSync();
}

bool _directoryExists(String path) {
  return Directory(path).existsSync();
}

String _readFile(String path) {
  try {
    return File(path).readAsStringSync();
  } catch (_) {
    return '';
  }
}

String? _findFile(List<String> paths) {
  for (final path in paths) {
    if (_fileExists(path)) return path;
  }
  return null;
}

bool _hasFilesMatching(String directory, String extension) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return false;

  try {
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .any((f) => f.path.endsWith(extension));
  } catch (_) {
    return false;
  }
}

// ============================================================
// TYPES
// ============================================================

class ReleaseIssue {
  final String category;
  final String message;
  final String fix;

  const ReleaseIssue({
    required this.category,
    required this.message,
    required this.fix,
  });
}

// ============================================================
// IMPORTS
// ============================================================

import 'dart:io';

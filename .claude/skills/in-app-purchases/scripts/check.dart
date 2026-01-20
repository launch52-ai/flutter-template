#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// In-App Purchases audit script for Flutter projects.
///
/// Detects common IAP implementation issues:
/// - Missing RevenueCat initialization
/// - Missing entitlement checks
/// - Missing restore purchases functionality
/// - Platform configuration issues
///
/// Usage:
///   dart run .claude/skills/in-app-purchases/scripts/check.dart
///   dart run .claude/skills/in-app-purchases/scripts/check.dart --feature purchases
///   dart run .claude/skills/in-app-purchases/scripts/check.dart --json
///   dart run .claude/skills/in-app-purchases/scripts/check.dart --help
void main(List<String> args) async {
  final help = args.contains('--help') || args.contains('-h');
  final jsonOutput = args.contains('--json');
  final featureFilter = _getArgValue(args, '--feature');

  if (help) {
    _printHelp();
    return;
  }

  if (!jsonOutput) {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('  In-App Purchases Audit');
    print('═══════════════════════════════════════════════════════════');
    print('');
  }

  final issues = <AuditIssue>[];
  final warnings = <AuditIssue>[];
  final passed = <String>[];

  // Run checks
  await _checkDependencies(issues, warnings, passed, verbose: !jsonOutput);
  await _checkInitialization(issues, warnings, passed, verbose: !jsonOutput);
  await _checkPlatformConfig(issues, warnings, passed, verbose: !jsonOutput);
  await _checkImplementation(issues, warnings, passed,
      feature: featureFilter, verbose: !jsonOutput);
  await _checkPaywall(issues, warnings, passed, verbose: !jsonOutput);

  // Output results
  if (jsonOutput) {
    _printJsonResults(issues, warnings, passed);
  } else {
    _printResults(issues, warnings, passed);
  }

  // Exit code
  if (issues.isNotEmpty) {
    exit(1);
  }
}

// ============================================================
// CHECK FUNCTIONS
// ============================================================

Future<void> _checkDependencies(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) async {
  if (verbose) print('📦 Checking dependencies...\n');

  final pubspecPath = 'pubspec.yaml';
  if (!_fileExists(pubspecPath)) {
    issues.add(const AuditIssue(
      category: 'Dependencies',
      message: 'pubspec.yaml not found',
      fix: 'Run from project root directory',
    ));
    return;
  }

  final pubspec = _readFile(pubspecPath);

  // Check for purchases_flutter
  if (!pubspec.contains('purchases_flutter:')) {
    issues.add(const AuditIssue(
      category: 'Dependencies',
      file: 'pubspec.yaml',
      message: 'purchases_flutter dependency not found',
      fix: 'Add: purchases_flutter: ^8.0.0',
    ));
  } else {
    passed.add('Dependencies: purchases_flutter installed');
  }

  if (verbose) print('');
}

Future<void> _checkInitialization(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) async {
  if (verbose) print('🚀 Checking initialization...\n');

  // Check main.dart for RevenueCat initialization
  final mainPath = 'lib/main.dart';
  if (_fileExists(mainPath)) {
    final mainContent = _readFile(mainPath);

    if (!mainContent.contains('Purchases.configure') &&
        !mainContent.contains('PurchasesService') &&
        !mainContent.contains('purchases_flutter')) {
      issues.add(const AuditIssue(
        category: 'Initialization',
        file: 'lib/main.dart',
        message: 'RevenueCat not initialized in main.dart',
        fix:
            'Call Purchases.configure() or PurchasesService.instance.initialize() in main()',
      ));
    } else {
      passed.add('Initialization: RevenueCat configured in main.dart');
    }
  }

  // Check for API key configuration
  final envFiles = ['lib/core/env/', 'lib/config/', '.env'];
  var hasApiKeyConfig = false;

  for (final path in envFiles) {
    if (_fileExists(path) || _directoryExists(path)) {
      hasApiKeyConfig = true;
      break;
    }
  }

  // Check for dart-define usage
  final mainContent =
      _fileExists(mainPath) ? _readFile(mainPath) : '';
  if (mainContent.contains('String.fromEnvironment') &&
      (mainContent.contains('REVENUECAT') ||
          mainContent.contains('revenuecat'))) {
    hasApiKeyConfig = true;
  }

  if (!hasApiKeyConfig) {
    warnings.add(const AuditIssue(
      category: 'Initialization',
      message: 'No API key configuration found',
      fix:
          'Store RevenueCat API keys in env file or use --dart-define',
    ));
  }

  if (verbose) print('');
}

Future<void> _checkPlatformConfig(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) async {
  if (verbose) print('📱 Checking platform configuration...\n');

  // iOS: Check for In-App Purchase capability
  final iosProjectPath = 'ios/Runner.xcodeproj/project.pbxproj';
  if (_fileExists(iosProjectPath)) {
    final projectContent = _readFile(iosProjectPath);

    // Check for StoreKit capability
    if (!projectContent.contains('StoreKit') &&
        !projectContent.contains('In-App Purchase')) {
      warnings.add(const AuditIssue(
        category: 'iOS',
        file: 'ios/Runner.xcodeproj',
        message: 'In-App Purchase capability may not be enabled',
        fix:
            'In Xcode: Target → Signing & Capabilities → + In-App Purchase',
      ));
    } else {
      passed.add('iOS: In-App Purchase capability enabled');
    }
  }

  // Android: Check for billing permission
  final androidManifestPath = 'android/app/src/main/AndroidManifest.xml';
  if (_fileExists(androidManifestPath)) {
    final manifest = _readFile(androidManifestPath);

    if (!manifest.contains('com.android.vending.BILLING')) {
      issues.add(const AuditIssue(
        category: 'Android',
        file: 'android/app/src/main/AndroidManifest.xml',
        message: 'BILLING permission not found',
        fix:
            'Add: <uses-permission android:name="com.android.vending.BILLING" />',
      ));
    } else {
      passed.add('Android: BILLING permission present');
    }
  }

  // Check for StoreKit configuration file (iOS testing)
  if (_directoryExists('ios')) {
    final storeKitFiles = Directory('ios')
        .listSync(recursive: true)
        .where((f) => f.path.endsWith('.storekit'))
        .toList();

    if (storeKitFiles.isEmpty) {
      warnings.add(const AuditIssue(
        category: 'iOS',
        message: 'No StoreKit configuration file found',
        fix:
            'Create StoreKit Config in Xcode for Simulator testing',
      ));
    } else {
      passed.add('iOS: StoreKit configuration file present');
    }
  }

  if (verbose) print('');
}

Future<void> _checkImplementation(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  String? feature,
  bool verbose = true,
}) async {
  if (verbose) print('🔧 Checking implementation...\n');

  final searchDir = feature != null ? 'lib/features/$feature' : 'lib';

  if (!_directoryExists(searchDir)) {
    if (feature != null) {
      warnings.add(AuditIssue(
        category: 'Implementation',
        message: 'Feature directory not found: $searchDir',
        fix: 'Create purchases feature or check feature name',
      ));
    }
    return;
  }

  // Look for purchases-related files
  final dartFiles = _findDartFiles(searchDir);

  var hasRepository = false;
  var hasProvider = false;
  var hasEntitlementCheck = false;
  var hasRestorePurchases = false;

  for (final file in dartFiles) {
    final content = _readFile(file);

    // Check for repository
    if (content.contains('PurchasesRepository') ||
        content.contains('purchasesRepository')) {
      hasRepository = true;
    }

    // Check for providers
    if (content.contains('subscriptionStatus') ||
        content.contains('isPremium') ||
        content.contains('offeringsProvider')) {
      hasProvider = true;
    }

    // Check for entitlement checks
    if (content.contains('isActive') ||
        content.contains('hasEntitlement') ||
        content.contains('isPremium')) {
      hasEntitlementCheck = true;
    }

    // Check for restore purchases
    if (content.contains('restorePurchases') ||
        content.contains('Restore')) {
      hasRestorePurchases = true;
    }
  }

  if (hasRepository) {
    passed.add('Implementation: PurchasesRepository found');
  } else {
    warnings.add(const AuditIssue(
      category: 'Implementation',
      message: 'PurchasesRepository not found',
      fix: 'Create purchases repository following skill reference',
    ));
  }

  if (hasProvider) {
    passed.add('Implementation: Purchases providers found');
  }

  if (!hasEntitlementCheck && dartFiles.length > 5) {
    warnings.add(const AuditIssue(
      category: 'Implementation',
      message: 'No entitlement checks found',
      fix: 'Add isPremium checks to gate premium features',
    ));
  }

  if (!hasRestorePurchases) {
    issues.add(const AuditIssue(
      category: 'Implementation',
      message: 'Restore purchases functionality not found',
      fix: 'Add restore purchases button (App Store requirement)',
    ));
  } else {
    passed.add('Implementation: Restore purchases found');
  }

  if (verbose) print('');
}

Future<void> _checkPaywall(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) async {
  if (verbose) print('💰 Checking paywall...\n');

  final dartFiles = _findDartFiles('lib');

  var hasPaywallScreen = false;
  var hasPackageDisplay = false;
  var hasTermsLink = false;
  var hasPrivacyLink = false;

  for (final file in dartFiles) {
    final content = _readFile(file);
    final lowerContent = content.toLowerCase();

    if (lowerContent.contains('paywall') ||
        file.toLowerCase().contains('paywall')) {
      hasPaywallScreen = true;

      // Check for package display
      if (content.contains('Package') ||
          content.contains('priceString') ||
          content.contains('availablePackages')) {
        hasPackageDisplay = true;
      }

      // Check for legal links
      if (lowerContent.contains('terms') ||
          lowerContent.contains('conditions')) {
        hasTermsLink = true;
      }
      if (lowerContent.contains('privacy')) {
        hasPrivacyLink = true;
      }
    }
  }

  if (hasPaywallScreen) {
    passed.add('Paywall: Paywall screen found');

    if (hasPackageDisplay) {
      passed.add('Paywall: Package display found');
    } else {
      warnings.add(const AuditIssue(
        category: 'Paywall',
        message: 'Package/price display not found in paywall',
        fix: 'Display product prices from offerings',
      ));
    }

    if (!hasTermsLink) {
      warnings.add(const AuditIssue(
        category: 'Paywall',
        message: 'Terms of Service link not found',
        fix: 'Add Terms link (App Store requirement)',
      ));
    }

    if (!hasPrivacyLink) {
      warnings.add(const AuditIssue(
        category: 'Paywall',
        message: 'Privacy Policy link not found',
        fix: 'Add Privacy Policy link (App Store requirement)',
      ));
    }
  } else {
    warnings.add(const AuditIssue(
      category: 'Paywall',
      message: 'No paywall screen found',
      fix: 'Create paywall screen to display purchase options',
    ));
  }

  if (verbose) print('');
}

// ============================================================
// OUTPUT
// ============================================================

void _printResults(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed,
) {
  print('═══════════════════════════════════════════════════════════');
  print('  Results');
  print('═══════════════════════════════════════════════════════════');
  print('');

  // Print passed
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
      if (warning.file != null) {
        print('     File: ${warning.file}');
      }
      print('     Fix: ${warning.fix}');
    }
    print('');
  }

  // Print issues
  if (issues.isNotEmpty) {
    print('❌ Issues (${issues.length}):');
    for (final issue in issues) {
      print('   ✗ [${issue.category}] ${issue.message}');
      if (issue.file != null) {
        print('     File: ${issue.file}');
      }
      print('     Fix: ${issue.fix}');
    }
    print('');
  }

  // Summary
  print('───────────────────────────────────────────────────────────');
  if (issues.isEmpty && warnings.isEmpty) {
    print('');
    print('🎉 All checks passed!');
  } else if (issues.isEmpty) {
    print('');
    print('⚠️  ${warnings.length} warning(s) found.');
  } else {
    print('');
    print('❌ ${issues.length} issue(s) must be fixed.');
    print('');
    print('See: .claude/skills/in-app-purchases/SKILL.md');
  }
  print('');
}

void _printJsonResults(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed,
) {
  final result = {
    'valid': issues.isEmpty,
    'summary': {
      'passed': passed.length,
      'warnings': warnings.length,
      'issues': issues.length,
    },
    'passed': passed,
    'warnings': warnings
        .map((w) => <String, Object?>{
              'category': w.category,
              'file': w.file,
              'message': w.message,
              'fix': w.fix,
            })
        .toList(),
    'issues': issues
        .map((i) => <String, Object?>{
              'category': i.category,
              'file': i.file,
              'message': i.message,
              'fix': i.fix,
            })
        .toList(),
  };

  print(_jsonEncode(result));
}

String _jsonEncode(Object? obj) {
  if (obj == null) return 'null';
  if (obj is String) return '"${obj.replaceAll('"', '\\"')}"';
  if (obj is num || obj is bool) return '$obj';
  if (obj is List) return '[${obj.map(_jsonEncode).join(',')}]';
  if (obj is Map) {
    final pairs =
        obj.entries.map((e) => '"${e.key}":${_jsonEncode(e.value)}');
    return '{${pairs.join(',')}}';
  }
  return 'null';
}

// ============================================================
// HELP
// ============================================================

void _printHelp() {
  print('''
In-App Purchases Audit Tool

Checks your Flutter project for RevenueCat IAP implementation issues.

USAGE:
  dart run .claude/skills/in-app-purchases/scripts/check.dart [options]

OPTIONS:
  --feature <name>  Only check specific feature directory
  --json            Output as JSON (for CI)
  -h, --help        Show this help

EXAMPLES:
  dart run .claude/skills/in-app-purchases/scripts/check.dart
  dart run .claude/skills/in-app-purchases/scripts/check.dart --feature purchases
  dart run .claude/skills/in-app-purchases/scripts/check.dart --json

CHECKS PERFORMED:
  Dependencies:
    • purchases_flutter package installed

  Initialization:
    • RevenueCat configured in main.dart
    • API keys configured securely

  Platform Config:
    • iOS: In-App Purchase capability
    • iOS: StoreKit configuration file
    • Android: BILLING permission

  Implementation:
    • PurchasesRepository exists
    • Entitlement checks in place
    • Restore purchases functionality

  Paywall:
    • Paywall screen exists
    • Package/price display
    • Terms & Privacy links

SEE ALSO:
  .claude/skills/in-app-purchases/SKILL.md
  .claude/skills/in-app-purchases/checklist.md
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

bool _fileExists(String path) => File(path).existsSync();

bool _directoryExists(String path) => Directory(path).existsSync();

String _readFile(String path) {
  try {
    return File(path).readAsStringSync();
  } catch (_) {
    return '';
  }
}

List<String> _findDartFiles(String directory) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return [];

  return dir
      .listSync(recursive: true)
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path)
      .toList();
}

// ============================================================
// TYPES
// ============================================================

class AuditIssue {
  final String category;
  final String? file;
  final int? line;
  final String message;
  final String fix;

  const AuditIssue({
    required this.category,
    this.file,
    this.line,
    required this.message,
    required this.fix,
  });
}

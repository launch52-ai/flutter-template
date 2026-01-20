#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Force Update skill audit script for Flutter projects.
///
/// Validates force update implementation:
/// - Required dependencies (package_info_plus, url_launcher, in_app_update)
/// - Version service implementation
/// - Update UI screens
/// - Backend configuration (Supabase table or Remote Config)
///
/// Usage:
///   dart run .claude/skills/force-update/scripts/check.dart
///   dart run .claude/skills/force-update/scripts/check.dart --check dependencies
///   dart run .claude/skills/force-update/scripts/check.dart --check service
///   dart run .claude/skills/force-update/scripts/check.dart --check ui
///   dart run .claude/skills/force-update/scripts/check.dart --json
///   dart run .claude/skills/force-update/scripts/check.dart --help
void main(List<String> args) async {
  final help = args.contains('--help') || args.contains('-h');
  final jsonOutput = args.contains('--json');
  final checkFilter = _getArgValue(args, '--check');

  if (help) {
    _printHelp();
    return;
  }

  if (!jsonOutput) {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('  Force Update Implementation Audit');
    print('═══════════════════════════════════════════════════════════');
    print('');
  }

  final issues = <AuditIssue>[];
  final warnings = <AuditIssue>[];
  final passed = <String>[];

  // Run checks
  if (checkFilter == null || checkFilter == 'dependencies') {
    await _checkDependencies(issues, warnings, passed, verbose: !jsonOutput);
  }
  if (checkFilter == null || checkFilter == 'service') {
    await _checkVersionService(issues, warnings, passed, verbose: !jsonOutput);
  }
  if (checkFilter == null || checkFilter == 'ui') {
    await _checkUpdateUI(issues, warnings, passed, verbose: !jsonOutput);
  }
  if (checkFilter == null || checkFilter == 'integration') {
    await _checkIntegration(issues, warnings, passed, verbose: !jsonOutput);
  }

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

  final pubspec = _readFile('pubspec.yaml');

  // Required dependencies
  final requiredDeps = [
    'package_info_plus',
    'url_launcher',
  ];

  for (final dep in requiredDeps) {
    if (pubspec.contains(dep)) {
      passed.add('Dependency: $dep found');
      if (verbose) print('   ✓ $dep');
    } else {
      issues.add(AuditIssue(
        category: 'Dependencies',
        message: '$dep not found in pubspec.yaml',
        fix: 'Run: flutter pub add $dep',
      ));
      if (verbose) print('   ✗ $dep missing');
    }
  }

  // Optional but recommended
  if (pubspec.contains('in_app_update')) {
    passed.add('Dependency: in_app_update found (Android in-app updates)');
    if (verbose) print('   ✓ in_app_update (optional)');
  } else {
    warnings.add(AuditIssue(
      category: 'Dependencies',
      message: 'in_app_update not found (optional for Android)',
      fix: 'Run: flutter pub add in_app_update for seamless Android updates',
    ));
    if (verbose) print('   ⚠ in_app_update not found (optional)');
  }

  if (verbose) print('');
}

Future<void> _checkVersionService(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) async {
  if (verbose) print('🔧 Checking version service...\n');

  // Check for version service file
  final serviceLocations = [
    'lib/core/services/app_version_service.dart',
    'lib/services/app_version_service.dart',
    'lib/features/force_update/data/repositories/version_repository.dart',
  ];

  var serviceFound = false;
  String? serviceFile;

  for (final location in serviceLocations) {
    if (_fileExists(location)) {
      serviceFound = true;
      serviceFile = location;
      break;
    }
  }

  if (serviceFound) {
    passed.add('Version service: Found at $serviceFile');
    if (verbose) print('   ✓ Version service found: $serviceFile');

    // Check service implementation
    final content = _readFile(serviceFile!);

    if (content.contains('compareVersions') || content.contains('_compareVersions')) {
      passed.add('Version comparison: Implementation found');
      if (verbose) print('   ✓ Version comparison logic found');
    } else {
      warnings.add(AuditIssue(
        category: 'Version Service',
        file: serviceFile,
        message: 'No version comparison logic found',
        fix: 'Implement semantic version comparison (see version-checking-guide.md)',
      ));
      if (verbose) print('   ⚠ Version comparison logic not found');
    }

    if (content.contains('checkVersion') || content.contains('checkForUpdate')) {
      passed.add('Version check: Method found');
      if (verbose) print('   ✓ Version check method found');
    } else {
      issues.add(AuditIssue(
        category: 'Version Service',
        file: serviceFile,
        message: 'No checkVersion method found',
        fix: 'Implement checkVersion() method to fetch version info',
      ));
      if (verbose) print('   ✗ Version check method not found');
    }
  } else {
    issues.add(AuditIssue(
      category: 'Version Service',
      message: 'No version service found',
      fix: 'Create AppVersionService (see reference/services/app_version_service.dart)',
    ));
    if (verbose) print('   ✗ Version service not found');
  }

  // Check for UpdateStatus enum
  final enumLocations = [
    'lib/features/force_update/domain/enums/update_status.dart',
    'lib/core/enums/update_status.dart',
  ];

  var enumFound = false;
  for (final location in enumLocations) {
    if (_fileExists(location)) {
      enumFound = true;
      passed.add('UpdateStatus enum: Found at $location');
      if (verbose) print('   ✓ UpdateStatus enum found');
      break;
    }
  }

  if (!enumFound) {
    // Check if defined inline somewhere
    final allDartFiles = _findDartFiles('lib');
    for (final file in allDartFiles) {
      final content = _readFile(file);
      if (content.contains('enum UpdateStatus')) {
        enumFound = true;
        passed.add('UpdateStatus enum: Found in $file');
        if (verbose) print('   ✓ UpdateStatus enum found in $file');
        break;
      }
    }
  }

  if (!enumFound) {
    issues.add(AuditIssue(
      category: 'Version Service',
      message: 'UpdateStatus enum not found',
      fix: 'Create UpdateStatus enum (see reference/entities/update_status.dart)',
    ));
    if (verbose) print('   ✗ UpdateStatus enum not found');
  }

  if (verbose) print('');
}

Future<void> _checkUpdateUI(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) async {
  if (verbose) print('🎨 Checking update UI...\n');

  // Check for force update screen
  final forceUpdateLocations = [
    'lib/features/force_update/presentation/screens/force_update_screen.dart',
    'lib/screens/force_update_screen.dart',
    'lib/ui/screens/force_update_screen.dart',
  ];

  var forceUpdateFound = false;
  for (final location in forceUpdateLocations) {
    if (_fileExists(location)) {
      forceUpdateFound = true;
      passed.add('Force update screen: Found at $location');
      if (verbose) print('   ✓ Force update screen found');

      // Verify PopScope for preventing back navigation
      final content = _readFile(location);
      if (content.contains('PopScope') || content.contains('WillPopScope')) {
        passed.add('Back prevention: Implemented');
        if (verbose) print('   ✓ Back navigation prevention found');
      } else {
        warnings.add(AuditIssue(
          category: 'Update UI',
          file: location,
          message: 'No back navigation prevention found',
          fix: 'Wrap screen with PopScope(canPop: false) to prevent dismissal',
        ));
        if (verbose) print('   ⚠ Back navigation prevention not found');
      }
      break;
    }
  }

  if (!forceUpdateFound) {
    issues.add(AuditIssue(
      category: 'Update UI',
      message: 'Force update screen not found',
      fix: 'Create ForceUpdateScreen (see reference/screens/force_update_screen.dart)',
    ));
    if (verbose) print('   ✗ Force update screen not found');
  }

  // Check for soft update dialog
  final softUpdateLocations = [
    'lib/features/force_update/presentation/widgets/soft_update_dialog.dart',
    'lib/widgets/soft_update_dialog.dart',
    'lib/ui/widgets/soft_update_dialog.dart',
  ];

  var softUpdateFound = false;
  for (final location in softUpdateLocations) {
    if (_fileExists(location)) {
      softUpdateFound = true;
      passed.add('Soft update dialog: Found at $location');
      if (verbose) print('   ✓ Soft update dialog found');
      break;
    }
  }

  if (!softUpdateFound) {
    warnings.add(AuditIssue(
      category: 'Update UI',
      message: 'Soft update dialog not found',
      fix: 'Create SoftUpdateDialog (see reference/widgets/soft_update_dialog.dart)',
    ));
    if (verbose) print('   ⚠ Soft update dialog not found');
  }

  // Check for maintenance screen
  final maintenanceLocations = [
    'lib/features/force_update/presentation/screens/maintenance_screen.dart',
    'lib/screens/maintenance_screen.dart',
  ];

  var maintenanceFound = false;
  for (final location in maintenanceLocations) {
    if (_fileExists(location)) {
      maintenanceFound = true;
      passed.add('Maintenance screen: Found at $location');
      if (verbose) print('   ✓ Maintenance screen found');
      break;
    }
  }

  if (!maintenanceFound) {
    warnings.add(AuditIssue(
      category: 'Update UI',
      message: 'Maintenance screen not found',
      fix: 'Create MaintenanceScreen (see reference/screens/maintenance_screen.dart)',
    ));
    if (verbose) print('   ⚠ Maintenance screen not found');
  }

  if (verbose) print('');
}

Future<void> _checkIntegration(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) async {
  if (verbose) print('🔗 Checking integration...\n');

  // Check main.dart for version check on startup
  final mainDart = _readFile('lib/main.dart');

  if (mainDart.contains('checkVersion') ||
      mainDart.contains('updateNotifier') ||
      mainDart.contains('versionService')) {
    passed.add('Startup check: Version check appears to be integrated');
    if (verbose) print('   ✓ Version check integrated in main.dart');
  } else {
    warnings.add(AuditIssue(
      category: 'Integration',
      file: 'lib/main.dart',
      message: 'No version check found on app startup',
      fix: 'Add version check in app initialization (see SKILL.md Phase 4)',
    ));
    if (verbose) print('   ⚠ Version check not found in main.dart');
  }

  // Check for store URLs
  final allDartFiles = _findDartFiles('lib');
  var hasIosUrl = false;
  var hasAndroidUrl = false;

  for (final file in allDartFiles) {
    final content = _readFile(file);
    if (content.contains('apps.apple.com') || content.contains('itunes.apple.com')) {
      hasIosUrl = true;
    }
    if (content.contains('play.google.com')) {
      hasAndroidUrl = true;
    }
  }

  if (hasIosUrl && hasAndroidUrl) {
    passed.add('Store URLs: Both iOS and Android URLs found');
    if (verbose) print('   ✓ Store URLs configured');
  } else if (hasIosUrl || hasAndroidUrl) {
    warnings.add(AuditIssue(
      category: 'Integration',
      message: 'Only ${hasIosUrl ? "iOS" : "Android"} store URL found',
      fix: 'Add store URL for ${hasIosUrl ? "Android" : "iOS"} platform',
    ));
    if (verbose) print('   ⚠ Only one platform store URL found');
  } else {
    issues.add(AuditIssue(
      category: 'Integration',
      message: 'No app store URLs found',
      fix: 'Configure store URLs for iOS (apps.apple.com) and Android (play.google.com)',
    ));
    if (verbose) print('   ✗ No store URLs found');
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

  if (passed.isNotEmpty) {
    print('✅ Passed (${passed.length}):');
    for (final item in passed) {
      print('   ✓ $item');
    }
    print('');
  }

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

  print('───────────────────────────────────────────────────────────');
  if (issues.isEmpty && warnings.isEmpty) {
    print('');
    print('🎉 All checks passed! Force update is properly configured.');
  } else if (issues.isEmpty) {
    print('');
    print('⚠️  ${warnings.length} warning(s) found. Consider addressing them.');
  } else {
    print('');
    print('❌ ${issues.length} issue(s) must be fixed.');
    print('');
    print('See: .claude/skills/force-update/SKILL.md');
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
    'warnings': warnings.map((w) => {
      return {
        'category': w.category,
        'file': w.file,
        'message': w.message,
        'fix': w.fix,
      };
    }).toList(),
    'issues': issues.map((i) => {
      return {
        'category': i.category,
        'file': i.file,
        'message': i.message,
        'fix': i.fix,
      };
    }).toList(),
  };

  print(_jsonEncode(result));
}

String _jsonEncode(Object obj) {
  if (obj == null) return 'null';
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
// HELP
// ============================================================

void _printHelp() {
  print('''
Force Update Implementation Audit Tool

Validates your Flutter project's force update implementation.

USAGE:
  dart run .claude/skills/force-update/scripts/check.dart [options]

OPTIONS:
  --check <type>  Only check specific aspect:
                  - dependencies: Check pubspec.yaml
                  - service: Check version service implementation
                  - ui: Check update screens and dialogs
                  - integration: Check app startup integration
  --json          Output as JSON (for CI)
  -h, --help      Show this help

EXAMPLES:
  dart run .claude/skills/force-update/scripts/check.dart
  dart run .claude/skills/force-update/scripts/check.dart --check dependencies
  dart run .claude/skills/force-update/scripts/check.dart --json

CHECKS PERFORMED:
  Dependencies:
    • package_info_plus (required)
    • url_launcher (required)
    • in_app_update (optional, for Android)

  Version Service:
    • AppVersionService or VersionRepository exists
    • Version comparison logic implemented
    • UpdateStatus enum defined

  Update UI:
    • ForceUpdateScreen exists
    • Back navigation prevention
    • SoftUpdateDialog exists
    • MaintenanceScreen exists

  Integration:
    • Version check on app startup
    • Store URLs configured

SEE ALSO:
  .claude/skills/force-update/SKILL.md
  .claude/skills/force-update/version-checking-guide.md
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

String _readFile(String path) {
  try {
    return File(path).readAsStringSync();
  } catch (_) {
    return '';
  }
}

List<String> _findDartFiles(String directory) {
  final files = <String>[];
  final dir = Directory(directory);

  if (!dir.existsSync()) return files;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity.path);
    }
  }

  return files;
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

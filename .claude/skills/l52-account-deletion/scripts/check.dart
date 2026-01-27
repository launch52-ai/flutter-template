#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Account Deletion audit script for Flutter projects.
///
/// Detects common account deletion implementation issues:
/// - Missing domain layer (failure types, repository interface)
/// - Missing data layer (repository implementation)
/// - Missing presentation layer (notifier, dialog, button)
/// - Missing settings integration
/// - Localization issues
///
/// Usage:
///   dart run .claude/skills/account-deletion/scripts/check.dart
///   dart run .claude/skills/account-deletion/scripts/check.dart --feature settings
///   dart run .claude/skills/account-deletion/scripts/check.dart --json
///   dart run .claude/skills/account-deletion/scripts/check.dart --help
void main(List<String> args) async {
  final help = args.contains('--help') || args.contains('-h');
  final jsonOutput = args.contains('--json');
  final featureFilter = _getArgValue(args, '--feature') ?? 'settings';

  if (help) {
    _printHelp();
    return;
  }

  if (!jsonOutput) {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('  Account Deletion Audit');
    print('═══════════════════════════════════════════════════════════');
    print('');
  }

  final issues = <AuditIssue>[];
  final warnings = <AuditIssue>[];
  final passed = <String>[];

  // Run checks
  await _checkDomainLayer(issues, warnings, passed,
      feature: featureFilter, verbose: !jsonOutput);
  await _checkDataLayer(issues, warnings, passed,
      feature: featureFilter, verbose: !jsonOutput);
  await _checkPresentationLayer(issues, warnings, passed,
      feature: featureFilter, verbose: !jsonOutput);
  await _checkLocalization(issues, warnings, passed,
      feature: featureFilter, verbose: !jsonOutput);
  await _checkCompliance(issues, warnings, passed,
      feature: featureFilter, verbose: !jsonOutput);

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

Future<void> _checkDomainLayer(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  String? feature,
  bool verbose = true,
}) async {
  if (verbose) print('📦 Checking domain layer...\n');

  final featurePath = 'lib/features/${feature ?? "settings"}';
  final failurePath = '$featurePath/domain/failures/account_deletion_failure.dart';
  final repoInterfacePath = '$featurePath/domain/repositories';

  // Check failure types exist
  if (_fileExists(failurePath)) {
    final content = _readFile(failurePath);

    // Check for required failure types
    final requiredFailures = [
      'AccountDeletionNetworkFailure',
      'AccountDeletionServerFailure',
      'AccountDeletionAuthFailure',
    ];

    var allFailuresPresent = true;
    for (final failure in requiredFailures) {
      if (!content.contains(failure)) {
        issues.add(AuditIssue(
          category: 'Domain',
          file: failurePath,
          message: 'Missing failure type: $failure',
          fix: 'Add $failure to AccountDeletionFailure sealed class',
        ));
        allFailuresPresent = false;
      }
    }

    if (allFailuresPresent) {
      passed.add('Domain: AccountDeletionFailure has all required types');
    }
  } else {
    issues.add(AuditIssue(
      category: 'Domain',
      file: failurePath,
      message: 'AccountDeletionFailure file missing',
      fix: 'Create $failurePath with sealed failure class',
    ));
  }

  // Check repository interface has deleteAccount method
  if (_directoryExists(repoInterfacePath)) {
    final repoFiles = Directory(repoInterfacePath)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('.g.dart'));

    var hasDeleteMethod = false;
    for (final file in repoFiles) {
      final content = _readFile(file.path);
      if (content.contains('deleteAccount()') || content.contains('deleteAccount(')) {
        hasDeleteMethod = true;
        passed.add('Domain: Repository interface has deleteAccount method');
        break;
      }
    }

    if (!hasDeleteMethod) {
      issues.add(AuditIssue(
        category: 'Domain',
        message: 'No deleteAccount method in repository interface',
        fix: 'Add Future<Either<AccountDeletionFailure, void>> deleteAccount() to repository',
      ));
    }
  }

  if (verbose) print('');
}

Future<void> _checkDataLayer(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  String? feature,
  bool verbose = true,
}) async {
  if (verbose) print('💾 Checking data layer...\n');

  final featurePath = 'lib/features/${feature ?? "settings"}';
  final repoImplPath = '$featurePath/data/repositories';

  if (_directoryExists(repoImplPath)) {
    final repoFiles = Directory(repoImplPath)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('.g.dart'));

    var hasDeleteImpl = false;
    var hasCleanup = false;

    for (final file in repoFiles) {
      final content = _readFile(file.path);

      if (content.contains('deleteAccount()') || content.contains('deleteAccount(')) {
        hasDeleteImpl = true;
      }

      // Check for data cleanup
      if (content.contains('deleteAll') ||
          content.contains('secureStorage') ||
          content.contains('_cleanupLocalData') ||
          content.contains('_cleanupUserData')) {
        hasCleanup = true;
      }
    }

    if (hasDeleteImpl) {
      passed.add('Data: deleteAccount implemented in repository');
    } else {
      issues.add(AuditIssue(
        category: 'Data',
        message: 'No deleteAccount implementation found',
        fix: 'Implement deleteAccount() in repository implementation',
      ));
    }

    if (hasCleanup) {
      passed.add('Data: Local data cleanup implemented');
    } else {
      warnings.add(AuditIssue(
        category: 'Data',
        message: 'No local data cleanup found',
        fix: 'Add cleanup for SecureStorage, SharedPreferences, and analytics',
      ));
    }
  } else {
    issues.add(AuditIssue(
      category: 'Data',
      message: 'No data/repositories directory found',
      fix: 'Create repository implementation at $repoImplPath',
    ));
  }

  if (verbose) print('');
}

Future<void> _checkPresentationLayer(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  String? feature,
  bool verbose = true,
}) async {
  if (verbose) print('🎨 Checking presentation layer...\n');

  final featurePath = 'lib/features/${feature ?? "settings"}';
  final providersPath = '$featurePath/presentation/providers';
  final widgetsPath = '$featurePath/presentation/widgets';
  final screensPath = '$featurePath/presentation/screens';

  // Check for notifier
  var hasNotifier = false;
  if (_directoryExists(providersPath)) {
    final providerFiles = Directory(providersPath)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('.g.dart'));

    for (final file in providerFiles) {
      final content = _readFile(file.path);
      if (content.contains('AccountDeletionNotifier') ||
          content.contains('account_deletion') ||
          content.contains('deleteAccount')) {
        hasNotifier = true;
        passed.add('Presentation: AccountDeletionNotifier found');

        // Check for disposal safety
        if (!content.contains('_disposed') && !content.contains('onDispose')) {
          warnings.add(AuditIssue(
            category: 'Presentation',
            file: file.path,
            message: 'Notifier may lack disposal safety',
            fix: 'Add _disposed flag and check after async operations',
          ));
        }
        break;
      }
    }
  }

  if (!hasNotifier) {
    issues.add(AuditIssue(
      category: 'Presentation',
      message: 'No AccountDeletionNotifier found',
      fix: 'Create notifier at $providersPath/account_deletion_notifier.dart',
    ));
  }

  // Check for dialog
  var hasDialog = false;
  if (_directoryExists(widgetsPath)) {
    final widgetFiles = Directory(widgetsPath)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in widgetFiles) {
      final content = _readFile(file.path);
      if (content.contains('DeleteAccountDialog') ||
          content.contains('delete_account_dialog')) {
        hasDialog = true;
        passed.add('Presentation: DeleteAccountDialog found');

        // Check for barrierDismissible: false
        if (!content.contains('barrierDismissible: false')) {
          warnings.add(AuditIssue(
            category: 'Presentation',
            file: file.path,
            message: 'Dialog may be accidentally dismissible',
            fix: 'Add barrierDismissible: false to showDialog',
          ));
        }
        break;
      }
    }
  }

  if (!hasDialog) {
    issues.add(AuditIssue(
      category: 'Presentation',
      message: 'No DeleteAccountDialog found',
      fix: 'Create dialog at $widgetsPath/delete_account_dialog.dart',
    ));
  }

  // Check for button
  var hasButton = false;
  if (_directoryExists(widgetsPath)) {
    final widgetFiles = Directory(widgetsPath)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in widgetFiles) {
      final content = _readFile(file.path);
      if (content.contains('DeleteAccountButton') ||
          content.contains('delete_account_button')) {
        hasButton = true;
        passed.add('Presentation: DeleteAccountButton found');
        break;
      }
    }
  }

  if (!hasButton) {
    issues.add(AuditIssue(
      category: 'Presentation',
      message: 'No DeleteAccountButton found',
      fix: 'Create button at $widgetsPath/delete_account_button.dart',
    ));
  }

  // Check settings screen integration
  if (_directoryExists(screensPath)) {
    final screenFiles = Directory(screensPath)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('settings') && f.path.endsWith('.dart'));

    for (final file in screenFiles) {
      final content = _readFile(file.path);
      if (content.contains('DeleteAccountButton') ||
          content.contains('deleteAccount') ||
          content.contains('delete_account')) {
        passed.add('Presentation: Delete account integrated in settings screen');
      } else {
        warnings.add(AuditIssue(
          category: 'Presentation',
          file: file.path,
          message: 'Settings screen may not have delete account option',
          fix: 'Add DeleteAccountButton to settings screen',
        ));
      }
    }
  }

  if (verbose) print('');
}

Future<void> _checkLocalization(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  String? feature,
  bool verbose = true,
}) async {
  if (verbose) print('🌍 Checking localization...\n');

  final featurePath = 'lib/features/${feature ?? "settings"}';
  final i18nPath = '$featurePath/i18n';

  if (_directoryExists(i18nPath)) {
    final i18nFiles = Directory(i18nPath)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml'));

    var hasDeleteStrings = false;
    for (final file in i18nFiles) {
      final content = _readFile(file.path);
      if (content.contains('deleteAccount') || content.contains('delete_account')) {
        hasDeleteStrings = true;
        passed.add('Localization: Delete account strings found');

        // Check for required strings
        final requiredStrings = ['title', 'warning', 'button', 'cancel'];
        for (final str in requiredStrings) {
          if (!content.contains(str)) {
            warnings.add(AuditIssue(
              category: 'Localization',
              file: file.path,
              message: 'May be missing "$str" string for delete account',
              fix: 'Add $str to deleteAccount section in i18n file',
            ));
          }
        }
        break;
      }
    }

    if (!hasDeleteStrings) {
      warnings.add(AuditIssue(
        category: 'Localization',
        message: 'No delete account localization strings found',
        fix: 'Add deleteAccount section to i18n files',
      ));
    }
  } else {
    warnings.add(AuditIssue(
      category: 'Localization',
      message: 'No i18n directory found for feature',
      fix: 'Create $i18nPath with localization files',
    ));
  }

  if (verbose) print('');
}

Future<void> _checkCompliance(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  String? feature,
  bool verbose = true,
}) async {
  if (verbose) print('✅ Checking compliance...\n');

  final featurePath = 'lib/features/${feature ?? "settings"}';

  // Check if delete is easy to find (in settings)
  if (_directoryExists('$featurePath/presentation/screens')) {
    final hasSettingsScreen = Directory('$featurePath/presentation/screens')
        .listSync()
        .whereType<File>()
        .any((f) => f.path.contains('settings'));

    if (hasSettingsScreen) {
      passed.add('Compliance: Delete option in settings (App Store requirement)');
    } else {
      issues.add(AuditIssue(
        category: 'Compliance',
        message: 'No settings screen found',
        fix: 'Create settings screen with delete account option',
      ));
    }
  }

  // Check for confirmation dialog (not just a button)
  final widgetsPath = '$featurePath/presentation/widgets';
  if (_directoryExists(widgetsPath)) {
    final hasConfirmation = Directory(widgetsPath)
        .listSync()
        .whereType<File>()
        .any((f) {
          final content = _readFile(f.path);
          return content.contains('AlertDialog') ||
                 content.contains('showDialog') ||
                 content.contains('Dialog');
        });

    if (hasConfirmation) {
      passed.add('Compliance: Confirmation dialog exists');
    } else {
      issues.add(AuditIssue(
        category: 'Compliance',
        message: 'No confirmation dialog for deletion',
        fix: 'Add confirmation dialog before deletion',
      ));
    }
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
    print('See: .claude/skills/account-deletion/SKILL.md');
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
Account Deletion Audit Tool

Checks your Flutter project for account deletion implementation completeness.

USAGE:
  dart run .claude/skills/account-deletion/scripts/check.dart [options]

OPTIONS:
  --feature <name>  Feature containing settings (default: settings)
  --json            Output as JSON (for CI)
  -h, --help        Show this help

EXAMPLES:
  dart run .claude/skills/account-deletion/scripts/check.dart
  dart run .claude/skills/account-deletion/scripts/check.dart --feature settings
  dart run .claude/skills/account-deletion/scripts/check.dart --json

CHECKS PERFORMED:
  Domain Layer:
    • AccountDeletionFailure sealed class exists
    • Required failure types present
    • Repository interface has deleteAccount method

  Data Layer:
    • Repository implementation exists
    • deleteAccount implemented
    • Local data cleanup implemented

  Presentation Layer:
    • AccountDeletionNotifier exists
    • DeleteAccountDialog exists
    • DeleteAccountButton exists
    • Settings screen integration

  Localization:
    • Delete account strings in i18n files

  Compliance:
    • Delete option in settings (App Store)
    • Confirmation dialog exists

SEE ALSO:
  .claude/skills/account-deletion/SKILL.md
  .claude/skills/account-deletion/checklist.md
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

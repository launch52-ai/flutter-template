#!/usr/bin/env dart
// ignore_for_file: avoid_print
// CI/CD Setup Validation Script
//
// Usage:
//   dart run .claude/skills/ci-cd/scripts/check.dart
//   dart run .claude/skills/ci-cd/scripts/check.dart --verbose
//   dart run .claude/skills/ci-cd/scripts/check.dart --fix
//   dart run .claude/skills/ci-cd/scripts/check.dart --json
//   dart run .claude/skills/ci-cd/scripts/check.dart --help

import 'dart:io';

void main(List<String> args) {
  final help = args.contains('--help') || args.contains('-h');
  final verbose = args.contains('--verbose') || args.contains('-v');
  final fix = args.contains('--fix');
  final jsonOutput = args.contains('--json');

  if (help) {
    _printHelp();
    return;
  }

  if (!jsonOutput) {
    print('CI/CD Setup Validator');
    print('=' * 50);
    print('');
  }

  final results = <CheckResult>[];

  // Check GitHub Actions workflows
  results.addAll(_checkGitHubWorkflows(verbose));

  // Check Fastlane setup
  results.addAll(_checkFastlaneSetup(verbose));

  // Check version format
  results.addAll(_checkVersioning(verbose));

  // Check .gitignore
  results.addAll(_checkGitignore(verbose));

  // Check scripts
  results.addAll(_checkScripts(verbose));

  // Summary
  final passed = results.where((r) => r.status == CheckStatus.pass).length;
  final warnings = results.where((r) => r.status == CheckStatus.warning).length;
  final failed = results.where((r) => r.status == CheckStatus.fail).length;
  final skipped = results.where((r) => r.status == CheckStatus.skip).length;

  if (jsonOutput) {
    _printJsonResults(results, passed, warnings, failed, skipped);
  } else {
    print('');
    print('=' * 50);
    print('Summary');
    print('=' * 50);

    print('');
    print('  Passed:   $passed');
    print('  Warnings: $warnings');
    print('  Failed:   $failed');
    print('  Skipped:  $skipped');
    print('');

    if (failed > 0) {
      print('Some checks failed. See details above.');
      print('');
      print('Quick fixes:');
      for (final result in results.where((r) => r.status == CheckStatus.fail)) {
        if (result.fix != null) {
          print('  - ${result.fix}');
        }
      }
    } else if (warnings > 0) {
      print('All required checks passed with warnings.');
    } else {
      print('All checks passed!');
    }
  }

  exit(failed > 0 ? 1 : 0);
}

// ============================================================================
// GitHub Workflows Checks
// ============================================================================

List<CheckResult> _checkGitHubWorkflows(bool verbose) {
  final results = <CheckResult>[];

  _printSection('GitHub Actions Workflows');

  final workflowsDir = Directory('.github/workflows');

  // Check if workflows directory exists
  if (!workflowsDir.existsSync()) {
    results.add(CheckResult(
      name: 'Workflows directory',
      status: CheckStatus.fail,
      message: '.github/workflows directory not found',
      fix: 'mkdir -p .github/workflows',
    ));
    _printResult(results.last);
    return results;
  }

  results.add(CheckResult(
    name: 'Workflows directory',
    status: CheckStatus.pass,
    message: '.github/workflows exists',
  ));
  _printResult(results.last);

  // Check for CI workflow
  final ciWorkflow = File('.github/workflows/ci.yml');
  if (!ciWorkflow.existsSync()) {
    results.add(CheckResult(
      name: 'CI workflow',
      status: CheckStatus.fail,
      message: 'ci.yml not found - PRs won\'t be validated',
      fix: 'Run: dart run .claude/skills/ci-cd/scripts/setup.dart',
    ));
  } else {
    final content = ciWorkflow.readAsStringSync();
    final hasFlutterAction = content.contains('subosito/flutter-action');
    final hasCache = content.contains('cache: true') || content.contains('actions/cache');
    final hasAnalyze = content.contains('flutter analyze');
    final hasTest = content.contains('flutter test');

    if (!hasFlutterAction) {
      results.add(CheckResult(
        name: 'CI workflow - Flutter action',
        status: CheckStatus.warning,
        message: 'Consider using subosito/flutter-action for caching',
      ));
    }

    if (!hasCache) {
      results.add(CheckResult(
        name: 'CI workflow - Caching',
        status: CheckStatus.warning,
        message: 'No caching detected - builds may be slow',
      ));
    }

    if (!hasAnalyze || !hasTest) {
      results.add(CheckResult(
        name: 'CI workflow - Steps',
        status: CheckStatus.warning,
        message: 'Missing analyze or test steps',
      ));
    }

    results.add(CheckResult(
      name: 'CI workflow',
      status: CheckStatus.pass,
      message: 'ci.yml exists',
    ));
  }
  _printResult(results.last);

  // Check for deployment workflows
  final deployWorkflows = [
    'deploy-firebase-android.yml',
    'deploy-firebase-ios.yml',
    'deploy-testflight.yml',
    'deploy-playstore.yml',
  ];

  var hasAnyDeploy = false;
  for (final workflow in deployWorkflows) {
    if (File('.github/workflows/$workflow').existsSync()) {
      hasAnyDeploy = true;
      if (verbose) {
        results.add(CheckResult(
          name: 'Deploy workflow - $workflow',
          status: CheckStatus.pass,
          message: 'Found',
        ));
        _printResult(results.last);
      }
    }
  }

  if (!hasAnyDeploy) {
    results.add(CheckResult(
      name: 'Deploy workflows',
      status: CheckStatus.skip,
      message: 'No deployment workflows found (optional)',
    ));
    _printResult(results.last);
  } else {
    results.add(CheckResult(
      name: 'Deploy workflows',
      status: CheckStatus.pass,
      message: 'Deployment workflows configured',
    ));
    _printResult(results.last);
  }

  return results;
}

// ============================================================================
// Fastlane Checks
// ============================================================================

List<CheckResult> _checkFastlaneSetup(bool verbose) {
  final results = <CheckResult>[];

  _printSection('Fastlane Setup');

  // iOS Fastlane
  final iosFastfile = File('ios/fastlane/Fastfile');
  final iosGemfile = File('ios/Gemfile');

  if (iosFastfile.existsSync()) {
    results.add(CheckResult(
      name: 'iOS Fastfile',
      status: CheckStatus.pass,
      message: 'ios/fastlane/Fastfile exists',
    ));

    if (!iosGemfile.existsSync()) {
      results.add(CheckResult(
        name: 'iOS Gemfile',
        status: CheckStatus.warning,
        message: 'ios/Gemfile not found - add for version locking',
      ));
    }

    // Check for match
    final content = iosFastfile.readAsStringSync();
    if (!content.contains('match')) {
      results.add(CheckResult(
        name: 'iOS Match',
        status: CheckStatus.warning,
        message: 'Consider using Fastlane Match for code signing',
      ));
    }
  } else {
    results.add(CheckResult(
      name: 'iOS Fastlane',
      status: CheckStatus.skip,
      message: 'Not configured (optional)',
    ));
  }
  _printResult(results.last);

  // Android Fastlane
  final androidFastfile = File('android/fastlane/Fastfile');
  final androidGemfile = File('android/Gemfile');

  if (androidFastfile.existsSync()) {
    results.add(CheckResult(
      name: 'Android Fastfile',
      status: CheckStatus.pass,
      message: 'android/fastlane/Fastfile exists',
    ));

    if (!androidGemfile.existsSync()) {
      results.add(CheckResult(
        name: 'Android Gemfile',
        status: CheckStatus.warning,
        message: 'android/Gemfile not found - add for version locking',
      ));
    }
  } else {
    results.add(CheckResult(
      name: 'Android Fastlane',
      status: CheckStatus.skip,
      message: 'Not configured (optional)',
    ));
  }
  _printResult(results.last);

  return results;
}

// ============================================================================
// Versioning Checks
// ============================================================================

List<CheckResult> _checkVersioning(bool verbose) {
  final results = <CheckResult>[];

  _printSection('Versioning');

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    results.add(CheckResult(
      name: 'pubspec.yaml',
      status: CheckStatus.fail,
      message: 'pubspec.yaml not found',
    ));
    _printResult(results.last);
    return results;
  }

  final content = pubspec.readAsStringSync();
  final versionMatch = RegExp(r'version:\s*(\d+\.\d+\.\d+\+\d+)').firstMatch(content);

  if (versionMatch == null) {
    final simpleMatch = RegExp(r'version:\s*(\d+\.\d+\.\d+)').firstMatch(content);
    if (simpleMatch != null) {
      results.add(CheckResult(
        name: 'Version format',
        status: CheckStatus.warning,
        message: 'Version missing build number (e.g., 1.0.0+1)',
        fix: 'Update version to include build number: version: 1.0.0+1',
      ));
    } else {
      results.add(CheckResult(
        name: 'Version format',
        status: CheckStatus.fail,
        message: 'Invalid version format in pubspec.yaml',
        fix: 'Add version: 1.0.0+1 to pubspec.yaml',
      ));
    }
  } else {
    results.add(CheckResult(
      name: 'Version format',
      status: CheckStatus.pass,
      message: 'Version: ${versionMatch.group(1)}',
    ));
  }
  _printResult(results.last);

  // Check for version bump script
  final bumpScript = File('scripts/bump_version.sh');
  final bumpScriptDart = File('scripts/bump_version.dart');

  if (bumpScript.existsSync() || bumpScriptDart.existsSync()) {
    results.add(CheckResult(
      name: 'Version bump script',
      status: CheckStatus.pass,
      message: 'Version bump script found',
    ));
  } else {
    results.add(CheckResult(
      name: 'Version bump script',
      status: CheckStatus.skip,
      message: 'No bump script (optional - see versioning-guide.md)',
    ));
  }
  _printResult(results.last);

  // Check for CHANGELOG.md
  final changelog = File('CHANGELOG.md');
  if (changelog.existsSync()) {
    results.add(CheckResult(
      name: 'CHANGELOG.md',
      status: CheckStatus.pass,
      message: 'Changelog exists',
    ));
  } else {
    results.add(CheckResult(
      name: 'CHANGELOG.md',
      status: CheckStatus.skip,
      message: 'No changelog (recommended for releases)',
    ));
  }
  _printResult(results.last);

  return results;
}

// ============================================================================
// Gitignore Checks
// ============================================================================

List<CheckResult> _checkGitignore(bool verbose) {
  final results = <CheckResult>[];

  _printSection('Security (.gitignore)');

  final gitignore = File('.gitignore');
  if (!gitignore.existsSync()) {
    results.add(CheckResult(
      name: '.gitignore',
      status: CheckStatus.fail,
      message: '.gitignore not found',
    ));
    _printResult(results.last);
    return results;
  }

  final content = gitignore.readAsStringSync();

  // Check for sensitive files
  final sensitivePatterns = {
    'key.properties': 'Android signing config',
    '*.jks': 'Java keystore',
    '*.keystore': 'Android keystore',
    '.env': 'Environment variables',
    'service-account.json': 'Google service account',
    '*.p8': 'Apple API keys',
  };

  var allIgnored = true;
  for (final entry in sensitivePatterns.entries) {
    final pattern = entry.key;
    final description = entry.value;

    // Simple check - could be improved with proper gitignore parsing
    final isIgnored = content.contains(pattern) ||
        content.contains(pattern.replaceAll('*', '')) ||
        (pattern.startsWith('*.') && content.contains(pattern.substring(1)));

    if (!isIgnored) {
      allIgnored = false;
      if (verbose) {
        results.add(CheckResult(
          name: 'Gitignore - $pattern',
          status: CheckStatus.warning,
          message: '$description may not be ignored',
        ));
        _printResult(results.last);
      }
    }
  }

  if (allIgnored) {
    results.add(CheckResult(
      name: 'Sensitive files',
      status: CheckStatus.pass,
      message: 'Sensitive files appear to be ignored',
    ));
  } else {
    results.add(CheckResult(
      name: 'Sensitive files',
      status: CheckStatus.warning,
      message: 'Some sensitive files may not be in .gitignore',
    ));
  }
  _printResult(results.last);

  return results;
}

// ============================================================================
// Scripts Checks
// ============================================================================

List<CheckResult> _checkScripts(bool verbose) {
  final results = <CheckResult>[];

  _printSection('Scripts Directory');

  final scriptsDir = Directory('scripts');
  if (!scriptsDir.existsSync()) {
    results.add(CheckResult(
      name: 'Scripts directory',
      status: CheckStatus.skip,
      message: 'scripts/ not found (optional)',
    ));
    _printResult(results.last);
    return results;
  }

  results.add(CheckResult(
    name: 'Scripts directory',
    status: CheckStatus.pass,
    message: 'scripts/ exists',
  ));
  _printResult(results.last);

  // Check for common scripts
  final commonScripts = [
    'bump_version.sh',
    'bump_version.dart',
    'generate_changelog.sh',
  ];

  for (final script in commonScripts) {
    final file = File('scripts/$script');
    if (file.existsSync()) {
      // Check if executable (Unix only)
      if (!Platform.isWindows && script.endsWith('.sh')) {
        final result = Process.runSync('test', ['-x', file.path]);
        if (result.exitCode != 0) {
          results.add(CheckResult(
            name: 'Script - $script',
            status: CheckStatus.warning,
            message: 'Script exists but is not executable',
            fix: 'chmod +x scripts/$script',
          ));
          _printResult(results.last);
        }
      }
    }
  }

  return results;
}

// ============================================================================
// Utilities
// ============================================================================

void _printSection(String title) {
  print('');
  print('$title');
  print('-' * 40);
}

void _printResult(CheckResult result) {
  final icon = switch (result.status) {
    CheckStatus.pass => '✓',
    CheckStatus.warning => '⚠',
    CheckStatus.fail => '✗',
    CheckStatus.skip => '○',
  };

  final color = switch (result.status) {
    CheckStatus.pass => '\x1B[32m',    // Green
    CheckStatus.warning => '\x1B[33m', // Yellow
    CheckStatus.fail => '\x1B[31m',    // Red
    CheckStatus.skip => '\x1B[90m',    // Gray
  };

  const reset = '\x1B[0m';

  print('$color$icon$reset ${result.name}: ${result.message}');
}

enum CheckStatus { pass, warning, fail, skip }

class CheckResult {
  final String name;
  final CheckStatus status;
  final String message;
  final String? fix;

  CheckResult({
    required this.name,
    required this.status,
    required this.message,
    this.fix,
  });
}

void _printHelp() {
  print('''
CI/CD Setup Validator

Validates CI/CD configuration for Flutter projects.

USAGE:
  dart run .claude/skills/ci-cd/scripts/check.dart [options]

OPTIONS:
  -v, --verbose   Show detailed output for all checks
  --fix           Auto-fix simple issues (where possible)
  --json          Output results as JSON (for CI integration)
  -h, --help      Show this help message

CHECKS PERFORMED:
  GitHub Actions:
    • Workflows directory exists
    • CI workflow (ci.yml) configured
    • Flutter action and caching
    • Deployment workflows

  Fastlane:
    • iOS Fastfile and Gemfile
    • Android Fastfile and Gemfile
    • Match configuration

  Versioning:
    • pubspec.yaml version format
    • Version bump scripts
    • CHANGELOG.md

  Security:
    • Sensitive files in .gitignore

EXAMPLES:
  dart run .claude/skills/ci-cd/scripts/check.dart
  dart run .claude/skills/ci-cd/scripts/check.dart --verbose
  dart run .claude/skills/ci-cd/scripts/check.dart --json

SEE ALSO:
  .claude/skills/ci-cd/SKILL.md
''');
}

void _printJsonResults(
  List<CheckResult> results,
  int passed,
  int warnings,
  int failed,
  int skipped,
) {
  final jsonResults = results.map((r) => {
    'name': r.name,
    'status': r.status.name,
    'message': r.message,
    if (r.fix != null) 'fix': r.fix,
  }).toList();

  final output = {
    'valid': failed == 0,
    'summary': {
      'passed': passed,
      'warnings': warnings,
      'failed': failed,
      'skipped': skipped,
    },
    'results': jsonResults,
  };

  print(_jsonEncode(output));
}

String _jsonEncode(dynamic obj) {
  if (obj == null) return 'null';
  if (obj is String) return '"${obj.replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
  if (obj is num || obj is bool) return '$obj';
  if (obj is List) return '[${obj.map(_jsonEncode).join(',')}]';
  if (obj is Map) {
    final pairs = obj.entries.map((e) => '"${e.key}":${_jsonEncode(e.value)}');
    return '{${pairs.join(',')}}';
  }
  return 'null';
}

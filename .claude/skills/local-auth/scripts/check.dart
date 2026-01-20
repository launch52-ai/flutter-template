// Local Auth Skill - Validation Script
//
// Validates that local authentication is properly configured.
//
// Usage:
//   dart run .claude/skills/local-auth/scripts/check.dart
//   dart run .claude/skills/local-auth/scripts/check.dart --help
//   dart run .claude/skills/local-auth/scripts/check.dart --json
//
// Checks:
//   - Dependencies in pubspec.yaml
//   - iOS Info.plist configuration
//   - Android manifest permissions
//   - Core files exist
//   - Provider registration

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  // Handle --help
  if (args.contains('--help') || args.contains('-h')) {
    _printHelp();
    exit(0);
  }

  final jsonOutput = args.contains('--json');

  final results = <CheckResult>[];

  // Dependency checks
  results.add(_checkDependency());

  // Platform checks
  results.add(_checkiOSConfig());
  results.add(_checkAndroidConfig());
  results.add(_checkAndroidMainActivity());

  // Core file checks
  results.addAll(_checkCoreFiles());

  // Output results
  if (jsonOutput) {
    _printJson(results);
  } else {
    _printHuman(results);
  }

  // Exit with appropriate code
  final hasFailures = results.any((r) => r.status == CheckStatus.fail);
  exit(hasFailures ? 1 : 0);
}

void _printHelp() {
  print('''
Local Auth - Validation Script

Validates that local authentication is properly configured in a Flutter project.

USAGE:
  dart run .claude/skills/local-auth/scripts/check.dart [OPTIONS]

OPTIONS:
  --help, -h    Show this help message
  --json        Output results as JSON (for CI integration)

CHECKS:
  - local_auth dependency in pubspec.yaml
  - iOS Info.plist NSFaceIDUsageDescription
  - Android USE_BIOMETRIC permission
  - Android FlutterFragmentActivity
  - Core service and provider files

EXAMPLES:
  # Run validation with human-readable output
  dart run .claude/skills/local-auth/scripts/check.dart

  # Run validation with JSON output for CI
  dart run .claude/skills/local-auth/scripts/check.dart --json

EXIT CODES:
  0  All checks passed (or only warnings)
  1  One or more checks failed
''');
}

void _printJson(List<CheckResult> results) {
  int passed = 0;
  int failed = 0;
  int warnings = 0;
  int skipped = 0;

  for (final result in results) {
    switch (result.status) {
      case CheckStatus.pass:
        passed++;
      case CheckStatus.fail:
        failed++;
      case CheckStatus.warn:
        warnings++;
      case CheckStatus.skip:
        skipped++;
    }
  }

  final json = {
    'skill': 'local-auth',
    'summary': {
      'passed': passed,
      'failed': failed,
      'warnings': warnings,
      'skipped': skipped,
      'success': failed == 0,
    },
    'checks': results.map((r) {
      final check = <String, dynamic>{
        'name': r.name,
        'status': r.status.name,
      };
      if (r.message != null) check['message'] = r.message;
      return check;
    }).toList(),
  };

  print(jsonEncode(json));
}

void _printHuman(List<CheckResult> results) {
  print('Local Auth - Validation Check\n');

  int passed = 0;
  int failed = 0;
  int warnings = 0;

  for (final result in results) {
    final icon = switch (result.status) {
      CheckStatus.pass => ' ',
      CheckStatus.fail => ' ',
      CheckStatus.warn => ' ',
      CheckStatus.skip => ' ',
    };

    print('$icon ${result.name}');
    if (result.message != null) {
      print('   ${result.message}');
    }

    switch (result.status) {
      case CheckStatus.pass:
        passed++;
      case CheckStatus.fail:
        failed++;
      case CheckStatus.warn:
        warnings++;
      case CheckStatus.skip:
        break;
    }
  }

  print('\n${'=' * 50}');
  print('Results: $passed passed, $failed failed, $warnings warnings');

  if (failed > 0) {
    print('\n Some checks failed. Please fix the issues above.');
  } else if (warnings > 0) {
    print('\n All checks passed with warnings.');
  } else {
    print('\n All checks passed!');
  }
}

// =============================================================================
// Check Functions
// =============================================================================

CheckResult _checkDependency() {
  final pubspecFile = File('pubspec.yaml');

  if (!pubspecFile.existsSync()) {
    return CheckResult(
      name: 'local_auth dependency',
      status: CheckStatus.fail,
      message: 'pubspec.yaml not found',
    );
  }

  final content = pubspecFile.readAsStringSync();

  if (content.contains('local_auth:')) {
    final versionMatch = RegExp(r'local_auth:\s*\^?(\d+\.\d+\.\d+)')
        .firstMatch(content);

    if (versionMatch != null) {
      final version = versionMatch.group(1)!;
      final major = int.parse(version.split('.')[0]);

      if (major >= 2) {
        return CheckResult(
          name: 'local_auth dependency',
          status: CheckStatus.pass,
          message: 'Version $version',
        );
      } else {
        return CheckResult(
          name: 'local_auth dependency',
          status: CheckStatus.warn,
          message: 'Version $version - consider upgrading to ^2.3.0',
        );
      }
    }

    return CheckResult(
      name: 'local_auth dependency',
      status: CheckStatus.pass,
    );
  }

  return CheckResult(
    name: 'local_auth dependency',
    status: CheckStatus.fail,
    message: 'Add to pubspec.yaml: local_auth: ^2.3.0',
  );
}

CheckResult _checkiOSConfig() {
  final infoPlistFile = File('ios/Runner/Info.plist');

  if (!infoPlistFile.existsSync()) {
    return CheckResult(
      name: 'iOS NSFaceIDUsageDescription',
      status: CheckStatus.skip,
      message: 'iOS project not found',
    );
  }

  final content = infoPlistFile.readAsStringSync();

  if (content.contains('NSFaceIDUsageDescription')) {
    return CheckResult(
      name: 'iOS NSFaceIDUsageDescription',
      status: CheckStatus.pass,
    );
  }

  return CheckResult(
    name: 'iOS NSFaceIDUsageDescription',
    status: CheckStatus.fail,
    message: 'Add NSFaceIDUsageDescription to ios/Runner/Info.plist',
  );
}

CheckResult _checkAndroidConfig() {
  final manifestFile = File('android/app/src/main/AndroidManifest.xml');

  if (!manifestFile.existsSync()) {
    return CheckResult(
      name: 'Android USE_BIOMETRIC permission',
      status: CheckStatus.skip,
      message: 'Android project not found',
    );
  }

  final content = manifestFile.readAsStringSync();

  if (content.contains('USE_BIOMETRIC')) {
    return CheckResult(
      name: 'Android USE_BIOMETRIC permission',
      status: CheckStatus.pass,
    );
  }

  return CheckResult(
    name: 'Android USE_BIOMETRIC permission',
    status: CheckStatus.fail,
    message: 'Add USE_BIOMETRIC permission to AndroidManifest.xml',
  );
}

CheckResult _checkAndroidMainActivity() {
  final kotlinFile = _findFile('android/app/src/main/kotlin', 'MainActivity.kt');
  final javaFile = _findFile('android/app/src/main/java', 'MainActivity.java');

  final mainActivityFile = kotlinFile ?? javaFile;

  if (mainActivityFile == null) {
    return CheckResult(
      name: 'Android FlutterFragmentActivity',
      status: CheckStatus.skip,
      message: 'MainActivity not found',
    );
  }

  final content = mainActivityFile.readAsStringSync();

  if (content.contains('FlutterFragmentActivity')) {
    return CheckResult(
      name: 'Android FlutterFragmentActivity',
      status: CheckStatus.pass,
    );
  }

  if (content.contains('FlutterActivity')) {
    return CheckResult(
      name: 'Android FlutterFragmentActivity',
      status: CheckStatus.warn,
      message: 'Consider FlutterFragmentActivity for BiometricPrompt',
    );
  }

  return CheckResult(
    name: 'Android FlutterFragmentActivity',
    status: CheckStatus.warn,
    message: 'Could not determine Activity type',
  );
}

List<CheckResult> _checkCoreFiles() {
  final results = <CheckResult>[];

  final coreFiles = [
    ('LocalAuthService', 'lib/core/services/local_auth_service.dart'),
    ('LocalAuthProvider', 'lib/core/providers/local_auth_provider.dart'),
    ('LocalAuthSettings', 'lib/core/providers/local_auth_settings.dart'),
  ];

  for (final (name, path) in coreFiles) {
    final file = File(path);
    if (file.existsSync()) {
      results.add(CheckResult(
        name: name,
        status: CheckStatus.pass,
        message: path,
      ));
    } else {
      results.add(CheckResult(
        name: name,
        status: CheckStatus.fail,
        message: 'Missing: $path',
      ));
    }
  }

  return results;
}

// =============================================================================
// Helpers
// =============================================================================

File? _findFile(String directory, String filename) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return null;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith(filename)) {
      return entity;
    }
  }
  return null;
}

// =============================================================================
// Models
// =============================================================================

enum CheckStatus { pass, fail, warn, skip }

final class CheckResult {
  final String name;
  final CheckStatus status;
  final String? message;

  CheckResult({
    required this.name,
    required this.status,
    this.message,
  });
}

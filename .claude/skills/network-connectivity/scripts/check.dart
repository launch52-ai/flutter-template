// Network Connectivity Skill Validation Script
//
// Verifies that network connectivity monitoring is properly set up.
//
// Usage:
//   dart run .claude/skills/network-connectivity/scripts/check.dart
//   dart run .claude/skills/network-connectivity/scripts/check.dart --json
//   dart run .claude/skills/network-connectivity/scripts/check.dart --help

import 'dart:io';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _printHelp();
    return;
  }

  final jsonOutput = args.contains('--json');
  final issues = <Map<String, String>>[];
  final passed = <String>[];

  // Check 1: pubspec.yaml has connectivity_plus
  _check(
    'connectivity_plus dependency',
    () => _hasDependency('connectivity_plus'),
    issues,
    passed,
  );

  // Check 2: ConnectivityService exists
  _check(
    'ConnectivityService file exists',
    () => _fileExists('lib/core/services/connectivity_service.dart'),
    issues,
    passed,
  );

  // Check 3: Connectivity provider exists
  _check(
    'Connectivity provider file exists',
    () => _fileExists('lib/core/providers/connectivity_provider.dart'),
    issues,
    passed,
  );

  // Check 4: Generated provider file exists
  _check(
    'Connectivity provider generated file exists',
    () => _fileExists('lib/core/providers/connectivity_provider.g.dart'),
    issues,
    passed,
    suggestion: 'Run: dart run build_runner build --delete-conflicting-outputs',
  );

  // Check 5: Banner widget exists
  _check(
    'ConnectivityBanner widget exists',
    () => _fileExists('lib/core/widgets/connectivity_banner.dart'),
    issues,
    passed,
  );

  // Check 6: Wrapper widget exists
  _check(
    'ConnectivityWrapper widget exists',
    () => _fileExists('lib/core/widgets/connectivity_wrapper.dart'),
    issues,
    passed,
  );

  // Check 7: main.dart uses ConnectivityWrapper
  _check(
    'main.dart uses ConnectivityWrapper',
    () => _fileContains('lib/main.dart', 'ConnectivityWrapper'),
    issues,
    passed,
    suggestion: 'Wrap MaterialApp with ConnectivityWrapper in main.dart',
  );

  // Check 8: Classes are final
  _check(
    'ConnectivityService is final class',
    () => _fileContains(
      'lib/core/services/connectivity_service.dart',
      'final class ConnectivityService',
    ),
    issues,
    passed,
    suggestion: 'Make ConnectivityService a final class',
  );

  // Output results
  if (jsonOutput) {
    _printJsonOutput(issues, passed);
  } else {
    _printHumanOutput(issues, passed);
  }

  // Exit with error code if issues found
  if (issues.isNotEmpty) {
    exit(1);
  }
}

void _check(
  String name,
  bool Function() check,
  List<Map<String, String>> issues,
  List<String> passed, {
  String? suggestion,
}) {
  try {
    if (check()) {
      passed.add(name);
    } else {
      issues.add({
        'check': name,
        'status': 'failed',
        if (suggestion != null) 'suggestion': suggestion,
      });
    }
  } catch (e) {
    issues.add({
      'check': name,
      'status': 'error',
      'error': e.toString(),
    });
  }
}

bool _hasDependency(String packageName) {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) return false;

  final content = pubspec.readAsStringSync();
  // Check for package in dependencies section
  final dependenciesMatch = RegExp(
    r'dependencies:\s*([\s\S]*?)(?=dev_dependencies:|flutter:|$)',
  ).firstMatch(content);

  if (dependenciesMatch == null) return false;

  final dependencies = dependenciesMatch.group(1) ?? '';
  return dependencies.contains(RegExp('$packageName:'));
}

bool _fileExists(String path) {
  return File(path).existsSync();
}

bool _fileContains(String path, String content) {
  final file = File(path);
  if (!file.existsSync()) return false;
  return file.readAsStringSync().contains(content);
}

void _printHelp() {
  print('''
Network Connectivity Validation Script

Checks that network connectivity monitoring is properly configured.

Usage:
  dart run .claude/skills/network-connectivity/scripts/check.dart [options]

Options:
  --help, -h    Show this help message
  --json        Output results as JSON

Checks performed:
  1. connectivity_plus is in pubspec.yaml
  2. ConnectivityService exists in lib/core/services/
  3. Connectivity providers exist in lib/core/providers/
  4. Generated provider file exists (.g.dart)
  5. ConnectivityBanner widget exists
  6. ConnectivityWrapper widget exists
  7. main.dart uses ConnectivityWrapper
  8. Classes follow final class convention
''');
}

void _printHumanOutput(
  List<Map<String, String>> issues,
  List<String> passed,
) {
  print('\n=== Network Connectivity Check ===\n');

  if (passed.isNotEmpty) {
    print('PASSED (${passed.length}):');
    for (final check in passed) {
      print('  [OK] $check');
    }
    print('');
  }

  if (issues.isNotEmpty) {
    print('ISSUES (${issues.length}):');
    for (final issue in issues) {
      print('  [X] ${issue['check']}');
      if (issue['suggestion'] != null) {
        print('      Suggestion: ${issue['suggestion']}');
      }
      if (issue['error'] != null) {
        print('      Error: ${issue['error']}');
      }
    }
    print('');
  }

  if (issues.isEmpty) {
    print('All checks passed! Network connectivity is properly configured.');
  } else {
    print('${issues.length} issue(s) found. See suggestions above.');
  }
  print('');
}

void _printJsonOutput(
  List<Map<String, String>> issues,
  List<String> passed,
) {
  final result = {
    'passed': passed,
    'issues': issues,
    'summary': {
      'total': passed.length + issues.length,
      'passed': passed.length,
      'failed': issues.length,
    },
  };

  // Simple JSON output (no external dependencies)
  print('{');
  print('  "passed": [${passed.map((p) => '"$p"').join(', ')}],');
  print('  "issues": [');
  for (var i = 0; i < issues.length; i++) {
    final issue = issues[i];
    final comma = i < issues.length - 1 ? ',' : '';
    final parts = <String>[];
    issue.forEach((key, value) {
      parts.add('"$key": "${value.replaceAll('"', '\\"')}"');
    });
    print('    {${parts.join(', ')}}$comma');
  }
  print('  ],');
  print('  "summary": {');
  print('    "total": ${passed.length + issues.length},');
  print('    "passed": ${passed.length},');
  print('    "failed": ${issues.length}');
  print('  }');
  print('}');
}

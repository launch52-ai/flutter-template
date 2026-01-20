#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Flavors audit script for Flutter projects.
///
/// Validates environment flavor configuration:
/// - Environment files (.env.dev, .env.staging, .env.prod)
/// - Android productFlavors in build.gradle
/// - iOS xcconfig files and schemes
/// - Dart FlavorConfig class
///
/// Usage:
///   dart run .claude/skills/flavors/scripts/check.dart
///   dart run .claude/skills/flavors/scripts/check.dart --json
///   dart run .claude/skills/flavors/scripts/check.dart --help
void main(List<String> args) async {
  final help = args.contains('--help') || args.contains('-h');
  final jsonOutput = args.contains('--json');

  if (help) {
    _printHelp();
    return;
  }

  if (!jsonOutput) {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('  Flavors Configuration Audit');
    print('═══════════════════════════════════════════════════════════');
    print('');
  }

  final issues = <AuditIssue>[];
  final warnings = <AuditIssue>[];
  final passed = <String>[];

  // Run checks
  await _checkEnvironmentFiles(issues, warnings, passed, verbose: !jsonOutput);
  await _checkAndroidConfig(issues, warnings, passed, verbose: !jsonOutput);
  await _checkIosConfig(issues, warnings, passed, verbose: !jsonOutput);
  await _checkDartConfig(issues, warnings, passed, verbose: !jsonOutput);
  await _checkGitignore(issues, warnings, passed, verbose: !jsonOutput);

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

Future<void> _checkEnvironmentFiles(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) async {
  if (verbose) print('📁 Checking environment files...\n');

  final requiredFiles = ['.env.dev', '.env.prod'];
  final optionalFiles = ['.env.staging'];
  final requiredKeys = ['FLAVOR', 'APP_NAME', 'API_URL'];

  // Check required env files exist
  for (final file in requiredFiles) {
    if (_fileExists(file)) {
      passed.add('Environment: $file exists');

      // Check required keys
      final content = _readFile(file);
      for (final key in requiredKeys) {
        if (!content.contains('$key=')) {
          warnings.add(AuditIssue(
            category: 'Environment',
            file: file,
            message: 'Missing required key: $key',
            fix: 'Add $key=<value> to $file',
          ));
        }
      }
    } else {
      issues.add(AuditIssue(
        category: 'Environment',
        file: file,
        message: 'Required environment file missing',
        fix: 'Create $file from .env.example or skill templates',
      ));
    }
  }

  // Check optional files
  for (final file in optionalFiles) {
    if (_fileExists(file)) {
      passed.add('Environment: $file exists (optional)');
    } else if (verbose) {
      print('   ℹ️  $file not found (optional for 2-flavor setup)');
    }
  }

  // Check .env.example exists
  if (_fileExists('.env.example')) {
    passed.add('Environment: .env.example exists');
  } else {
    warnings.add(AuditIssue(
      category: 'Environment',
      file: '.env.example',
      message: '.env.example not found',
      fix: 'Create .env.example as a template (without secret values)',
    ));
  }

  if (verbose) print('');
}

Future<void> _checkAndroidConfig(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) async {
  if (verbose) print('🤖 Checking Android configuration...\n');

  final buildGradle = 'android/app/build.gradle';

  if (!_fileExists(buildGradle)) {
    if (_directoryExists('android')) {
      issues.add(AuditIssue(
        category: 'Android',
        file: buildGradle,
        message: 'build.gradle not found',
        fix: 'Ensure Android module exists at android/app/build.gradle',
      ));
    } else if (verbose) {
      print('   ℹ️  Android module not found (may be a web-only project)');
    }
    if (verbose) print('');
    return;
  }

  final content = _readFile(buildGradle);

  // Check for flavorDimensions
  if (content.contains('flavorDimensions')) {
    passed.add('Android: flavorDimensions defined');
  } else {
    issues.add(AuditIssue(
      category: 'Android',
      file: buildGradle,
      message: 'flavorDimensions not defined',
      fix: 'Add flavorDimensions "environment" to android {} block',
    ));
  }

  // Check for productFlavors
  if (content.contains('productFlavors')) {
    passed.add('Android: productFlavors block exists');

    // Check for specific flavors
    final flavors = ['dev', 'prod'];
    for (final flavor in flavors) {
      // Look for flavor definition (name followed by { or whitespace)
      final flavorPattern = RegExp(r'\b' + flavor + r'\s*\{');
      if (flavorPattern.hasMatch(content)) {
        passed.add('Android: $flavor flavor defined');
      } else {
        issues.add(AuditIssue(
          category: 'Android',
          file: buildGradle,
          line: _findLine(content, 'productFlavors'),
          message: '$flavor flavor not defined in productFlavors',
          fix: 'Add $flavor { ... } inside productFlavors block',
        ));
      }
    }

    // Check for applicationIdSuffix
    if (content.contains('applicationIdSuffix')) {
      passed.add('Android: applicationIdSuffix configured');
    } else {
      warnings.add(AuditIssue(
        category: 'Android',
        file: buildGradle,
        message: 'applicationIdSuffix not found',
        fix: 'Add applicationIdSuffix ".dev" to dev flavor for separate app IDs',
      ));
    }

    // Check for resValue app_name
    if (content.contains('resValue') && content.contains('app_name')) {
      passed.add('Android: app_name resValue configured');
    } else {
      warnings.add(AuditIssue(
        category: 'Android',
        file: buildGradle,
        message: 'app_name resValue not found',
        fix: 'Add resValue "string", "app_name", "..." to each flavor',
      ));
    }
  } else {
    issues.add(AuditIssue(
      category: 'Android',
      file: buildGradle,
      message: 'productFlavors block not found',
      fix: 'Add productFlavors { dev {...} prod {...} } to android {} block',
    ));
  }

  // Check AndroidManifest uses @string/app_name
  final manifest = 'android/app/src/main/AndroidManifest.xml';
  if (_fileExists(manifest)) {
    final manifestContent = _readFile(manifest);
    if (manifestContent.contains('@string/app_name')) {
      passed.add('Android: AndroidManifest uses @string/app_name');
    } else if (manifestContent.contains('android:label=')) {
      warnings.add(AuditIssue(
        category: 'Android',
        file: manifest,
        message: 'android:label is hardcoded',
        fix: 'Change android:label to "@string/app_name"',
      ));
    }
  }

  if (verbose) print('');
}

Future<void> _checkIosConfig(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) async {
  if (verbose) print('🍎 Checking iOS configuration...\n');

  if (!_directoryExists('ios')) {
    if (verbose) print('   ℹ️  iOS module not found (may be a web-only project)');
    if (verbose) print('');
    return;
  }

  // Check xcconfig files
  final requiredConfigs = ['Dev.xcconfig', 'Prod.xcconfig'];
  final optionalConfigs = ['Staging.xcconfig'];

  for (final config in requiredConfigs) {
    final path = 'ios/Flutter/$config';
    if (_fileExists(path)) {
      passed.add('iOS: $config exists');

      // Check content
      final content = _readFile(path);
      if (content.contains('PRODUCT_BUNDLE_IDENTIFIER')) {
        passed.add('iOS: $config has PRODUCT_BUNDLE_IDENTIFIER');
      } else {
        issues.add(AuditIssue(
          category: 'iOS',
          file: path,
          message: 'PRODUCT_BUNDLE_IDENTIFIER not set',
          fix: 'Add PRODUCT_BUNDLE_IDENTIFIER=com.example.myapp to $config',
        ));
      }

      if (content.contains('DISPLAY_NAME')) {
        passed.add('iOS: $config has DISPLAY_NAME');
      } else {
        warnings.add(AuditIssue(
          category: 'iOS',
          file: path,
          message: 'DISPLAY_NAME not set',
          fix: 'Add DISPLAY_NAME=My App to $config',
        ));
      }

      if (content.contains('FLAVOR=')) {
        passed.add('iOS: $config has FLAVOR');
      } else {
        warnings.add(AuditIssue(
          category: 'iOS',
          file: path,
          message: 'FLAVOR variable not set',
          fix: 'Add FLAVOR=${config.replaceAll('.xcconfig', '').toLowerCase()} for Firebase script',
        ));
      }
    } else {
      issues.add(AuditIssue(
        category: 'iOS',
        file: path,
        message: 'xcconfig file missing',
        fix: 'Create $path from skill templates',
      ));
    }
  }

  for (final config in optionalConfigs) {
    final path = 'ios/Flutter/$config';
    if (_fileExists(path)) {
      passed.add('iOS: $config exists (optional)');
    } else if (verbose) {
      print('   ℹ️  $config not found (optional for 2-flavor setup)');
    }
  }

  // Check for Xcode schemes
  final schemesDir = 'ios/Runner.xcodeproj/xcshareddata/xcschemes';
  if (_directoryExists(schemesDir)) {
    final schemes = Directory(schemesDir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.xcscheme'))
        .map((f) => f.path.split('/').last.replaceAll('.xcscheme', ''))
        .toList();

    final requiredSchemes = ['dev', 'prod'];
    for (final scheme in requiredSchemes) {
      if (schemes.any((s) => s.toLowerCase() == scheme)) {
        passed.add('iOS: $scheme scheme exists');
      } else {
        warnings.add(AuditIssue(
          category: 'iOS',
          file: schemesDir,
          message: '$scheme scheme not found',
          fix: 'Create $scheme.xcscheme in Xcode or manually',
        ));
      }
    }
  } else {
    warnings.add(AuditIssue(
      category: 'iOS',
      file: schemesDir,
      message: 'Xcode schemes directory not found',
      fix: 'Schemes may need to be created in Xcode',
    ));
  }

  if (verbose) print('');
}

Future<void> _checkDartConfig(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) async {
  if (verbose) print('🎯 Checking Dart configuration...\n');

  // Check for FlavorConfig
  final possiblePaths = [
    'lib/core/config/flavor_config.dart',
    'lib/core/flavor_config.dart',
    'lib/config/flavor_config.dart',
    'lib/flavor_config.dart',
  ];

  String? foundPath;
  for (final path in possiblePaths) {
    if (_fileExists(path)) {
      foundPath = path;
      break;
    }
  }

  if (foundPath != null) {
    passed.add('Dart: FlavorConfig exists at $foundPath');

    final content = _readFile(foundPath);

    // Check for String.fromEnvironment usage
    if (content.contains('String.fromEnvironment')) {
      passed.add('Dart: Uses String.fromEnvironment');
    } else {
      warnings.add(AuditIssue(
        category: 'Dart',
        file: foundPath,
        message: 'Not using String.fromEnvironment',
        fix: 'Use String.fromEnvironment for compile-time variables',
      ));
    }

    // Check for flutter_dotenv (should NOT be used with flavors)
    if (content.contains('flutter_dotenv') || content.contains('dotenv')) {
      warnings.add(AuditIssue(
        category: 'Dart',
        file: foundPath,
        message: 'Using flutter_dotenv with flavors',
        fix: 'Remove flutter_dotenv usage; use --dart-define-from-file instead',
      ));
    }

    // Check for flavor helpers
    if (content.contains('isDev') && content.contains('isProd')) {
      passed.add('Dart: Has isDev/isProd helpers');
    } else {
      warnings.add(AuditIssue(
        category: 'Dart',
        file: foundPath,
        message: 'Missing isDev/isProd helper getters',
        fix: 'Add convenience getters: isDev, isStaging, isProd',
      ));
    }
  } else {
    issues.add(AuditIssue(
      category: 'Dart',
      file: 'lib/core/config/flavor_config.dart',
      message: 'FlavorConfig not found',
      fix: 'Create FlavorConfig class from skill reference files',
    ));
  }

  // Check main.dart doesn't use flutter_dotenv
  if (_fileExists('lib/main.dart')) {
    final mainContent = _readFile('lib/main.dart');
    if (mainContent.contains('dotenv.load') || mainContent.contains('DotEnv')) {
      warnings.add(AuditIssue(
        category: 'Dart',
        file: 'lib/main.dart',
        message: 'main.dart uses flutter_dotenv',
        fix: 'Remove flutter_dotenv; values come from --dart-define-from-file',
      ));
    }
  }

  if (verbose) print('');
}

Future<void> _checkGitignore(
  List<AuditIssue> issues,
  List<AuditIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) async {
  if (verbose) print('🔒 Checking .gitignore...\n');

  if (!_fileExists('.gitignore')) {
    issues.add(AuditIssue(
      category: 'Security',
      file: '.gitignore',
      message: '.gitignore not found',
      fix: 'Create .gitignore and add .env files',
    ));
    if (verbose) print('');
    return;
  }

  final content = _readFile('.gitignore');
  final envPatterns = ['.env', '.env.dev', '.env.staging', '.env.prod'];

  // Check if any env pattern is ignored
  var hasEnvIgnore = false;
  for (final pattern in envPatterns) {
    if (content.contains(pattern)) {
      hasEnvIgnore = true;
      break;
    }
  }

  // Also check for glob patterns
  if (content.contains('.env*') || content.contains('.env.*')) {
    hasEnvIgnore = true;
  }

  if (hasEnvIgnore) {
    passed.add('Security: .env files in .gitignore');
  } else {
    issues.add(AuditIssue(
      category: 'Security',
      file: '.gitignore',
      message: '.env files not in .gitignore',
      fix: 'Add .env, .env.dev, .env.staging, .env.prod to .gitignore',
    ));
  }

  // Check that .env.example is NOT ignored
  if (content.contains('!.env.example')) {
    passed.add('Security: .env.example not ignored');
  } else if (verbose) {
    print('   ℹ️  Consider adding !.env.example to explicitly allow template');
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
        final lineInfo = warning.line != null ? ':${warning.line}' : '';
        print('     File: ${warning.file}$lineInfo');
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
        final lineInfo = issue.line != null ? ':${issue.line}' : '';
        print('     File: ${issue.file}$lineInfo');
      }
      print('     Fix: ${issue.fix}');
    }
    print('');
  }

  // Summary
  print('───────────────────────────────────────────────────────────');
  if (issues.isEmpty && warnings.isEmpty) {
    print('');
    print('🎉 All checks passed! Flavor configuration is complete.');
  } else if (issues.isEmpty) {
    print('');
    print('⚠️  ${warnings.length} warning(s) found. Review recommended.');
  } else {
    print('');
    print('❌ ${issues.length} issue(s) must be fixed.');
    print('');
    print('See: .claude/skills/flavors/SKILL.md');
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
        'line': w.line,
        'message': w.message,
        'fix': w.fix,
      };
    }).toList(),
    'issues': issues.map((i) => {
      return {
        'category': i.category,
        'file': i.file,
        'line': i.line,
        'message': i.message,
        'fix': i.fix,
      };
    }).toList(),
  };

  print(_jsonEncode(result));
}

String _jsonEncode(Object? obj) {
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
Flavors Configuration Audit Tool

Validates your Flutter project's environment flavor setup.

USAGE:
  dart run .claude/skills/flavors/scripts/check.dart [options]

OPTIONS:
  --json            Output as JSON (for CI)
  -h, --help        Show this help

EXAMPLES:
  dart run .claude/skills/flavors/scripts/check.dart
  dart run .claude/skills/flavors/scripts/check.dart --json

CHECKS PERFORMED:
  Environment Files:
    • .env.dev, .env.staging, .env.prod exist
    • Required keys (FLAVOR, APP_NAME, API_URL) present
    • .env.example template exists

  Android:
    • flavorDimensions defined in build.gradle
    • productFlavors block with dev/prod flavors
    • applicationIdSuffix for separate app IDs
    • app_name resValue for display names

  iOS:
    • Dev.xcconfig, Prod.xcconfig exist
    • PRODUCT_BUNDLE_IDENTIFIER set per flavor
    • DISPLAY_NAME set per flavor
    • Xcode schemes exist

  Dart:
    • FlavorConfig class exists
    • Uses String.fromEnvironment (not flutter_dotenv)
    • Has isDev/isProd helpers

  Security:
    • .env files in .gitignore

SEE ALSO:
  .claude/skills/flavors/SKILL.md
  .claude/skills/flavors/checklist.md
''');
}

// ============================================================
// UTILITIES
// ============================================================

bool _fileExists(String path) => File(path).existsSync();

bool _directoryExists(String path) => Directory(path).existsSync();

String _readFile(String path) {
  try {
    return File(path).readAsStringSync();
  } catch (_) {
    return '';
  }
}

int? _findLine(String content, String search) {
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains(search)) {
      return i + 1;
    }
  }
  return null;
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

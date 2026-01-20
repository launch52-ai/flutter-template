#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// i18n Check, Audit & Generate Tool
///
/// Comprehensive i18n management for Flutter projects:
/// - Check which features have i18n files
/// - Generate skeleton i18n files for missing features
/// - Audit features for hardcoded strings
/// - Report string quality issues
///
/// Usage:
///   dart run tool/i18n_check.dart              # Check i18n file status
///   dart run tool/i18n_check.dart --generate   # Generate missing i18n files
///   dart run tool/i18n_check.dart --audit      # Audit ALL features for hardcoded strings
///   dart run tool/i18n_check.dart --audit auth # Audit specific feature
///   dart run tool/i18n_check.dart --help       # Show help

import 'dart:io';

const String featuresDir = 'lib/features';
const String coreDir = 'lib/core';
const String coreI18nDir = 'lib/core/i18n';

void main(List<String> args) {
  final help = args.contains('--help') || args.contains('-h');
  final generate = args.contains('--generate') || args.contains('-g');
  final audit = args.contains('--audit') || args.contains('-a');

  if (help) {
    _printHelp();
    return;
  }

  print('');
  print('═══════════════════════════════════════════════════════');
  print('  i18n Check & Audit Tool');
  print('═══════════════════════════════════════════════════════');
  print('');

  if (audit) {
    // Get feature name if provided
    final featureIndex = args.indexOf('--audit') + 1;
    final altFeatureIndex = args.indexOf('-a') + 1;
    final idx = featureIndex > 0 ? featureIndex : altFeatureIndex;

    String? targetFeature;
    if (idx > 0 && idx < args.length && !args[idx].startsWith('-')) {
      targetFeature = args[idx];
    }

    _runAudit(targetFeature);
    return;
  }

  // Default: check i18n file status
  _checkCoreI18n();

  final features = _discoverFeatures();
  if (features.isEmpty) {
    print('⚠️  No features found in $featuresDir');
    return;
  }

  print('Found ${features.length} feature(s):');
  print('');

  final missing = <String>[];
  final existing = <String>[];

  for (final feature in features) {
    final i18nFile = '$featuresDir/$feature/i18n/$feature.i18n.yaml';
    final exists = File(i18nFile).existsSync();

    if (exists) {
      existing.add(feature);
      print('  ✅ $feature');
      print('     └─ $i18nFile');
    } else {
      missing.add(feature);
      print('  ❌ $feature');
      print('     └─ Missing: $i18nFile');
    }
    print('');
  }

  // Summary
  print('───────────────────────────────────────────────────────');
  print('Summary: ${existing.length}/${features.length} features have i18n files');
  print('');

  if (missing.isEmpty) {
    print('✅ All features have i18n files!');
    print('');
    _printUsageReminder();
    return;
  }

  if (generate) {
    print('Generating missing i18n files...');
    print('');

    for (final feature in missing) {
      _generateI18nFile(feature);
    }

    print('');
    print('✅ Generated ${missing.length} i18n file(s)');
    print('');
    print('Next steps:');
    print('  1. Edit the generated files to add your strings');
    print('  2. Run: dart run build_runner build --delete-conflicting-outputs');
    print('');
  } else {
    print('To generate missing files, run:');
    print('  dart run tool/i18n_check.dart --generate');
    print('');
    print('To audit for hardcoded strings, run:');
    print('  dart run tool/i18n_check.dart --audit');
    print('');
  }
}

// ============================================================
// AUDIT FUNCTIONS
// ============================================================

void _runAudit(String? targetFeature) {
  final features = _discoverFeatures();

  if (targetFeature != null) {
    if (!features.contains(targetFeature)) {
      print('❌ Feature "$targetFeature" not found.');
      print('   Available features: ${features.join(', ')}');
      return;
    }
    _auditFeature(targetFeature);
  } else {
    // Audit all features
    print('Auditing all features for hardcoded strings...');
    print('');

    var totalHardcoded = 0;
    var totalFiles = 0;

    // Also audit core
    final coreResults = _auditDirectory(coreDir, 'core');
    totalHardcoded += coreResults.hardcodedCount;
    totalFiles += coreResults.filesScanned;

    for (final feature in features) {
      final results = _auditFeature(feature);
      totalHardcoded += results.hardcodedCount;
      totalFiles += results.filesScanned;
    }

    print('');
    print('═══════════════════════════════════════════════════════');
    print('  AUDIT SUMMARY');
    print('═══════════════════════════════════════════════════════');
    print('');
    print('  Files scanned: $totalFiles');
    print('  Hardcoded strings found: $totalHardcoded');
    print('');

    if (totalHardcoded == 0) {
      print('  ✅ No hardcoded strings found!');
    } else {
      print('  ⚠️  Found $totalHardcoded hardcoded string(s) to review.');
      print('');
      print('  Next steps:');
      print('  1. Review the findings above');
      print('  2. Add strings to appropriate i18n.yaml files');
      print('  3. Replace hardcoded strings with t.feature.key');
      print('  4. Run: dart run build_runner build --delete-conflicting-outputs');
    }
    print('');
  }
}

({int hardcodedCount, int filesScanned}) _auditFeature(String feature) {
  final dir = '$featuresDir/$feature';
  return _auditDirectory(dir, feature);
}

({int hardcodedCount, int filesScanned}) _auditDirectory(
    String dir, String name) {
  print('───────────────────────────────────────────────────────');
  print('📁 Auditing: $name');
  print('───────────────────────────────────────────────────────');

  final dartFiles = _findDartFiles(dir);
  var hardcodedCount = 0;

  for (final file in dartFiles) {
    final findings = _scanFileForHardcodedStrings(file);
    if (findings.isNotEmpty) {
      hardcodedCount += findings.length;
      print('');
      print('  📄 ${file.replaceFirst('$dir/', '')}');
      for (final finding in findings) {
        print('     Line ${finding.line}: ${finding.type}');
        print('       ${_truncate(finding.content, 60)}');
        print('       → Suggested: $name.${finding.suggestedKey}');
      }
    }
  }

  if (hardcodedCount == 0) {
    print('  ✅ No hardcoded strings found');
  }
  print('');

  return (hardcodedCount: hardcodedCount, filesScanned: dartFiles.length);
}

List<String> _findDartFiles(String dir) {
  final directory = Directory(dir);
  if (!directory.existsSync()) return [];

  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .where((f) => !f.path.endsWith('.freezed.dart'))
      .map((f) => f.path)
      .toList();
}

List<HardcodedStringFinding> _scanFileForHardcodedStrings(String filePath) {
  final file = File(filePath);
  final content = file.readAsStringSync();
  final lines = content.split('\n');
  final findings = <HardcodedStringFinding>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineNum = i + 1;

    // Skip comments
    final trimmed = line.trim();
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;

    // Skip imports
    if (trimmed.startsWith('import ') || trimmed.startsWith('export ')) {
      continue;
    }

    // Pattern 1: Text('...')  or Text("...")
    final textMatches = RegExp(r'''Text\s*\(\s*(['"])(.*?)\1''').allMatches(line);
    for (final match in textMatches) {
      final stringContent = match.group(2) ?? '';
      if (_isUserFacingString(stringContent)) {
        findings.add(HardcodedStringFinding(
          line: lineNum,
          content: "Text('$stringContent')",
          type: 'Text widget',
          suggestedKey: _suggestKey(stringContent, filePath),
        ));
      }
    }

    // Pattern 2: title: '...' or label: '...' etc.
    final propMatches = RegExp(
            r'''(title|label|hintText|labelText|helperText|errorText|message|content|text|subtitle|description)\s*:\s*(['"])(.*?)\2''')
        .allMatches(line);
    for (final match in propMatches) {
      final prop = match.group(1) ?? '';
      final stringContent = match.group(3) ?? '';
      if (_isUserFacingString(stringContent) && !line.contains('t.')) {
        findings.add(HardcodedStringFinding(
          line: lineNum,
          content: "$prop: '$stringContent'",
          type: 'Property',
          suggestedKey: _suggestKeyFromProp(prop, stringContent, filePath),
        ));
      }
    }

    // Pattern 3: SnackBar with hardcoded content
    if (line.contains('SnackBar') && line.contains("Text(")) {
      final snackMatch =
          RegExp(r'''Text\s*\(\s*(['"])(.*?)\1''').firstMatch(line);
      if (snackMatch != null) {
        final stringContent = snackMatch.group(2) ?? '';
        if (_isUserFacingString(stringContent)) {
          findings.add(HardcodedStringFinding(
            line: lineNum,
            content: "SnackBar: '$stringContent'",
            type: 'SnackBar message',
            suggestedKey: 'messages.${_toKey(stringContent)}',
          ));
        }
      }
    }

    // Pattern 4: AppBar title
    if (line.contains('AppBar') || line.contains('title:')) {
      final appBarMatch =
          RegExp(r'''title\s*:\s*(?:const\s+)?Text\s*\(\s*(['"])(.*?)\1''')
              .firstMatch(line);
      if (appBarMatch != null) {
        final stringContent = appBarMatch.group(2) ?? '';
        if (_isUserFacingString(stringContent)) {
          findings.add(HardcodedStringFinding(
            line: lineNum,
            content: "AppBar title: '$stringContent'",
            type: 'AppBar title',
            suggestedKey: 'title',
          ));
        }
      }
    }
  }

  // Deduplicate by line number
  final seen = <int>{};
  return findings.where((f) => seen.add(f.line)).toList();
}

bool _isUserFacingString(String s) {
  // Skip empty or whitespace-only
  if (s.trim().isEmpty) return false;

  // Skip very short strings (likely keys or symbols)
  if (s.length < 2) return false;

  // Skip strings that look like:
  // - URLs or paths
  if (s.startsWith('http') ||
      s.startsWith('/') ||
      s.startsWith('assets/') ||
      s.contains('://')) {
    return false;
  }

  // - Package imports
  if (s.startsWith('package:')) return false;

  // - Keys or identifiers (snake_case or camelCase without spaces)
  if (RegExp(r'^[a-z][a-zA-Z0-9_]*$').hasMatch(s) && !s.contains(' ')) {
    return false;
  }

  // - Technical patterns
  if (s.startsWith(r'$') ||
      s.startsWith('{') ||
      s.startsWith('[') ||
      s.contains('::')) {
    return false;
  }

  // - Regex patterns
  if (s.startsWith('^') || s.startsWith(r'\')) return false;

  // - Font names
  if (s == 'System' ||
      s == 'Roboto' ||
      s == 'SF Pro' ||
      s.contains('Font')) {
    return false;
  }

  // - Date/number formats
  if (RegExp(r'^[MdyHhms/:.\-\s]+$').hasMatch(s)) return false;

  // Likely user-facing if:
  // - Contains spaces (natural language)
  // - Starts with capital letter
  // - Is a common word
  if (s.contains(' ') ||
      s[0] == s[0].toUpperCase() ||
      _commonUiWords.contains(s.toLowerCase())) {
    return true;
  }

  return false;
}

const _commonUiWords = {
  'ok',
  'cancel',
  'save',
  'delete',
  'edit',
  'add',
  'remove',
  'done',
  'next',
  'back',
  'close',
  'open',
  'yes',
  'no',
  'error',
  'loading',
  'success',
  'failed',
  'retry',
  'submit',
  'send',
  'confirm',
  'settings',
  'home',
  'profile',
  'search',
  'filter',
  'login',
  'logout',
  'signin',
  'signup',
  'welcome',
  'hello',
  'hi',
};

String _suggestKey(String content, String filePath) {
  // Extract screen/widget name from path
  final pathParts = filePath.split('/');
  final fileName =
      pathParts.last.replaceAll('.dart', '').replaceAll('_screen', '');

  final key = _toKey(content);
  return '$fileName.$key';
}

String _suggestKeyFromProp(String prop, String content, String filePath) {
  final propGroup = switch (prop) {
    'hintText' || 'labelText' || 'helperText' => 'labels',
    'errorText' => 'errors',
    'title' => 'title',
    'subtitle' || 'description' => 'descriptions',
    _ => 'text',
  };

  if (propGroup == 'title') {
    return 'title';
  }

  final key = _toKey(content);
  return '$propGroup.$key';
}

String _toKey(String content) {
  // Convert "Welcome back!" → "welcomeBack"
  return content
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .trim()
      .split(RegExp(r'\s+'))
      .take(3) // Limit to first 3 words
      .toList()
      .asMap()
      .entries
      .map((e) => e.key == 0 ? e.value : _capitalize(e.value))
      .join();
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

String _truncate(String s, int maxLength) {
  if (s.length <= maxLength) return s;
  return '${s.substring(0, maxLength - 3)}...';
}

// ============================================================
// CHECK FUNCTIONS
// ============================================================

void _printHelp() {
  print('''
i18n Check & Audit Tool

Manages i18n files and audits for hardcoded strings.

USAGE:
  dart run tool/i18n_check.dart [options] [feature]

OPTIONS:
  -g, --generate     Generate skeleton i18n files for features missing them
  -a, --audit        Audit features for hardcoded strings
  -h, --help         Show this help message

EXAMPLES:
  dart run tool/i18n_check.dart              # Check i18n file status
  dart run tool/i18n_check.dart -g           # Generate missing i18n files
  dart run tool/i18n_check.dart -a           # Audit ALL features
  dart run tool/i18n_check.dart -a auth      # Audit specific feature
  dart run tool/i18n_check.dart --audit settings

FILE STRUCTURE:
  lib/
  ├── core/i18n/
  │   ├── common.i18n.yaml      → t.common.*
  │   └── translations.g.dart   → Generated (all namespaces merged)
  └── features/
      ├── auth/i18n/
      │   └── auth.i18n.yaml    → t.auth.*
      └── {feature}/i18n/
          └── {feature}.i18n.yaml → t.{feature}.*

USAGE IN CODE:
  import 'package:your_app/core/i18n/translations.g.dart';

  // Common strings
  Text(t.common.buttons.cancel)

  // Feature strings
  Text(t.auth.login.title)

AUDIT OUTPUT:
  The audit command scans Dart files for:
  - Text() widgets with hardcoded strings
  - Hardcoded title, label, hint properties
  - SnackBar messages
  - AppBar titles

  It will suggest appropriate i18n keys for each finding.

UX WRITING:
  See 07-UX_WRITING_GUIDE.md for string quality guidelines.
''');
}

void _checkCoreI18n() {
  final commonFile = '$coreI18nDir/common.i18n.yaml';
  final exists = File(commonFile).existsSync();

  print('Core i18n:');
  if (exists) {
    print('  ✅ common.i18n.yaml');
  } else {
    print('  ❌ common.i18n.yaml missing!');
    print('     Create: $commonFile');
  }
  print('');
}

List<String> _discoverFeatures() {
  final dir = Directory(featuresDir);
  if (!dir.existsSync()) {
    return [];
  }

  return dir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split('/').last)
      .where((name) => !name.startsWith('.'))
      .toList()
    ..sort();
}

void _generateI18nFile(String feature) {
  final i18nDir = '$featuresDir/$feature/i18n';
  final i18nFile = '$i18nDir/$feature.i18n.yaml';

  // Create directory if needed
  Directory(i18nDir).createSync(recursive: true);

  // Generate skeleton content
  final content = _generateSkeletonContent(feature);

  // Write file
  File(i18nFile).writeAsStringSync(content);

  print('  📄 Created: $i18nFile');
}

String _generateSkeletonContent(String feature) {
  final titleCase = _toTitleCase(feature);

  return '''# $titleCase feature strings
# Usage: t.$feature.title, t.$feature.*, etc.
#
# UX Writing Guidelines: See 07-UX_WRITING_GUIDE.md
# - Be specific, not vague
# - Use plain words
# - Make buttons clearly state outcomes
# - Make errors actionable
#
# After editing, run:
#   dart run build_runner build --delete-conflicting-outputs

title: $titleCase

# Add your feature-specific strings below

# Screen titles and descriptions
# screens:
#   main:
#     title: $titleCase
#     subtitle: Your subtitle here

# Button labels - should complete "I want to ___"
# buttons:
#   create: Create $titleCase
#   save: Save changes
#   delete: Delete $feature

# Form labels and placeholders
# labels:
#   name: Name
#   description: Description
# placeholders:
#   name: Enter a name
#   description: Add a description...

# Messages - be specific about what happened
# messages:
#   saved: Changes saved
#   deleted: $titleCase deleted
#   error: Could not save. Try again.

# Empty states - explain what goes here and how to add content
# empty:
#   title: No ${feature}s yet
#   description: ${titleCase}s you create will appear here.
#   action: Create your first $feature

# Confirmations - clear outcomes, not "Are you sure?"
# dialogs:
#   delete:
#     title: Delete this $feature?
#     message: This cannot be undone.
#     confirm: Delete
#     cancel: Keep $feature
''';
}

String _toTitleCase(String input) {
  if (input.isEmpty) return input;

  // Handle snake_case
  final words = input.split('_');

  return words.map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

void _printUsageReminder() {
  print('Usage reminder:');
  print('');
  print('  import \'package:your_app/core/i18n/translations.g.dart\';');
  print('');
  print('  // Common strings');
  print('  Text(t.common.buttons.cancel)');
  print('  Text(t.common.errors.network)');
  print('');
  print('  // Feature strings');
  print('  Text(t.auth.login.title)');
  print('  Text(t.settings.theme.dark)');
  print('');
  print('To regenerate translations:');
  print('  dart run build_runner build --delete-conflicting-outputs');
  print('');
  print('To audit for hardcoded strings:');
  print('  dart run .claude/skills/i18n/scripts/check.dart --audit');
  print('');
}

// ============================================================
// DATA CLASSES
// ============================================================

class HardcodedStringFinding {
  final int line;
  final String content;
  final String type;
  final String suggestedKey;

  HardcodedStringFinding({
    required this.line,
    required this.content,
    required this.type,
    required this.suggestedKey,
  });
}

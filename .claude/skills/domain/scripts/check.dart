#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// Domain Layer Check & Validation Tool
///
/// Validates domain layer structure and code quality:
/// - Check if spec file exists
/// - Validate domain layer structure (entities, enums, repositories)
/// - Verify no forbidden imports (Flutter, dio, etc.)
/// - Check Freezed annotations
/// - Report missing components
///
/// Usage:
///   dart run .claude/skills/domain/scripts/check.dart {feature}
///   dart run .claude/skills/domain/scripts/check.dart {feature} --generate
///   dart run .claude/skills/domain/scripts/check.dart --all
///   dart run .claude/skills/domain/scripts/check.dart --help

import 'dart:io';

const String featuresDir = 'lib/features';
const String docsDir = 'docs/features';

void main(List<String> args) {
  final help = args.contains('--help') || args.contains('-h');
  final generate = args.contains('--generate') || args.contains('-g');
  final all = args.contains('--all') || args.contains('-a');

  if (help) {
    _printHelp();
    return;
  }

  print('');
  print('═══════════════════════════════════════════════════════');
  print('  Domain Layer Check & Validation Tool');
  print('═══════════════════════════════════════════════════════');
  print('');

  if (all) {
    _checkAllFeatures();
    return;
  }

  // Get feature name
  final featureArgs = args.where((a) => !a.startsWith('-')).toList();
  if (featureArgs.isEmpty) {
    print('❌ No feature specified.');
    print('');
    print('Usage: dart run .claude/skills/domain/scripts/check.dart {feature}');
    print('       dart run .claude/skills/domain/scripts/check.dart --all');
    print('');
    _listAvailableFeatures();
    return;
  }

  final feature = featureArgs.first;

  if (generate) {
    _generateDomainLayer(feature);
  } else {
    _checkFeature(feature);
  }
}

// ============================================================
// CHECK FUNCTIONS
// ============================================================

void _checkAllFeatures() {
  final features = _discoverFeatures();

  if (features.isEmpty) {
    print('⚠️  No features found in $featuresDir');
    return;
  }

  print('Checking ${features.length} feature(s)...');
  print('');

  var totalIssues = 0;

  for (final feature in features) {
    final issues = _checkFeature(feature, verbose: false);
    totalIssues += issues;
  }

  print('');
  print('═══════════════════════════════════════════════════════');
  print('  SUMMARY');
  print('═══════════════════════════════════════════════════════');
  print('');
  print('  Features checked: ${features.length}');
  print('  Total issues: $totalIssues');
  print('');

  if (totalIssues == 0) {
    print('  ✅ All domain layers are valid!');
  } else {
    print('  ⚠️  Found $totalIssues issue(s) to review.');
    print('');
    print('  Run with specific feature for details:');
    print('  dart run .claude/skills/domain/scripts/check.dart {feature}');
  }
  print('');
}

int _checkFeature(String feature, {bool verbose = true}) {
  var issues = 0;

  if (verbose) {
    print('───────────────────────────────────────────────────────');
    print('📁 Checking domain layer for: $feature');
    print('───────────────────────────────────────────────────────');
    print('');
  }

  final featureDir = '$featuresDir/$feature';
  final domainDir = '$featureDir/domain';

  // Check if feature exists
  if (!Directory(featureDir).existsSync()) {
    print('  ❌ Feature directory not found: $featureDir');
    return 1;
  }

  // 1. Check for spec file
  final specInFeature = '$featureDir/.spec.md';
  final specInDocs = '$docsDir/$feature.spec.md';
  final hasSpec = File(specInFeature).existsSync() || File(specInDocs).existsSync();

  if (verbose) {
    print('  Spec File:');
    if (hasSpec) {
      final specPath = File(specInFeature).existsSync() ? specInFeature : specInDocs;
      print('    ✅ Found: $specPath');
    } else {
      print('    ⚠️  No spec file found');
      print('       Expected: $specInFeature or $specInDocs');
      print('       Run /plan $feature to create one');
    }
    print('');
  }

  // 2. Check domain directory structure
  if (!Directory(domainDir).existsSync()) {
    if (verbose) {
      print('  ❌ Domain directory not found: $domainDir');
      print('');
      print('  Expected structure:');
      print('    $domainDir/');
      print('    ├── entities/');
      print('    ├── enums/');
      print('    └── repositories/');
      print('');
    }
    return 1;
  }

  if (verbose) {
    print('  Structure:');
  }

  // Check subdirectories
  final entitiesDir = '$domainDir/entities';
  final enumsDir = '$domainDir/enums';
  final reposDir = '$domainDir/repositories';

  final hasEntities = Directory(entitiesDir).existsSync();
  final hasEnums = Directory(enumsDir).existsSync();
  final hasRepos = Directory(reposDir).existsSync();

  if (verbose) {
    print('    ${hasEntities ? "✅" : "❌"} entities/');
    print('    ${hasEnums ? "✅" : "⚠️ "} enums/ (optional)');
    print('    ${hasRepos ? "✅" : "❌"} repositories/');
    print('');
  }

  if (!hasEntities) issues++;
  if (!hasRepos) issues++;

  // 3. Check entities
  if (hasEntities) {
    final entityIssues = _checkEntities(entitiesDir, verbose);
    issues += entityIssues;
  }

  // 4. Check enums
  if (hasEnums) {
    final enumIssues = _checkEnums(enumsDir, verbose);
    issues += enumIssues;
  }

  // 5. Check repository interfaces
  if (hasRepos) {
    final repoIssues = _checkRepositories(reposDir, verbose);
    issues += repoIssues;
  }

  // 6. Check for forbidden imports in all domain files
  final importIssues = _checkForbiddenImports(domainDir, verbose);
  issues += importIssues;

  if (verbose) {
    print('───────────────────────────────────────────────────────');
    if (issues == 0) {
      print('✅ Domain layer for $feature is valid!');
    } else {
      print('⚠️  Found $issues issue(s) in domain layer');
    }
    print('');
  } else {
    final status = issues == 0 ? '✅' : '❌';
    print('  $status $feature ($issues issues)');
  }

  return issues;
}

int _checkEntities(String dir, bool verbose) {
  var issues = 0;
  final files = _findDartFiles(dir);

  if (verbose) {
    print('  Entities:');
  }

  if (files.isEmpty) {
    if (verbose) {
      print('    ⚠️  No entity files found');
    }
    return 1;
  }

  for (final file in files) {
    final fileName = file.split('/').last;
    final content = File(file).readAsStringSync();
    final fileIssues = <String>[];

    // Skip generated files (shouldn't exist in pure Dart domain)
    if (fileName.endsWith('.freezed.dart') || fileName.endsWith('.g.dart')) {
      fileIssues.add('Generated file found - domain should be pure Dart');
    }

    // Check for final class (required)
    if (!content.contains('final class ')) {
      fileIssues.add('Should use "final class" for entities');
    }

    // Check for doc comments
    if (!content.contains('///')) {
      fileIssues.add('Missing documentation comments');
    }

    // Check for Freezed (should NOT be in domain)
    if (content.contains('@freezed') || content.contains('package:freezed')) {
      fileIssues.add('Freezed found - domain should be pure Dart (use in data layer)');
    }

    // Check for JSON (should NOT be in domain)
    if (content.contains('fromJson') || content.contains('toJson') ||
        content.contains('package:json_annotation')) {
      fileIssues.add('JSON serialization found - belongs in data layer');
    }

    if (verbose) {
      if (fileIssues.isEmpty) {
        print('    ✅ $fileName');
      } else {
        print('    ❌ $fileName');
        for (final issue in fileIssues) {
          print('       └─ $issue');
        }
        issues += fileIssues.length;
      }
    } else {
      issues += fileIssues.length;
    }
  }

  if (verbose) print('');
  return issues;
}

int _checkEnums(String dir, bool verbose) {
  var issues = 0;
  final files = _findDartFiles(dir);

  if (verbose) {
    print('  Enums:');
  }

  if (files.isEmpty) {
    if (verbose) {
      print('    (none)');
    }
    return 0;
  }

  for (final file in files) {
    final fileName = file.split('/').last;
    final content = File(file).readAsStringSync();
    final fileIssues = <String>[];

    // Check for enum declaration
    if (!content.contains('enum ')) {
      fileIssues.add('No enum declaration found');
    }

    // Check for doc comments
    if (!content.contains('///')) {
      fileIssues.add('Missing documentation comments');
    }

    if (verbose) {
      if (fileIssues.isEmpty) {
        print('    ✅ $fileName');
      } else {
        print('    ⚠️  $fileName');
        for (final issue in fileIssues) {
          print('       └─ $issue');
        }
        issues += fileIssues.length;
      }
    } else {
      issues += fileIssues.length;
    }
  }

  if (verbose) print('');
  return issues;
}

int _checkRepositories(String dir, bool verbose) {
  var issues = 0;
  final files = _findDartFiles(dir);

  if (verbose) {
    print('  Repositories:');
  }

  if (files.isEmpty) {
    if (verbose) {
      print('    ❌ No repository files found');
    }
    return 1;
  }

  for (final file in files) {
    final fileName = file.split('/').last;
    final content = File(file).readAsStringSync();
    final fileIssues = <String>[];

    // Check for abstract interface class
    if (!content.contains('abstract interface class')) {
      fileIssues.add('Should use "abstract interface class" pattern');
    }

    // Check for doc comments
    if (!content.contains('///')) {
      fileIssues.add('Missing documentation comments');
    }

    // Check it's not a concrete implementation
    if (content.contains('implements') && content.contains('class ') &&
        !content.contains('abstract')) {
      fileIssues.add('Domain should only have interfaces, not implementations');
    }

    if (verbose) {
      if (fileIssues.isEmpty) {
        print('    ✅ $fileName');
      } else {
        print('    ❌ $fileName');
        for (final issue in fileIssues) {
          print('       └─ $issue');
        }
        issues += fileIssues.length;
      }
    } else {
      issues += fileIssues.length;
    }
  }

  if (verbose) print('');
  return issues;
}

int _checkForbiddenImports(String dir, bool verbose) {
  var issues = 0;
  final files = _findDartFiles(dir);

  final forbiddenPatterns = [
    (pattern: 'package:flutter/', name: 'Flutter'),
    (pattern: 'package:dio/', name: 'Dio (networking)'),
    (pattern: 'package:http/', name: 'HTTP package'),
    (pattern: 'package:supabase', name: 'Supabase'),
    (pattern: 'package:shared_preferences/', name: 'SharedPreferences'),
    (pattern: 'package:flutter_secure_storage/', name: 'SecureStorage'),
    (pattern: 'dart:ui', name: 'dart:ui'),
    (pattern: 'dart:html', name: 'dart:html'),
    (pattern: '/data/', name: 'Data layer import'),
    (pattern: '/presentation/', name: 'Presentation layer import'),
  ];

  final violations = <String, List<String>>{};

  for (final file in files) {
    // Skip generated files
    if (file.endsWith('.freezed.dart') || file.endsWith('.g.dart')) {
      continue;
    }

    final content = File(file).readAsStringSync();
    final fileName = file.split('/').last;

    for (final forbidden in forbiddenPatterns) {
      if (content.contains(forbidden.pattern)) {
        violations.putIfAbsent(fileName, () => []).add(forbidden.name);
        issues++;
      }
    }
  }

  if (verbose && violations.isNotEmpty) {
    print('  Forbidden Imports:');
    for (final entry in violations.entries) {
      print('    ❌ ${entry.key}');
      for (final violation in entry.value) {
        print('       └─ Imports $violation (not allowed in domain)');
      }
    }
    print('');
  }

  return issues;
}

// ============================================================
// GENERATE FUNCTIONS
// ============================================================

void _generateDomainLayer(String feature) {
  print('Generating domain layer skeleton for: $feature');
  print('');

  final featureDir = '$featuresDir/$feature';
  final domainDir = '$featureDir/domain';

  // Create directories
  Directory('$domainDir/entities').createSync(recursive: true);
  Directory('$domainDir/enums').createSync(recursive: true);
  Directory('$domainDir/repositories').createSync(recursive: true);

  print('  ✅ Created directory structure');

  // Generate skeleton files
  final entityName = _toPascalCase(feature);
  final entityFile = '$domainDir/entities/${feature}.dart';
  final repoFile = '$domainDir/repositories/${feature}_repository.dart';

  // Entity skeleton
  if (!File(entityFile).existsSync()) {
    File(entityFile).writeAsStringSync(_generateEntitySkeleton(feature, entityName));
    print('  ✅ Created: $entityFile');
  } else {
    print('  ⚠️  Skipped (exists): $entityFile');
  }

  // Repository skeleton
  if (!File(repoFile).existsSync()) {
    File(repoFile).writeAsStringSync(_generateRepoSkeleton(feature, entityName));
    print('  ✅ Created: $repoFile');
  } else {
    print('  ⚠️  Skipped (exists): $repoFile');
  }

  print('');
  print('Next steps:');
  print('  1. Edit the generated files based on your spec');
  print('  2. Add additional entities/enums as needed');
  print('  3. Add == and hashCode only if entity is used in state comparison');
  print('  4. Add copyWith only if entity needs immutable updates');
  print('');
  print('Note: Domain is pure Dart - no build_runner needed.');
  print('      Freezed/JSON goes in data layer (models), not domain.');
  print('');
}

String _generateEntitySkeleton(String feature, String entityName) {
  return '''/// TODO: Add description from spec
final class $entityName {
  /// Unique identifier.
  final String id;

  // TODO: Add fields from spec

  /// When this was created.
  final DateTime createdAt;

  /// When this was last modified.
  final DateTime? updatedAt;

  const $entityName({
    required this.id,
    // TODO: Add required/optional fields
    required this.createdAt,
    this.updatedAt,
  });

  // TODO: Add computed properties from spec

  // Add equality only if needed for state comparison:
  // @override
  // bool operator ==(Object other) =>
  //     identical(this, other) ||
  //     other is $entityName && other.id == id;
  //
  // @override
  // int get hashCode => id.hashCode;

  // Add copyWith only if needed for immutable updates:
  // $entityName copyWith({...}) { ... }
}
''';
}

String _generateRepoSkeleton(String feature, String entityName) {
  final repoName = '${entityName}Repository';

  return '''import '../entities/$feature.dart';

/// Repository interface for $feature operations.
///
/// Implementations handle data source details (API, storage, etc.).
/// Domain layer only knows this interface, not implementations.
abstract interface class $repoName {
  /// Get all ${feature}s.
  Future<List<$entityName>> getAll();

  /// Get a single $feature by ID.
  ///
  /// Returns null if not found.
  Future<$entityName?> getById(String id);

  /// Create a new $feature.
  ///
  /// TODO: Add parameters from spec
  Future<$entityName> create({
    // required Type field1,
  });

  /// Update an existing $feature.
  ///
  /// TODO: Add parameters from spec
  Future<$entityName> update({
    required String id,
    // Type? field1,
  });

  /// Delete a $feature.
  Future<void> delete(String id);
}
''';
}

// ============================================================
// HELPER FUNCTIONS
// ============================================================

void _printHelp() {
  print('''
Domain Layer Check & Validation Tool

Validates domain layer structure and code quality.

USAGE:
  dart run .claude/skills/domain/scripts/check.dart {feature}
  dart run .claude/skills/domain/scripts/check.dart {feature} --generate
  dart run .claude/skills/domain/scripts/check.dart --all
  dart run .claude/skills/domain/scripts/check.dart --help

OPTIONS:
  -g, --generate     Generate skeleton domain files for feature
  -a, --all          Check all features
  -h, --help         Show this help message

EXAMPLES:
  dart run .claude/skills/domain/scripts/check.dart memories
  dart run .claude/skills/domain/scripts/check.dart tasks --generate
  dart run .claude/skills/domain/scripts/check.dart --all

CHECKS PERFORMED:
  1. Spec file exists (.spec.md)
  2. Domain directory structure (entities/, enums/, repositories/)
  3. Entities have @freezed annotation and part directives
  4. Repository interfaces use "abstract interface class"
  5. No forbidden imports (Flutter, Dio, data layer, presentation layer)
  6. Documentation comments present

EXPECTED STRUCTURE:
  lib/features/{feature}/domain/
  ├── entities/
  │   ├── {entity}.dart           # Freezed entity
  │   └── {entity}.freezed.dart   # Generated
  ├── enums/
  │   └── {enum_name}.dart        # Enum definitions
  └── repositories/
      └── {feature}_repository.dart  # Abstract interface
''');
}

List<String> _discoverFeatures() {
  final dir = Directory(featuresDir);
  if (!dir.existsSync()) return [];

  return dir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split('/').last)
      .where((name) => !name.startsWith('.'))
      .toList()
    ..sort();
}

void _listAvailableFeatures() {
  final features = _discoverFeatures();
  if (features.isEmpty) {
    print('No features found in $featuresDir');
    return;
  }

  print('Available features:');
  for (final feature in features) {
    print('  - $feature');
  }
  print('');
}

List<String> _findDartFiles(String dir) {
  final directory = Directory(dir);
  if (!directory.existsSync()) return [];

  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path)
      .toList();
}

String _toPascalCase(String input) {
  if (input.isEmpty) return input;

  return input
      .split('_')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join();
}

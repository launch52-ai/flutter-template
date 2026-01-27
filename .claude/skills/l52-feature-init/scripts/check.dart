#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// Feature Structure Check & Generate Tool
///
/// Manages feature scaffolding for Clean Architecture projects:
/// - Check which features exist and their layer completeness
/// - Validate feature structure against expected pattern
/// - Generate new feature scaffolding
///
/// Usage:
///   dart run .claude/skills/feature-init/scripts/check.dart              # Check all features
///   dart run .claude/skills/feature-init/scripts/check.dart --generate bookmarks  # Generate new feature
///   dart run .claude/skills/feature-init/scripts/check.dart --validate auth       # Validate feature
///   dart run .claude/skills/feature-init/scripts/check.dart --help        # Show help

import 'dart:io';

const String featuresDir = 'lib/features';

// Expected structure for a complete feature
const expectedLayers = [
  'domain/entities',
  'domain/repositories',
  'data/models',
  'data/repositories',
  'presentation/providers',
  'presentation/screens',
  'presentation/widgets',
  'i18n',
];

void main(List<String> args) {
  final help = args.contains('--help') || args.contains('-h');
  final generate = args.contains('--generate') || args.contains('-g');
  final validate = args.contains('--validate') || args.contains('-v');

  if (help) {
    _printHelp();
    return;
  }

  print('');
  print('═══════════════════════════════════════════════════════');
  print('  Feature Structure Tool');
  print('═══════════════════════════════════════════════════════');
  print('');

  if (generate) {
    final featureName = _getArgValue(args, '--generate') ??
        _getArgValue(args, '-g');
    if (featureName == null) {
      print('❌ Please provide a feature name:');
      print('   dart run .claude/skills/feature-init/scripts/check.dart --generate feature_name');
      return;
    }
    _generateFeature(featureName);
    return;
  }

  if (validate) {
    final featureName = _getArgValue(args, '--validate') ??
        _getArgValue(args, '-v');
    if (featureName == null) {
      print('❌ Please provide a feature name:');
      print('   dart run .claude/skills/feature-init/scripts/check.dart --validate feature_name');
      return;
    }
    _validateFeature(featureName);
    return;
  }

  // Default: check all features
  _checkAllFeatures();
}

// ============================================================
// CHECK ALL FEATURES
// ============================================================

void _checkAllFeatures() {
  final features = _discoverFeatures();

  if (features.isEmpty) {
    print('⚠️  No features found in $featuresDir');
    print('');
    print('To create a new feature:');
    print('  dart run .claude/skills/feature-init/scripts/check.dart --generate feature_name');
    return;
  }

  print('Found ${features.length} feature(s):');
  print('');

  var totalComplete = 0;

  for (final feature in features) {
    final analysis = _analyzeFeature(feature);
    _printFeatureAnalysis(feature, analysis);

    if (analysis.completeness >= 80) {
      totalComplete++;
    }
  }

  print('───────────────────────────────────────────────────────');
  print('');
  print('Summary: $totalComplete/${features.length} features are substantially complete (80%+)');
  print('');
  print('Commands:');
  print('  --generate <name>   Create new feature scaffolding');
  print('  --validate <name>   Check specific feature structure');
  print('');
}

FeatureAnalysis _analyzeFeature(String feature) {
  final featurePath = '$featuresDir/$feature';
  final presentLayers = <String>[];
  final missingLayers = <String>[];

  for (final layer in expectedLayers) {
    final layerPath = '$featurePath/$layer';
    final dir = Directory(layerPath);

    if (dir.existsSync()) {
      // Check if it has any .dart files
      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('.g.dart'))
          .where((f) => !f.path.endsWith('.freezed.dart'));

      if (dartFiles.isNotEmpty) {
        presentLayers.add(layer);
      } else {
        missingLayers.add('$layer (empty)');
      }
    } else {
      missingLayers.add(layer);
    }
  }

  // Special check for i18n file
  final i18nFile = '$featurePath/i18n/$feature.i18n.yaml';
  if (File(i18nFile).existsSync()) {
    if (!presentLayers.contains('i18n')) {
      presentLayers.add('i18n');
      missingLayers.remove('i18n');
    }
  }

  final completeness = (presentLayers.length / expectedLayers.length * 100).round();

  return FeatureAnalysis(
    presentLayers: presentLayers,
    missingLayers: missingLayers,
    completeness: completeness,
  );
}

void _printFeatureAnalysis(String feature, FeatureAnalysis analysis) {
  final icon = analysis.completeness >= 80 ? '✅' : analysis.completeness >= 50 ? '⚠️' : '❌';

  print('$icon $feature (${analysis.completeness}% complete)');

  if (analysis.presentLayers.isNotEmpty) {
    print('   Present:');
    for (final layer in analysis.presentLayers) {
      print('     ✓ $layer');
    }
  }

  if (analysis.missingLayers.isNotEmpty) {
    print('   Missing:');
    for (final layer in analysis.missingLayers) {
      print('     ✗ $layer');
    }
  }

  print('');
}

// ============================================================
// VALIDATE FEATURE
// ============================================================

void _validateFeature(String feature) {
  final featurePath = '$featuresDir/$feature';

  if (!Directory(featurePath).existsSync()) {
    print('❌ Feature "$feature" not found at $featurePath');
    print('');
    print('Available features:');
    for (final f in _discoverFeatures()) {
      print('  - $f');
    }
    return;
  }

  print('Validating feature: $feature');
  print('');

  final analysis = _analyzeFeature(feature);
  _printFeatureAnalysis(feature, analysis);

  // Detailed validation
  final issues = <String>[];

  // Check domain interface
  final domainDir = '$featurePath/domain/repositories';
  if (Directory(domainDir).existsSync()) {
    final interfaces = _findDartFiles(domainDir);
    if (interfaces.isEmpty) {
      issues.add('domain/repositories: No interface files found');
    } else {
      for (final file in interfaces) {
        final content = File(file).readAsStringSync();
        if (!content.contains('abstract interface class')) {
          issues.add('${_relativePath(file)}: Missing abstract interface class');
        }
      }
    }
  }

  // Check data implementation
  final dataRepoDir = '$featurePath/data/repositories';
  if (Directory(dataRepoDir).existsSync()) {
    final impls = _findDartFiles(dataRepoDir);
    for (final file in impls) {
      final content = File(file).readAsStringSync();
      if (!content.contains('implements') && !content.contains('final class')) {
        issues.add('${_relativePath(file)}: Missing final class or implements');
      }
    }
  }

  // Check models use Freezed
  final modelsDir = '$featurePath/data/models';
  if (Directory(modelsDir).existsSync()) {
    final models = _findDartFiles(modelsDir);
    for (final file in models) {
      final content = File(file).readAsStringSync();
      if (!content.contains('@freezed')) {
        issues.add('${_relativePath(file)}: Model not using @freezed');
      }
    }
  }

  // Check provider uses @riverpod
  final providersDir = '$featurePath/presentation/providers';
  if (Directory(providersDir).existsSync()) {
    final providers = _findDartFiles(providersDir)
        .where((f) => !f.contains('_state.dart'));
    for (final file in providers) {
      final content = File(file).readAsStringSync();
      if (!content.contains('@riverpod')) {
        issues.add('${_relativePath(file)}: Provider not using @riverpod');
      }
      if (content.contains('extends _\$') && !content.contains('_disposed')) {
        issues.add('${_relativePath(file)}: Notifier may be missing disposal safety');
      }
    }
  }

  // Check state uses sealed class
  final stateFiles = _findDartFiles(providersDir)
      .where((f) => f.contains('_state.dart'));
  for (final file in stateFiles) {
    final content = File(file).readAsStringSync();
    if (!content.contains('sealed class')) {
      issues.add('${_relativePath(file)}: State not using sealed class');
    }
  }

  // Check screen uses ConsumerWidget
  final screensDir = '$featurePath/presentation/screens';
  if (Directory(screensDir).existsSync()) {
    final screens = _findDartFiles(screensDir);
    for (final file in screens) {
      final content = File(file).readAsStringSync();
      if (!content.contains('ConsumerWidget') && !content.contains('ConsumerStatefulWidget')) {
        issues.add('${_relativePath(file)}: Screen not using Consumer widget');
      }
      if (!content.contains('final class')) {
        issues.add('${_relativePath(file)}: Screen class not marked final');
      }
    }
  }

  // Check i18n
  final i18nFile = '$featurePath/i18n/$feature.i18n.yaml';
  if (!File(i18nFile).existsSync()) {
    issues.add('i18n: Missing $feature.i18n.yaml');
  }

  // Check dependency violations
  final domainFiles = _findDartFiles('$featurePath/domain');
  for (final file in domainFiles) {
    final content = File(file).readAsStringSync();
    if (content.contains("import '../../data/") ||
        content.contains("import '../../presentation/")) {
      issues.add(
          '${_relativePath(file)}: Domain layer has forbidden dependency on data/presentation');
    }
  }

  final presentationFiles = _findDartFiles('$featurePath/presentation');
  for (final file in presentationFiles) {
    final content = File(file).readAsStringSync();
    if (content.contains("import '../../data/")) {
      issues.add(
          '${_relativePath(file)}: Presentation layer has forbidden dependency on data');
    }
  }

  // Print results
  print('───────────────────────────────────────────────────────');
  print('');

  if (issues.isEmpty) {
    print('✅ No validation issues found!');
  } else {
    print('⚠️  Found ${issues.length} issue(s):');
    print('');
    for (final issue in issues) {
      print('  - $issue');
    }
  }

  print('');
}

// ============================================================
// GENERATE FEATURE
// ============================================================

void _generateFeature(String feature) {
  final featurePath = '$featuresDir/$feature';

  if (Directory(featurePath).existsSync()) {
    print('⚠️  Feature "$feature" already exists.');
    print('');
    print('To validate existing feature:');
    print('  dart run .claude/skills/feature-init/scripts/check.dart --validate $feature');
    return;
  }

  print('Generating feature: $feature');
  print('');

  // Create directories
  final dirs = [
    '$featurePath/domain/entities',
    '$featurePath/domain/repositories',
    '$featurePath/data/models',
    '$featurePath/data/repositories',
    '$featurePath/presentation/providers',
    '$featurePath/presentation/screens',
    '$featurePath/presentation/widgets',
    '$featurePath/i18n',
  ];

  for (final dir in dirs) {
    Directory(dir).createSync(recursive: true);
    print('  📁 Created: $dir');
  }

  // Generate skeleton files
  final pascalCase = _toPascalCase(feature);
  final camelCase = _toCamelCase(feature);

  // Domain entity (no external dependencies)
  _writeFile(
    '$featurePath/domain/entities/$feature.dart',
    _generateEntity(feature, pascalCase),
  );

  // Domain interface (uses entity only)
  _writeFile(
    '$featurePath/domain/repositories/${feature}_repository.dart',
    _generateDomainInterface(feature, pascalCase),
  );

  // Data model (DTO, maps to entity)
  _writeFile(
    '$featurePath/data/models/${feature}_model.dart',
    _generateModel(feature, pascalCase),
  );

  // Data repository
  _writeFile(
    '$featurePath/data/repositories/${feature}_repository_impl.dart',
    _generateRepositoryImpl(feature, pascalCase),
  );

  // State
  _writeFile(
    '$featurePath/presentation/providers/${feature}_state.dart',
    _generateState(feature, pascalCase),
  );

  // Provider
  _writeFile(
    '$featurePath/presentation/providers/${feature}_provider.dart',
    _generateProvider(feature, pascalCase, camelCase),
  );

  // Screen
  _writeFile(
    '$featurePath/presentation/screens/${feature}_screen.dart',
    _generateScreen(feature, pascalCase, camelCase),
  );

  // i18n
  _writeFile(
    '$featurePath/i18n/$feature.i18n.yaml',
    _generateI18n(feature, pascalCase),
  );

  print('');
  print('───────────────────────────────────────────────────────');
  print('');
  print('✅ Feature scaffolding complete!');
  print('');
  print('Next steps:');
  print('  1. Run: /i18n $feature');
  print('  2. Run: /testing $feature');
  print('  3. Run: /design (when implementing UI)');
  print('  4. Add route to lib/core/router/app_router.dart');
  print('  5. Run: dart run build_runner build --delete-conflicting-outputs');
  print('');
}

// ============================================================
// FILE GENERATORS
// ============================================================

String _generateEntity(String feature, String pascal) {
  return '''/// $pascal domain entity.
///
/// Pure domain model with no external dependencies.
/// Used by repository interfaces and presentation layer.
final class $pascal {
  const $pascal({
    required this.id,
    // TODO: Add fields based on feature requirements
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
''';
}

String _generateDomainInterface(String feature, String pascal) {
  return '''import '../entities/$feature.dart';

/// $pascal repository interface.
///
/// Defines the contract for $feature data operations.
/// Uses domain entities only - no data layer imports.
abstract interface class ${pascal}Repository {
  /// Get all $feature items.
  Future<List<$pascal>> getAll();

  /// Get $feature by ID.
  Future<$pascal?> getById(String id);

  // TODO: Add methods based on feature requirements
}
''';
}

String _generateModel(String feature, String pascal) {
  return '''import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/$feature.dart';

part '${feature}_model.freezed.dart';
part '${feature}_model.g.dart';

/// $pascal data transfer object.
///
/// Handles JSON serialization. Maps to domain entity.
@freezed
abstract class ${pascal}Model with _\$${pascal}Model {
  const ${pascal}Model._();

  const factory ${pascal}Model({
    required String id,
    // TODO: Add fields based on feature requirements
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _${pascal}Model;

  factory ${pascal}Model.fromJson(Map<String, dynamic> json) =>
      _\$${pascal}ModelFromJson(json);

  /// Convert to domain entity.
  $pascal toEntity() => $pascal(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Create from domain entity.
  factory ${pascal}Model.fromEntity($pascal entity) => ${pascal}Model(
        id: entity.id,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}
''';
}

String _generateRepositoryImpl(String feature, String pascal) {
  return '''import '../../domain/entities/$feature.dart';
import '../../domain/repositories/${feature}_repository.dart';
import '../models/${feature}_model.dart';

/// Implementation of [${pascal}Repository].
///
/// Fetches data, maps DTOs to domain entities.
final class ${pascal}RepositoryImpl implements ${pascal}Repository {
  const ${pascal}RepositoryImpl();
  // TODO: Add dependencies (Dio, storage, etc.) via constructor

  @override
  Future<List<$pascal>> getAll() async {
    // TODO: Fetch data, map to entities
    // final response = await _dio.get('/$feature');
    // final models = (response.data as List)
    //     .map((json) => ${pascal}Model.fromJson(json))
    //     .toList();
    // return models.map((m) => m.toEntity()).toList();
    throw UnimplementedError();
  }

  @override
  Future<$pascal?> getById(String id) async {
    // TODO: Fetch data, map to entity
    throw UnimplementedError();
  }
}
''';
}

String _generateState(String feature, String pascal) {
  return '''import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/$feature.dart';

part '${feature}_state.freezed.dart';

/// $pascal state.
///
/// Uses domain entities only - no data layer imports.
@freezed
sealed class ${pascal}State with _\$${pascal}State {
  const factory ${pascal}State.initial() = ${pascal}StateInitial;
  const factory ${pascal}State.loading() = ${pascal}StateLoading;
  const factory ${pascal}State.loaded({
    required List<$pascal> items,
  }) = ${pascal}StateLoaded;
  const factory ${pascal}State.error(String message) = ${pascal}StateError;
}
''';
}

String _generateProvider(String feature, String pascal, String camel) {
  return '''import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/${feature}_repository.dart';
import '${feature}_state.dart';

part '${feature}_provider.g.dart';

// Note: Repository provider should be defined in core/providers.dart
// to keep presentation layer independent of data layer.
//
// Example in core/providers.dart:
// @riverpod
// ${pascal}Repository ${camel}Repository(Ref ref) {
//   return ${pascal}RepositoryImpl(ref.watch(dioProvider));
// }

/// $pascal state notifier.
///
/// Uses domain repository interface only - no data layer imports.
@riverpod
final class ${pascal}Notifier extends _\$${pascal}Notifier {
  bool _disposed = false;

  @override
  ${pascal}State build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _loadInitialData();
    return const ${pascal}State.initial();
  }

  void _safeSetState(${pascal}State newState) {
    if (!_disposed) {
      state = newState;
    }
  }

  Future<void> _loadInitialData() async {
    _safeSetState(const ${pascal}State.loading());

    try {
      final repository = ref.read(${camel}RepositoryProvider);
      final items = await repository.getAll();
      if (_disposed) return;
      _safeSetState(${pascal}State.loaded(items: items));
    } catch (e) {
      if (_disposed) return;
      _safeSetState(${pascal}State.error(e.toString()));
    }
  }

  Future<void> refresh() async {
    await _loadInitialData();
  }
}
''';
}

String _generateScreen(String feature, String pascal, String camel) {
  return '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/strings.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/${feature}_provider.dart';
import '../providers/${feature}_state.dart';

/// $pascal screen.
///
/// Uses domain entities via state - no data layer imports.
final class ${pascal}Screen extends ConsumerWidget {
  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${camel}NotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.$feature.title),
      ),
      body: switch (state) {
        ${pascal}StateInitial() || ${pascal}StateLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        ${pascal}StateLoaded(:final items) => items.isEmpty
            ? EmptyState(
                icon: Icons.inbox_outlined,
                message: t.$feature.empty,
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(item.id), // TODO: Replace with actual field
                  );
                },
              ),
        ${pascal}StateError(:final message) => EmptyState(
            icon: Icons.error_outline,
            message: message,
          ),
      },
    );
  }
}
''';
}

String _generateI18n(String feature, String pascal) {
  return '''# $pascal feature strings
# Usage: t.$feature.title, t.$feature.*, etc.
#
# After editing, run:
#   dart run build_runner build --delete-conflicting-outputs

title: $pascal
empty: No items yet

# TODO: Use /i18n skill to add user-friendly strings
''';
}

// ============================================================
// HELPERS
// ============================================================

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

String _relativePath(String path) {
  return path.replaceFirst('$featuresDir/', '');
}

String? _getArgValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  final value = args[index + 1];
  if (value.startsWith('-')) return null;
  return value;
}

String _toPascalCase(String input) {
  return input.split('_').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join();
}

String _toCamelCase(String input) {
  final pascal = _toPascalCase(input);
  if (pascal.isEmpty) return pascal;
  return pascal[0].toLowerCase() + pascal.substring(1);
}

void _writeFile(String path, String content) {
  File(path).writeAsStringSync(content);
  print('  📄 Created: $path');
}

void _printHelp() {
  print('''
Feature Structure Tool

Manages Clean Architecture feature scaffolding.

USAGE:
  dart run .claude/skills/feature-init/scripts/check.dart [options]

OPTIONS:
  -g, --generate <name>   Generate new feature scaffolding
  -v, --validate <name>   Validate existing feature structure
  -h, --help              Show this help message

EXAMPLES:
  dart run .claude/skills/feature-init/scripts/check.dart                    # Check all features
  dart run .claude/skills/feature-init/scripts/check.dart -g bookmarks       # Generate bookmarks feature
  dart run .claude/skills/feature-init/scripts/check.dart --validate auth    # Validate auth feature

FEATURE STRUCTURE:
  lib/features/{feature}/
  ├── domain/                               # No external dependencies
  │   ├── entities/
  │   │   └── {feature}.dart                # Pure domain entity
  │   └── repositories/
  │       └── {feature}_repository.dart     # Interface (uses entities)
  ├── data/                                 # Depends on domain only
  │   ├── models/
  │   │   └── {feature}_model.dart          # DTO with toEntity/fromEntity
  │   └── repositories/
  │       └── {feature}_repository_impl.dart
  ├── presentation/                         # Depends on domain only
  │   ├── providers/
  │   │   ├── {feature}_state.dart          # Uses domain entities
  │   │   └── {feature}_provider.dart       # Riverpod notifier
  │   ├── screens/
  │   │   └── {feature}_screen.dart         # Consumer widget
  │   └── widgets/
  └── i18n/
      └── {feature}.i18n.yaml               # Localized strings

DEPENDENCY RULES:
  Domain      → No dependencies (innermost layer)
  Data        → Depends on Domain only
  Presentation → Depends on Domain only

  Data and Presentation must NEVER depend on each other.

WORKFLOW:
  1. Generate feature:  dart run .claude/skills/feature-init/scripts/check.dart -g feature_name
  2. Add strings:       /i18n feature_name
  3. Add tests:         /testing feature_name
  4. Polish UI:         /design
  5. Add route:         lib/core/router/app_router.dart
  6. Generate code:     dart run build_runner build --delete-conflicting-outputs
''');
}

// ============================================================
// DATA CLASSES
// ============================================================

final class FeatureAnalysis {
  final List<String> presentLayers;
  final List<String> missingLayers;
  final int completeness;

  const FeatureAnalysis({
    required this.presentLayers,
    required this.missingLayers,
    required this.completeness,
  });
}

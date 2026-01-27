// ignore_for_file: avoid_print
import 'dart:io';

/// Data Layer Validation Script
///
/// Usage:
///   dart run .claude/skills/data/scripts/check.dart {feature}
///   dart run .claude/skills/data/scripts/check.dart memories
///   dart run .claude/skills/data/scripts/check.dart --all
///   dart run .claude/skills/data/scripts/check.dart tasks --generate
///   dart run .claude/skills/data/scripts/check.dart --deep
///   dart run .claude/skills/data/scripts/check.dart -f auth --deep
///
/// Checks:
/// - Data layer structure exists
/// - DTOs have Freezed annotations
/// - DTOs have toEntity() and fromEntity() methods
/// - Repository implements domain interface
/// - No direct Flutter imports
/// - Data sources follow patterns
/// - Mock repository exists (--deep)
/// - Provider registration (--deep)
void main(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printUsage();
    if (args.contains('--help') || args.contains('-h')) {
      exit(0);
    }
    exit(1);
  }

  final checkAll = args.contains('--all');
  final generate = args.contains('--generate');
  final deep = args.contains('--deep') || args.contains('-d');
  final featureArg = _getArgValue(args, '--feature') ?? _getArgValue(args, '-f');
  final features = args
      .where((a) => !a.startsWith('--') && !a.startsWith('-'))
      .where((a) => a != featureArg)
      .toList();

  // Add featureArg to features if provided
  if (featureArg != null) features.add(featureArg);

  print('');
  print('═══════════════════════════════════════════════════════');
  print('  Data Layer Validation');
  print('═══════════════════════════════════════════════════════');
  print('');

  if (checkAll) {
    _checkAllFeatures(generate: generate, deep: deep);
  } else if (features.isEmpty) {
    _printUsage();
    exit(1);
  } else {
    var totalIssues = 0;
    for (final feature in features) {
      totalIssues += _checkFeature(feature, generate: generate, deep: deep);
    }
    _printSummary(totalIssues, deep);
  }
}

void _printUsage() {
  print('''
Data Layer Validation Script

Validates data layer implementation following Clean Architecture patterns.

USAGE:
  dart run .claude/skills/data/scripts/check.dart [options] [feature]

OPTIONS:
  --all             Check all features
  -f, --feature     Check specific feature
  -d, --deep        Deep validation (mock repos, providers)
  --generate        Generate skeleton data layer files
  -h, --help        Show this help message

EXAMPLES:
  dart run .claude/skills/data/scripts/check.dart memories
  dart run .claude/skills/data/scripts/check.dart -f auth --deep
  dart run .claude/skills/data/scripts/check.dart tasks --generate
  dart run .claude/skills/data/scripts/check.dart --all
  dart run .claude/skills/data/scripts/check.dart --all --deep

CHECKS PERFORMED:

  Structure:
    ✓ data/models/ directory exists
    ✓ data/repositories/ directory exists
    ✓ data/data_sources/ directory exists (optional)

  DTOs (data/models/):
    ✓ Uses @freezed annotation
    ✓ Has part '{name}.freezed.dart'
    ✓ Has part '{name}.g.dart' for JSON
    ✓ Has toEntity() method
    ✓ Has fromEntity() factory
    ✓ No Flutter imports

  Repository Implementation:
    ✓ Implements domain interface
    ✓ Uses final class
    ✓ Imports domain repository interface
    ✓ Returns domain entities (not models)
    ✓ No Flutter imports

  Data Sources:
    ✓ Uses final class
    ✓ Remote sources use Dio
    ✓ Returns models (not entities)
    ✓ No Flutter UI imports

  Deep Checks (--deep):
    ✓ Mock repository exists
    ✓ Mock implements interface
    ✓ Mock has delay simulation
    ✓ Provider registered in core/providers.dart

SEVERITY LEVELS:
  ✗ Error   - Must fix for proper Clean Architecture
  ⚠ Warning - Should fix for best practices
  ℹ Info    - Suggestions for improvement
''');
}

void _checkAllFeatures({required bool generate, required bool deep}) {
  final featuresDir = Directory('lib/features');
  if (!featuresDir.existsSync()) {
    print('No features directory found at lib/features/');
    exit(1);
  }

  final features = featuresDir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split('/').last)
      .where((name) => !name.startsWith('.'))
      .toList()
    ..sort();

  if (features.isEmpty) {
    print('No features found in lib/features/');
    exit(0);
  }

  print('Checking ${features.length} features...\n');

  var totalIssues = 0;
  for (final feature in features) {
    totalIssues += _checkFeature(feature, generate: generate, deep: deep);
  }

  _printSummary(totalIssues, deep);
}

void _printSummary(int totalIssues, bool deep) {
  print('───────────────────────────────────────────────────────');
  print('');
  if (totalIssues == 0) {
    print('All features pass data layer checks.');
  } else {
    print('Total issues found: $totalIssues');
    if (!deep) {
      print('');
      print('Run with --deep for more detailed analysis:');
      print('  dart run .claude/skills/data/scripts/check.dart --all --deep');
    }
  }
  print('');
}

int _checkFeature(String feature, {required bool generate, required bool deep}) {
  final featureDir = Directory('lib/features/$feature');
  if (!featureDir.existsSync()) {
    print('❌ Feature directory not found: lib/features/$feature');
    return 1;
  }

  // Check if domain layer exists first
  final domainDir = Directory('lib/features/$feature/domain');
  if (!domainDir.existsSync()) {
    print('⚠️  $feature: Domain layer not found. Run /domain $feature first.');
    print('');
    return 1;
  }

  final dataDir = Directory('lib/features/$feature/data');
  final issues = <_AuditIssue>[];

  if (!dataDir.existsSync()) {
    if (generate) {
      _generateDataLayer(feature);
      print('✅ $feature: Generated skeleton data layer');
      print('');
      return 0;
    } else {
      issues.add(_AuditIssue(
        severity: _Severity.error,
        message: 'Data layer directory not found: lib/features/$feature/data/',
        suggestion: 'Run with --generate to create skeleton files',
      ));
    }
  } else {
    // Check data layer structure
    issues.addAll(_checkDataStructure(feature));

    // Check DTOs
    issues.addAll(_checkDTOs(feature));

    // Check repository implementation
    issues.addAll(_checkRepositoryImpl(feature, deep: deep));

    // Check data sources
    issues.addAll(_checkDataSources(feature));

    // Deep checks
    if (deep) {
      issues.addAll(_checkMockRepository(feature));
      issues.addAll(_checkProviderRegistration(feature));
    }
  }

  // Print results
  _printFeatureResult(feature, issues, deep);

  return issues.where((i) => i.severity != _Severity.info).length;
}

void _printFeatureResult(String feature, List<_AuditIssue> issues, bool deep) {
  final icon = issues.isEmpty
      ? '✅'
      : issues.any((i) => i.severity == _Severity.error)
          ? '❌'
          : '⚠️';

  print('$icon $feature');

  if (issues.isEmpty) {
    print('   All data layer checks passed.');
  } else {
    final errors = issues.where((i) => i.severity == _Severity.error).toList();
    final warnings = issues.where((i) => i.severity == _Severity.warning).toList();
    final infos = issues.where((i) => i.severity == _Severity.info).toList();

    if (errors.isNotEmpty) {
      print('   Errors (${errors.length}):');
      for (final issue in errors) {
        print('     ✗ ${issue.message}');
        if (deep && issue.suggestion != null) {
          print('       → ${issue.suggestion}');
        }
      }
    }

    if (warnings.isNotEmpty) {
      print('   Warnings (${warnings.length}):');
      for (final issue in warnings) {
        print('     ⚠ ${issue.message}');
        if (deep && issue.suggestion != null) {
          print('       → ${issue.suggestion}');
        }
      }
    }

    if (deep && infos.isNotEmpty) {
      print('   Info (${infos.length}):');
      for (final issue in infos) {
        print('     ℹ ${issue.message}');
      }
    }
  }

  print('');
}

List<_AuditIssue> _checkDataStructure(String feature) {
  final issues = <_AuditIssue>[];
  final dataDir = Directory('lib/features/$feature/data');

  // Check for required subdirectories
  final requiredDirs = ['models', 'repositories'];
  for (final dir in requiredDirs) {
    final subDir = Directory('${dataDir.path}/$dir');
    if (!subDir.existsSync()) {
      issues.add(_AuditIssue(
        severity: _Severity.error,
        message: 'Missing directory: data/$dir/',
        suggestion: 'Create the $dir directory for data layer components',
      ));
    }
  }

  return issues;
}

List<_AuditIssue> _checkDTOs(String feature) {
  final issues = <_AuditIssue>[];
  final modelsDir = Directory('lib/features/$feature/data/models');

  if (!modelsDir.existsSync()) {
    return [
      _AuditIssue(
        severity: _Severity.error,
        message: 'Models directory not found',
      )
    ];
  }

  final modelFiles = modelsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.freezed.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .toList();

  if (modelFiles.isEmpty) {
    issues.add(_AuditIssue(
      severity: _Severity.warning,
      message: 'No model files found in data/models/',
      suggestion: 'Create Freezed DTOs for API responses',
    ));
    return issues;
  }

  for (final file in modelFiles) {
    final content = file.readAsStringSync();
    final fileName = file.path.split('/').last;
    final fileIssues = <_AuditIssue>[];

    // Check for Freezed annotation (required in data layer)
    if (!content.contains('@freezed')) {
      fileIssues.add(_AuditIssue(
        severity: _Severity.warning,
        message: 'Missing @freezed annotation',
        suggestion: 'Use Freezed for DTOs with JSON serialization',
      ));
    }

    // Check for Freezed import
    if (!content.contains("package:freezed_annotation")) {
      fileIssues.add(_AuditIssue(
        severity: _Severity.warning,
        message: 'Missing freezed_annotation import',
      ));
    }

    // Check for part directives
    if (!content.contains('.freezed.dart')) {
      fileIssues.add(_AuditIssue(
        severity: _Severity.warning,
        message: "Missing part '{name}.freezed.dart' directive",
      ));
    }

    // Check for JSON support (most DTOs need it)
    final isRequestModel = fileName.contains('request');
    final isResponseModel = fileName.contains('response');
    final isMainModel = fileName.endsWith('_model.dart');

    if ((isMainModel || isRequestModel || isResponseModel) &&
        !content.contains('.g.dart')) {
      fileIssues.add(_AuditIssue(
        severity: _Severity.warning,
        message: "Missing part '{name}.g.dart' directive for JSON",
        suggestion: 'Add JSON serialization with json_serializable',
      ));
    }

    // Check for toEntity method (main models should have it)
    if (isMainModel && !isRequestModel && !isResponseModel) {
      if (!content.contains('toEntity()')) {
        fileIssues.add(_AuditIssue(
          severity: _Severity.error,
          message: 'Missing toEntity() method',
          suggestion: 'Add toEntity() to map DTO to domain entity',
        ));
      }
      if (!content.contains('fromEntity(')) {
        fileIssues.add(_AuditIssue(
          severity: _Severity.warning,
          message: 'Missing fromEntity() factory',
          suggestion: 'Add fromEntity() for mapping entity back to DTO',
        ));
      }
    }

    // Check for Flutter imports (should not be in data layer models)
    if (content.contains("package:flutter/")) {
      fileIssues.add(_AuditIssue(
        severity: _Severity.error,
        message: 'Flutter import found - data models should not use Flutter',
        suggestion: 'Remove Flutter imports from data layer',
      ));
    }

    if (fileIssues.isNotEmpty) {
      issues.add(_AuditIssue(
        severity: _Severity.info,
        message: '$fileName:',
      ));
      issues.addAll(fileIssues);
    }
  }

  return issues;
}

List<_AuditIssue> _checkRepositoryImpl(String feature, {required bool deep}) {
  final issues = <_AuditIssue>[];
  final reposDir = Directory('lib/features/$feature/data/repositories');

  if (!reposDir.existsSync()) {
    return [
      _AuditIssue(
        severity: _Severity.error,
        message: 'Repositories directory not found',
      )
    ];
  }

  final repoFiles = reposDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('_impl.dart'))
      .toList();

  if (repoFiles.isEmpty) {
    issues.add(_AuditIssue(
      severity: _Severity.warning,
      message: 'No repository implementation files found (*_impl.dart)',
      suggestion: 'Create ${feature}_repository_impl.dart',
    ));
    return issues;
  }

  for (final file in repoFiles) {
    final content = file.readAsStringSync();
    final fileName = file.path.split('/').last;
    final fileIssues = <_AuditIssue>[];

    // Check for implements keyword
    if (!content.contains('implements')) {
      fileIssues.add(_AuditIssue(
        severity: _Severity.error,
        message: 'Repository should implement domain interface',
      ));
    }

    // Check for domain repository import
    if (!content.contains("domain/repositories/")) {
      fileIssues.add(_AuditIssue(
        severity: _Severity.error,
        message: 'Missing import of domain repository interface',
      ));
    }

    // Check for final class
    if (!content.contains('final class')) {
      fileIssues.add(_AuditIssue(
        severity: _Severity.warning,
        message: 'Repository implementation should be final class',
      ));
    }

    // Check for Flutter imports
    if (content.contains("package:flutter/")) {
      fileIssues.add(_AuditIssue(
        severity: _Severity.error,
        message: 'Flutter import found - repository should not use Flutter',
      ));
    }

    // Check that it returns domain entities, not models
    if (content.contains('Future<') && content.contains('Model>')) {
      if (RegExp(r'Future<\w*Model>').hasMatch(content)) {
        fileIssues.add(_AuditIssue(
          severity: _Severity.error,
          message: 'Repository should return domain entities, not models',
          suggestion: 'Call toEntity() on models before returning',
        ));
      }
    }

    // Check for error handling (deep only)
    if (deep) {
      final hasDio = content.contains('Dio') || content.contains('_dio');
      final hasErrorMapping = content.contains('_mapDioError') ||
          content.contains('_mapError') ||
          content.contains('mapDioError') ||
          content.contains('on DioException');

      if (hasDio && !hasErrorMapping) {
        fileIssues.add(_AuditIssue(
          severity: _Severity.warning,
          message: 'Missing Dio error handling',
          suggestion: 'Add error mapping to convert DioException to Failure',
        ));
      }

      // Check for TODO stubs
      if (content.contains('throw UnimplementedError()') ||
          content.contains('// TODO')) {
        fileIssues.add(_AuditIssue(
          severity: _Severity.warning,
          message: 'Contains unimplemented methods or TODOs',
        ));
      }

      // Check entity mapping
      if (!content.contains('.toEntity()')) {
        fileIssues.add(_AuditIssue(
          severity: _Severity.warning,
          message: 'Not calling toEntity() on DTOs',
          suggestion: 'Map DTOs to domain entities before returning',
        ));
      }
    }

    if (fileIssues.isNotEmpty) {
      issues.add(_AuditIssue(
        severity: _Severity.info,
        message: '$fileName:',
      ));
      issues.addAll(fileIssues);
    }
  }

  return issues;
}

List<_AuditIssue> _checkDataSources(String feature) {
  final issues = <_AuditIssue>[];
  final dataSourcesDir = Directory('lib/features/$feature/data/data_sources');

  if (!dataSourcesDir.existsSync()) {
    // Data sources are optional
    return [];
  }

  final sourceFiles = dataSourcesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  for (final file in sourceFiles) {
    final content = file.readAsStringSync();
    final fileName = file.path.split('/').last;
    final fileIssues = <_AuditIssue>[];

    // Check for final class
    if (!content.contains('final class')) {
      fileIssues.add(_AuditIssue(
        severity: _Severity.warning,
        message: 'Data source should be final class',
      ));
    }

    // Check remote data source for Dio
    if (fileName.contains('remote')) {
      if (!content.contains('Dio')) {
        fileIssues.add(_AuditIssue(
          severity: _Severity.info,
          message: 'Remote data source should typically use Dio',
        ));
      }
    }

    // Data sources should return models, not entities
    if (content.contains('toEntity()')) {
      fileIssues.add(_AuditIssue(
        severity: _Severity.error,
        message: 'Data source should return models, not call toEntity()',
        suggestion: 'toEntity() should be called in repository, not data source',
      ));
    }

    // Check for Flutter UI imports
    if (content.contains("package:flutter/material") ||
        content.contains("package:flutter/widgets")) {
      fileIssues.add(_AuditIssue(
        severity: _Severity.error,
        message: 'Data source should not import Flutter UI',
      ));
    }

    if (fileIssues.isNotEmpty) {
      issues.add(_AuditIssue(
        severity: _Severity.info,
        message: '$fileName:',
      ));
      issues.addAll(fileIssues);
    }
  }

  return issues;
}

List<_AuditIssue> _checkMockRepository(String feature) {
  final issues = <_AuditIssue>[];
  final reposDir = Directory('lib/features/$feature/data/repositories');

  if (!reposDir.existsSync()) return [];

  // Look for mock repository
  final mockFiles = reposDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.contains('mock_') && f.path.endsWith('.dart'))
      .toList();

  if (mockFiles.isEmpty) {
    issues.add(_AuditIssue(
      severity: _Severity.warning,
      message: 'Missing mock repository for testing',
      suggestion: 'Create mock_${feature}_repository.dart',
    ));
    return issues;
  }

  for (final file in mockFiles) {
    final content = file.readAsStringSync();
    final fileName = file.path.split('/').last;

    // Check implements interface
    if (!content.contains('implements')) {
      issues.add(_AuditIssue(
        severity: _Severity.warning,
        message: '$fileName: Does not implement repository interface',
      ));
    }

    // Check has delay simulation
    if (!content.contains('Future.delayed')) {
      issues.add(_AuditIssue(
        severity: _Severity.info,
        message: '$fileName: No delay simulation for realistic testing',
        suggestion: 'Add Future.delayed() to simulate network latency',
      ));
    }
  }

  return issues;
}

List<_AuditIssue> _checkProviderRegistration(String feature) {
  final issues = <_AuditIssue>[];
  final providersFile = File('lib/core/providers.dart');

  if (!providersFile.existsSync()) {
    issues.add(_AuditIssue(
      severity: _Severity.info,
      message: 'core/providers.dart not found - verify provider registration',
    ));
    return issues;
  }

  final content = providersFile.readAsStringSync();
  final pascalCase = _toPascalCase(feature);
  final camelCase = _toCamelCase(feature);

  // Check for repository provider
  if (!content.contains('${camelCase}Repository') &&
      !content.contains('${pascalCase}Repository')) {
    issues.add(_AuditIssue(
      severity: _Severity.warning,
      message: 'Repository provider not found in core/providers.dart',
      suggestion: 'Add ${camelCase}RepositoryProvider to core/providers.dart',
    ));
  }

  return issues;
}

void _generateDataLayer(String feature) {
  final dataDir = Directory('lib/features/$feature/data');
  final modelsDir = Directory('${dataDir.path}/models');
  final reposDir = Directory('${dataDir.path}/repositories');
  final sourcesDir = Directory('${dataDir.path}/data_sources');

  // Create directories
  modelsDir.createSync(recursive: true);
  reposDir.createSync(recursive: true);
  sourcesDir.createSync(recursive: true);

  // Get feature name in different cases
  final featurePascal = _toPascalCase(feature);
  final featureSnake = _toSnakeCase(feature);
  final entityName = _singularize(featurePascal);
  final entitySnake = _toSnakeCase(entityName);

  // Generate model file
  final modelFile = File('${modelsDir.path}/${entitySnake}_model.dart');
  modelFile.writeAsStringSync('''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/$entitySnake.dart';

part '${entitySnake}_model.freezed.dart';
part '${entitySnake}_model.g.dart';

/// DTO for $entityName entity.
@freezed
abstract class ${entityName}Model with _\$${entityName}Model {
  const ${entityName}Model._();

  const factory ${entityName}Model({
    required String id,
    // TODO: Add fields matching API response
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _${entityName}Model;

  factory ${entityName}Model.fromJson(Map<String, dynamic> json) =>
      _\$${entityName}ModelFromJson(json);

  /// Convert to domain entity.
  $entityName toEntity() => $entityName(
    id: id,
    // TODO: Map all fields
    createdAt: createdAt,
  );

  /// Create from domain entity.
  factory ${entityName}Model.fromEntity($entityName entity) => ${entityName}Model(
    id: entity.id,
    // TODO: Map all fields
    createdAt: entity.createdAt,
  );
}
''');

  // Generate remote data source
  final remoteSourceFile =
      File('${sourcesDir.path}/${featureSnake}_remote_data_source.dart');
  remoteSourceFile.writeAsStringSync('''
import 'package:dio/dio.dart';
import '../models/${entitySnake}_model.dart';

/// Remote data source for $feature API.
final class ${featurePascal}RemoteDataSource {
  const ${featurePascal}RemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Fetch all ${feature.toLowerCase()}.
  Future<List<${entityName}Model>> fetchAll() async {
    final response = await _dio.get('/$featureSnake');
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => ${entityName}Model.fromJson(json)).toList();
  }

  /// Fetch a single ${entityName.toLowerCase()} by ID.
  Future<${entityName}Model?> fetchById(String id) async {
    try {
      final response = await _dio.get('/$featureSnake/\$id');
      return ${entityName}Model.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  // TODO: Add create, update, delete methods
}
''');

  // Generate repository implementation
  final repoImplFile =
      File('${reposDir.path}/${featureSnake}_repository_impl.dart');
  repoImplFile.writeAsStringSync('''
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/$entitySnake.dart';
import '../../domain/repositories/${featureSnake}_repository.dart';
import '../data_sources/${featureSnake}_remote_data_source.dart';

/// Implementation of ${featurePascal}Repository.
final class ${featurePascal}RepositoryImpl implements ${featurePascal}Repository {
  const ${featurePascal}RepositoryImpl({
    required ${featurePascal}RemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ${featurePascal}RemoteDataSource _remoteDataSource;

  @override
  Future<List<$entityName>> getAll() async {
    try {
      final models = await _remoteDataSource.fetchAll();
      return models.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<$entityName?> getById(String id) async {
    try {
      final model = await _remoteDataSource.fetchById(id);
      return model?.toEntity();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _mapDioError(e);
    }
  }

  // TODO: Implement remaining repository methods

  Failure _mapDioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const Failure.network(NetworkFailure.timeout()),
      DioExceptionType.connectionError =>
        const Failure.network(NetworkFailure.noConnection()),
      DioExceptionType.badResponse => _mapStatusCode(e.response?.statusCode),
      _ => Failure.network(NetworkFailure.unknown(e.message)),
    };
  }

  Failure _mapStatusCode(int? statusCode) {
    return switch (statusCode) {
      400 => const Failure.server(ServerFailure.badRequest()),
      401 => const Failure.server(ServerFailure.unauthorized()),
      403 => const Failure.server(ServerFailure.forbidden()),
      404 => const Failure.server(ServerFailure.notFound()),
      >= 500 => const Failure.server(ServerFailure.internal()),
      _ => Failure.server(ServerFailure.unknown(statusCode)),
    };
  }
}
''');

  // Generate mock repository
  final mockRepoFile =
      File('${reposDir.path}/mock_${featureSnake}_repository.dart');
  mockRepoFile.writeAsStringSync('''
import '../../domain/entities/$entitySnake.dart';
import '../../domain/repositories/${featureSnake}_repository.dart';

/// Mock implementation of ${featurePascal}Repository for testing.
final class Mock${featurePascal}Repository implements ${featurePascal}Repository {
  final List<$entityName> _items = [];
  int _idCounter = 0;

  @override
  Future<List<$entityName>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_items);
  }

  @override
  Future<$entityName?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _items.where((item) => item.id == id).firstOrNull;
  }

  // TODO: Implement remaining repository methods

  /// Reset mock data for testing.
  void reset() {
    _items.clear();
    _idCounter = 0;
  }

  /// Seed with test data.
  void seed(List<$entityName> items) {
    _items
      ..clear()
      ..addAll(items);
  }
}
''');

  print('');
  print('Generated skeleton files:');
  print('  - data/models/${entitySnake}_model.dart');
  print('  - data/data_sources/${featureSnake}_remote_data_source.dart');
  print('  - data/repositories/${featureSnake}_repository_impl.dart');
  print('  - data/repositories/mock_${featureSnake}_repository.dart');
  print('');
  print('Next steps:');
  print('  1. Update model fields to match API response');
  print('  2. Add toEntity/fromEntity field mappings');
  print('  3. Implement all repository methods');
  print('  4. Register provider in core/providers.dart');
  print('  5. Run: dart run build_runner build --delete-conflicting-outputs');
}

// ============================================================
// HELPERS
// ============================================================

String? _getArgValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  final value = args[index + 1];
  if (value.startsWith('-')) return null;
  return value;
}

String _toPascalCase(String input) {
  return input
      .split(RegExp(r'[_\-\s]+'))
      .map((word) => word.isEmpty
          ? ''
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join();
}

String _toCamelCase(String input) {
  final pascal = _toPascalCase(input);
  if (pascal.isEmpty) return pascal;
  return pascal[0].toLowerCase() + pascal.substring(1);
}

String _toSnakeCase(String input) {
  return input
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      )
      .replaceFirst(RegExp(r'^_'), '');
}

String _singularize(String input) {
  if (input.endsWith('ies')) {
    return '${input.substring(0, input.length - 3)}y';
  } else if (input.endsWith('es')) {
    return input.substring(0, input.length - 2);
  } else if (input.endsWith('s')) {
    return input.substring(0, input.length - 1);
  }
  return input;
}

// ============================================================
// DATA CLASSES
// ============================================================

enum _Severity { error, warning, info }

final class _AuditIssue {
  final _Severity severity;
  final String message;
  final String? suggestion;

  const _AuditIssue({
    required this.severity,
    required this.message,
    this.suggestion,
  });
}

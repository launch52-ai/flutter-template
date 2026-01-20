// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Offline Support Validation Script
///
/// Usage:
///   dart run .claude/skills/offline/scripts/check.dart --feature {feature}
///   dart run .claude/skills/offline/scripts/check.dart --all
///   dart run .claude/skills/offline/scripts/check.dart --deep
///
/// Checks:
/// - Local data source exists
/// - Sync status tracking in models
/// - Sync queue implementation
/// - Repository uses local-first pattern
/// - Sync service configured
void main(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printUsage();
    if (args.contains('--help') || args.contains('-h')) {
      exit(0);
    }
    exit(1);
  }

  final checkAll = args.contains('--all');
  final deep = args.contains('--deep') || args.contains('-d');
  final jsonOutput = args.contains('--json');
  final featureArg =
      _getArgValue(args, '--feature') ?? _getArgValue(args, '-f');
  final features = args
      .where((a) => !a.startsWith('--') && !a.startsWith('-'))
      .where((a) => a != featureArg)
      .toList();

  if (featureArg != null) features.add(featureArg);

  // JSON output mode
  if (jsonOutput) {
    final allIssues = <String, List<Map<String, dynamic>>>{};
    allIssues['core'] = _checkCoreInfrastructure(deep)
        .map((i) => {'severity': i.severity.name, 'message': i.message})
        .toList();

    if (checkAll) {
      final featuresDir = Directory('lib/features');
      if (featuresDir.existsSync()) {
        for (final dir in featuresDir.listSync().whereType<Directory>()) {
          final name = dir.path.split('/').last;
          if (!name.startsWith('.')) {
            allIssues[name] = _checkFeatureIssues(name, deep: deep)
                .map((i) => {'severity': i.severity.name, 'message': i.message})
                .toList();
          }
        }
      }
    } else {
      for (final feature in features) {
        allIssues[feature] = _checkFeatureIssues(feature, deep: deep)
            .map((i) => {'severity': i.severity.name, 'message': i.message})
            .toList();
      }
    }

    print(jsonEncode({
      'skill': 'offline',
      'issues': allIssues,
      'totalErrors': allIssues.values
          .expand((l) => l)
          .where((i) => i['severity'] == 'error')
          .length,
      'totalWarnings': allIssues.values
          .expand((l) => l)
          .where((i) => i['severity'] == 'warning')
          .length,
    }));
    exit(0);
  }

  print('');
  print('═══════════════════════════════════════════════════════');
  print('  Offline Support Validation');
  print('═══════════════════════════════════════════════════════');
  print('');

  // Always check core offline infrastructure
  final coreIssues = _checkCoreInfrastructure(deep);
  _printCoreResult(coreIssues, deep);

  if (checkAll) {
    _checkAllFeatures(deep: deep);
  } else if (features.isNotEmpty) {
    var totalIssues = coreIssues.length;
    for (final feature in features) {
      totalIssues += _checkFeature(feature, deep: deep);
    }
    _printSummary(totalIssues, deep);
  } else {
    _printSummary(coreIssues.length, deep);
  }
}

void _printUsage() {
  print('''
Offline Support Validation Script

Validates offline-first architecture implementation.

USAGE:
  dart run .claude/skills/offline/scripts/check.dart [options] [feature]

OPTIONS:
  --all             Check all features
  -f, --feature     Check specific feature
  -d, --deep        Deep validation (sync service, providers)
  --json            Output results as JSON (for CI integration)
  -h, --help        Show this help message

EXAMPLES:
  dart run .claude/skills/offline/scripts/check.dart -f tasks
  dart run .claude/skills/offline/scripts/check.dart --all
  dart run .claude/skills/offline/scripts/check.dart --all --deep

CHECKS PERFORMED:

  Core Infrastructure:
    ✓ Local database setup (Drift or Hive)
    ✓ Sync queue table/box exists
    ✓ Sync status enum defined
    ✓ Sync service implementation

  Feature-Level (per feature):
    ✓ Local data source exists
    ✓ Models have sync tracking fields
    ✓ Repository implements local-first pattern
    ✓ UUID generation for local IDs

  Deep Checks (--deep):
    ✓ Sync providers registered
    ✓ WorkManager setup for background sync
    ✓ Connectivity monitoring integration
    ✓ Conflict resolution strategy

SEVERITY LEVELS:
  ✗ Error   - Required for offline support
  ⚠ Warning - Recommended for robust implementation
  ℹ Info    - Suggestions for improvement
''');
}

// ─────────────────────────────────────────────────────────────────
// Core Infrastructure Checks
// ─────────────────────────────────────────────────────────────────

List<_AuditIssue> _checkCoreInfrastructure(bool deep) {
  final issues = <_AuditIssue>[];

  // Check for Drift or Hive
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    final content = pubspecFile.readAsStringSync();

    final hasDrift = content.contains('drift:');
    final hasHive = content.contains('hive_ce:') || content.contains('hive:');

    if (!hasDrift && !hasHive) {
      issues.add(_AuditIssue(
        severity: _Severity.error,
        message: 'No local database found in pubspec.yaml',
        suggestion: 'Add drift or hive_ce for offline storage',
      ));
    }

    if (!content.contains('uuid:')) {
      issues.add(_AuditIssue(
        severity: _Severity.warning,
        message: 'uuid package not found in pubspec.yaml',
        suggestion: 'Add uuid for client-generated IDs',
      ));
    }

    if (!content.contains('connectivity_plus:')) {
      issues.add(_AuditIssue(
        severity: _Severity.warning,
        message: 'connectivity_plus not found',
        suggestion: 'Add connectivity_plus for network detection',
      ));
    }
  }

  // Check for sync status enum
  final syncStatusFile = File('lib/core/data/sync/sync_status.dart');
  final altSyncStatusFile = File('lib/core/domain/sync_status.dart');
  if (!syncStatusFile.existsSync() && !altSyncStatusFile.existsSync()) {
    // Search for SyncStatus enum
    final found = _searchForPattern('lib', 'enum SyncStatus');
    if (found.isEmpty) {
      issues.add(_AuditIssue(
        severity: _Severity.error,
        message: 'SyncStatus enum not found',
        suggestion: 'Create sync_status.dart with SyncStatus enum',
      ));
    }
  }

  // Check for sync queue
  final hasQueue = _searchForPattern('lib', 'class SyncQueue').isNotEmpty ||
      _searchForPattern('lib', 'SyncOperations extends Table').isNotEmpty ||
      _searchForPattern('lib', "Box<SyncOperation").isNotEmpty;

  if (!hasQueue) {
    issues.add(_AuditIssue(
      severity: _Severity.error,
      message: 'Sync queue implementation not found',
      suggestion: 'Create SyncQueue for persisting pending operations',
    ));
  }

  // Check for sync service
  final hasSyncService =
      _searchForPattern('lib', 'class SyncService').isNotEmpty;

  if (!hasSyncService) {
    issues.add(_AuditIssue(
      severity: _Severity.warning,
      message: 'SyncService not found',
      suggestion: 'Create SyncService to orchestrate sync operations',
    ));
  }

  // Deep checks
  if (deep) {
    // Check for WorkManager
    final pubspec = File('pubspec.yaml');
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync();
      if (!content.contains('workmanager:')) {
        issues.add(_AuditIssue(
          severity: _Severity.info,
          message: 'workmanager package not found',
          suggestion: 'Add workmanager for background sync',
        ));
      }
    }

    // Check for conflict resolver
    final hasConflictResolver =
        _searchForPattern('lib', 'class ConflictResolver').isNotEmpty ||
            _searchForPattern('lib', 'ConflictStrategy').isNotEmpty;

    if (!hasConflictResolver) {
      issues.add(_AuditIssue(
        severity: _Severity.warning,
        message: 'ConflictResolver not found',
        suggestion: 'Create ConflictResolver for handling sync conflicts',
      ));
    }

    // Check sync providers
    final hasSyncProviders =
        _searchForPattern('lib', 'syncServiceProvider').isNotEmpty ||
            _searchForPattern('lib', 'SyncService syncService').isNotEmpty;

    if (!hasSyncProviders) {
      issues.add(_AuditIssue(
        severity: _Severity.warning,
        message: 'Sync providers not found',
        suggestion: 'Create providers for SyncService and SyncQueue',
      ));
    }
  }

  return issues;
}

void _printCoreResult(List<_AuditIssue> issues, bool deep) {
  final icon = issues.isEmpty
      ? '✅'
      : issues.any((i) => i.severity == _Severity.error)
          ? '❌'
          : '⚠️';

  print('$icon Core Offline Infrastructure');

  if (issues.isEmpty) {
    print('   All core checks passed.');
  } else {
    final errors = issues.where((i) => i.severity == _Severity.error).toList();
    final warnings =
        issues.where((i) => i.severity == _Severity.warning).toList();
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

// ─────────────────────────────────────────────────────────────────
// Feature Checks
// ─────────────────────────────────────────────────────────────────

void _checkAllFeatures({required bool deep}) {
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
    totalIssues += _checkFeature(feature, deep: deep);
  }

  _printSummary(totalIssues, deep);
}

int _checkFeature(String feature, {required bool deep}) {
  final featureDir = Directory('lib/features/$feature');
  if (!featureDir.existsSync()) {
    print('❌ Feature directory not found: lib/features/$feature');
    return 1;
  }

  final dataDir = Directory('lib/features/$feature/data');
  if (!dataDir.existsSync()) {
    print('⚠️  $feature: No data layer - skipping offline checks');
    print('');
    return 0;
  }

  final issues = <_AuditIssue>[];

  // Check for local data source
  issues.addAll(_checkLocalDataSource(feature));

  // Check models for sync tracking
  issues.addAll(_checkModelsForSyncTracking(feature));

  // Check repository for local-first pattern
  issues.addAll(_checkRepositoryPattern(feature, deep: deep));

  _printFeatureResult(feature, issues, deep);

  return issues.where((i) => i.severity != _Severity.info).length;
}

/// Returns issues for JSON output (doesn't print).
List<_AuditIssue> _checkFeatureIssues(String feature, {required bool deep}) {
  final featureDir = Directory('lib/features/$feature');
  if (!featureDir.existsSync()) {
    return [_AuditIssue(severity: _Severity.error, message: 'Feature directory not found')];
  }

  final dataDir = Directory('lib/features/$feature/data');
  if (!dataDir.existsSync()) {
    return [];
  }

  final issues = <_AuditIssue>[];
  issues.addAll(_checkLocalDataSource(feature));
  issues.addAll(_checkModelsForSyncTracking(feature));
  issues.addAll(_checkRepositoryPattern(feature, deep: deep));
  return issues;
}

List<_AuditIssue> _checkLocalDataSource(String feature) {
  final issues = <_AuditIssue>[];
  final dataSourcesDir = Directory('lib/features/$feature/data/data_sources');

  if (!dataSourcesDir.existsSync()) {
    issues.add(_AuditIssue(
      severity: _Severity.warning,
      message: 'No data_sources directory found',
      suggestion: 'Create local data source for offline storage',
    ));
    return issues;
  }

  final files = dataSourcesDir.listSync().whereType<File>().toList();
  final hasLocalSource = files.any((f) =>
      f.path.contains('local') ||
      f.path.contains('_local_') ||
      f.path.contains('_local.dart'));

  if (!hasLocalSource) {
    issues.add(_AuditIssue(
      severity: _Severity.warning,
      message: 'No local data source found',
      suggestion: 'Create {feature}_local_data_source.dart',
    ));
  }

  return issues;
}

List<_AuditIssue> _checkModelsForSyncTracking(String feature) {
  final issues = <_AuditIssue>[];
  final modelsDir = Directory('lib/features/$feature/data/models');

  if (!modelsDir.existsSync()) return issues;

  final modelFiles = modelsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.freezed.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .toList();

  for (final file in modelFiles) {
    final content = file.readAsStringSync();
    final fileName = file.path.split('/').last;

    // Skip request models
    if (fileName.contains('request')) continue;

    final hasSyncStatus = content.contains('syncStatus') ||
        content.contains('sync_status') ||
        content.contains('SyncStatus');

    final hasLocalId = content.contains('localId') || content.contains('local_id');

    if (!hasSyncStatus && !hasLocalId) {
      issues.add(_AuditIssue(
        severity: _Severity.info,
        message: '$fileName: No sync tracking fields found',
        suggestion: 'Add localId and syncStatus for offline support',
      ));
    }
  }

  return issues;
}

List<_AuditIssue> _checkRepositoryPattern(String feature, {required bool deep}) {
  final issues = <_AuditIssue>[];
  final reposDir = Directory('lib/features/$feature/data/repositories');

  if (!reposDir.existsSync()) return issues;

  final repoFiles = reposDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('_impl.dart'))
      .toList();

  for (final file in repoFiles) {
    final content = file.readAsStringSync();
    final fileName = file.path.split('/').last;

    // Check for local data source usage
    final hasLocalSource = content.contains('LocalDataSource') ||
        content.contains('_local') ||
        content.contains('localDataSource');

    if (!hasLocalSource) {
      issues.add(_AuditIssue(
        severity: _Severity.warning,
        message: '$fileName: No local data source reference',
        suggestion: 'Add LocalDataSource for offline support',
      ));
    }

    // Check for sync queue usage
    final hasSyncQueue = content.contains('SyncQueue') ||
        content.contains('_queue') ||
        content.contains('syncQueue');

    if (!hasSyncQueue && deep) {
      issues.add(_AuditIssue(
        severity: _Severity.info,
        message: '$fileName: No sync queue reference',
        suggestion: 'Add SyncQueue for queueing offline operations',
      ));
    }

    // Check for UUID usage
    final hasUuid =
        content.contains('Uuid') || content.contains('uuid') || content.contains('UUID');

    if (!hasUuid && deep) {
      issues.add(_AuditIssue(
        severity: _Severity.info,
        message: '$fileName: No UUID generation found',
        suggestion: 'Use UUID for client-generated local IDs',
      ));
    }

    // Check for local-first pattern indicators
    final hasLocalFirst = content.contains('// Save to local') ||
        content.contains('await _local') ||
        content.contains('localDataSource');

    if (!hasLocalFirst && deep) {
      issues.add(_AuditIssue(
        severity: _Severity.warning,
        message: '$fileName: May not follow local-first pattern',
        suggestion: 'Write to local storage before remote',
      ));
    }
  }

  return issues;
}

void _printFeatureResult(String feature, List<_AuditIssue> issues, bool deep) {
  final icon = issues.isEmpty
      ? '✅'
      : issues.any((i) => i.severity == _Severity.error)
          ? '❌'
          : '⚠️';

  print('$icon $feature');

  if (issues.isEmpty) {
    print('   Offline support checks passed.');
  } else {
    final errors = issues.where((i) => i.severity == _Severity.error).toList();
    final warnings =
        issues.where((i) => i.severity == _Severity.warning).toList();
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

void _printSummary(int totalIssues, bool deep) {
  print('───────────────────────────────────────────────────────');
  print('');
  if (totalIssues == 0) {
    print('All offline support checks passed.');
  } else {
    print('Total issues found: $totalIssues');
    if (!deep) {
      print('');
      print('Run with --deep for more detailed analysis:');
      print('  dart run .claude/skills/offline/scripts/check.dart --all --deep');
    }
  }
  print('');
}

// ─────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────

String? _getArgValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  final value = args[index + 1];
  if (value.startsWith('-')) return null;
  return value;
}

List<String> _searchForPattern(String directory, String pattern) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return [];

  final matches = <String>[];

  void search(Directory d) {
    for (final entity in d.listSync()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        try {
          final content = entity.readAsStringSync();
          if (content.contains(pattern)) {
            matches.add(entity.path);
          }
        } catch (_) {}
      } else if (entity is Directory && !entity.path.contains('.')) {
        search(entity);
      }
    }
  }

  search(dir);
  return matches;
}

// ─────────────────────────────────────────────────────────────────
// Data Classes
// ─────────────────────────────────────────────────────────────────

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

#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Adds standard headers to reference files that are missing them.
///
/// Usage:
///   dart run .claude/skills/skill-create/scripts/fix_headers.dart
///   dart run .claude/skills/skill-create/scripts/fix_headers.dart --skill data
///   dart run .claude/skills/skill-create/scripts/fix_headers.dart --dry-run
void main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final skillFilter = _getArgValue(args, '--skill');

  print('');
  print('═══════════════════════════════════════════════════════════');
  print('  Reference File Header Fixer');
  print('═══════════════════════════════════════════════════════════');
  print('');

  if (dryRun) {
    print('DRY RUN - No files will be modified\n');
  }

  final skillsDir = Directory('.claude/skills');
  if (!skillsDir.existsSync()) {
    print('Error: .claude/skills directory not found');
    exit(1);
  }

  var totalFixed = 0;
  var totalSkipped = 0;

  for (final skillDir in skillsDir.listSync().whereType<Directory>()) {
    final skillName = skillDir.path.split('/').last;

    // Filter by skill if specified
    if (skillFilter != null && skillName != skillFilter) continue;

    final refDir = Directory('${skillDir.path}/reference');
    if (!refDir.existsSync()) continue;

    print('📁 $skillName/reference/');

    for (final file in refDir.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      final content = file.readAsStringSync();
      final relativePath = file.path.replaceFirst('${skillDir.path}/', '');

      // Check if already has proper header
      if (_hasProperHeader(content)) {
        totalSkipped++;
        continue;
      }

      // Generate header based on file path and content
      final header = _generateHeader(relativePath, content);
      final newContent = '$header\n$content';

      if (dryRun) {
        print('   Would fix: $relativePath');
      } else {
        file.writeAsStringSync(newContent);
        print('   ✓ Fixed: $relativePath');
      }
      totalFixed++;
    }
  }

  print('');
  print('───────────────────────────────────────────────────────────');
  print('  Fixed: $totalFixed | Already OK: $totalSkipped');
  print('───────────────────────────────────────────────────────────');
  print('');
}

bool _hasProperHeader(String content) {
  if (!content.startsWith('//')) return false;
  return content.contains('// Location:') && content.contains('// Usage:');
}

String _generateHeader(String relativePath, String content) {
  // Extract meaningful info from path
  final parts = relativePath.split('/');
  final fileName = parts.last.replaceAll('.dart', '');
  final category = parts.length > 1 ? parts[1] : 'unknown';

  // Determine template description
  final description = _inferDescription(fileName, category, content);

  // Determine target location
  final location = _inferLocation(relativePath, category);

  return '''
// Template: $description
//
// Location: $location
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed
''';
}

String _inferDescription(String fileName, String category, String content) {
  // Common patterns
  final patterns = {
    'repository_impl': 'Repository implementation with Dio HTTP client',
    'repository': 'Repository interface or implementation',
    'data_source': 'Data source for API/local storage',
    'remote_data_source': 'Remote data source with Dio HTTP client',
    'local_data_source': 'Local data source with SharedPreferences/SecureStorage',
    'model': 'Freezed DTO model for API serialization',
    'entity': 'Domain entity with Freezed',
    'failure': 'Sealed failure types for error handling',
    'provider': 'Riverpod provider definition',
    'notifier': 'AsyncNotifier for state management',
    'state': 'Freezed state class',
    'interceptor': 'Dio interceptor',
    'cache': 'Caching utility',
    'retry': 'Retry logic for network requests',
    'upload': 'File upload with progress tracking',
    'mock': 'Mock implementation for testing',
    'test': 'Test example',
    'enum': 'Enum definition',
    'value_object': 'Value object with validation',
    'pagination': 'Pagination utilities',
    'cursor': 'Cursor-based pagination',
    'infinite_scroll': 'Infinite scroll provider',
    'optimistic': 'Optimistic update pattern',
    'cancellable': 'Cancellable request pattern',
    'nonce': 'Nonce/security helpers',
    'phone': 'Phone number utilities',
    'country': 'Country data model',
    'auth': 'Authentication related',
    'social': 'Social login related',
    'oauth': 'OAuth callback handling',
  };

  // Check content for class/type hints
  if (content.contains('implements') && content.contains('Repository')) {
    return 'Repository implementation';
  }
  if (content.contains('abstract') && content.contains('Repository')) {
    return 'Repository interface';
  }
  if (content.contains('@freezed') && content.contains('factory')) {
    if (category == 'models' || fileName.contains('model') || fileName.contains('dto')) {
      return 'Freezed DTO model for API serialization';
    }
    if (category == 'entities' || fileName.contains('entity')) {
      return 'Domain entity with Freezed';
    }
    if (fileName.contains('state')) {
      return 'Freezed state class for Riverpod';
    }
    if (fileName.contains('failure')) {
      return 'Sealed failure types for error handling';
    }
  }
  if (content.contains('sealed class') && content.contains('Failure')) {
    return 'Sealed failure types for error handling';
  }
  if (content.contains('AsyncNotifier')) {
    return 'AsyncNotifier for state management';
  }
  if (content.contains('Interceptor')) {
    return 'Dio interceptor';
  }

  // Match by filename patterns
  for (final entry in patterns.entries) {
    if (fileName.contains(entry.key)) {
      return entry.value;
    }
  }

  // Fallback based on category
  final categoryDescriptions = {
    'models': 'Freezed DTO model',
    'entities': 'Domain entity',
    'repositories': 'Repository implementation',
    'data_sources': 'Data source',
    'providers': 'Riverpod provider',
    'failures': 'Failure type definitions',
    'utils': 'Utility functions',
    'widgets': 'Reusable widget',
    'screens': 'Screen widget',
    'testing': 'Test utilities',
    'pagination': 'Pagination utilities',
    'retry': 'Retry utilities',
    'caching': 'Caching utilities',
    'upload': 'Upload utilities',
    'auth': 'Authentication utilities',
    'cancellation': 'Request cancellation',
    'optimistic': 'Optimistic updates',
    'enums': 'Enum definition',
    'value_objects': 'Value object',
    'examples': 'Example implementation',
  };

  return categoryDescriptions[category] ?? 'Reference implementation';
}

String _inferLocation(String relativePath, String category) {
  // Map reference paths to typical lib paths
  final locationMappings = {
    'models': 'lib/features/{feature}/data/models/',
    'entities': 'lib/features/{feature}/domain/entities/',
    'repositories': 'lib/features/{feature}/data/repositories/',
    'data_sources': 'lib/features/{feature}/data/data_sources/',
    'providers': 'lib/features/{feature}/presentation/providers/',
    'failures': 'lib/features/{feature}/domain/failures/',
    'utils': 'lib/features/{feature}/data/utils/',
    'widgets': 'lib/features/{feature}/presentation/widgets/',
    'screens': 'lib/features/{feature}/presentation/screens/',
    'testing': 'test/features/{feature}/',
    'pagination': 'lib/core/data/pagination/',
    'retry': 'lib/core/data/retry/',
    'caching': 'lib/core/data/caching/',
    'upload': 'lib/core/data/upload/',
    'auth': 'lib/core/data/auth/',
    'cancellation': 'lib/core/data/cancellation/',
    'optimistic': 'lib/core/data/optimistic/',
    'enums': 'lib/features/{feature}/domain/enums/',
    'value_objects': 'lib/features/{feature}/domain/value_objects/',
    'examples': 'lib/features/{feature}/',
  };

  // Handle nested paths like examples/posts/domain
  if (relativePath.contains('examples/')) {
    final match = RegExp(r'examples/(\w+)/(domain|data)/').firstMatch(relativePath);
    if (match != null) {
      final layer = match.group(2);
      return 'lib/features/{feature}/$layer/';
    }
  }

  return locationMappings[category] ?? 'lib/features/{feature}/';
}

String? _getArgValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  final value = args[index + 1];
  if (value.startsWith('-')) return null;
  return value;
}

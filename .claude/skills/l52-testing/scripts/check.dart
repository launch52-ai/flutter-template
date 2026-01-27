#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// Test Coverage Audit & Generation Tool
///
/// Comprehensive test management for Flutter projects:
/// - Check which source files have corresponding tests
/// - Generate skeleton test files for untested components
/// - Audit test quality and naming conventions
/// - Report coverage gaps by component type
///
/// Usage:
///   dart run .claude/skills/testing/scripts/check.dart              # Check test coverage
///   dart run .claude/skills/testing/scripts/check.dart --generate   # Generate missing tests
///   dart run .claude/skills/testing/scripts/check.dart --feature auth   # Check specific feature
///   dart run .claude/skills/testing/scripts/check.dart --audit      # Audit test quality
///   dart run .claude/skills/testing/scripts/check.dart --help       # Show help

import 'dart:io';

// Configuration
const String libDir = 'lib';
const String testDir = 'test';
const String featuresDir = 'lib/features';
const String coreDir = 'lib/core';

// Test type directories
const String unitTestDir = 'test/unit';
const String widgetTestDir = 'test/widget';
const String goldenTestDir = 'test/golden';
const String integrationTestDir = 'test/integration';
const String helpersDir = 'test/helpers';

void main(List<String> args) {
  final help = args.contains('--help') || args.contains('-h');
  final generate = args.contains('--generate') || args.contains('-g');
  final audit = args.contains('--audit') || args.contains('-a');
  final featureIndex = args.indexOf('--feature');
  final targetFeature = featureIndex != -1 && featureIndex + 1 < args.length
      ? args[featureIndex + 1]
      : null;

  if (help) {
    _printHelp();
    return;
  }

  print('');
  print('═══════════════════════════════════════════════════════');
  print('  Test Coverage Audit Tool');
  print('═══════════════════════════════════════════════════════');
  print('');

  if (audit) {
    _runQualityAudit(targetFeature);
    return;
  }

  // Default: check coverage
  final results = _checkCoverage(targetFeature);
  _printResults(results);

  if (generate && results.missing.isNotEmpty) {
    print('');
    print('Generating missing test files...');
    print('');

    for (final missing in results.missing) {
      _generateTestFile(missing);
    }

    print('');
    print('✅ Generated ${results.missing.length} test file(s)');
    print('');
    print('Next steps:');
    print('  1. Implement the generated test skeletons');
    print('  2. Run: flutter test');
    print('');
  } else if (results.missing.isNotEmpty && !generate) {
    print('');
    print('To generate missing test files, run:');
    print('  dart run .claude/skills/testing/scripts/check.dart --generate');
    print('');
  }
}

// ============================================================
// COVERAGE CHECK
// ============================================================

CoverageResults _checkCoverage(String? targetFeature) {
  final sourceFiles = _findSourceFiles(targetFeature);
  final testableFiles = sourceFiles.where(_isTestable).toList();

  final covered = <SourceFile>[];
  final missing = <SourceFile>[];

  for (final source in testableFiles) {
    final expectedTestPath = _getExpectedTestPath(source);
    final hasTest = File(expectedTestPath).existsSync();

    if (hasTest) {
      covered.add(source);
    } else {
      missing.add(source);
    }
  }

  return CoverageResults(
    total: testableFiles.length,
    covered: covered,
    missing: missing,
  );
}

List<SourceFile> _findSourceFiles(String? targetFeature) {
  final files = <SourceFile>[];

  // Find feature files
  final featuresDirObj = Directory(featuresDir);
  if (featuresDirObj.existsSync()) {
    for (final featureDir in featuresDirObj.listSync().whereType<Directory>()) {
      final featureName = featureDir.path.split('/').last;

      // Skip if targeting specific feature
      if (targetFeature != null && featureName != targetFeature) continue;

      files.addAll(_scanDirectory(featureDir.path, featureName));
    }
  }

  // Find core files (only if not targeting specific feature)
  if (targetFeature == null) {
    final coreDirObj = Directory(coreDir);
    if (coreDirObj.existsSync()) {
      files.addAll(_scanDirectory(coreDir, 'core'));
    }
  }

  return files;
}

List<SourceFile> _scanDirectory(String path, String module) {
  final files = <SourceFile>[];
  final dir = Directory(path);

  if (!dir.existsSync()) return files;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    // Skip generated files
    if (entity.path.endsWith('.g.dart')) continue;
    if (entity.path.endsWith('.freezed.dart')) continue;

    // Skip i18n files
    if (entity.path.contains('/i18n/')) continue;

    final relativePath = entity.path.replaceFirst('$libDir/', '');
    final componentType = _getComponentType(entity.path);

    files.add(SourceFile(
      path: entity.path,
      relativePath: relativePath,
      module: module,
      componentType: componentType,
    ));
  }

  return files;
}

bool _isTestable(SourceFile file) {
  // Skip files that typically don't need tests
  final skipPatterns = [
    'main.dart',
    'app.dart',
    '/providers.dart', // DI setup files
    '/constants/',
    '/theme/',
    '/routes/',
    '/router/',
  ];

  for (final pattern in skipPatterns) {
    if (file.path.contains(pattern)) return false;
  }

  return true;
}

ComponentType _getComponentType(String path) {
  if (path.contains('/data/repositories/')) return ComponentType.repository;
  if (path.contains('/domain/repositories/')) return ComponentType.repositoryInterface;
  if (path.contains('/data/models/')) return ComponentType.model;
  if (path.contains('/domain/models/')) return ComponentType.model;
  if (path.contains('/presentation/providers/')) return ComponentType.provider;
  if (path.contains('/presentation/screens/')) return ComponentType.screen;
  if (path.contains('/presentation/widgets/')) return ComponentType.widget;
  if (path.contains('/services/')) return ComponentType.service;
  if (path.contains('/utils/')) return ComponentType.util;
  if (path.contains('/network/')) return ComponentType.network;
  if (path.contains('/errors/')) return ComponentType.error;
  return ComponentType.other;
}

String _getExpectedTestPath(SourceFile source) {
  // Determine test directory based on component type
  final testBase = switch (source.componentType) {
    ComponentType.screen => widgetTestDir,
    ComponentType.widget => widgetTestDir,
    _ => unitTestDir,
  };

  // Build test path: test/{type}/{relativePath}_test.dart
  final testPath = source.relativePath
      .replaceFirst('.dart', '_test.dart');

  return '$testBase/$testPath';
}

// ============================================================
// QUALITY AUDIT
// ============================================================

void _runQualityAudit(String? targetFeature) {
  print('Auditing test quality...');
  print('');

  final testFiles = _findTestFiles(targetFeature);
  var totalIssues = 0;

  for (final testFile in testFiles) {
    final issues = _auditTestFile(testFile);
    if (issues.isNotEmpty) {
      totalIssues += issues.length;
      print('📄 ${testFile.replaceFirst('$testDir/', '')}');
      for (final issue in issues) {
        print('   ⚠️  Line ${issue.line}: ${issue.message}');
      }
      print('');
    }
  }

  print('───────────────────────────────────────────────────────');
  print('');
  if (totalIssues == 0) {
    print('✅ No quality issues found!');
  } else {
    print('⚠️  Found $totalIssues quality issue(s)');
  }
  print('');
}

List<String> _findTestFiles(String? targetFeature) {
  final files = <String>[];
  final testDirObj = Directory(testDir);

  if (!testDirObj.existsSync()) return files;

  for (final entity in testDirObj.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('_test.dart')) continue;

    // Skip if targeting specific feature
    if (targetFeature != null && !entity.path.contains('/$targetFeature/')) {
      continue;
    }

    files.add(entity.path);
  }

  return files;
}

List<TestIssue> _auditTestFile(String path) {
  final file = File(path);
  final content = file.readAsStringSync();
  final lines = content.split('\n');
  final issues = <TestIssue>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineNum = i + 1;

    // Check for bad test names
    final testMatch = RegExp(r'''test\(['"](.+?)['"]''').firstMatch(line);
    if (testMatch != null) {
      final testName = testMatch.group(1) ?? '';

      // Check naming convention
      if (!testName.contains('_')) {
        issues.add(TestIssue(
          line: lineNum,
          message: 'Test name should follow pattern: '
              'test_{subject}_{scenario}_{expected}',
        ));
      }

      // Check for vague names
      if (testName.toLowerCase().contains('works') ||
          testName.toLowerCase().contains('should work')) {
        issues.add(TestIssue(
          line: lineNum,
          message: 'Test name is too vague: "$testName"',
        ));
      }
    }

    // Check for hardcoded delays
    if (line.contains('Future.delayed') && !path.contains('fake_async')) {
      issues.add(TestIssue(
        line: lineNum,
        message: 'Avoid hardcoded delays. Use fakeAsync or Completer instead.',
      ));
    }

    // Check for missing await
    if (line.contains('tester.pump') && !line.contains('await')) {
      issues.add(TestIssue(
        line: lineNum,
        message: 'Missing await on tester.pump()',
      ));
    }

    // Check for expect without message
    final expectWithoutReason = RegExp(r'expect\([^,]+,[^,]+\);').hasMatch(line);
    if (line.contains('expect(') &&
        !line.contains('reason:') &&
        !expectWithoutReason) {
      // This is fine, we don't require reason on every expect
    }

    // Check for empty test
    if (line.contains('test(') || line.contains('testWidgets(')) {
      // Look ahead for expect
      var hasExpect = false;
      for (var j = i; j < lines.length && j < i + 30; j++) {
        if (lines[j].contains('expect(') || lines[j].contains('verify(')) {
          hasExpect = true;
          break;
        }
        if (lines[j].contains('});')) break;
      }
      if (!hasExpect) {
        issues.add(TestIssue(
          line: lineNum,
          message: 'Test may be missing assertions (no expect or verify found)',
        ));
      }
    }
  }

  return issues;
}

// ============================================================
// GENERATION
// ============================================================

void _generateTestFile(SourceFile source) {
  final testPath = _getExpectedTestPath(source);
  final testDir = File(testPath).parent;

  // Create directory if needed
  if (!testDir.existsSync()) {
    testDir.createSync(recursive: true);
  }

  // Generate content based on component type
  final content = _generateTestContent(source);

  // Write file
  File(testPath).writeAsStringSync(content);
  print('  📄 Created: $testPath');
}

String _generateTestContent(SourceFile source) {
  final className = _extractClassName(source);
  final testClassName = '${className}Test';

  return switch (source.componentType) {
    ComponentType.repository => _generateRepositoryTest(source, className),
    ComponentType.service => _generateServiceTest(source, className),
    ComponentType.provider => _generateProviderTest(source, className),
    ComponentType.screen => _generateWidgetTest(source, className),
    ComponentType.widget => _generateWidgetTest(source, className),
    ComponentType.util => _generateUtilTest(source, className),
    _ => _generateBasicTest(source, className),
  };
}

String _extractClassName(SourceFile source) {
  final file = File(source.path);
  final content = file.readAsStringSync();

  // Try to find class name
  final classMatch = RegExp(r'class\s+(\w+)').firstMatch(content);
  if (classMatch != null) {
    return classMatch.group(1) ?? 'Unknown';
  }

  // Fall back to file name
  return source.path.split('/').last.replaceAll('.dart', '').split('_').map((s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }).join();
}

String _generateRepositoryTest(SourceFile source, String className) {
  final importPath = source.relativePath.replaceAll('.dart', '');

  return '''import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_app/$importPath.dart';
import '../../../../../helpers/test_helpers.dart';
import '../../../../../helpers/mocks.dart';

void main() {
  late $className sut;
  // TODO: Add mock dependencies
  // late MockDependency mockDep;

  /// Creates System Under Test with all dependencies
  $className makeSUT() {
    return $className(
      // TODO: Pass dependencies
    );
  }

  setUp(() {
    // TODO: Initialize mocks
    // mockDep = MockDependency();
    sut = makeSUT();
  });

  setUpAll(() {
    registerFallbackValues();
  });

  group('$className', () {
    // TODO: Add test groups for each method

    group('methodName', () {
      test('scenario_expectedBehavior', () async {
        // Arrange
        // TODO: Set up test conditions

        // Act
        // TODO: Execute the behavior

        // Assert
        // TODO: Verify the outcome
      });

      test('errorScenario_throwsExpectedException', () async {
        // Arrange
        // TODO: Set up error condition

        // Act & Assert
        // expect(() => sut.method(), throwsA(isA<ExpectedException>()));
      });
    });
  });
}
''';
}

String _generateServiceTest(SourceFile source, String className) {
  final importPath = source.relativePath.replaceAll('.dart', '');

  return '''import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_app/$importPath.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late $className sut;

  setUp(() {
    sut = $className();
  });

  group('$className', () {
    // TODO: Add test groups

    test('operation_withValidInput_succeeds', () async {
      // Arrange
      // TODO: Set up conditions

      // Act
      // TODO: Call method

      // Assert
      // TODO: Verify outcome
    });
  });
}
''';
}

String _generateProviderTest(SourceFile source, String className) {
  final importPath = source.relativePath.replaceAll('.dart', '');

  return '''import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_app/$importPath.dart';
import '../../../../../helpers/test_helpers.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/riverpod_helpers.dart';

void main() {
  late ProviderContainer container;
  // TODO: Add spy dependencies
  // late RepositorySpy repositorySpy;

  setUp(() {
    // TODO: Initialize spies
    // repositorySpy = RepositorySpy();
    container = makeProviderContainer(
      overrides: [
        // TODO: Add provider overrides
        // repositoryProvider.overrideWithValue(repositorySpy),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('$className', () {
    test('initialState_isCorrect', () {
      // Act
      // final state = container.read(providerName);

      // Assert
      // expect(state, expectedInitialState);
    });

    test('action_updatesStateCorrectly', () async {
      // Arrange
      // repositorySpy.completeWithResult(expectedResult);

      // Act
      // await container.read(providerName.notifier).action();

      // Assert
      // final state = container.read(providerName);
      // expect(state, expectedState);
    });

    test('action_emitsCorrectStateTransitions', () async {
      // Arrange
      final listener = ProviderListener<dynamic>();
      // container.listen(providerName, listener.call, fireImmediately: true);

      // Act
      // await container.read(providerName.notifier).action();

      // Assert
      // expect(listener.states, [
      //   initialState,
      //   loadingState,
      //   successState,
      // ]);
    });
  });
}
''';
}

String _generateWidgetTest(SourceFile source, String className) {
  final importPath = source.relativePath.replaceAll('.dart', '');

  return '''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_app/$importPath.dart';
import '../../../../../helpers/pump_app.dart';
import '../../../../../helpers/mocks.dart';

void main() {
  group('$className', () {
    testWidgets('rendersCorrectly', (tester) async {
      // Arrange & Act
      await tester.pumpApp(const $className());

      // Assert
      // TODO: Add widget assertions
      // expect(find.byType($className), findsOneWidget);
    });

    testWidgets('interaction_triggersExpectedBehavior', (tester) async {
      // Arrange
      await tester.pumpApp(const $className());

      // Act
      // await tester.simulateTapOn(find.byKey(const Key('button')));

      // Assert
      // TODO: Verify interaction result
    });

    testWidgets('loadingState_showsProgressIndicator', (tester) async {
      // Arrange
      await tester.pumpApp(
        const $className(),
        overrides: [
          // TODO: Override with loading state
        ],
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('errorState_showsErrorMessage', (tester) async {
      // Arrange
      await tester.pumpApp(
        const $className(),
        overrides: [
          // TODO: Override with error state
        ],
      );

      // Assert
      // expect(find.text('Error message'), findsOneWidget);
    });
  });
}
''';
}

String _generateUtilTest(SourceFile source, String className) {
  final importPath = source.relativePath.replaceAll('.dart', '');

  return '''import 'package:flutter_test/flutter_test.dart';

import 'package:your_app/$importPath.dart';

void main() {
  group('$className', () {
    // TODO: Add test cases for each function

    group('functionName', () {
      test('withValidInput_returnsExpectedOutput', () {
        // Arrange
        // final input = ...;

        // Act
        // final result = functionName(input);

        // Assert
        // expect(result, expectedOutput);
      });

      test('withInvalidInput_returnsError', () {
        // Arrange
        // final invalidInput = ...;

        // Act & Assert
        // expect(
        //   () => functionName(invalidInput),
        //   throwsA(isA<ExpectedException>()),
        // );
      });
    });
  });
}
''';
}

String _generateBasicTest(SourceFile source, String className) {
  final importPath = source.relativePath.replaceAll('.dart', '');

  return '''import 'package:flutter_test/flutter_test.dart';

import 'package:your_app/$importPath.dart';

void main() {
  group('$className', () {
    // TODO: Add tests

    test('basicTest', () {
      // Arrange

      // Act

      // Assert
    });
  });
}
''';
}

// ============================================================
// OUTPUT
// ============================================================

void _printResults(CoverageResults results) {
  final coveragePercent =
      results.total > 0 ? (results.covered.length / results.total * 100) : 0.0;

  print('Coverage Summary:');
  print('  Total testable files: ${results.total}');
  print('  Files with tests: ${results.covered.length}');
  print('  Files missing tests: ${results.missing.length}');
  print('  Coverage: ${coveragePercent.toStringAsFixed(1)}%');
  print('');

  if (results.missing.isNotEmpty) {
    // Group by component type
    final byType = <ComponentType, List<SourceFile>>{};
    for (final file in results.missing) {
      byType.putIfAbsent(file.componentType, () => []).add(file);
    }

    print('Missing Tests by Type:');
    print('');

    for (final type in ComponentType.values) {
      final files = byType[type];
      if (files == null || files.isEmpty) continue;

      print('  ${type.displayName} (${files.length}):');
      for (final file in files.take(5)) {
        print('    ❌ ${file.relativePath}');
      }
      if (files.length > 5) {
        print('    ... and ${files.length - 5} more');
      }
      print('');
    }
  } else {
    print('✅ All testable files have corresponding tests!');
  }
}

void _printHelp() {
  print('''
Test Coverage Audit Tool

Checks test coverage and generates missing test files.

USAGE:
  dart run .claude/skills/testing/scripts/check.dart [options]

OPTIONS:
  -g, --generate       Generate skeleton test files for missing tests
  -a, --audit          Audit test quality and naming conventions
  --feature <name>     Check specific feature only
  -h, --help           Show this help message

EXAMPLES:
  dart run .claude/skills/testing/scripts/check.dart              # Check coverage
  dart run .claude/skills/testing/scripts/check.dart -g           # Generate missing tests
  dart run .claude/skills/testing/scripts/check.dart --feature auth   # Check auth feature
  dart run .claude/skills/testing/scripts/check.dart -a           # Audit test quality

TEST STRUCTURE:
  test/
  ├── unit/                    # Unit tests (repositories, services, utils)
  │   ├── core/
  │   └── features/{feature}/
  ├── widget/                  # Widget tests (screens, widgets)
  │   └── features/{feature}/
  ├── golden/                  # Golden tests
  ├── integration/             # Integration tests
  └── helpers/                 # Test utilities
      ├── test_helpers.dart
      ├── mocks.dart
      ├── pump_app.dart
      └── riverpod_helpers.dart

NAMING CONVENTIONS:
  Files: {component}_test.dart
  Tests: test_{subject}_{scenario}_{expected}

COVERAGE EXPECTATIONS:
  Repositories:      90%+
  Providers:         85%+
  Utils/Helpers:     80%+
  Models:            70%+
  Widgets:           60%+
''');
}

// ============================================================
// DATA CLASSES
// ============================================================

final class SourceFile {
  final String path;
  final String relativePath;
  final String module;
  final ComponentType componentType;

  const SourceFile({
    required this.path,
    required this.relativePath,
    required this.module,
    required this.componentType,
  });
}

final class CoverageResults {
  final int total;
  final List<SourceFile> covered;
  final List<SourceFile> missing;

  const CoverageResults({
    required this.total,
    required this.covered,
    required this.missing,
  });
}

final class TestIssue {
  final int line;
  final String message;

  const TestIssue({
    required this.line,
    required this.message,
  });
}

enum ComponentType {
  repository('Repositories'),
  repositoryInterface('Repository Interfaces'),
  model('Models'),
  provider('Providers'),
  screen('Screens'),
  widget('Widgets'),
  service('Services'),
  util('Utils'),
  network('Network'),
  error('Errors'),
  other('Other');

  const ComponentType(this.displayName);
  final String displayName;
}

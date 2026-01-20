// ignore_for_file: avoid_print

import 'dart:io';

/// Accessibility audit script for Flutter projects.
///
/// Detects common accessibility issues:
/// - Images without semanticLabel
/// - IconButton without tooltip
/// - GestureDetector without Semantics
/// - Small touch targets (visual inspection needed)
/// - Missing Semantics on custom widgets
///
/// Usage:
///   dart run .claude/skills/a11y/scripts/check.dart
///   dart run .claude/skills/a11y/scripts/check.dart --feature auth
///   dart run .claude/skills/a11y/scripts/check.dart --semantics-only
///   dart run .claude/skills/a11y/scripts/check.dart --generate-tests auth
void main(List<String> args) async {
  final featureFilter = _getArgValue(args, '--feature');
  final semanticsOnly = args.contains('--semantics-only');
  final generateTests = _getArgValue(args, '--generate-tests');

  if (generateTests != null) {
    await _generateAccessibilityTests(generateTests);
    return;
  }

  print('🔍 Accessibility Audit\n');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ Error: lib/ directory not found');
    exit(1);
  }

  final issues = <AccessibilityIssue>[];

  await for (final file in libDir
      .list(recursive: true)
      .where((e) => e is File && e.path.endsWith('.dart'))) {
    final filePath = (file as File).path;

    // Filter by feature if specified
    if (featureFilter != null && !filePath.contains('features/$featureFilter')) {
      continue;
    }

    // Skip generated files
    if (filePath.endsWith('.g.dart') || filePath.endsWith('.freezed.dart')) {
      continue;
    }

    final content = await file.readAsString();
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;

      // Check for images without semanticLabel
      if (!semanticsOnly) {
        if (_hasImageWithoutSemanticLabel(line, lines, i)) {
          issues.add(AccessibilityIssue(
            file: filePath,
            line: lineNum,
            type: IssueType.missingImageLabel,
            code: line.trim(),
          ));
        }

        // Check for IconButton without tooltip
        if (_hasIconButtonWithoutTooltip(line, lines, i)) {
          issues.add(AccessibilityIssue(
            file: filePath,
            line: lineNum,
            type: IssueType.missingIconButtonTooltip,
            code: line.trim(),
          ));
        }

        // Check for GestureDetector without Semantics
        if (_hasGestureDetectorWithoutSemantics(line, lines, i)) {
          issues.add(AccessibilityIssue(
            file: filePath,
            line: lineNum,
            type: IssueType.gestureDetectorWithoutSemantics,
            code: line.trim(),
          ));
        }

        // Check for InkWell without Semantics
        if (_hasInkWellWithoutSemantics(line, lines, i)) {
          issues.add(AccessibilityIssue(
            file: filePath,
            line: lineNum,
            type: IssueType.inkWellWithoutSemantics,
            code: line.trim(),
          ));
        }
      }

      // Check for RichText (should use Text.rich for scaling)
      if (_hasRichText(line)) {
        issues.add(AccessibilityIssue(
          file: filePath,
          line: lineNum,
          type: IssueType.richTextUsage,
          code: line.trim(),
        ));
      }

      // Check for hardcoded sizes that should scale
      if (_hasHardcodedIconSize(line)) {
        issues.add(AccessibilityIssue(
          file: filePath,
          line: lineNum,
          type: IssueType.hardcodedIconSize,
          code: line.trim(),
        ));
      }
    }
  }

  // Print results
  if (issues.isEmpty) {
    print('✅ No accessibility issues found!\n');
    _printReminders();
    return;
  }

  // Group by type
  final byType = <IssueType, List<AccessibilityIssue>>{};
  for (final issue in issues) {
    byType.putIfAbsent(issue.type, () => []).add(issue);
  }

  print('Found ${issues.length} potential accessibility issues:\n');

  for (final entry in byType.entries) {
    print(_issueTypeHeader(entry.key));
    print('${'─' * 60}\n');

    for (final issue in entry.value) {
      _printIssue(issue);
    }
    print('');
  }

  _printReminders();
  print('\n📖 See .claude/skills/a11y/SKILL.md for fixes\n');

  // Exit with error if issues found
  exit(1);
}

// ============================================================
// DETECTION FUNCTIONS
// ============================================================

bool _hasImageWithoutSemanticLabel(String line, List<String> lines, int index) {
  // Check if line contains Image widget
  if (!line.contains('Image.') && !line.contains('Image(')) {
    return false;
  }

  // Look ahead for semanticLabel in the next 10 lines or until closing paren
  final searchLines = lines.skip(index).take(15).join('\n');

  // If wrapped in ExcludeSemantics, it's intentional
  if (_isWrappedInExcludeSemantics(lines, index)) {
    return false;
  }

  return !searchLines.contains('semanticLabel');
}

bool _hasIconButtonWithoutTooltip(String line, List<String> lines, int index) {
  if (!line.contains('IconButton(')) {
    return false;
  }

  final searchLines = lines.skip(index).take(15).join('\n');
  return !searchLines.contains('tooltip:');
}

bool _hasGestureDetectorWithoutSemantics(
    String line, List<String> lines, int index) {
  if (!line.contains('GestureDetector(')) {
    return false;
  }

  // Check if wrapped in Semantics
  if (_isWrappedInSemantics(lines, index)) {
    return false;
  }

  // Check if child is already semantic (like a button)
  final searchLines = lines.skip(index).take(20).join('\n');
  if (searchLines.contains('ElevatedButton') ||
      searchLines.contains('TextButton') ||
      searchLines.contains('OutlinedButton') ||
      searchLines.contains('IconButton')) {
    return false;
  }

  return true;
}

bool _hasInkWellWithoutSemantics(String line, List<String> lines, int index) {
  if (!line.contains('InkWell(')) {
    return false;
  }

  // Check if wrapped in Semantics
  if (_isWrappedInSemantics(lines, index)) {
    return false;
  }

  // Check if parent is ListTile (which provides semantics)
  if (_isChildOfListTile(lines, index)) {
    return false;
  }

  return true;
}

bool _hasRichText(String line) {
  // RichText doesn't respect text scaling by default
  return line.contains('RichText(') && !line.contains('// a11y-ok');
}

bool _hasHardcodedIconSize(String line) {
  // Look for Icon with hardcoded size not using textScaler
  if (!line.contains('Icon(') && !line.contains('size:')) {
    return false;
  }

  if (line.contains('Icon(') &&
      line.contains('size:') &&
      !line.contains('textScaler') &&
      !line.contains('// a11y-ok')) {
    return true;
  }

  return false;
}

bool _isWrappedInSemantics(List<String> lines, int index) {
  // Look back up to 5 lines for Semantics wrapper
  final start = (index - 5).clamp(0, lines.length);
  final searchLines = lines.sublist(start, index).join('\n');
  return searchLines.contains('Semantics(') ||
      searchLines.contains('MergeSemantics(');
}

bool _isWrappedInExcludeSemantics(List<String> lines, int index) {
  final start = (index - 5).clamp(0, lines.length);
  final searchLines = lines.sublist(start, index).join('\n');
  return searchLines.contains('ExcludeSemantics(');
}

bool _isChildOfListTile(List<String> lines, int index) {
  final start = (index - 10).clamp(0, lines.length);
  final searchLines = lines.sublist(start, index).join('\n');
  return searchLines.contains('ListTile(');
}

// ============================================================
// OUTPUT
// ============================================================

void _printIssue(AccessibilityIssue issue) {
  final relativePath = issue.file.replaceFirst('lib/', '');
  print('  📍 $relativePath:${issue.line}');
  print('     ${issue.code}');
  print('     💡 ${_issueTypeFix(issue.type)}\n');
}

String _issueTypeHeader(IssueType type) {
  return switch (type) {
    IssueType.missingImageLabel => '🖼️  Images without semanticLabel',
    IssueType.missingIconButtonTooltip => '🔘 IconButton without tooltip',
    IssueType.gestureDetectorWithoutSemantics =>
      '👆 GestureDetector without Semantics',
    IssueType.inkWellWithoutSemantics => '💧 InkWell without Semantics',
    IssueType.richTextUsage => '📝 RichText (use Text.rich for scaling)',
    IssueType.hardcodedIconSize => '📏 Hardcoded icon size (won\'t scale)',
  };
}

String _issueTypeFix(IssueType type) {
  return switch (type) {
    IssueType.missingImageLabel =>
      'Add semanticLabel: \'description\' or wrap in ExcludeSemantics',
    IssueType.missingIconButtonTooltip => 'Add tooltip: \'action description\'',
    IssueType.gestureDetectorWithoutSemantics =>
      'Wrap in Semantics(label: \'...\', button: true, child: ...)',
    IssueType.inkWellWithoutSemantics =>
      'Wrap in Semantics(label: \'...\', button: true, child: ...)',
    IssueType.richTextUsage =>
      'Replace RichText with Text.rich for text scaling support',
    IssueType.hardcodedIconSize =>
      'Use textScaler.scale(24) for scalable sizing',
  };
}

void _printReminders() {
  print('📋 Manual Checks Required:');
  print('   • Touch targets ≥48×48dp');
  print('   • Text contrast ≥4.5:1');
  print('   • Test with VoiceOver/TalkBack');
  print('   • Verify focus order matches visual layout');
  print('   • Check UI at 2x text scale');
}

// ============================================================
// TEST GENERATION
// ============================================================

Future<void> _generateAccessibilityTests(String feature) async {
  final testDir = Directory('test/accessibility');
  if (!testDir.existsSync()) {
    testDir.createSync(recursive: true);
  }

  final testFile = File('test/accessibility/${feature}_a11y_test.dart');

  final content = '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// TODO: Import your screens
// import 'package:your_app/features/$feature/presentation/screens/${feature}_screen.dart';

void main() {
  group('$feature accessibility', () {
    testWidgets('meets text contrast guidelines', (tester) async {
      // TODO: Replace with actual screen
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Placeholder())),
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('meets touch target guidelines', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Placeholder())),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('all interactive elements have labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Placeholder())),
      );

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('handles 2x text scale', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: MaterialApp(home: Scaffold(body: Placeholder())),
        ),
      );
      await tester.pumpAndSettle();

      // Should not overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets guidelines in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: Placeholder()),
        ),
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
''';

  await testFile.writeAsString(content);
  print('✅ Generated: ${testFile.path}');
  print('\n   Edit the file to import your actual screens and widgets.');
}

// ============================================================
// UTILITIES
// ============================================================

String? _getArgValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index != -1 && index + 1 < args.length) {
    return args[index + 1];
  }
  return null;
}

// ============================================================
// TYPES
// ============================================================

enum IssueType {
  missingImageLabel,
  missingIconButtonTooltip,
  gestureDetectorWithoutSemantics,
  inkWellWithoutSemantics,
  richTextUsage,
  hardcodedIconSize,
}

class AccessibilityIssue {
  final String file;
  final int line;
  final IssueType type;
  final String code;

  AccessibilityIssue({
    required this.file,
    required this.line,
    required this.type,
    required this.code,
  });
}

#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Skill validation script for Claude Code skills.
///
/// Validates skills against quality gates:
/// - Gate 1: Structure (required)
/// - Gate 2: Content (required)
/// - Gate 3: Quality (recommended)
/// - Gate 4: Integration (recommended)
///
/// Usage:
///   dart run .claude/skills/skill-create/scripts/validate.dart --skill {name}
///   dart run .claude/skills/skill-create/scripts/validate.dart --all
///   dart run .claude/skills/skill-create/scripts/validate.dart --skill {name} --gate structure
///   dart run .claude/skills/skill-create/scripts/validate.dart --skill {name} --report
///   dart run .claude/skills/skill-create/scripts/validate.dart --skill {name} --json
///   dart run .claude/skills/skill-create/scripts/validate.dart --list-checks
///   dart run .claude/skills/skill-create/scripts/validate.dart --help
void main(List<String> args) async {
  final help = args.contains('--help') || args.contains('-h');
  final listChecks = args.contains('--list-checks');
  final all = args.contains('--all');
  final report = args.contains('--report');
  final jsonOutput = args.contains('--json');
  final skillName = _getArgValue(args, '--skill');
  final gate = _getArgValue(args, '--gate');

  if (help) {
    _printHelp();
    return;
  }

  if (listChecks) {
    _printCheckList();
    return;
  }

  if (all) {
    await _validateAllSkills(jsonOutput: jsonOutput, report: report);
    return;
  }

  if (skillName == null) {
    print('Error: --skill {name} or --all required\n');
    _printHelp();
    exit(1);
  }

  await _validateSkill(
    skillName,
    gate: gate,
    report: report,
    jsonOutput: jsonOutput,
  );
}

// ============================================================
// MAIN VALIDATION
// ============================================================

Future<void> _validateSkill(
  String skillName, {
  String? gate,
  bool report = false,
  bool jsonOutput = false,
}) async {
  final skillPath = '.claude/skills/$skillName';
  final errors = <ValidationIssue>[];
  final warnings = <ValidationIssue>[];
  final passed = <String>[];

  if (!jsonOutput) {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('  Skill Validation: $skillName');
    print('═══════════════════════════════════════════════════════════');
    print('');
  }

  // Run gates based on filter
  if (gate == null || gate == 'structure') {
    _validateStructure(skillPath, skillName, errors, warnings, passed,
        verbose: !jsonOutput);
  }

  if (gate == null || gate == 'content') {
    _validateContent(skillPath, skillName, errors, warnings, passed,
        verbose: !jsonOutput);
  }

  if (gate == null || gate == 'quality') {
    _validateQuality(skillPath, skillName, errors, warnings, passed,
        verbose: !jsonOutput);
  }

  if (gate == null || gate == 'integration') {
    _validateIntegration(skillPath, skillName, errors, warnings, passed,
        verbose: !jsonOutput);
  }

  // Output results
  if (jsonOutput) {
    _printJsonResults(skillName, errors, warnings, passed);
  } else {
    _printResults(errors, warnings, passed, report: report);
  }

  // Exit code
  if (errors.isNotEmpty) {
    exit(1);
  }
}

Future<void> _validateAllSkills({
  bool jsonOutput = false,
  bool report = false,
}) async {
  final skillsDir = Directory('.claude/skills');
  if (!skillsDir.existsSync()) {
    print('Error: .claude/skills directory not found');
    exit(1);
  }

  final skills = skillsDir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split('/').last)
      .where((name) => !name.startsWith('.'))
      .toList()
    ..sort();

  if (!jsonOutput) {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('  Validating ${skills.length} Skills');
    print('═══════════════════════════════════════════════════════════');
    print('');
  }

  final results = <String, Map<String, dynamic>>{};
  var totalErrors = 0;
  var totalWarnings = 0;

  for (final skill in skills) {
    final skillPath = '.claude/skills/$skill';
    final errors = <ValidationIssue>[];
    final warnings = <ValidationIssue>[];
    final passed = <String>[];

    _validateStructure(skillPath, skill, errors, warnings, passed,
        verbose: false);
    _validateContent(skillPath, skill, errors, warnings, passed, verbose: false);
    _validateQuality(skillPath, skill, errors, warnings, passed, verbose: false);
    _validateIntegration(skillPath, skill, errors, warnings, passed,
        verbose: false);

    final score = _calculateScore(errors.length, warnings.length);

    results[skill] = {
      'errors': errors.length,
      'warnings': warnings.length,
      'passed': passed.length,
      'score': score,
    };

    totalErrors += errors.length;
    totalWarnings += warnings.length;

    if (!jsonOutput) {
      final emoji = errors.isEmpty ? (warnings.isEmpty ? '✅' : '⚠️') : '❌';
      print('  $emoji $skill - Score: $score (${errors.length}E/${warnings.length}W)');
    }
  }

  if (jsonOutput) {
    _printJsonAllResults(results, totalErrors, totalWarnings);
  } else {
    print('');
    print('───────────────────────────────────────────────────────────');
    print('  Total: ${skills.length} skills, $totalErrors errors, $totalWarnings warnings');
    print('───────────────────────────────────────────────────────────');
    print('');
  }

  if (totalErrors > 0) {
    exit(1);
  }
}

// ============================================================
// GATE 1: STRUCTURE
// ============================================================

void _validateStructure(
  String skillPath,
  String skillName,
  List<ValidationIssue> errors,
  List<ValidationIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) {
  if (verbose) print('📁 Gate 1: Structure\n');

  // E001: Directory exists
  if (!Directory(skillPath).existsSync()) {
    errors.add(ValidationIssue(
      code: 'E001',
      message: 'Skill directory not found',
      fix: 'Create directory: mkdir -p $skillPath',
    ));
    return; // Can't continue without directory
  }
  passed.add('E001: Skill directory exists');

  // E002: SKILL.md exists
  if (!File('$skillPath/SKILL.md').existsSync()) {
    errors.add(ValidationIssue(
      code: 'E002',
      message: 'SKILL.md not found',
      fix: 'Create $skillPath/SKILL.md with required content',
    ));
    return; // Can't continue without SKILL.md
  }
  passed.add('E002: SKILL.md exists');

  // E003: Valid directory name
  final nameRegex = RegExp(r'^[a-z][a-z0-9-]*$');
  if (!nameRegex.hasMatch(skillName)) {
    errors.add(ValidationIssue(
      code: 'E003',
      message: 'Invalid skill name: "$skillName"',
      fix: 'Use lowercase letters, numbers, and hyphens only',
    ));
  } else if (skillName.length > 64) {
    errors.add(ValidationIssue(
      code: 'E003',
      message: 'Skill name too long (${skillName.length} > 64)',
      fix: 'Shorten skill name to < 64 characters',
    ));
  } else {
    passed.add('E003: Valid directory name');
  }

  // E004: No reserved names
  const reserved = ['anthropic', 'claude', 'ai', 'assistant'];
  if (reserved.contains(skillName.toLowerCase())) {
    errors.add(ValidationIssue(
      code: 'E004',
      message: 'Reserved skill name: "$skillName"',
      fix: 'Choose a different name',
    ));
  } else {
    passed.add('E004: Name not reserved');
  }

  if (verbose) print('');
}

// ============================================================
// GATE 2: CONTENT
// ============================================================

void _validateContent(
  String skillPath,
  String skillName,
  List<ValidationIssue> errors,
  List<ValidationIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) {
  if (verbose) print('📝 Gate 2: Content\n');

  final skillMdPath = '$skillPath/SKILL.md';
  if (!File(skillMdPath).existsSync()) {
    // Already caught in structure
    return;
  }

  final content = File(skillMdPath).readAsStringSync();
  final lines = content.split('\n');

  // Parse frontmatter
  final frontmatter = _parseFrontmatter(content);

  // E101: Frontmatter exists
  if (frontmatter == null) {
    errors.add(ValidationIssue(
      code: 'E101',
      message: 'Invalid or missing YAML frontmatter',
      fix: 'Add frontmatter between --- markers at top of file',
    ));
    return;
  }
  passed.add('E101: Valid frontmatter');

  // E102: Name present
  if (!frontmatter.containsKey('name')) {
    errors.add(ValidationIssue(
      code: 'E102',
      message: 'Frontmatter missing "name" field',
      fix: 'Add "name: $skillName" to frontmatter',
    ));
  } else {
    passed.add('E102: Name field present');

    // E103: Name matches directory
    if (frontmatter['name'] != skillName) {
      errors.add(ValidationIssue(
        code: 'E103',
        message: 'Frontmatter name "${frontmatter['name']}" != directory "$skillName"',
        fix: 'Change frontmatter name to "$skillName"',
      ));
    } else {
      passed.add('E103: Name matches directory');
    }
  }

  // E104: Description present
  if (!frontmatter.containsKey('description')) {
    errors.add(ValidationIssue(
      code: 'E104',
      message: 'Frontmatter missing "description" field',
      fix: 'Add "description: ..." to frontmatter',
    ));
  } else {
    passed.add('E104: Description present');

    final desc = frontmatter['description'] as String;

    // E105: Description length
    if (desc.length > 1024) {
      errors.add(ValidationIssue(
        code: 'E105',
        message: 'Description too long (${desc.length} > 1024)',
        fix: 'Shorten description, move details to guides',
      ));
    } else {
      passed.add('E105: Description length OK');
    }

    // E106: Description voice
    final firstPerson = RegExp(r'\b(I can|I will|I help|we can|we will)\b', caseSensitive: false);
    if (firstPerson.hasMatch(desc)) {
      errors.add(ValidationIssue(
        code: 'E106',
        message: 'Description uses first person',
        fix: 'Use third person: "Generates..." not "I can..."',
      ));
    } else {
      passed.add('E106: Third person voice');
    }
  }

  // E107: Allowed tools
  if (!frontmatter.containsKey('allowed-tools')) {
    errors.add(ValidationIssue(
      code: 'E107',
      message: 'Frontmatter missing "allowed-tools" field',
      fix: 'Add "allowed-tools: Read, Write, Edit, ..."',
    ));
  } else {
    passed.add('E107: Allowed tools present');
  }

  // Section checks
  final requiredSections = {
    'E201': (r'^#\s+', 'Title heading'),
    'E202': (r'##\s+When to Use', 'When to Use section'),
    'E203': (r'##\s+Workflow', 'Workflow section'),
    'E204': (r'##\s+Guides', 'Guides section'),
    'E205': (r'##\s+.*Checklist', 'Checklist section'),
    'E206': (r'##\s+Related Skills', 'Related Skills section'),
  };

  for (final entry in requiredSections.entries) {
    final regex = RegExp(entry.value.$1, multiLine: true);
    if (regex.hasMatch(content)) {
      passed.add('${entry.key}: ${entry.value.$2} exists');
    } else {
      errors.add(ValidationIssue(
        code: entry.key,
        message: 'Missing ${entry.value.$2}',
        fix: 'Add "${entry.value.$2}" section to SKILL.md',
      ));
    }
  }

  // E205 additional: Check for checkbox items
  if (content.contains('## Checklist')) {
    final checkboxCount = RegExp(r'- \[ \]').allMatches(content).length;
    if (checkboxCount < 3) {
      warnings.add(ValidationIssue(
        code: 'W304',
        message: 'Checklist has < 3 items ($checkboxCount found)',
        fix: 'Add more actionable checklist items',
      ));
    }
  }

  if (verbose) print('');
}

// ============================================================
// GATE 3: QUALITY
// ============================================================

void _validateQuality(
  String skillPath,
  String skillName,
  List<ValidationIssue> errors,
  List<ValidationIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) {
  if (verbose) print('✨ Gate 3: Quality\n');

  final skillMdPath = '$skillPath/SKILL.md';
  if (!File(skillMdPath).existsSync()) return;

  final content = File(skillMdPath).readAsStringSync();
  final lines = content.split('\n');

  // W301: Line count < 300
  if (lines.length > 300) {
    warnings.add(ValidationIssue(
      code: 'W301',
      message: 'SKILL.md too long (${lines.length} > 300 lines)',
      fix: 'Move detailed content to guide files',
    ));
  } else {
    passed.add('W301: Line count OK (${lines.length} lines)');
  }

  // W302: Ideal length < 200
  if (lines.length > 200 && lines.length <= 300) {
    warnings.add(ValidationIssue(
      code: 'W302',
      message: 'SKILL.md longer than ideal (${lines.length} > 200)',
      fix: 'Consider moving some content to guides',
    ));
  }

  // W303: No code blocks > 10 lines
  final codeBlockRegex = RegExp(r'```[\s\S]*?```');
  for (final match in codeBlockRegex.allMatches(content)) {
    final block = match.group(0)!;
    final blockLines = block.split('\n').length - 2; // Exclude ``` markers
    if (blockLines > 10) {
      warnings.add(ValidationIssue(
        code: 'W303',
        message: 'Code block with $blockLines lines (> 10)',
        fix: 'Move long code to reference/ files',
      ));
    }
  }

  // W305: Workflow has numbered steps
  if (content.contains('## Workflow')) {
    final workflowMatch = RegExp(r'## Workflow[\s\S]*?(?=\n## |$)').firstMatch(content);
    if (workflowMatch != null) {
      final workflowSection = workflowMatch.group(0)!;
      // Check for ### Phase N, ### Step N, ### N., or numbered list items
      final hasPhaseHeaders = RegExp(r'###\s+(Phase|Step)\s*\d+', caseSensitive: false)
          .hasMatch(workflowSection);
      final hasNumberedHeadings = RegExp(r'###\s+\d+\.?\s')
          .hasMatch(workflowSection);
      final hasNumberedList = RegExp(r'\n\d+\.\s')
          .hasMatch(workflowSection);

      if (!hasPhaseHeaders && !hasNumberedHeadings && !hasNumberedList) {
        warnings.add(ValidationIssue(
          code: 'W305',
          message: 'Workflow lacks numbered steps',
          fix: 'Add numbered steps or phases to workflow',
        ));
      }
    }
  }

  // W306: Skill boundary violations (stepping on other skills)
  _validateSkillBoundaries(skillPath, skillName, warnings, passed);

  // W401-W404: Link validation
  _validateLinks(skillPath, content, warnings, passed);

  // W501-W503: Reference file headers
  _validateReferenceFiles(skillPath, warnings, passed);

  // W601-W604: Validation script
  _validateCheckScript(skillPath, warnings, passed);

  if (verbose) print('');
}

void _validateLinks(
  String skillPath,
  String content,
  List<ValidationIssue> warnings,
  List<String> passed,
) {
  // Find all markdown links
  final linkRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
  var brokenLinks = 0;

  for (final match in linkRegex.allMatches(content)) {
    final linkPath = match.group(2)!;

    // Skip external links
    if (linkPath.startsWith('http://') || linkPath.startsWith('https://')) {
      continue;
    }

    // Skip anchors
    if (linkPath.startsWith('#')) {
      continue;
    }

    // Check if file exists
    final fullPath = '$skillPath/$linkPath';
    if (!File(fullPath).existsSync() && !Directory(fullPath).existsSync()) {
      warnings.add(ValidationIssue(
        code: 'W401',
        message: 'Broken link: $linkPath',
        fix: 'Create file or fix path',
      ));
      brokenLinks++;
    }
  }

  if (brokenLinks == 0) {
    passed.add('W401: All internal links resolve');
  }
}

void _validateReferenceFiles(
  String skillPath,
  List<ValidationIssue> warnings,
  List<String> passed,
) {
  final refDir = Directory('$skillPath/reference');
  if (!refDir.existsSync()) return;

  var missingHeaders = 0;

  for (final file in refDir.listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;

    final content = file.readAsStringSync();
    final relativePath = file.path.replaceFirst('$skillPath/', '');

    // Check for header comment
    if (!content.startsWith('//')) {
      warnings.add(ValidationIssue(
        code: 'W501',
        message: 'Reference file missing header: $relativePath',
        fix: 'Add header comment with Template, Location, Usage',
      ));
      missingHeaders++;
      continue;
    }

    // Check for Location comment
    if (!content.contains('// Location:')) {
      warnings.add(ValidationIssue(
        code: 'W502',
        message: 'Reference file missing Location: $relativePath',
        fix: 'Add "// Location:" to header',
      ));
    }

    // Check for Usage comment
    if (!content.contains('// Usage:')) {
      warnings.add(ValidationIssue(
        code: 'W503',
        message: 'Reference file missing Usage: $relativePath',
        fix: 'Add "// Usage:" to header',
      ));
    }
  }

  if (missingHeaders == 0) {
    passed.add('W501: Reference files have headers');
  }
}

void _validateCheckScript(
  String skillPath,
  List<ValidationIssue> warnings,
  List<String> passed,
) {
  final scriptsDir = Directory('$skillPath/scripts');
  if (!scriptsDir.existsSync()) {
    return; // Scripts not required for all skills
  }

  // Find check script
  final checkScript = [
    '$skillPath/scripts/check.dart',
    '$skillPath/scripts/validate.dart',
  ].firstWhere(
    (path) => File(path).existsSync(),
    orElse: () => '',
  );

  if (checkScript.isEmpty) {
    warnings.add(ValidationIssue(
      code: 'W601',
      message: 'No check/validate script in scripts/',
      fix: 'Create scripts/check.dart for validation',
    ));
    return;
  }
  passed.add('W601: Check script exists');

  // Check script content
  final content = File(checkScript).readAsStringSync();

  if (!content.contains('--help') && !content.contains('-h')) {
    warnings.add(ValidationIssue(
      code: 'W603',
      message: 'Check script missing --help option',
      fix: 'Add --help support to script',
    ));
  } else {
    passed.add('W603: Check script has --help');
  }

  if (!content.contains('--json')) {
    warnings.add(ValidationIssue(
      code: 'W604',
      message: 'Check script missing --json option',
      fix: 'Add --json output for CI integration',
    ));
  } else {
    passed.add('W604: Check script has --json');
  }
}

void _validateSkillBoundaries(
  String skillPath,
  String skillName,
  List<ValidationIssue> warnings,
  List<String> passed,
) {
  // Skills that own specific concerns - skip checking themselves
  const ownerSkills = {
    'i18n': 'i18n',
    'design': 'design',
    'a11y': 'a11y',
    'testing': 'testing',
  };

  // Skip if this skill owns one of the concerns
  if (ownerSkills.containsKey(skillName)) {
    passed.add('W306: Skill boundary check (owner skill, skipped)');
    return;
  }

  // Patterns that indicate stepping on other skills' work
  // These should only flag INSTRUCTIONAL content, not code examples showing expected output
  // Format: (pattern, ownerSkill, description, markdownOnly)
  final boundaryPatterns = <(RegExp, String, String, bool)>[
    // i18n patterns - only flag instructional sections, not code examples
    (
      RegExp(r'###\s*Locali[zs](ed|ation)\s*(Message|String)?', caseSensitive: false),
      'i18n',
      'Localization section header',
      true, // markdown only
    ),
    (
      RegExp(r'replace\s+(hardcoded\s+)?string\s+with\s+(your\s+)?i18n', caseSensitive: false),
      'i18n',
      'i18n setup instructions',
      true,
    ),
    (
      RegExp(r'using\s+(slang|flutter_localizations|easy_localization)', caseSensitive: false),
      'i18n',
      'i18n library instructions',
      true,
    ),

    // design patterns - only flag instructional sections
    (
      RegExp(r'###\s*Custom\s*(Banner\s*)?Colors?', caseSensitive: false),
      'design',
      'Custom colors section',
      true,
    ),
    (
      RegExp(r'###\s*(Styling|Theme\s*Customization)', caseSensitive: false),
      'design',
      'Styling section header',
      true,
    ),
    (
      RegExp(r'adjust\s+colors?\s+to\s+match', caseSensitive: false),
      'design',
      'Color adjustment instructions',
      true,
    ),

    // a11y patterns - only flag instructional sections
    (
      RegExp(r'###\s*Accessibility', caseSensitive: false),
      'a11y',
      'Accessibility section header',
      true,
    ),
    (
      RegExp(r'add\s+(semantic|accessibility)\s+labels?', caseSensitive: false),
      'a11y',
      'Accessibility setup instructions',
      true,
    ),

    // testing patterns - only flag instructional sections (not in /testing skill)
    (
      RegExp(r'###\s*(Unit|Widget|Golden)\s*Test(s|ing)?', caseSensitive: false),
      'testing',
      'Testing section header',
      true,
    ),
    (
      RegExp(r'###\s*How\s+to\s+(Write\s+)?Test', caseSensitive: false),
      'testing',
      'Testing instructions header',
      true,
    ),
  ];

  // Patterns that are OK (simple delegations)
  final okPatterns = [
    RegExp(r'Run\s+`?/?(i18n|design|a11y|testing)`?', caseSensitive: false),
    RegExp(r'`/?i18n`|`/?design`|`/?a11y`|`/?testing`'),
    RegExp(r'for\s+(localization|UI polish|accessibility|tests)', caseSensitive: false),
  ];

  final violations = <(String, String, String)>[]; // (file, ownerSkill, description)

  // Check all markdown files in the skill
  final filesToCheck = <File>[];
  final skillDir = Directory(skillPath);

  for (final entity in skillDir.listSync(recursive: true)) {
    if (entity is File) {
      final path = entity.path;
      if (path.endsWith('.md') || path.endsWith('.dart')) {
        filesToCheck.add(entity);
      }
    }
  }

  for (final file in filesToCheck) {
    final content = file.readAsStringSync();
    final relativePath = file.path.replaceFirst('$skillPath/', '');
    final isMarkdown = relativePath.endsWith('.md');
    final isReference = relativePath.startsWith('reference/');

    for (final (pattern, ownerSkill, description, markdownOnly) in boundaryPatterns) {
      // Skip non-markdown files if pattern is markdown-only
      if (markdownOnly && !isMarkdown) continue;

      // Skip reference files entirely - they're meant to show code examples
      if (isReference) continue;

      final matches = pattern.allMatches(content);

      for (final match in matches) {
        // Check if this match is part of an OK pattern (simple delegation)
        final isOkDelegation = okPatterns.any((okPattern) {
          // Check if the match is within an OK context
          final start = (match.start - 50).clamp(0, content.length);
          final end = (match.end + 50).clamp(0, content.length);
          final context = content.substring(start, end);
          return okPattern.hasMatch(context);
        });

        if (isOkDelegation) continue;

        violations.add((relativePath, ownerSkill, description));
      }
    }
  }

  // Deduplicate violations by file and owner skill
  final uniqueViolations = <String, Set<String>>{};
  for (final (file, ownerSkill, description) in violations) {
    uniqueViolations.putIfAbsent(ownerSkill, () => {}).add('$file: $description');
  }

  if (uniqueViolations.isEmpty) {
    passed.add('W306: No skill boundary violations');
  } else {
    for (final entry in uniqueViolations.entries) {
      final ownerSkill = entry.key;
      final issues = entry.value;
      for (final issue in issues.take(3)) {
        // Limit to 3 per owner skill
        warnings.add(ValidationIssue(
          code: 'W306',
          message: 'Content belongs to /$ownerSkill: $issue',
          fix: 'Remove detailed how-to, use "Run `/$ownerSkill`" delegation instead',
        ));
      }
    }
  }
}

// ============================================================
// GATE 4: INTEGRATION
// ============================================================

void _validateIntegration(
  String skillPath,
  String skillName,
  List<ValidationIssue> errors,
  List<ValidationIssue> warnings,
  List<String> passed, {
  bool verbose = true,
}) {
  if (verbose) print('🔗 Gate 4: Integration\n');

  // Check SKILL_STRUCTURE.md
  final structurePath = '.claude/SKILL_STRUCTURE.md';
  if (!File(structurePath).existsSync()) {
    warnings.add(ValidationIssue(
      code: 'W701',
      message: 'SKILL_STRUCTURE.md not found',
      fix: 'Cannot validate integration',
    ));
    return;
  }

  final structureContent = File(structurePath).readAsStringSync();

  // W701: In skill table
  if (structureContent.contains('`/$skillName`') ||
      structureContent.contains('| $skillName |')) {
    passed.add('W701: Registered in SKILL_STRUCTURE.md');
  } else {
    warnings.add(ValidationIssue(
      code: 'W701',
      message: 'Skill not in SKILL_STRUCTURE.md skill table',
      fix: 'Add to "Complete Skill Reference" table',
    ));
  }

  // Check related skills exist
  final skillMdPath = '$skillPath/SKILL.md';
  if (File(skillMdPath).existsSync()) {
    final content = File(skillMdPath).readAsStringSync();

    // Find Related Skills section
    final relatedMatch = RegExp(
      r'## Related Skills[\s\S]*?(?=##|$)',
    ).firstMatch(content);

    if (relatedMatch != null) {
      final relatedSection = relatedMatch.group(0)!;
      final skillRefs = RegExp(r'`/([a-z0-9-]+)`').allMatches(relatedSection);

      for (final match in skillRefs) {
        final refSkill = match.group(1)!;
        if (!Directory('.claude/skills/$refSkill').existsSync()) {
          warnings.add(ValidationIssue(
            code: 'W801',
            message: 'Related skill does not exist: $refSkill',
            fix: 'Remove reference or create skill',
          ));
        }
      }
    }
  }

  if (verbose) print('');
}

// ============================================================
// HELPERS
// ============================================================

Map<String, dynamic>? _parseFrontmatter(String content) {
  if (!content.startsWith('---')) return null;

  final endIndex = content.indexOf('---', 3);
  if (endIndex == -1) return null;

  final yaml = content.substring(3, endIndex).trim();
  final result = <String, dynamic>{};

  for (final line in yaml.split('\n')) {
    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) continue;

    final key = line.substring(0, colonIndex).trim();
    final value = line.substring(colonIndex + 1).trim();
    result[key] = value;
  }

  return result;
}

String _calculateScore(int errors, int warnings) {
  if (errors > 0) return 'F';
  if (warnings == 0) return 'A';
  if (warnings < 3) return 'B';
  if (warnings <= 5) return 'C';
  return 'D';
}

String? _getArgValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  final value = args[index + 1];
  if (value.startsWith('-')) return null;
  return value;
}

// ============================================================
// OUTPUT
// ============================================================

void _printResults(
  List<ValidationIssue> errors,
  List<ValidationIssue> warnings,
  List<String> passed, {
  bool report = false,
}) {
  print('═══════════════════════════════════════════════════════════');
  print('  Results');
  print('═══════════════════════════════════════════════════════════');
  print('');

  if (report && passed.isNotEmpty) {
    print('✅ Passed (${passed.length}):');
    for (final item in passed) {
      print('   ✓ $item');
    }
    print('');
  }

  if (warnings.isNotEmpty) {
    print('⚠️  Warnings (${warnings.length}):');
    for (final warning in warnings) {
      print('   ⚠ [${warning.code}] ${warning.message}');
      print('     Fix: ${warning.fix}');
    }
    print('');
  }

  if (errors.isNotEmpty) {
    print('❌ Errors (${errors.length}):');
    for (final error in errors) {
      print('   ✗ [${error.code}] ${error.message}');
      print('     Fix: ${error.fix}');
    }
    print('');
  }

  final score = _calculateScore(errors.length, warnings.length);

  print('───────────────────────────────────────────────────────────');
  print('');
  print('  Score: $score');
  print('  Passed: ${passed.length} | Warnings: ${warnings.length} | Errors: ${errors.length}');
  print('');

  if (errors.isEmpty && warnings.isEmpty) {
    print('  🎉 Skill passes all quality gates!');
  } else if (errors.isEmpty) {
    print('  ⚠️  Skill is functional but has ${warnings.length} warning(s).');
  } else {
    print('  ❌ Skill has ${errors.length} error(s) that must be fixed.');
  }
  print('');
}

void _printJsonResults(
  String skillName,
  List<ValidationIssue> errors,
  List<ValidationIssue> warnings,
  List<String> passed,
) {
  final result = {
    'skill': skillName,
    'score': _calculateScore(errors.length, warnings.length),
    'valid': errors.isEmpty,
    'summary': {
      'passed': passed.length,
      'warnings': warnings.length,
      'errors': errors.length,
    },
    'passed': passed,
    'warnings': warnings
        .map((w) => <String, String>{'code': w.code, 'message': w.message, 'fix': w.fix})
        .toList(),
    'errors': errors
        .map((e) => <String, String>{'code': e.code, 'message': e.message, 'fix': e.fix})
        .toList(),
  };

  print(_jsonEncode(result));
}

void _printJsonAllResults(
  Map<String, Map<String, dynamic>> results,
  int totalErrors,
  int totalWarnings,
) {
  final output = {
    'valid': totalErrors == 0,
    'summary': {
      'skills': results.length,
      'errors': totalErrors,
      'warnings': totalWarnings,
    },
    'skills': results,
  };

  print(_jsonEncode(output));
}

String _jsonEncode(dynamic obj) {
  if (obj == null) return 'null';
  if (obj is String) return '"${obj.replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
  if (obj is num || obj is bool) return '$obj';
  if (obj is List) return '[${obj.map((e) => _jsonEncode(e)).join(',')}]';
  if (obj is Map) {
    final pairs = obj.entries.map((e) => '"${e.key}":${_jsonEncode(e.value)}');
    return '{${pairs.join(',')}}';
  }
  return 'null';
}

void _printCheckList() {
  print('''
Skill Validation Checks
═══════════════════════

GATE 1: STRUCTURE (Required)
  E001  Skill directory exists
  E002  SKILL.md exists
  E003  Valid directory name (lowercase, hyphens, < 64 chars)
  E004  Name not reserved (anthropic, claude, etc.)

GATE 2: CONTENT (Required)
  E101  Valid YAML frontmatter
  E102  Name field present
  E103  Name matches directory
  E104  Description field present
  E105  Description < 1024 characters
  E106  Third person voice
  E107  Allowed tools present
  E201  Title heading exists
  E202  "When to Use" section exists
  E203  "Workflow" section exists
  E204  "Guides" section exists
  E205  "Checklist" section exists
  E206  "Related Skills" section exists

GATE 3: QUALITY (Recommended)
  W301  SKILL.md < 300 lines
  W302  SKILL.md < 200 lines (ideal)
  W303  No code blocks > 10 lines
  W304  Checklist has > 3 items
  W305  Workflow has numbered steps
  W306  No skill boundary violations (i18n, design, a11y, testing content)
  W401  All internal links resolve
  W501  Reference files have headers
  W502  Reference files have Location comment
  W503  Reference files have Usage comment
  W601  Check script exists
  W603  Check script has --help
  W604  Check script has --json

GATE 4: INTEGRATION (Recommended)
  W701  Registered in SKILL_STRUCTURE.md
  W801  Related skills exist

Run validation:
  dart run .claude/skills/skill-create/scripts/validate.dart --skill {name}
''');
}

void _printHelp() {
  print('''
Skill Validation Tool

Validates Claude Code skills against quality gates.

USAGE:
  dart run .claude/skills/skill-create/scripts/validate.dart [options]

OPTIONS:
  --skill <name>   Validate specific skill
  --all            Validate all skills
  --gate <name>    Run specific gate (structure, content, quality, integration)
  --report         Show detailed report including passed checks
  --json           Output as JSON for CI
  --list-checks    List all validation checks
  -h, --help       Show this help

EXAMPLES:
  # Validate a skill
  dart run .claude/skills/skill-create/scripts/validate.dart --skill auth

  # Validate all skills
  dart run .claude/skills/skill-create/scripts/validate.dart --all

  # Check only structure
  dart run .claude/skills/skill-create/scripts/validate.dart --skill auth --gate structure

  # Get detailed report
  dart run .claude/skills/skill-create/scripts/validate.dart --skill auth --report

  # JSON output for CI
  dart run .claude/skills/skill-create/scripts/validate.dart --skill auth --json

QUALITY GATES:
  Gate 1: Structure  - Directory and files exist (required)
  Gate 2: Content    - SKILL.md has required sections (required)
  Gate 3: Quality    - Best practices and guidelines (recommended)
  Gate 4: Integration - Registered in skill system (recommended)

SCORES:
  A - All gates pass, 0 warnings
  B - Required gates pass, < 3 warnings
  C - Required gates pass, 3-5 warnings
  D - Required gates pass, > 5 warnings
  F - Required gate fails

SEE ALSO:
  .claude/skills/skill-create/checklist.md
  .claude/skills/skill-create/quality-gates.md
''');
}

// ============================================================
// TYPES
// ============================================================

class ValidationIssue {
  final String code;
  final String message;
  final String fix;

  const ValidationIssue({
    required this.code,
    required this.message,
    required this.fix,
  });
}

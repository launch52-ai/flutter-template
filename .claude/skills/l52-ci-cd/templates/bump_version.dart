#!/usr/bin/env dart
// Version bump script for Flutter projects
//
// Usage:
//   dart run scripts/bump_version.dart [major|minor|patch|build] [--tag]
//
// Examples:
//   dart run scripts/bump_version.dart patch        # 1.0.0 → 1.0.1
//   dart run scripts/bump_version.dart minor        # 1.0.1 → 1.1.0
//   dart run scripts/bump_version.dart major        # 1.1.0 → 2.0.0
//   dart run scripts/bump_version.dart build        # Only increment build number
//   dart run scripts/bump_version.dart patch --tag  # Bump + create git tag

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    _printUsage();
    exit(0);
  }

  final bumpType = args.first;
  final createTag = args.contains('--tag');

  // Validate bump type
  if (!['major', 'minor', 'patch', 'build'].contains(bumpType)) {
    print('Error: Invalid bump type "$bumpType"');
    _printUsage();
    exit(1);
  }

  // Find pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found');
    print('Make sure you run this from the project root.');
    exit(1);
  }

  // Read and parse version
  final content = pubspecFile.readAsStringSync();
  final versionMatch = RegExp(r'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)').firstMatch(content);

  if (versionMatch == null) {
    // Try without build number
    final simpleMatch = RegExp(r'version:\s*(\d+)\.(\d+)\.(\d+)').firstMatch(content);
    if (simpleMatch != null) {
      print('Error: Version missing build number.');
      print('Update pubspec.yaml to use format: version: 1.0.0+1');
      exit(1);
    }
    print('Error: Could not parse version from pubspec.yaml');
    exit(1);
  }

  var major = int.parse(versionMatch.group(1)!);
  var minor = int.parse(versionMatch.group(2)!);
  var patch = int.parse(versionMatch.group(3)!);
  var build = int.parse(versionMatch.group(4)!);

  print('Current version: $major.$minor.$patch+$build');

  // Apply bump
  switch (bumpType) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
    case 'minor':
      minor++;
      patch = 0;
    case 'patch':
      patch++;
    case 'build':
      // Only increment build
      break;
  }

  // Always increment build number
  build++;

  final newVersion = '$major.$minor.$patch+$build';
  final tagName = 'v$major.$minor.$patch';

  print('New version: $newVersion');

  // Update pubspec.yaml
  final newContent = content.replaceFirst(
    RegExp(r'version:\s*\d+\.\d+\.\d+\+\d+'),
    'version: $newVersion',
  );

  pubspecFile.writeAsStringSync(newContent);
  print('Updated pubspec.yaml');

  // Create git tag if requested
  if (createTag) {
    print('');
    print('Creating git tag...');

    // Stage pubspec.yaml
    final addResult = Process.runSync('git', ['add', 'pubspec.yaml']);
    if (addResult.exitCode != 0) {
      print('Warning: git add failed');
    }

    // Commit
    final commitResult = Process.runSync(
      'git',
      ['commit', '-m', 'Bump version to $newVersion'],
    );
    if (commitResult.exitCode != 0) {
      print('Warning: git commit failed (maybe no changes?)');
    }

    // Create tag
    final tagResult = Process.runSync(
      'git',
      ['tag', '-a', tagName, '-m', 'Release $major.$minor.$patch'],
    );
    if (tagResult.exitCode != 0) {
      print('Error: Failed to create tag');
      print(tagResult.stderr);
      exit(1);
    }

    print('Created tag: $tagName');
    print('');
    print('To push: git push origin main --tags');
  }

  print('');
  print('Done!');
}

void _printUsage() {
  print('''
Version Bump Script

Usage:
  dart run scripts/bump_version.dart <type> [--tag]

Types:
  major   Bump major version (breaking changes)  1.0.0 → 2.0.0
  minor   Bump minor version (new features)      1.0.0 → 1.1.0
  patch   Bump patch version (bug fixes)         1.0.0 → 1.0.1
  build   Only increment build number            1.0.0+1 → 1.0.0+2

Options:
  --tag   Create git commit and tag after bumping

Examples:
  dart run scripts/bump_version.dart patch
  dart run scripts/bump_version.dart minor --tag
''');
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const domainDirectory = 'lib/features/tasks/domain';

  test('Tasks domain exists and imports no UI or infrastructure SDK', () {
    final directory = Directory(domainDirectory);
    expect(
      directory.existsSync(),
      isTrue,
      reason: 'T022 must create the Tasks-owned domain boundary',
    );

    const forbiddenPrefixes = <String>[
      'package:flutter/',
      'package:drift/',
      'package:drift_flutter/',
      'package:supabase/',
      'package:supabase_flutter/',
      'package:namma_project/core/data/',
      'package:namma_project/features/tasks/data/',
      'package:namma_project/features/tasks/presentation/',
    ];
    final violations = <String>[];
    final importPattern = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );

    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      for (final match in importPattern.allMatches(entity.readAsStringSync())) {
        final target = match.group(1)!;
        final importsAnotherFeature =
            target.startsWith('package:namma_project/features/') &&
            !target.startsWith('package:namma_project/features/tasks/domain/');
        if (forbiddenPrefixes.any(target.startsWith) || importsAnotherFeature) {
          violations.add('${entity.path}: $target');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Task domain code must remain SDK and infrastructure independent',
    );
  });

  test('canonical Task aggregate is declared only by its owning domain', () {
    final libDirectory = Directory('lib');
    final declarations = <String>[];
    final declarationPattern = RegExp(
      r'^\s*(?:final\s+|sealed\s+|abstract\s+)?class\s+Task\s',
      multiLine: true,
    );

    for (final entity in libDirectory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      if (declarationPattern.hasMatch(entity.readAsStringSync())) {
        declarations.add(entity.path.replaceAll('\\', '/'));
      }
    }

    expect(declarations, <String>['lib/features/tasks/domain/task.dart']);
  });

  test('other features do not own Task persistence or presentation copies', () {
    final featureRoot = Directory('lib/features');
    if (!featureRoot.existsSync()) {
      fail('Feature root is missing');
    }

    final violations = <String>[];
    final forbiddenOwnership = RegExp(
      r'\b(?:TaskRepository|TaskRecords|TasksCubit|class\s+Task)\b',
    );

    for (final entity in featureRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final normalized = entity.path.replaceAll('\\', '/');
      if (normalized.contains('/features/tasks/')) {
        continue;
      }
      if (forbiddenOwnership.hasMatch(entity.readAsStringSync())) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Tasks is the single canonical owner of Task state',
    );
  });
}

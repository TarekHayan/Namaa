import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture boundary: Domain code must not import Flutter, Supabase,
/// Drift, routing, notification, or platform-adapter libraries
/// (specs/001-namaa-foundation/contracts/application-boundaries.md;
/// Constitution: shared business rules with no infrastructure coupling).
void main() {
  const forbiddenPackagePrefixes = <String>[
    'dart:ui',
    'package:flutter/',
    'package:supabase',
    'package:drift',
    'package:go_router',
    // Notification packages (product domains are out of Foundation scope).
    'package:flutter_local_notifications',
    'package:firebase_messaging',
    // Platform adapters.
    'package:flutter_secure_storage',
    'package:shared_preferences',
    'package:path_provider',
  ];

  /// Returns import/export directives in [source] that violate the boundary.
  List<String> violationsIn(String source) {
    final directive = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );
    return directive
        .allMatches(source)
        .map((match) => match.group(1)!)
        .where(
          (target) => forbiddenPackagePrefixes.any(
            (prefix) => target.startsWith(prefix),
          ),
        )
        .toList(growable: false);
  }

  test('scanner detects a forbidden import (failure-mode control)', () {
    const sample = '''
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
''';
    final violations = violationsIn(sample);
    expect(violations, hasLength(2));
    expect(violations.any((v) => v.startsWith('package:flutter/')), isTrue);
    expect(violations.any((v) => v.startsWith('package:supabase')), isTrue);
  });

  test('Foundation Domain files import no infrastructure libraries', () {
    final domainDirs = <Directory>[
      Directory('lib/core/domain'),
      Directory('lib/features/foundation/domain'),
    ];
    final violations = <String>[];
    for (final dir in domainDirs) {
      expect(dir.existsSync(), isTrue, reason: '${dir.path} must exist');
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        for (final target in violationsIn(entity.readAsStringSync())) {
          violations.add('${entity.path}: $target');
        }
      }
    }
    expect(violations, isEmpty, reason: 'Domain must stay infrastructure-free');
  });
}

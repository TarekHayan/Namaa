import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _directive = RegExp(
  r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);
final _remoteWrite = RegExp(
  r'''\.from\s*\(\s*['"](?:adhkar_item_counts|adhkar_conflicts|'''
  r'''adhkar_catalog_items|qiyam_nights|qiyam_conflicts|xp_awards)['"]'''
  r'''\s*\)\s*\.(?:insert|upsert|update|delete)\s*\(''',
);
final _directStorage = RegExp(
  r'\b(?:FoundationDatabase|SupabaseClient|adhkarItemCounts|qiyamNights|'
  r'conflictRecords|xpAwards)\b',
);

String _normalize(String path) => path.replaceAll('\\', '/');

/// Resolves a directive reference to a project path: package imports map to
/// lib/, relative imports resolve against the source file, and anything else
/// (dart:, third-party packages) returns null.
String? _projectTarget(String sourcePath, String reference) {
  const packagePrefix = 'package:namma_project/';
  if (reference.startsWith(packagePrefix)) {
    return 'lib/${reference.substring(packagePrefix.length)}';
  }
  if (reference.contains(':')) return null;
  final segments = _normalize(sourcePath).split('/')..removeLast();
  for (final part in reference.split('/')) {
    if (part == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else if (part != '.' && part.isNotEmpty) {
      segments.add(part);
    }
  }
  return segments.join('/');
}

String? _layerOf(String normalizedPath) => RegExp(
  r'^lib/features/(?:adhkar|qiyam)/([^/]+)/',
).firstMatch(normalizedPath)?[1];

bool _infrastructurePackage(String target) =>
    target.startsWith('package:flutter/') ||
    target.startsWith('package:drift/') ||
    target.startsWith('package:supabase_') ||
    target.startsWith('package:uuid/') ||
    target.startsWith('package:timezone/');

List<String> _violations(String path, String source) {
  final issues = <String>[];
  final normalized = _normalize(path);
  final isAdhkar = normalized.startsWith('lib/features/adhkar/');
  final isQiyam = normalized.startsWith('lib/features/qiyam/');
  final isToday = normalized.startsWith('lib/features/today/');

  for (final match in _directive.allMatches(source)) {
    final reference = match.group(1)!;
    // Third-party packages keep their raw reference so the infrastructure
    // package bans can match them.
    final target = _projectTarget(path, reference) ?? reference;

    // Rule 1: Adhkar and Qiyam never import each other.
    if ((isAdhkar && target.startsWith('lib/features/qiyam/')) ||
        (isQiyam && target.startsWith('lib/features/adhkar/'))) {
      issues.add('$path crosses the Adhkar/Qiyam isolation: $reference');
    }

    // Rule 2: neither feature imports Prayer at all — the Prayer day
    // boundaries arrive only through ports wired in lib/app/composition.
    if ((isAdhkar || isQiyam) && target.startsWith('lib/features/prayer/')) {
      issues.add('$path imports Prayer directly: $reference');
    }

    // Rule 3: Today reaches Adhkar/Qiyam only through their application/
    // and domain/ folders, never data/ or presentation/.
    if (isToday &&
        (target.startsWith('lib/features/adhkar/') ||
            target.startsWith('lib/features/qiyam/'))) {
      final targetLayer = target
          .substring('lib/features/'.length)
          .split('/')[1];
      if (targetLayer == 'data' || targetLayer == 'presentation') {
        issues.add('$path bypasses the Adhkar/Qiyam surface: $reference');
      }
    }

    // Rule 4: the AGENTS.md layer table for both features. The project-layer
    // bans only look at project paths (lib/…), never at third-party package
    // paths that merely contain a folder named data or presentation.
    final isProjectTarget = target.startsWith('lib/');
    switch (_layerOf(normalized)) {
      case 'domain':
        // Domain imports domain only — no other layer, no infrastructure.
        if (_infrastructurePackage(target) ||
            (isProjectTarget &&
                (target.contains('/data/') ||
                    target.contains('/presentation/') ||
                    target.contains('/application/')))) {
          issues.add('$path domain imports outside domain: $reference');
        }
      case 'application':
        // Application imports domain and application — never data or
        // presentation, and no infrastructure package.
        if (_infrastructurePackage(target) ||
            (isProjectTarget &&
                (target.contains('/data/') ||
                    target.contains('/presentation/')))) {
          issues.add('$path application imports infrastructure: $reference');
        }
      case 'data':
        if (isProjectTarget && target.contains('/presentation/')) {
          issues.add('$path data imports presentation: $reference');
        }
      case 'presentation':
        if (isProjectTarget && target.contains('/data/')) {
          issues.add('$path presentation imports data: $reference');
        }
    }

    // Rule 6 (T090): My Adhkar never touches XP (FR-026) — no my_adhkar_*
    // file imports lib/features/xp/, no matter its layer.
    if (normalized.split('/').last.startsWith('my_adhkar_') &&
        target.startsWith('lib/features/xp/')) {
      issues.add('$path imports XP from My Adhkar: $reference');
    }
  }

  // Rule 5: storage stays in data/ — the encrypted database and the
  // Supabase client are never touched elsewhere, and remote tables are
  // only written through the versioned RPCs (never .from(...).insert).
  if ((isAdhkar || isQiyam) &&
      !normalized.contains('/data/') &&
      _directStorage.hasMatch(source)) {
    issues.add('$path touches storage directly');
  }
  if ((isAdhkar || isQiyam) &&
      normalized.contains('/data/') &&
      _remoteWrite.hasMatch(source)) {
    issues.add('$path writes remote stores outside the RPC gateways');
  }
  return issues;
}

void main() {
  test('negative controls reject isolation and Prayer bypasses', () {
    expect(
      _violations(
        'lib/features/adhkar/domain/example.dart',
        "import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/qiyam/application/example.dart',
        "import '../../adhkar/application/adhkar_repository.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/adhkar/application/example.dart',
        'import '
            "'package:namma_project/features/prayer/data/drift_prayer_repository.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/qiyam/domain/example.dart',
        "import 'package:namma_project/features/prayer/domain/prayer_name.dart';",
      ),
      isNotEmpty,
    );
  });

  test('negative controls reject Today reaching data or presentation', () {
    expect(
      _violations(
        'lib/features/today/data/example.dart',
        'import '
            "'package:namma_project/features/adhkar/data/drift_adhkar_repository.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/today/presentation/example.dart',
        "import '../../qiyam/presentation/qiyam_screen.dart';",
      ),
      isNotEmpty,
    );
    // The real adapter surface: application and domain imports are exactly
    // what Today is allowed to reach.
    expect(
      _violations(
        'lib/features/today/data/adhkar_qiyam_today_adapter.dart',
        'import '
            "'package:namma_project/features/adhkar/application/adhkar_repository.dart';\n"
            "import '../../qiyam/domain/qiyam_night.dart';",
      ),
      isEmpty,
    );
  });

  test('negative controls enforce the layer table', () {
    expect(
      _violations(
        'lib/features/adhkar/domain/example.dart',
        "import 'package:drift/drift.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/adhkar/domain/example.dart',
        "import 'package:flutter/material.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/adhkar/domain/example.dart',
        "import '../application/adhkar_repository.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/qiyam/application/example.dart',
        'import '
            "'package:supabase_flutter/supabase_flutter.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/adhkar/data/example.dart',
        "import '../presentation/adhkar_screen.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/qiyam/presentation/example.dart',
        'import '
            "'package:namma_project/features/qiyam/data/drift_qiyam_repository.dart';",
      ),
      isNotEmpty,
    );
    // Allowed shapes: application over core and its own domain, data over
    // Drift, presentation over Flutter.
    expect(
      _violations(
        'lib/features/adhkar/application/example.dart',
        'import '
            "'package:namma_project/core/domain/results/app_result.dart';\n"
            "import '../domain/adhkar_catalog.dart';",
      ),
      isEmpty,
    );
    expect(
      _violations(
        'lib/features/qiyam/data/example.dart',
        "import 'package:drift/drift.dart';",
      ),
      isEmpty,
    );
    expect(
      _violations(
        'lib/features/qiyam/presentation/example.dart',
        "import 'package:flutter/material.dart';",
      ),
      isEmpty,
    );
  });

  test(
    'negative controls reject storage outside data and raw remote writes',
    () {
      expect(
        _violations(
          'lib/features/adhkar/application/example.dart',
          'final database = FoundationDatabase.instance;',
        ),
        isNotEmpty,
      );
      expect(
        _violations(
          'lib/features/qiyam/presentation/example.dart',
          'final client = SupabaseClient(url);',
        ),
        isNotEmpty,
      );
      expect(
        _violations(
          'lib/features/adhkar/data/example.dart',
          "client.from('adhkar_item_counts').insert({'count': 1});",
        ),
        isNotEmpty,
      );
      // Reads over the remote tables and local Drift writes stay legal in
      // data/ — the RPC gateways are the only writers.
      expect(
        _violations(
          'lib/features/adhkar/data/example.dart',
          "client.from('adhkar_item_counts').select().eq('owner', accountId);",
        ),
        isEmpty,
      );
      expect(
        _violations(
          'lib/features/qiyam/data/example.dart',
          'await (_database.update(_database.qiyamNights)..where()).write(row);',
        ),
        isEmpty,
      );
    },
  );

  test('negative controls reject My Adhkar reaching XP', () {
    expect(
      _violations(
        'lib/features/adhkar/data/my_adhkar_xp_probe.dart',
        "import 'package:namma_project/features/xp/application/award_ledger.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/adhkar/application/my_adhkar_commands.dart',
        "import 'package:namma_project/features/xp/domain/xp_award.dart';",
      ),
      isNotEmpty,
    );
    // The reviewed-catalog set-award path lives in non-my_adhkar files and
    // stays legal there.
    expect(
      _violations(
        'lib/features/adhkar/data/drift_adhkar_repository.dart',
        "import 'package:namma_project/features/xp/application/award_ledger.dart';",
      ),
      isEmpty,
    );
  });

  test('Adhkar, Qiyam and Today honor the boundaries on current code', () {
    final violations = <String>[];
    for (final root in [
      'lib/features/adhkar',
      'lib/features/qiyam',
      'lib/features/today',
    ]) {
      for (final file in Directory(
        root,
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        violations.addAll(
          _violations(_normalize(file.path), file.readAsStringSync()),
        );
      }
    }
    expect(violations, isEmpty);
  });
}

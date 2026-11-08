import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _import = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

String? _target(String source, String reference) {
  const package = 'package:namma_project/';
  if (reference.startsWith(package)) {
    return 'lib/${reference.substring(package.length)}';
  }
  if (reference.contains(':')) return null;
  return File.fromUri(
    File(source).parent.uri.resolve(reference),
  ).path.replaceAll('\\', '/');
}

List<String> _violations(String path, String source) {
  final violations = <String>[];
  for (final match in _import.allMatches(source)) {
    final reference = match.group(1)!;
    final target = _target(path, reference) ?? reference;
    if (path.contains('/features/prayer/domain/') ||
        path.contains('/features/prayer/application/')) {
      if (target.contains('/data/') ||
          target.contains('/presentation/') ||
          target.startsWith('package:flutter/') ||
          target.startsWith('package:drift/') ||
          target.startsWith('package:supabase_') ||
          target.startsWith('package:uuid/') ||
          target.startsWith('package:timezone/')) {
        violations.add('$path imports infrastructure: $reference');
      }
    }
    if (path.contains('/features/today/') &&
        (target.contains('/features/prayer/data/') ||
            target.contains('/features/prayer/presentation/'))) {
      violations.add('$path bypasses Prayer projection: $reference');
    }
  }
  if (path.contains('/features/prayer/') &&
      !path.contains('/features/prayer/data/') &&
      RegExp(
        r'\b(?:prayerReports|xpAwards|SupabaseClient|FoundationDatabase)\b',
      ).hasMatch(source)) {
    violations.add('$path touches storage directly');
  }
  if (path.contains('/features/prayer/data/') &&
      RegExp(
        r'''\.from\s*\(\s*['"](?:xp_awards|prayer_reports|prayer_conflicts)['"]\s*\)\s*\.(?:insert|upsert|update|delete)\s*\(''',
      ).hasMatch(source)) {
    violations.add('$path writes remote stores directly');
  }
  return violations;
}

void main() {
  test('scanner rejects domain infrastructure and Today DB coupling', () {
    expect(
      _violations(
        'lib/features/prayer/domain/example.dart',
        "import 'package:drift/drift.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/today/data/example.dart',
        "import 'package:namma_project/features/prayer/data/drift_prayer_repository.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/prayer/data/example.dart',
        "client.from('prayer_reports').insert({'status': 'pending'});",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/prayer/data/example.dart',
        "client.from('prayer_reports').select().eq('owner', accountId);",
      ),
      isEmpty,
    );
  });

  test('Prayer and Today keep application boundaries', () {
    final violations = <String>[];
    for (final root in ['lib/features/prayer', 'lib/features/today']) {
      for (final file in Directory(
        root,
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        violations.addAll(
          _violations(file.path.replaceAll('\\', '/'), file.readAsStringSync()),
        );
      }
    }
    expect(violations, isEmpty);
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _directive = RegExp(
  r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);
final _directStorage = RegExp(
  r'\b(?:FoundationDatabase|taskRecords|habitRecords|habitDayRecords|xpAwards|'
  r'DriftTaskRepository|DriftHabitRepository|DriftAwardLedger|'
  r'TaskCompletionUnitOfWork|TaskCompletionCommit|SupabaseClient)\b|'
  r'''\.from\s*\(\s*['"](?:task_records|habit_records|habit_days|xp_awards)['"]''',
);
final _awardWrite = RegExp(
  r'\b(?:TaskCompletionAward\s*\(|writeAward\s*\(|insertAward\s*\(|'
  r'commitAward\s*\(|awardTaskCompletion\s*\(|insertOnce\s*\(|'
  r'applyRemoteAward\s*\()',
);

String _normalize(String path) => path.replaceAll('\\', '/');

String? _projectTarget(String sourcePath, String target) {
  const packagePrefix = 'package:namma_project/';
  if (target.startsWith(packagePrefix)) {
    return 'lib/${target.substring(packagePrefix.length)}';
  }
  if (target.contains(':')) return null;
  final segments = _normalize(sourcePath).split('/')..removeLast();
  for (final part in target.split('/')) {
    if (part == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else if (part != '.' && part.isNotEmpty) {
      segments.add(part);
    }
  }
  return segments.join('/');
}

String? _allowedOwner(String path) => switch (_normalize(path)) {
  'lib/features/today/data/tasks_today_adapter.dart' => 'tasks',
  'lib/features/today/data/habits_today_adapter.dart' => 'habits',
  'lib/features/today/data/xp_today_adapter.dart' => 'xp',
  _ => null,
};

List<String> _violations(String path, String source) {
  final issues = <String>[];
  final allowedOwner = _allowedOwner(path);
  for (final match in _directive.allMatches(source)) {
    final import = match.group(1)!;
    final target = _projectTarget(path, import);
    if (target == null) continue;
    if (target.startsWith('lib/core/data/') ||
        target.startsWith('lib/core/platform/')) {
      issues.add('$path imports storage/platform implementation: $import');
    }
    final owner = RegExp(
      r'^lib/features/(tasks|habits|xp|mind_maps)/([^/]+)/',
    ).firstMatch(target);
    if (owner == null) continue;
    final name = owner[1]!;
    final layer = owner[2]!;
    if (name != allowedOwner || (layer != 'application' && layer != 'domain')) {
      issues.add('$path bypasses the named owner read adapter: $import');
    }
  }
  if (_directStorage.hasMatch(source)) {
    issues.add('$path accesses owner storage directly');
  }
  if (_awardWrite.hasMatch(source)) {
    issues.add('$path writes an award instead of reading the XP ledger');
  }
  return issues;
}

void main() {
  test('negative controls reject package and relative owner bypasses', () {
    expect(
      _violations(
        'lib/features/today/application/shortcut.dart',
        "import 'package:namma_project/features/tasks/domain/task.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/today/domain/shortcut.dart',
        "import '../../habits/application/habit_commands.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/today/data/tasks_today_adapter.dart',
        "import '../../habits/domain/habit.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/today/data/tasks_today_adapter.dart',
        "import '../../tasks/presentation/tasks_cubit.dart';",
      ),
      isNotEmpty,
    );
  });

  test('negative controls reject direct tables and award writes', () {
    expect(
      _violations(
        'lib/features/today/data/xp_today_adapter.dart',
        'final records = database.xpAwards; TaskCompletionAward();',
      ),
      hasLength(2),
    );
    expect(
      _violations(
        'lib/features/today/data/tasks_today_adapter.dart',
        "import '../../../core/data/local/foundation_database.dart';",
      ),
      isNotEmpty,
    );
    expect(
      _violations(
        'lib/features/today/data/xp_today_adapter.dart',
        'await ledger.insertOnce(award);',
      ),
      isNotEmpty,
    );
  });

  test('named bridges may import only their owner application/domain', () {
    expect(
      _violations(
        'lib/features/today/data/tasks_today_adapter.dart',
        "import '../../tasks/application/task_repository.dart';",
      ),
      isEmpty,
    );
    expect(
      _violations(
        'lib/features/today/data/habits_today_adapter.dart',
        "import 'package:namma_project/features/habits/domain/habit.dart';",
      ),
      isEmpty,
    );
  });

  test('all current Today production files honor owner boundaries', () {
    final violations = <String>[];
    for (final file in Directory(
      'lib/features/today',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      violations.addAll(
        _violations(_normalize(file.path), file.readAsStringSync()),
      );
    }
    expect(violations, isEmpty);
  });
}

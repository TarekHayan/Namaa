import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _directive = RegExp(
  r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);
final _directStorage = RegExp(
  r'''\b(?:taskRecords|xpAwards|DriftTaskRepository|TaskCompletionUnitOfWork|AwardLedger|DriftAwardLedger|SupabaseTaskGateway|SupabaseTaskReader)\b|\.from\s*\(\s*['"](?:task_records|xp_awards)['"]\s*\)''',
);

String _normalized(File file) => file.path.replaceAll('\\', '/');

String? _projectTarget(String sourcePath, String target) {
  const prefix = 'package:namma_project/';
  if (target.startsWith(prefix)) {
    return 'lib/${target.substring(prefix.length)}';
  }
  if (target.contains(':')) return null;
  return _normalized(File.fromUri(File(sourcePath).parent.uri.resolve(target)));
}

List<String> _violations(String path, String source) {
  final issues = <String>[];
  final bridge = path.endsWith(
    '/features/mind_maps/data/tasks_map_link_adapter.dart',
  );
  for (final match in _directive.allMatches(source)) {
    final target = _projectTarget(path, match.group(1)!);
    if (target == null) continue;
    if (target.contains('/features/tasks/data/') ||
        target.contains('/features/tasks/presentation/') ||
        target.contains('/features/xp/')) {
      issues.add('$path imports Task/XP internals: ${match.group(1)}');
    }
    if (!bridge && target.contains('/features/tasks/')) {
      issues.add('$path bypasses the Task bridge: ${match.group(1)}');
    }
  }
  if (_directStorage.hasMatch(source)) {
    issues.add('$path accesses Task/XP storage directly');
  }
  return issues;
}

void main() {
  test('scanner rejects Task presentation and storage imports', () {
    const path = 'lib/features/mind_maps/application/example.dart';
    const source = '''
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/presentation/tasks_screen.dart';
''';
    expect(_violations(path, source), hasLength(4));
  });

  test('scanner rejects direct XP and Task writes', () {
    const path = 'lib/features/mind_maps/data/example.dart';
    const source = '''
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
final tasks = db.taskRecords;
final awards = db.xpAwards;
''';
    expect(_violations(path, source), hasLength(2));
  });

  test('Mind Maps uses its Task port and sole Tasks application bridge', () {
    final violations = <String>[];
    final root = Directory('lib/features/mind_maps');
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      violations.addAll(
        _violations(_normalized(file), file.readAsStringSync()),
      );
    }
    expect(violations, isEmpty);

    final port = File(
      'lib/features/mind_maps/application/map_task_link_port.dart',
    ).readAsStringSync();
    final commands = File(
      'lib/features/mind_maps/application/map_task_link_commands.dart',
    ).readAsStringSync();
    final bridge = File(
      'lib/features/mind_maps/data/tasks_map_link_adapter.dart',
    ).readAsStringSync();
    final composition = File(
      'lib/app/composition/configure_dependencies.dart',
    ).readAsStringSync();
    expect(port, contains('abstract interface class MapTaskLinkPort'));
    expect(commands, contains('MapTaskLinkPort'));
    expect(bridge, contains('implements MapTaskLinkPort'));
    expect(bridge, contains('TaskCompletionService'));
    expect(composition, contains('registerLazySingleton<MapTaskLinkPort>'));
  });
}

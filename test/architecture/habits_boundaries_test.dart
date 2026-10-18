import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _directive = RegExp(
  r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

Iterable<File> _dartFiles(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) return const Iterable<File>.empty();
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

String _normalizedPath(File file) => file.path.replaceAll('\\', '/');

String? _projectImport(String sourceFile, String target) {
  const packagePrefix = 'package:namma_project/';
  if (target.startsWith(packagePrefix)) {
    return 'lib/${target.substring(packagePrefix.length)}';
  }
  if (target.contains(':')) return null;
  final path = File.fromUri(File(sourceFile).parent.uri.resolve(target));
  return _normalizedPath(path);
}

List<String> _consumerViolations(String filePath, String source) {
  final violations = <String>[];
  for (final match in _directive.allMatches(source)) {
    final target = _projectImport(filePath, match.group(1)!);
    if (target != null && target.contains('/features/habits/data/')) {
      violations.add('$filePath imports Habit storage: ${match.group(1)}');
    }
  }
  final storageAccess = RegExp(
    r'''\b(?:HabitRecords|HabitDayRecords|habitRecords|habitDayRecords|HabitPayloadCodec|DriftHabitRepository|SupabaseHabitGateway|SupabaseHabitReader)\b|(?:\.from\s*\(\s*['"]habit(?:s|_days)['"]\s*\))''',
  );
  if (storageAccess.hasMatch(source)) {
    violations.add('$filePath accesses Habit storage directly');
  }
  return violations;
}

List<String> _xpViolations(String filePath, String source) {
  final violations = <String>[];
  for (final match in _directive.allMatches(source)) {
    final target = _projectImport(filePath, match.group(1)!);
    if (target != null &&
        (target.contains('/features/xp/application/') ||
            target.contains('/features/xp/data/'))) {
      violations.add(
        '$filePath imports an XP mutation layer: ${match.group(1)}',
      );
    }
  }
  final awardMutation = RegExp(
    r'''\b(?:AwardLedger|TaskCompletionAward|XpAward|XpLedger|awardXp|grantXp|applyXpAward)\b|(?:\.from\s*\(\s*['"]xp_awards['"]\s*\))''',
  );
  if (awardMutation.hasMatch(source)) {
    violations.add('$filePath references an XP award mutation');
  }
  return violations;
}

void main() {
  test('architecture scanner rejects direct Habit storage access', () {
    const file = 'lib/features/tasks/application/example.dart';
    const source = '''
import 'package:namma_project/features/habits/data/drift_habit_repository.dart';
final rows = client.from('habit_days');
''';
    expect(_consumerViolations(file, source), hasLength(2));
  });

  test('architecture scanner rejects Habit XP awards', () {
    const file = 'lib/features/habits/application/example.dart';
    const source = '''
import 'package:namma_project/features/xp/application/award_ledger.dart';
final award = TaskCompletionAward();
''';
    expect(_xpViolations(file, source), hasLength(2));
  });

  test('Tasks, Today, Dashboard and Analytics use Habit contracts only', () {
    final violations = <String>[];
    for (final feature in ['tasks', 'today', 'dashboard', 'analytics']) {
      for (final file in _dartFiles('lib/features/$feature')) {
        violations.addAll(
          _consumerViolations(_normalizedPath(file), file.readAsStringSync()),
        );
      }
    }
    expect(violations, isEmpty);
  });

  test('Habits cannot award or write XP', () {
    final violations = <String>[];
    for (final file in _dartFiles('lib/features/habits')) {
      violations.addAll(
        _xpViolations(_normalizedPath(file), file.readAsStringSync()),
      );
    }
    expect(violations, isEmpty);
  });
}

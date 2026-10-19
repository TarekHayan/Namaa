import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/habits_test_support.dart';

final _testKey = List<int>.generate(32, (index) => 0x50 + index);

void main() {
  late TemporaryDatabasePath tempPath;

  setUp(() => tempPath = TemporaryDatabasePath());
  tearDown(() => tempPath.dispose());

  Future<(String, FoundationDatabase)> createVersionThreeDatabase() async {
    final database = await FoundationDatabase.openEncrypted(
      path: tempPath.allocate(),
      key: _testKey,
      schemaVersion: 3,
    );

    // Drift's generated createAll represents the newest schema even when a
    // test opens an older version. Reproduce an installed v3 file explicitly.
    await database.rawExecute('DROP TABLE IF EXISTS habit_day_records');
    await database.rawExecute('DROP TABLE IF EXISTS habit_records');
    return (database.resolvedPath, database);
  }

  Future<void> seedVersionThreeData(FoundationDatabase database) async {
    await database.rawExecute(
      '''INSERT INTO foundation_preferences ("key", value, updated_at)
      VALUES ('locale', 'ar', '2026-10-12T08:00:00.000Z')''',
    );
    await database.rawExecute('''INSERT INTO local_records
      (record_id, account_id, payload, version_timestamp, sync_state, updated_at)
      VALUES ('probe-habits', '$kHabitsTestAccountA', 'foundation-payload',
        '2026-10-12T08:00:00.000Z', 0, '2026-10-12T08:00:00.000Z')''');
    await database.rawExecute('''INSERT INTO task_records
      (account_id, task_id, title, scheduled_date, category, quadrant,
       checklist_json, completion_xp, created_at, updated_at)
      VALUES ('$kHabitsTestAccountA', 'task-before-habits', 'task-sentinel',
        '2026-10-12', 'work', 'important_urgent', '[]', 15,
        '2026-10-12T08:00:00.000Z', '2026-10-12T08:00:00.000Z')''');
    await database.rawExecute('''INSERT INTO xp_awards
      (account_id, source, source_id, amount, awarded_at)
      VALUES ('$kHabitsTestAccountA', 'task_completion',
        'task-before-habits', 15, '2026-10-12T08:30:00.000Z')''');
    await database.rawExecute('''INSERT INTO pending_changes
      (operation_id, account_id, entity_type, entity_id, kind, state,
       attempt_count, serialized_change, created_at, version_timestamp)
      VALUES ('pending-before-habits', '$kHabitsTestAccountA',
        'task', 'task-before-habits', 0, 0, 0, '{"v":3}',
        '2026-10-12T08:00:00.000Z', '2026-10-12T08:00:00.000Z')''');
  }

  Future<void> expectPreviousData(FoundationDatabase database) async {
    expect(
      await database.rawScalar(
        "SELECT value FROM foundation_preferences WHERE \"key\" = 'locale'",
      ),
      'ar',
    );
    expect(
      await database.rawScalar(
        "SELECT payload FROM local_records WHERE record_id = 'probe-habits'",
      ),
      'foundation-payload',
    );
    expect(
      await database.rawScalar(
        "SELECT title FROM task_records WHERE task_id = 'task-before-habits'",
      ),
      'task-sentinel',
    );
    expect(
      await database.rawScalar(
        "SELECT amount FROM xp_awards WHERE source_id = 'task-before-habits'",
      ),
      15,
    );
    expect(
      await database.rawScalar(
        'SELECT serialized_change FROM pending_changes '
        "WHERE operation_id = 'pending-before-habits'",
      ),
      '{"v":3}',
    );
  }

  test('encrypted v3 to v4 preserves old rows and adds account-keyed '
      'Habit and HabitDay tables', () async {
    final (path, v3) = await createVersionThreeDatabase();
    await seedVersionThreeData(v3);
    await v3.close();

    final v4 = await FoundationDatabase.openEncrypted(
      path: path,
      key: _testKey,
      schemaVersion: 4,
    );
    expect(v4.schemaVersion, 4);
    await expectPreviousData(v4);
    expect(await v4.journalStatusFor(4), 'completed');
    expect(
      await v4.rawScalar(
        "SELECT count(*) FROM sqlite_master WHERE type = 'table' "
        "AND name IN ('habit_records', 'habit_day_records')",
      ),
      2,
    );
    expect(
      await v4.rawScalar(
        "SELECT count(*) FROM sqlite_master WHERE type = 'index' "
        "AND name IN ('habit_records_account_deleted', "
        "'habit_records_account_updated', "
        "'habit_day_records_account_habit_date', "
        "'habit_day_records_account_updated')",
      ),
      4,
    );

    const sentinel = 'encrypted-habit-v4-sentinel';
    Future<void> insertHabit(String accountId) =>
        v4.rawExecute('''INSERT INTO habit_records
      (account_id, habit_id, name, schedule_revisions_json,
       created_at, updated_at)
      VALUES ('$accountId', '$kHabitsTestHabitId', '$sentinel', '[]',
        '2026-10-12T09:00:00.000Z', '2026-10-12T09:00:00.000Z')''');
    Future<void> insertDay(String accountId) =>
        v4.rawExecute('''INSERT INTO habit_day_records
      (account_id, habit_id, local_date, completed_at, earned_while_due,
       recorded_utc_offset_minutes, updated_at)
      VALUES ('$accountId', '$kHabitsTestHabitId', '2026-10-12',
        '2026-10-12T09:30:00.000Z', 1, 120, '2026-10-12T09:30:00.000Z')''');

    await insertHabit(kHabitsTestAccountA);
    await insertHabit(kHabitsTestAccountB);
    await insertDay(kHabitsTestAccountA);
    await insertDay(kHabitsTestAccountB);
    expect(
      await v4.rawScalar(
        'SELECT count(*) FROM habit_records '
        "WHERE habit_id = '$kHabitsTestHabitId'",
      ),
      2,
    );
    expect(
      await v4.rawScalar(
        'SELECT count(*) FROM habit_day_records '
        "WHERE habit_id = '$kHabitsTestHabitId' AND local_date = '2026-10-12'",
      ),
      2,
    );
    await expectLater(insertHabit(kHabitsTestAccountA), throwsA(anything));
    await expectLater(insertDay(kHabitsTestAccountA), throwsA(anything));

    await v4.close();
    final bytes = await File(path).readAsBytes();
    expect(latin1.decode(bytes, allowInvalid: true), isNot(contains(sentinel)));
  });

  test(
    'failed v4 migration retains v3 rows and retry records recovery',
    () async {
      final (path, v3) = await createVersionThreeDatabase();
      await seedVersionThreeData(v3);
      await v3.close();

      await expectLater(
        FoundationDatabase.openEncrypted(
          path: path,
          key: _testKey,
          schemaVersion: 4,
          testMigrationHook: (migrator, from, to) async {
            expect(from, 3);
            expect(to, 4);
            throw StateError('injected v4 migration failure');
          },
        ),
        throwsA(
          isA<AppFailure>()
              .having(
                (failure) => failure.category,
                'category',
                AppFailureCategory.migration,
              )
              .having((failure) => failure.recoverable, 'recoverable', isTrue),
        ),
      );

      final retainedV3 = await FoundationDatabase.openEncrypted(
        path: path,
        key: _testKey,
        schemaVersion: 3,
      );
      await expectPreviousData(retainedV3);
      expect(await retainedV3.journalStatusFor(4), 'failed');
      expect(
        await retainedV3.rawScalar(
          "SELECT count(*) FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('habit_records', 'habit_day_records')",
        ),
        0,
      );
      await retainedV3.close();

      final recoveredV4 = await FoundationDatabase.openEncrypted(
        path: path,
        key: _testKey,
        schemaVersion: 4,
      );
      await expectPreviousData(recoveredV4);
      expect(await recoveredV4.journalStatusFor(4), 'recovered');
      expect(
        await recoveredV4.rawScalar(
          "SELECT count(*) FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('habit_records', 'habit_day_records')",
        ),
        2,
      );
      await recoveredV4.close();
    },
  );
}

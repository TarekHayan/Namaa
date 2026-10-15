import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';

import '../../../../support/foundation_test_support.dart';

final _testKey = List<int>.generate(32, (index) => 0x40 + index);

void main() {
  late TemporaryDatabasePath tempPath;

  setUp(() {
    tempPath = TemporaryDatabasePath();
  });

  tearDown(() => tempPath.dispose());

  Future<(String, FoundationDatabase)> createVersionTwoDatabase() async {
    final database = await FoundationDatabase.openEncrypted(
      path: tempPath.allocate(),
      key: _testKey,
      schemaVersion: 2,
    );
    final path = database.resolvedPath;

    // The generated schema always represents the newest application version.
    // Remove the v3-only tables to reproduce an installed v2 database.
    await database.rawExecute('DROP TABLE IF EXISTS task_records');
    await database.rawExecute('DROP TABLE IF EXISTS xp_awards');
    return (path, database);
  }

  Future<void> seedVersionTwoData(FoundationDatabase database) async {
    await database.rawExecute(
      '''INSERT INTO foundation_preferences ("key", value, updated_at)
      VALUES ('locale', 'ar', '2026-10-08T08:00:00.000Z')''',
    );
    await database.rawExecute('''INSERT INTO local_records
      (record_id, account_id, payload, version_timestamp, sync_state, updated_at)
      VALUES ('probe-1', 'account-1', 'probe-payload',
        '2026-10-08T08:00:00.000Z', 0, '2026-10-08T08:00:00.000Z')''');
    await database.rawExecute('''INSERT INTO pending_changes
      (operation_id, account_id, entity_type, entity_id, kind, state,
       attempt_count, serialized_change, created_at, version_timestamp)
      VALUES ('op-1', 'account-1', 'foundation_record', 'probe-1', 0, 0,
        0, '{"v":1}', '2026-10-08T08:00:00.000Z',
        '2026-10-08T08:00:00.000Z')''');
  }

  test('encrypted v2 to v3 upgrade preserves Foundation state and adds '
      'account-scoped Task and XP tables', () async {
    final (path, v2) = await createVersionTwoDatabase();
    await seedVersionTwoData(v2);
    await v2.close();

    final v3 = await FoundationDatabase.openEncrypted(
      path: path,
      key: _testKey,
    );

    expect(kFoundationSchemaVersion, 3);
    expect(
      await v3.rawScalar(
        "SELECT value FROM foundation_preferences WHERE \"key\" = 'locale'",
      ),
      'ar',
    );
    expect(
      await v3.rawScalar(
        "SELECT payload FROM local_records WHERE record_id = 'probe-1'",
      ),
      'probe-payload',
    );
    expect(
      await v3.rawScalar(
        "SELECT operation_id FROM pending_changes WHERE operation_id = 'op-1'",
      ),
      'op-1',
    );
    expect(await v3.journalStatusFor(3), 'completed');
    expect(
      await v3.rawScalar(
        '''SELECT count(*) FROM sqlite_master WHERE type = 'index'
        AND name IN (
          'task_records_account_date',
          'task_records_account_category',
          'task_records_account_quadrant',
          'task_records_account_completion',
          'task_records_account_updated',
          'task_records_account_deleted')''',
      ),
      6,
      reason: 'a v2→v3 upgrade must create every Task query index',
    );

    const encryptedSentinel = 'tasks-encrypted-v3-sentinel';
    await v3.rawExecute('''INSERT INTO task_records
        (account_id, task_id, title, scheduled_date, category, quadrant,
         checklist_json, completion_xp, created_at, updated_at)
        VALUES ('account-1', 'task-1', '$encryptedSentinel', '2026-10-08',
          'work', 'important_urgent', '[]', 15,
          '2026-10-08T08:00:00.000Z', '2026-10-08T08:00:00.000Z')''');
    await v3.rawExecute('''INSERT INTO task_records
        (account_id, task_id, title, scheduled_date, category, quadrant,
         checklist_json, completion_xp, created_at, updated_at)
        VALUES ('account-2', 'task-1', 'other account task', '2026-10-08',
          'work', 'important_urgent', '[]', 15,
          '2026-10-08T08:00:00.000Z', '2026-10-08T08:00:00.000Z')''');
    expect(
      await v3.rawScalar(
        "SELECT count(*) FROM task_records WHERE task_id = 'task-1'",
      ),
      2,
    );

    await v3.rawExecute('''INSERT INTO xp_awards
        (account_id, source, source_id, amount, awarded_at)
        VALUES ('account-1', 'task_completion', 'task-1', 15,
          '2026-10-08T09:00:00.000Z')''');
    await v3.rawExecute('''INSERT INTO xp_awards
        (account_id, source, source_id, amount, awarded_at)
        VALUES ('account-2', 'task_completion', 'task-1', 15,
          '2026-10-08T09:00:00.000Z')''');
    expect(
      await v3.rawScalar(
        "SELECT count(*) FROM xp_awards WHERE source_id = 'task-1'",
      ),
      2,
    );
    await expectLater(
      v3.rawExecute('''INSERT INTO xp_awards
          (account_id, source, source_id, amount, awarded_at)
          VALUES ('account-1', 'task_completion', 'task-1', 15,
            '2026-10-08T09:01:00.000Z')'''),
      throwsA(anything),
    );

    await v3.close();
    final bytes = await File(path).readAsBytes();
    final rawFile = latin1.decode(bytes, allowInvalid: true);
    expect(rawFile, isNot(contains(encryptedSentinel)));
  });

  test(
    'failed v3 upgrade preserves v2 data and a clean retry recovers it',
    () async {
      final (path, v2) = await createVersionTwoDatabase();
      await seedVersionTwoData(v2);
      await v2.close();

      await expectLater(
        FoundationDatabase.openEncrypted(
          path: path,
          key: _testKey,
          testMigrationHook: (migrator, from, to) async {
            throw Exception('injected v3 migration failure');
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

      final reopenedV2 = await FoundationDatabase.openEncrypted(
        path: path,
        key: _testKey,
        schemaVersion: 2,
      );
      expect(
        await reopenedV2.rawScalar(
          "SELECT value FROM foundation_preferences WHERE \"key\" = 'locale'",
        ),
        'ar',
      );
      expect(
        await reopenedV2.rawScalar(
          "SELECT payload FROM local_records WHERE record_id = 'probe-1'",
        ),
        'probe-payload',
      );
      expect(
        await reopenedV2.rawScalar(
          "SELECT operation_id FROM pending_changes WHERE operation_id = 'op-1'",
        ),
        'op-1',
      );
      expect(await reopenedV2.journalStatusFor(3), 'failed');
      expect(
        await reopenedV2.rawScalar(
          "SELECT count(*) FROM sqlite_master WHERE type = 'table' "
          "AND name = 'task_records'",
        ),
        0,
      );
      await reopenedV2.close();

      final recoveredV3 = await FoundationDatabase.openEncrypted(
        path: path,
        key: _testKey,
      );
      expect(await recoveredV3.journalStatusFor(3), 'recovered');
      expect(
        await recoveredV3.rawScalar(
          "SELECT count(*) FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('task_records', 'xp_awards')",
        ),
        2,
      );
      expect(
        await recoveredV3.rawScalar(
          "SELECT count(*) FROM pending_changes WHERE operation_id = 'op-1'",
        ),
        1,
      );
      await recoveredV3.close();
    },
  );
}

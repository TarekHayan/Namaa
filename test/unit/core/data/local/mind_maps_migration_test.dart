import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/mind_maps_test_support.dart';

final _key = List<int>.generate(32, (index) => 0x60 + index);

void main() {
  late TemporaryDatabasePath temp;
  setUp(() => temp = TemporaryDatabasePath());
  tearDown(() => temp.dispose());

  Future<(String, FoundationDatabase)> installedV4() async {
    final db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: _key,
      schemaVersion: 4,
    );
    // createAll uses the current generated schema even for an older version.
    // Remove v5 additions to reconstruct an installed v4 file.
    for (final table in [
      'mind_map_side_links',
      'mind_map_parent_slots',
      'mind_map_node_records',
      'mind_map_records',
    ]) {
      await db.rawExecute('DROP TABLE IF EXISTS $table');
    }
    await db.rawExecute(
      'ALTER TABLE task_records DROP COLUMN completion_changed_at',
    );
    return (db.resolvedPath, db);
  }

  Future<void> seed(FoundationDatabase db) async {
    await db.rawExecute('''INSERT INTO foundation_preferences
      ("key", value, updated_at) VALUES
      ('locale', 'ar', '2026-10-17T08:00:00.000Z')''');
    await db.rawExecute('''INSERT INTO local_records
      (record_id, account_id, payload, version_timestamp, sync_state, updated_at)
      VALUES ('map-migration-probe', '$kMindMapsTestAccountA',
      'foundation-private', '2026-10-17T08:00:00.000Z', 0,
      '2026-10-17T08:00:00.000Z')''');
    await db.rawExecute('''INSERT INTO task_records
      (account_id, task_id, title, scheduled_date, category, quadrant,
       checklist_json, completed_at, completion_xp, created_at, updated_at)
      VALUES ('$kMindMapsTestAccountA', '$kMindMapsTestTaskId',
      'task-private', '2026-10-17', 'work', 'important_urgent', '[]',
      '2026-10-17T09:00:00.000Z', 15, '2026-10-17T08:00:00.000Z',
      '2026-10-17T10:00:00.000Z')''');
    await db.rawExecute('''INSERT INTO task_records
      (account_id, task_id, title, scheduled_date, category, quadrant,
       checklist_json, completion_xp, created_at, updated_at)
      VALUES ('$kMindMapsTestAccountA', 'open-task-before-maps',
      'open-task-private', '2026-10-17', 'work', 'important_urgent', '[]',
      15, '2026-10-17T08:00:00.000Z', '2026-10-17T10:30:00.000Z')''');
    await db.rawExecute('''INSERT INTO habit_records
      (account_id, habit_id, name, schedule_revisions_json, created_at, updated_at)
      VALUES ('$kMindMapsTestAccountA', 'habit-before-maps', 'habit-private',
      '[]', '2026-10-17T08:00:00.000Z', '2026-10-17T08:00:00.000Z')''');
    await db.rawExecute('''INSERT INTO habit_day_records
      (account_id, habit_id, local_date, earned_while_due,
       recorded_utc_offset_minutes, updated_at)
      VALUES ('$kMindMapsTestAccountA', 'habit-before-maps', '2026-10-17',
      0, 120, '2026-10-17T08:00:00.000Z')''');
    await db.rawExecute('''INSERT INTO xp_awards
      (account_id, source, source_id, amount, awarded_at)
      VALUES ('$kMindMapsTestAccountA', 'task_completion',
      '$kMindMapsTestTaskId', 15, '2026-10-17T09:00:00.000Z')''');
    await db.rawExecute('''INSERT INTO pending_changes
      (operation_id, account_id, entity_type, entity_id, kind, state,
       attempt_count, serialized_change, created_at, version_timestamp)
      VALUES ('pending-before-maps', '$kMindMapsTestAccountA',
      'task', '$kMindMapsTestTaskId', 0, 0, 0, '{"v":4}',
      '2026-10-17T08:00:00.000Z', '2026-10-17T08:00:00.000Z')''');
  }

  Future<void> expectOldRows(FoundationDatabase db) async {
    for (final (sql, expected) in [
      (
        "SELECT value FROM foundation_preferences WHERE \"key\" = 'locale'",
        'ar',
      ),
      (
        "SELECT payload FROM local_records WHERE record_id = 'map-migration-probe'",
        'foundation-private',
      ),
      (
        "SELECT title FROM task_records WHERE task_id = '$kMindMapsTestTaskId'",
        'task-private',
      ),
      (
        "SELECT name FROM habit_records WHERE habit_id = 'habit-before-maps'",
        'habit-private',
      ),
      (
        "SELECT local_date FROM habit_day_records WHERE habit_id = 'habit-before-maps'",
        '2026-10-17',
      ),
      (
        "SELECT amount FROM xp_awards WHERE source_id = '$kMindMapsTestTaskId'",
        15,
      ),
      (
        "SELECT serialized_change FROM pending_changes WHERE operation_id = 'pending-before-maps'",
        '{"v":4}',
      ),
    ]) {
      expect(await db.rawScalar(sql), expected);
    }
  }

  test('encrypted v4 to v5 retains data, backfills Task transition and '
      'creates owner-qualified graph keys/indexes', () async {
    final (path, v4) = await installedV4();
    await seed(v4);
    await v4.close();

    final v5 = await FoundationDatabase.openEncrypted(path: path, key: _key);
    expect(v5.schemaVersion, 5);
    expect(await v5.journalStatusFor(5), 'completed');
    await expectOldRows(v5);
    expect(
      await v5.rawScalar(
        "SELECT completion_changed_at FROM task_records WHERE task_id = '$kMindMapsTestTaskId'",
      ),
      '2026-10-17T09:00:00.000Z',
    );
    expect(
      await v5.rawScalar(
        "SELECT completion_changed_at FROM task_records WHERE task_id = 'open-task-before-maps'",
      ),
      '2026-10-17T08:00:00.000Z',
    );
    expect(
      await v5.rawScalar(
        "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name IN ('mind_map_records', 'mind_map_node_records', 'mind_map_parent_slots', 'mind_map_side_links')",
      ),
      4,
    );
    expect(
      await v5.rawScalar(
        "SELECT count(*) FROM sqlite_master WHERE type = 'index' AND name LIKE 'mind_map_%'",
      ),
      greaterThanOrEqualTo(10),
    );

    const sentinel = 'encrypted-map-v5-sentinel';
    Future<void> insertMap(String account) =>
        v5.rawExecute('''INSERT INTO mind_map_records
      (account_id, map_id, title, central_node_id, settings_json, revision_id,
       created_at, updated_at) VALUES ('$account', '$kMindMapsTestMapId',
       '$sentinel', '$kMindMapsTestNodeId', '{}', 'revision-1',
       '2026-10-18T08:00:00.000Z', '2026-10-18T08:00:00.000Z')''');
    await insertMap(kMindMapsTestAccountA);
    await insertMap(kMindMapsTestAccountB);
    expect(
      await v5.rawScalar(
        "SELECT count(*) FROM mind_map_records WHERE map_id = '$kMindMapsTestMapId'",
      ),
      2,
    );
    await expectLater(insertMap(kMindMapsTestAccountA), throwsA(anything));

    Future<void> insertNode(String account) =>
        v5.rawExecute('''INSERT INTO mind_map_node_records
      (account_id, map_id, node_id, kind, title, x, y, status,
       priority, appearance_json, revision_id, created_at, updated_at)
      VALUES ('$account', '$kMindMapsTestMapId', '$kMindMapsTestNodeId',
      'central', 'Center', 0, 0, 'notStarted', 'medium', '{}', 'revision-1',
      '2026-10-18T08:00:00.000Z', '2026-10-18T08:00:00.000Z')''');
    Future<void> insertParent(String account) =>
        v5.rawExecute('''INSERT INTO mind_map_parent_slots
      (account_id, map_id, child_node_id, parent_node_id,
       appearance_json, revision_id, updated_at)
      VALUES ('$account', '$kMindMapsTestMapId', 'child-1',
      '$kMindMapsTestNodeId', '{}', 'revision-1',
      '2026-10-18T08:00:00.000Z')''');
    Future<void> insertSide(String account) =>
        v5.rawExecute('''INSERT INTO mind_map_side_links
      (account_id, map_id, first_node_id, second_node_id,
       appearance_json, revision_id, updated_at)
      VALUES ('$account', '$kMindMapsTestMapId', 'child-1',
      'other-1', '{}', 'revision-1', '2026-10-18T08:00:00.000Z')''');
    for (final insert in [insertNode, insertParent, insertSide]) {
      await insert(kMindMapsTestAccountA);
      await insert(kMindMapsTestAccountB);
      await expectLater(insert(kMindMapsTestAccountA), throwsA(anything));
    }
    for (final table in [
      'mind_map_node_records',
      'mind_map_parent_slots',
      'mind_map_side_links',
    ]) {
      expect(await v5.rawScalar('SELECT count(*) FROM $table'), 2);
    }
    await v5.close();

    final raw = latin1.decode(
      await File(path).readAsBytes(),
      allowInvalid: true,
    );
    expect(raw, isNot(contains(sentinel)));
  });

  test('failed v5 migration retains v4 rows and later retry recovers', () async {
    final (path, v4) = await installedV4();
    await seed(v4);
    await v4.close();
    await expectLater(
      FoundationDatabase.openEncrypted(
        path: path,
        key: _key,
        testMigrationHook: (migrator, from, to) async {
          expect((from, to), (4, 5));
          throw StateError('injected v5 failure');
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
    final retained = await FoundationDatabase.openEncrypted(
      path: path,
      key: _key,
      schemaVersion: 4,
    );
    await expectOldRows(retained);
    expect(await retained.journalStatusFor(5), 'failed');
    expect(
      await retained.rawScalar(
        "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = 'mind_map_records'",
      ),
      0,
    );
    await retained.close();

    final recovered = await FoundationDatabase.openEncrypted(
      path: path,
      key: _key,
    );
    await expectOldRows(recovered);
    expect(await recovered.journalStatusFor(5), 'recovered');
    expect(
      await recovered.rawScalar(
        "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = 'mind_map_records'",
      ),
      1,
    );
    await recovered.close();
  });
}

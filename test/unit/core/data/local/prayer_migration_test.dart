import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import '../../../../support/foundation_test_support.dart';

const _tables = <String>[
  'foundation_preferences',
  'local_records',
  'pending_changes',
  'conflict_records',
  'migration_journal',
  'foundation_audit_log',
  'task_records',
  'xp_awards',
  'habit_records',
  'habit_day_records',
  'mind_map_records',
  'mind_map_node_records',
  'mind_map_parent_slots',
  'mind_map_side_links',
  'prayer_device_preferences',
  'prayer_reports',
];

final _fixtures =
    (jsonDecode(
              File(
                'test/fixtures/prayer/migrations/schema_versions.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>)
        .map(
          (key, value) =>
              MapEntry(int.parse(key), value as Map<String, dynamic>),
        );

Future<FoundationDatabase> _installed(
  String path,
  List<int> key,
  int version,
) async {
  final db = await FoundationDatabase.openEncrypted(
    path: path,
    key: key,
    schemaVersion: version,
  );
  final fixture = _fixtures[version]!;
  final tables = (fixture['tables'] as List<dynamic>).cast<String>();
  // Drift createAll always uses the latest generated schema, even when this
  // connection says v1. Reconstruct and verify the installed physical shape.
  for (final table in _tables.reversed) {
    if (!tables.contains(table)) {
      await db.rawExecute('DROP TABLE IF EXISTS $table');
    }
  }
  if (fixture['taskXp'] == true) {
    await db.rawExecute(
      'ALTER TABLE task_records ADD COLUMN completion_xp INTEGER',
    );
  }
  if (version == 3 || version == 4) {
    await db.rawExecute(
      'ALTER TABLE task_records DROP COLUMN completion_changed_at',
    );
  }
  if (version == 4 || version == 5) {
    await db.rawExecute(
      'ALTER TABLE habit_day_records DROP COLUMN daily_count',
    );
  }
  if (fixture['outboxBase'] == false) {
    await db.rawExecute(
      'ALTER TABLE pending_changes DROP COLUMN base_updated_at',
    );
  }
  final actual =
      (await db
              .customSelect(
                'SELECT name FROM sqlite_master '
                "WHERE type='table' AND name NOT LIKE 'sqlite_%'",
              )
              .get())
          .map((row) => row.read<String>('name'))
          .toSet();
  expect(actual, tables.toSet(), reason: 'installed v$version table manifest');
  await db.rawExecute('''INSERT INTO foundation_preferences ("key", value,
    updated_at) VALUES ('locale', 'ar', '2026-10-29T10:00:00Z')''');
  await db.rawExecute('''INSERT INTO pending_changes (operation_id, account_id,
    entity_type, entity_id, kind, state, serialized_change, created_at,
    version_timestamp) VALUES ('old-op', 'owner', 'foundation_record', 'probe',
    0, 0, 'old-outbox', '2026-10-29T10:00:00Z', '2026-10-29T10:00:00Z')''');
  await db.rawExecute('''INSERT INTO conflict_records (conflict_id, account_id,
    entity_type, entity_id, active_source, active_timestamp, active_payload,
    retained_source, retained_timestamp, retained_payload, detected_at)
    VALUES ('old-conflict', 'owner', 'foundation_record', 'probe', 0,
    '2026-10-29T10:00:00Z', '{}', 1, '2026-10-29T10:00:00Z', '{}',
    '2026-10-29T10:00:00Z')''');
  if (version >= 3) {
    await db.rawExecute('''INSERT INTO task_records (account_id, task_id,
      title, scheduled_date, category, quadrant, created_at, updated_at)
      VALUES ('owner', 'old-task', 'legacy task', '2026-10-29', 'work',
      'important_urgent', '2026-10-29T10:00:00Z', '2026-10-29T10:00:00Z')''');
    await db.rawExecute('''INSERT INTO xp_awards (account_id, source,
      source_id, amount, awarded_at) VALUES ('owner', 'task_completion',
      'old-task', 15, '2026-10-29T10:00:00Z')''');
  }
  if (version >= 4) {
    await db.rawExecute('''INSERT INTO habit_records (account_id, habit_id,
      name, schedule_revisions_json, created_at, updated_at)
      VALUES ('owner', 'old-habit', 'legacy habit', '[]',
      '2026-10-29T10:00:00Z', '2026-10-29T10:00:00Z')''');
    await db.rawExecute('''INSERT INTO habit_day_records (account_id, habit_id,
      local_date, completed_at, earned_while_due,
      recorded_utc_offset_minutes, updated_at)
      VALUES ('owner', 'old-habit', '2026-10-29', '2026-10-29T10:00:00Z',
      1, 120, '2026-10-29T10:00:00Z')''');
  }
  if (version >= 5) {
    await db.rawExecute('''INSERT INTO mind_map_records (account_id, map_id,
      title, central_node_id, settings_json, revision_id, created_at,
      updated_at) VALUES ('owner', 'old-map', 'legacy map', 'old-node', '{}',
      'revision', '2026-10-29T10:00:00Z', '2026-10-29T10:00:00Z')''');
    await db.rawExecute('''INSERT INTO mind_map_parent_slots (account_id,
      map_id, child_node_id, parent_node_id, appearance_json, revision_id,
      updated_at) VALUES ('owner', 'old-map', 'old-child', 'old-node', '{}',
      'revision', '2026-10-29T10:00:00Z')''');
  }
  return db;
}

void main() {
  final key = List<int>.generate(32, (index) => index + 70);
  test('fresh v8 has Prayer indexes and no Task completion_xp', () async {
    final temp = TemporaryDatabasePath();
    final db = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: key,
    );
    try {
      expect(db.schemaVersion, 8);
      expect(
        await db.rawScalar(
          'SELECT count(*) FROM sqlite_master '
          "WHERE type='table' AND name LIKE 'prayer_%'",
        ),
        2,
      );
      expect(
        await db.rawScalar(
          'SELECT count(*) FROM sqlite_master '
          "WHERE type='index' AND name LIKE 'prayer_reports_owner_%'",
        ),
        3,
      );
      final columns = await db
          .customSelect('PRAGMA table_info(task_records)')
          .get();
      expect(
        columns.map((row) => row.read<String>('name')),
        isNot(contains('completion_xp')),
      );
    } finally {
      await db.close();
      temp.dispose();
    }
  });

  for (var version = 1; version <= 7; version++) {
    test(
      'physical v$version upgrades to v8, retains rows and restarts',
      () async {
        final temp = TemporaryDatabasePath();
        FoundationDatabase? db;
        try {
          final path = temp.allocate();
          db = await _installed(path, key, version);
          await db.close();
          db = await FoundationDatabase.openEncrypted(path: path, key: key);
          expect(await db.journalStatusFor(8), 'completed');
          expect(
            await db.rawScalar('SELECT value FROM foundation_preferences'),
            'ar',
          );
          expect(
            await db.rawScalar('SELECT serialized_change FROM pending_changes'),
            'old-outbox',
          );
          expect(
            await db.rawScalar('SELECT conflict_id FROM conflict_records'),
            'old-conflict',
          );
          if (version >= 3) {
            expect(
              await db.rawScalar('SELECT title FROM task_records'),
              'legacy task',
            );
            expect(await db.rawScalar('SELECT amount FROM xp_awards'), 15);
          }
          if (version >= 4) {
            expect(
              await db.rawScalar('SELECT name FROM habit_records'),
              'legacy habit',
            );
            expect(
              await db.rawScalar('SELECT daily_count FROM habit_day_records'),
              version >= 6 ? 0 : 1,
            );
          }
          if (version >= 5) {
            expect(
              await db.rawScalar('SELECT title FROM mind_map_records'),
              'legacy map',
            );
            expect(
              await db.rawScalar(
                'SELECT parent_node_id FROM mind_map_parent_slots',
              ),
              'old-node',
            );
          }
          final outbox = await db
              .customSelect('PRAGMA table_info(pending_changes)')
              .get();
          final task = await db
              .customSelect('PRAGMA table_info(task_records)')
              .get();
          expect(
            outbox.map((row) => row.read<String>('name')),
            contains('base_updated_at'),
          );
          expect(
            task.map((row) => row.read<String>('name')),
            isNot(contains('completion_xp')),
          );
          expect(
            await db.rawScalar(
              'SELECT count(*) FROM sqlite_master '
              "WHERE type='table' AND name LIKE 'prayer_%'",
            ),
            2,
          );
          await db.close();
          db = await FoundationDatabase.openEncrypted(path: path, key: key);
          expect(
            await db.rawScalar('SELECT value FROM foundation_preferences'),
            'ar',
          );
        } finally {
          await db?.close();
          temp.dispose();
        }
      },
    );
  }

  test('failed v8 upgrade rolls back and later records recovery', () async {
    final temp = TemporaryDatabasePath();
    FoundationDatabase? db;
    try {
      final path = temp.allocate();
      db = await _installed(path, key, 7);
      await db.close();
      await expectLater(
        FoundationDatabase.openEncrypted(
          path: path,
          key: key,
          testMigrationHook: (migrator, from, to) async {
            if (to == 8) throw StateError('injected failure');
          },
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.category,
            'category',
            AppFailureCategory.migration,
          ),
        ),
      );
      db = await FoundationDatabase.openEncrypted(
        path: path,
        key: key,
        schemaVersion: 7,
      );
      expect(
        await db.rawScalar('SELECT title FROM task_records'),
        'legacy task',
      );
      expect(
        await db.rawScalar(
          'SELECT count(*) FROM sqlite_master '
          "WHERE type='table' AND name='prayer_reports'",
        ),
        0,
      );
      await db.close();
      db = await FoundationDatabase.openEncrypted(path: path, key: key);
      expect(await db.journalStatusFor(8), 'recovered');
      expect(
        await db.rawScalar(
          'SELECT count(*) FROM migration_journal '
          "WHERE version=8 AND status='recovered'",
        ),
        greaterThanOrEqualTo(1),
      );
      expect(
        await db.rawScalar(
          'SELECT count(*) FROM migration_journal '
          "WHERE version=8 AND status='completed'",
        ),
        greaterThanOrEqualTo(1),
      );
    } finally {
      await db?.close();
      temp.dispose();
    }
  });
}

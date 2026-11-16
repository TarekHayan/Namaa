import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import '../../../../support/foundation_test_support.dart';

/// T015 + T086: every historical local schema (v1…v10) upgrades to v11 with
/// all existing rows preserved (v10→v11 keeps the Adhkar and Qiyam rows); a
/// fresh v11 is created correctly; an injected migration failure leaves the
/// prior database readable and recoverable.
void main() {
  final key = List<int>.generate(32, (index) => index + 80);

  const v10Tables = <String>[
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
    'adhkar_item_counts',
    'qiyam_nights',
  ];

  const v11Tables = <String>[
    ...v10Tables,
    'my_adhkar_items',
    'my_adhkar_counts',
  ];

  const v8Tables = <String>[
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

  final fixtures =
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

  Future<void> seedLegacy(FoundationDatabase db, int version) async {
    await db.rawExecute('''INSERT INTO foundation_preferences ("key", value,
      updated_at) VALUES ('locale', 'ar', '2026-10-29T10:00:00Z')''');
    await db.rawExecute('''INSERT INTO pending_changes (operation_id,
      account_id, entity_type, entity_id, kind, state, serialized_change,
      created_at, version_timestamp) VALUES ('old-op', 'owner',
      'foundation_record', 'probe', 0, 0, 'old-outbox',
      '2026-10-29T10:00:00Z', '2026-10-29T10:00:00Z')''');
    await db.rawExecute('''INSERT INTO conflict_records (conflict_id,
      account_id, entity_type, entity_id, active_source, active_timestamp,
      active_payload, retained_source, retained_timestamp, retained_payload,
      detected_at) VALUES ('old-conflict', 'owner', 'foundation_record',
      'probe', 0, '2026-10-29T10:00:00Z', '{}', 1, '2026-10-29T10:00:00Z',
      '{}', '2026-10-29T10:00:00Z')''');
    if (version >= 3) {
      await db.rawExecute('''INSERT INTO task_records (account_id, task_id,
        title, scheduled_date, category, quadrant, created_at, updated_at)
        VALUES ('owner', 'old-task', 'legacy task', '2026-10-29', 'work',
        'important_urgent', '2026-10-29T10:00:00Z',
        '2026-10-29T10:00:00Z')''');
      await db.rawExecute('''INSERT INTO xp_awards (account_id, source,
        source_id, amount, awarded_at) VALUES ('owner', 'task_completion',
        'old-task', 15, '2026-10-29T10:00:00Z')''');
    }
    if (version >= 4) {
      await db.rawExecute('''INSERT INTO habit_records (account_id, habit_id,
        name, schedule_revisions_json, created_at, updated_at)
        VALUES ('owner', 'old-habit', 'legacy habit', '[]',
        '2026-10-29T10:00:00Z', '2026-10-29T10:00:00Z')''');
      await db.rawExecute('''INSERT INTO habit_day_records (account_id,
        habit_id, local_date, completed_at, earned_while_due,
        recorded_utc_offset_minutes, updated_at) VALUES ('owner',
        'old-habit', '2026-10-29', '2026-10-29T10:00:00Z', 1, 120,
        '2026-10-29T10:00:00Z')''');
    }
    if (version >= 5) {
      await db.rawExecute('''INSERT INTO mind_map_records (account_id,
        map_id, title, central_node_id, settings_json, revision_id,
        created_at, updated_at) VALUES ('owner', 'old-map', 'legacy map',
        'old-node', '{}', 'revision', '2026-10-29T10:00:00Z',
        '2026-10-29T10:00:00Z')''');
    }
    if (version >= 8) {
      await db.rawExecute('''INSERT INTO prayer_reports (account_id,
        local_date, prayer_name, report_id, status, recorded_zone_id,
        recorded_offset_minutes, created_at, updated_at)
        VALUES ('owner', '2026-10-31', 'fajr', 'old-report', 'pending',
        'Africa/Cairo', 120, '2026-10-31T00:00:00Z',
        '2026-10-31T00:00:00Z')''');
    }
  }

  /// Reconstructs the physical installed shape for [version] on a fresh file
  /// (Drift createAll always emits the latest schema, so out-of-version
  /// tables are dropped), seeds legacy rows and returns the open database.
  Future<FoundationDatabase> installed(
    String path,
    List<int> key,
    int version,
  ) async {
    final db = await FoundationDatabase.openEncrypted(
      path: path,
      key: key,
      schemaVersion: version,
    );
    final List<String> keep;
    if (version <= 7) {
      keep = (fixtures[version]!['tables'] as List<dynamic>).cast<String>();
    } else if (version == 8) {
      keep = v8Tables;
    } else {
      // v9 and v10 also carry the customStatement annual-timetable table.
      keep = [...v10Tables, 'prayer_annual_timetables'];
    }
    for (final table in v11Tables.reversed) {
      if (!keep.contains(table)) {
        await db.rawExecute('DROP TABLE IF EXISTS $table');
      }
    }
    // prayer_annual_timetables (v9+) is a customStatement table, not a Drift
    // table in the generated schema; drop it for pre-v9 shapes.
    if (version < 9) {
      await db.rawExecute('DROP TABLE IF EXISTS prayer_annual_timetables');
    }
    // Reconstruct the physical column shapes the later migration steps add.
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
    if (version <= 7) {
      final fixture = fixtures[version]!;
      if (fixture['outboxBase'] == false) {
        await db.rawExecute(
          'ALTER TABLE pending_changes DROP COLUMN base_updated_at',
        );
      }
      if (fixture['taskXp'] == true) {
        await db.rawExecute(
          'ALTER TABLE task_records ADD COLUMN completion_xp INTEGER',
        );
      }
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
    expect(actual, keep.toSet(), reason: 'installed v$version table manifest');
    await seedLegacy(db, version);
    return db;
  }

  Future<void> expectLegacyRowsSurvive(FoundationDatabase db) async {
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
    expect(await db.rawScalar('SELECT title FROM task_records'), 'legacy task');
    expect(await db.rawScalar('SELECT amount FROM xp_awards'), 15);
    expect(
      await db.rawScalar('SELECT name FROM habit_records'),
      'legacy habit',
    );
    expect(
      await db.rawScalar('SELECT report_id FROM prayer_reports'),
      'old-report',
    );
    expect(
      await db.rawScalar('SELECT title FROM mind_map_records'),
      'legacy map',
    );
  }

  test('installed v9 upgrades to v11, keeps every row and restarts', () async {
    final temp = TemporaryDatabasePath();
    FoundationDatabase? db;
    try {
      final path = temp.allocate();
      db = await installed(path, key, 9);
      await db.close();
      db = await FoundationDatabase.openEncrypted(path: path, key: key);
      expect(db.schemaVersion, 11);
      expect(await db.journalStatusFor(11), 'completed');
      await expectLegacyRowsSurvive(db);
      expect(
        await db.rawScalar(
          "SELECT count(*) FROM sqlite_master WHERE type='table' "
          "AND name IN ('adhkar_item_counts','qiyam_nights',"
          "'my_adhkar_items','my_adhkar_counts')",
        ),
        4,
      );
      // Restart after the upgrade works.
      await db.close();
      db = await FoundationDatabase.openEncrypted(path: path, key: key);
      await expectLegacyRowsSurvive(db);
    } finally {
      await db?.close();
      temp.dispose();
    }
  });

  test(
    'installed v10 upgrades to v11 and keeps its Adhkar and Qiyam rows',
    () async {
      final temp = TemporaryDatabasePath();
      FoundationDatabase? db;
      try {
        final path = temp.allocate();
        db = await installed(path, key, 10);
        // Seed real v10 rows before the upgrade.
        await db.rawExecute(
          'INSERT INTO adhkar_item_counts (account_id, adhkar_day, item_id, '
          'record_id, catalog_version, list, count, created_at, updated_at) '
          "VALUES ('owner', '2026-11-15', 'm1', 'rec-m1', 1, 'morning', 1, "
          "'2026-11-15T08:00:00Z', '2026-11-15T08:00:00Z')",
        );
        await db.rawExecute(
          'INSERT INTO qiyam_nights (account_id, night_date, record_id, '
          'performed, rakahs, witr, recorded_zone_id, '
          'recorded_offset_minutes, created_at, updated_at) '
          "VALUES ('owner', '2026-11-15', 'rec-night', 1, 8, 1, "
          "'Africa/Cairo', 120, '2026-11-15T20:00:00Z', "
          "'2026-11-15T20:00:00Z')",
        );
        await db.close();
        db = await FoundationDatabase.openEncrypted(path: path, key: key);
        expect(db.schemaVersion, 11);
        expect(await db.journalStatusFor(11), 'completed');
        expect(await db.rawScalar('SELECT count FROM adhkar_item_counts'), 1);
        expect(await db.rawScalar('SELECT performed FROM qiyam_nights'), 1);
        expect(
          await db.rawScalar(
            "SELECT count(*) FROM sqlite_master WHERE type='table' "
            "AND name IN ('my_adhkar_items','my_adhkar_counts')",
          ),
          2,
        );
        // Restart after the upgrade works and the rows survive again.
        await db.close();
        db = await FoundationDatabase.openEncrypted(path: path, key: key);
        expect(await db.rawScalar('SELECT count FROM adhkar_item_counts'), 1);
        expect(await db.rawScalar('SELECT performed FROM qiyam_nights'), 1);
      } finally {
        await db?.close();
        temp.dispose();
      }
    },
  );

  test('installed v8 upgrades to v11 and keeps its Prayer report', () async {
    final temp = TemporaryDatabasePath();
    FoundationDatabase? db;
    try {
      final path = temp.allocate();
      db = await installed(path, key, 8);
      await db.close();
      db = await FoundationDatabase.openEncrypted(path: path, key: key);
      expect(db.schemaVersion, 11);
      expect(
        await db.rawScalar('SELECT report_id FROM prayer_reports'),
        'old-report',
      );
      expect(
        await db.rawScalar(
          "SELECT count(*) FROM sqlite_master WHERE type='table' "
          "AND name IN ('adhkar_item_counts','qiyam_nights',"
          "'my_adhkar_items','my_adhkar_counts')",
        ),
        4,
      );
    } finally {
      await db?.close();
      temp.dispose();
    }
  });

  for (var version = 1; version <= 7; version++) {
    test(
      'physical v$version upgrades to v11, retains rows and restarts',
      () async {
        final temp = TemporaryDatabasePath();
        FoundationDatabase? db;
        try {
          final path = temp.allocate();
          db = await installed(path, key, version);
          await db.close();
          db = await FoundationDatabase.openEncrypted(path: path, key: key);
          expect(db.schemaVersion, 11);
          expect(await db.journalStatusFor(11), 'completed');
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
          }
          if (version >= 5) {
            expect(
              await db.rawScalar('SELECT title FROM mind_map_records'),
              'legacy map',
            );
          }
          // Restart after the upgrade works.
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

  test(
    'fresh v11 creates the four tables with their columns and indexes',
    () async {
      final temp = TemporaryDatabasePath();
      final db = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: key,
      );
      try {
        expect(db.schemaVersion, 11);
        final adhkarColumns = await db
            .customSelect('PRAGMA table_info(adhkar_item_counts)')
            .get();
        expect(
          adhkarColumns.map((row) => row.read<String>('name')),
          containsAll([
            'account_id',
            'adhkar_day',
            'item_id',
            'record_id',
            'catalog_version',
            'list',
            'count',
            'created_at',
            'updated_at',
            'last_acknowledged_updated_at',
          ]),
        );
        final nightColumns = await db
            .customSelect('PRAGMA table_info(qiyam_nights)')
            .get();
        expect(
          nightColumns.map((row) => row.read<String>('name')),
          containsAll([
            'account_id',
            'night_date',
            'record_id',
            'performed',
            'rakahs',
            'witr',
            'start_time',
            'end_time',
            'note',
            'recorded_zone_id',
            'recorded_offset_minutes',
            'created_at',
            'updated_at',
            'last_acknowledged_updated_at',
          ]),
        );
        // rakahs/note/start_time/end_time are nullable; performed/witr are not.
        bool nullable(String table, String column) {
          final row = (table == 'qiyam_nights' ? nightColumns : adhkarColumns)
              .firstWhere((row) => row.read<String>('name') == column);
          return row.read<int>('notnull') == 0;
        }

        expect(nullable('qiyam_nights', 'rakahs'), isTrue);
        expect(nullable('qiyam_nights', 'note'), isTrue);
        expect(nullable('qiyam_nights', 'start_time'), isTrue);
        expect(nullable('qiyam_nights', 'end_time'), isTrue);
        expect(nullable('qiyam_nights', 'performed'), isFalse);
        expect(nullable('adhkar_item_counts', 'count'), isFalse);
        expect(
          await db.rawScalar(
            "SELECT count(*) FROM sqlite_master WHERE type='index' "
            "AND name IN ('adhkar_item_counts_owner_day_list',"
            "'adhkar_item_counts_owner_version',"
            "'adhkar_item_counts_owner_record',"
            "'qiyam_nights_owner_night','qiyam_nights_owner_version',"
            "'qiyam_nights_owner_record')",
          ),
          6,
        );
        // The v11 My Adhkar tables and their indexes.
        final itemColumns = await db
            .customSelect('PRAGMA table_info(my_adhkar_items)')
            .get();
        expect(
          itemColumns.map((row) => row.read<String>('name')),
          containsAll([
            'account_id',
            'item_id',
            'text',
            'target',
            'note',
            'created_at',
            'updated_at',
            'last_acknowledged_updated_at',
            'deleted_at',
          ]),
        );
        final countColumns = await db
            .customSelect('PRAGMA table_info(my_adhkar_counts)')
            .get();
        expect(
          countColumns.map((row) => row.read<String>('name')),
          containsAll([
            'account_id',
            'item_id',
            'adhkar_day',
            'record_id',
            'count',
            'created_at',
            'updated_at',
            'last_acknowledged_updated_at',
          ]),
        );
        bool myNullable(String table, String column) =>
            (table == 'my_adhkar_items' ? itemColumns : countColumns)
                .firstWhere((row) => row.read<String>('name') == column)
                .read<int>('notnull') ==
            0;
        expect(myNullable('my_adhkar_items', 'note'), isTrue);
        expect(myNullable('my_adhkar_items', 'deleted_at'), isTrue);
        expect(
          myNullable('my_adhkar_items', 'last_acknowledged_updated_at'),
          isTrue,
        );
        expect(myNullable('my_adhkar_items', 'text'), isFalse);
        expect(myNullable('my_adhkar_items', 'target'), isFalse);
        expect(myNullable('my_adhkar_counts', 'count'), isFalse);
        expect(myNullable('my_adhkar_counts', 'record_id'), isFalse);
        expect(
          await db.rawScalar(
            "SELECT count(*) FROM sqlite_master WHERE type='index' "
            "AND name IN ('my_adhkar_items_owner_tab',"
            "'my_adhkar_items_owner_version',"
            "'my_adhkar_counts_owner_day',"
            "'my_adhkar_counts_owner_version',"
            "'my_adhkar_counts_owner_record')",
          ),
          5,
        );
      } finally {
        await db.close();
        temp.dispose();
      }
    },
  );

  test(
    'the migration hook fires once per upgrade step with the step version',
    () async {
      final temp = TemporaryDatabasePath();
      FoundationDatabase? db;
      try {
        final path = temp.allocate();
        db = await installed(path, key, 7);
        await db.close();
        final seen = <String>[];
        db = await FoundationDatabase.openEncrypted(
          path: path,
          key: key,
          testMigrationHook: (migrator, from, to, step) async {
            seen.add('$from>$to@$step');
          },
        );
        expect(db.schemaVersion, 11);
        // A v7 -> v11 upgrade runs steps 8, 9, 10 and 11, each firing once.
        expect(seen, ['7>11@8', '7>11@9', '7>11@10', '7>11@11']);
      } finally {
        await db?.close();
        temp.dispose();
      }
    },
  );

  test(
    'an injected v11 failure leaves the v10 database readable and the '
    'journal records the failed attempt, then a clean reopen recovers',
    () async {
      final temp = TemporaryDatabasePath();
      FoundationDatabase? db;
      try {
        final path = temp.allocate();
        db = await installed(path, key, 10);
        await db.rawExecute(
          'INSERT INTO adhkar_item_counts (account_id, adhkar_day, item_id, '
          'record_id, catalog_version, list, count, created_at, updated_at) '
          "VALUES ('owner', '2026-11-15', 'm1', 'rec-m1', 1, 'morning', 1, "
          "'2026-11-15T08:00:00Z', '2026-11-15T08:00:00Z')",
        );
        await db.close();
        await expectLater(
          FoundationDatabase.openEncrypted(
            path: path,
            key: key,
            testMigrationHook: (migrator, from, to, step) async {
              if (to >= 11 && from < 11) {
                throw Exception('injected migration failure');
              }
            },
          ),
          throwsA(
            isA<AppFailure>()
                .having(
                  (f) => f.category,
                  'category',
                  AppFailureCategory.migration,
                )
                .having((f) => f.recoverable, 'recoverable', isTrue),
          ),
        );
        // The v10 data is still readable when the upgrade is not requested.
        final reopened = await FoundationDatabase.openEncrypted(
          path: path,
          key: key,
          schemaVersion: 10,
        );
        expect(
          await reopened.rawScalar('SELECT report_id FROM prayer_reports'),
          'old-report',
        );
        expect(
          await reopened.rawScalar('SELECT count FROM adhkar_item_counts'),
          1,
        );
        expect(
          await reopened.rawScalar(
            'SELECT version FROM migration_journal '
            "WHERE status = 'failed' ORDER BY started_at DESC LIMIT 1",
          ),
          11,
        );
        await reopened.close();
        // A subsequent clean upgrade marks the failed attempt recovered.
        db = await FoundationDatabase.openEncrypted(path: path, key: key);
        expect(db.schemaVersion, 11);
        expect(await db.journalStatusFor(11), 'recovered');
        expect(
          await db.rawScalar('SELECT report_id FROM prayer_reports'),
          'old-report',
        );
        expect(await db.rawScalar('SELECT count FROM adhkar_item_counts'), 1);
        expect(
          await db.rawScalar(
            "SELECT count(*) FROM sqlite_master WHERE type='table' "
            "AND name IN ('my_adhkar_items','my_adhkar_counts')",
          ),
          2,
        );
      } finally {
        await db?.close();
        temp.dispose();
      }
    },
  );
}

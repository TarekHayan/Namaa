import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';

import '../../../../support/foundation_test_support.dart';

void main() {
  test(
    'v5 upgrade preserves habit days and backfills completed counts',
    () async {
      final path = TemporaryDatabasePath();
      final key = List<int>.generate(32, (index) => index + 80);
      FoundationDatabase? database;
      try {
        database = await FoundationDatabase.openEncrypted(
          path: path.allocate(),
          key: key,
          schemaVersion: 5,
        );
        // Older installations have no counter column. createAll uses the
        // current generated schema even when a test opens at version five.
        await database.rawExecute(
          'ALTER TABLE habit_day_records DROP COLUMN daily_count',
        );
        await database.rawExecute('''
        INSERT INTO habit_day_records
          (account_id, habit_id, local_date, completed_at,
           earned_while_due, earned_against_revision_id,
           recorded_utc_offset_minutes, updated_at)
        VALUES
          ('owner', 'habit', '2026-10-24', '2026-10-24T09:00:00.000Z',
           1, 'revision', 120, '2026-10-24T09:00:00.000Z'),
          ('owner', 'habit', '2026-10-25', NULL,
           0, NULL, 120, '2026-10-25T09:00:00.000Z')
      ''');
        final file = database.resolvedPath;
        await database.close();
        database = await FoundationDatabase.openEncrypted(path: file, key: key);

        expect(database.schemaVersion, 6);
        expect(await database.journalStatusFor(6), 'completed');
        expect(
          await database.rawScalar('''
          SELECT daily_count FROM habit_day_records
          WHERE local_date = '2026-10-24'
        '''),
          1,
        );
        expect(
          await database.rawScalar('''
          SELECT daily_count FROM habit_day_records
          WHERE local_date = '2026-10-25'
        '''),
          0,
        );
      } finally {
        await database?.close();
        path.dispose();
      }
    },
  );
}

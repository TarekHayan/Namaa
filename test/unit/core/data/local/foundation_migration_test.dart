import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import '../../../../support/foundation_test_support.dart';

final _testKey = List<int>.generate(32, (i) => 0x30 + i);

void main() {
  late TemporaryDatabasePath tempPath;

  setUp(() {
    tempPath = TemporaryDatabasePath();
  });
  tearDown(() => tempPath.dispose());

  test(
    'a successful upgrade preserves prior data and completes the journal',
    () async {
      // Create the database at v1 and store data.
      final v1 = await FoundationDatabase.openEncrypted(
        path: tempPath.allocate(),
        key: _testKey,
        schemaVersion: 1,
      );
      await v1.rawExecute(
        '''INSERT INTO foundation_preferences ("key", value, updated_at)
      VALUES ('locale', 'ar', '2026-09-06T00:00:00.000Z')''',
      );
      final path = v1.resolvedPath;
      await v1.close();

      // Upgrade to v2 (adds the foundation_audit_log table).
      final v2 = await FoundationDatabase.openEncrypted(
        path: path,
        key: _testKey,
      );
      // Prior data survived the upgrade.
      expect(
        await v2.rawScalar('SELECT value FROM foundation_preferences'),
        'ar',
      );
      // The migration journal recorded a completed entry for version 2.
      expect(await v2.journalStatusFor(2), 'completed');
      await v2.close();
    },
  );

  test(
    'an injected migration failure retains prior data and records the failure',
    () async {
      final v1 = await FoundationDatabase.openEncrypted(
        path: tempPath.allocate(),
        key: _testKey,
        schemaVersion: 1,
      );
      await v1.rawExecute(
        '''INSERT INTO foundation_preferences ("key", value, updated_at)
      VALUES ('locale', 'en', '2026-09-06T00:00:00.000Z')''',
      );
      final path = v1.resolvedPath;
      await v1.close();

      // Injected failure: the v1 -> v2 step throws.
      await expectLater(
        FoundationDatabase.openEncrypted(
          path: path,
          key: _testKey,
          testMigrationHook: (migrator, from, to) async {
            throw Exception('injected migration failure');
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

      // Prior state is intact: reopen at v1 and read the stored row.
      final reopened = await FoundationDatabase.openEncrypted(
        path: path,
        key: _testKey,
        schemaVersion: 1,
      );
      expect(
        await reopened.rawScalar('SELECT value FROM foundation_preferences'),
        'en',
      );
      // The failure was recorded in the journal as a visible, non-secret
      // outcome (failed for the attempted version).
      final failedVersion = await reopened.rawScalar(
        'SELECT version FROM migration_journal '
        "WHERE status = 'failed' ORDER BY started_at DESC LIMIT 1",
      );
      expect(failedVersion, 2);
      await reopened.close();

      // A subsequent clean upgrade marks the failed attempt recovered.
      final v2 = await FoundationDatabase.openEncrypted(
        path: path,
        key: _testKey,
      );
      expect(await v2.journalStatusFor(2), 'recovered');
      await v2.close();
    },
  );
}

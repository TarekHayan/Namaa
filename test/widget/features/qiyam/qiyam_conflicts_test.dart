import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/features/qiyam/data/drift_qiyam_repository.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_conflicts_view.dart';

import '../../../support/foundation_test_support.dart';

/// T065: the read-only Qiyam "Sync differences" view — both versions of
/// every retained night conflict, with no resolve action, and no
/// foreign-owner data ever leaves the owner-scoped store. The word
/// "missed" never appears.
void main() {
  late FoundationDatabase db;
  late DriftQiyamRepository repository;
  late TemporaryDatabasePath temp;

  setUp(() {
    temp = TemporaryDatabasePath();
  });

  Future<void> openStore(WidgetTester tester) async {
    await tester.runAsync(() async {
      db = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: List<int>.generate(32, (i) => i + 130),
      );
      repository = DriftQiyamRepository(db);
    });
  }

  Future<void> seed(
    WidgetTester tester, {
    required String owner,
    required String conflictId,
    required String night,
    required bool activePerformed,
    required bool retainedPerformed,
  }) async {
    await tester.runAsync(() async {
      String payload(bool performed) =>
          '{"night_date":"$night","record_id":"rec-$night","performed":$performed,'
          '"rakahs":${performed ? 4 : null},"witr":$performed,'
          '"start_time":${performed ? '"22:10"' : null},'
          '"end_time":${performed ? '"02:40"' : null},'
          '"note":${performed ? '"n"' : null},'
          '"recorded_zone_id":"UTC","recorded_offset_minutes":0,'
          '"created_at":"2026-11-11T19:00:00.000Z",'
          '"updated_at":"2026-11-11T20:00:00.000Z"}';
      await db
          .into(db.conflictRecords)
          .insert(
            ConflictRecordsCompanion.insert(
              conflictId: conflictId,
              accountId: owner,
              entityType: 'qiyam_night',
              entityId: 'rec-$night',
              activeSource: VersionSource.remote,
              activeTimestamp: DateTime.utc(2026, 11, 11, 21),
              activePayload: payload(activePerformed),
              retainedSource: VersionSource.remote,
              retainedTimestamp: DateTime.utc(2026, 11, 11, 20),
              retainedPayload: payload(retainedPerformed),
              detectedAt: DateTime.utc(2026, 11, 11, 21, 10),
            ),
          );
    });
  }

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(
          body: QiyamConflictsView(
            conflicts: repository.watchConflicts('owner'),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  Future<void> closeStore(WidgetTester tester) async {
    await tester.runAsync(() async {
      await db.close();
      temp.dispose();
    });
  }

  testWidgets('shows both versions of a night conflict, read-only', (
    tester,
  ) async {
    await openStore(tester);
    await seed(
      tester,
      owner: 'owner',
      conflictId: 'q-1',
      night: '2026-11-11',
      activePerformed: true,
      retainedPerformed: false,
    );
    await pumpView(tester);
    expect(find.text('Sync differences'), findsOneWidget);
    expect(find.textContaining('2026-11-11'), findsOneWidget);
    expect(find.text("Prayed · 4 rak'ahs"), findsOneWidget);
    expect(find.text('Did not pray'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Retained'), findsOneWidget);
    expect(find.text('Read-only; nothing to resolve.'), findsOneWidget);
    expect(find.textContaining('missed'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextButton ||
            widget is ElevatedButton ||
            widget is IconButton ||
            widget is FilledButton,
      ),
      findsNothing,
      reason: 'no resolve action exists',
    );
    await closeStore(tester);
  });

  testWidgets('a foreign-owner conflict never leaves the store', (
    tester,
  ) async {
    await openStore(tester);
    await seed(
      tester,
      owner: 'owner',
      conflictId: 'q-owner',
      night: '2026-11-11',
      activePerformed: true,
      retainedPerformed: false,
    );
    await seed(
      tester,
      owner: 'foreign-owner',
      conflictId: 'q-foreign',
      night: '2026-11-10',
      activePerformed: true,
      retainedPerformed: true,
    );
    await pumpView(tester);
    expect(find.textContaining('2026-11-10'), findsNothing);
    expect(find.textContaining('2026-11-11'), findsOneWidget);
    await closeStore(tester);
  });
}

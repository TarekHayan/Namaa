import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/data/drift_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_conflicts_view.dart';

import '../../../support/foundation_test_support.dart';

/// T065: the read-only Adhkar "Sync differences" view — both versions of
/// every retained conflict, with no resolve action, and no foreign-owner
/// data ever leaves the owner-scoped store.
void main() {
  late FoundationDatabase db;
  late DriftAdhkarRepository repository;
  late TemporaryDatabasePath temp;

  setUp(() {
    temp = TemporaryDatabasePath();
  });

  // The encrypted store runs in a background isolate; every store access
  // from a widget test needs the real event loop (FakeAsync cannot receive
  // the isolate's replies).
  Future<void> openStore(WidgetTester tester) async {
    await tester.runAsync(() async {
      db = await FoundationDatabase.openEncrypted(
        path: temp.allocate(),
        key: List<int>.generate(32, (i) => i + 110),
      );
      repository = DriftAdhkarRepository(db);
    });
  }

  Future<void> seed(
    WidgetTester tester, {
    required String owner,
    required String conflictId,
    required String day,
    required String itemId,
    required int activeCount,
    required int retainedCount,
  }) async {
    await tester.runAsync(() async {
      String payload(int count) =>
          '{"adhkar_day":"$day","item_id":"$itemId","catalog_version":1,'
          '"list":"${itemId.startsWith('m') ? 'morning' : 'evening'}",'
          '"count":$count,"updated_at":"2026-11-10T08:00:00.000Z"}';
      await db
          .into(db.conflictRecords)
          .insert(
            ConflictRecordsCompanion.insert(
              conflictId: conflictId,
              accountId: owner,
              entityType: 'adhkar_item',
              entityId: 'record-$itemId',
              activeSource: VersionSource.remote,
              activeTimestamp: DateTime.utc(2026, 11, 10, 9),
              activePayload: payload(activeCount),
              retainedSource: VersionSource.remote,
              retainedTimestamp: DateTime.utc(2026, 11, 10, 8),
              retainedPayload: payload(retainedCount),
              detectedAt: DateTime.utc(2026, 11, 10, 9, 5),
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
          body: AdhkarConflictsView(
            conflicts: repository.watchConflicts('owner'),
            catalog: _FixtureCatalog(),
            ownerId: 'owner',
            locale: 'en',
          ),
        ),
      ),
    );
    // The drift watch delivers its first rows through the background
    // isolate; wait on the real event loop, then settle.
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

  testWidgets('shows both versions of a conflict, read-only', (tester) async {
    await openStore(tester);
    await seed(
      tester,
      owner: 'owner',
      conflictId: 'c-1',
      day: '2026-11-10',
      itemId: 'm1',
      activeCount: 2,
      retainedCount: 1,
    );
    await pumpView(tester);
    expect(find.text('Sync differences'), findsOneWidget);
    expect(find.text('Morning adhkar \u00b7 item 1'), findsOneWidget);
    expect(
      find.text('m1'),
      findsNothing,
      reason: 'internal item ids never reach the UI',
    );
    expect(
      find.text('2026-11-10'),
      findsNothing,
      reason: 'raw ISO dates never reach the UI',
    );
    expect(
      find.textContaining('Nov'),
      findsOneWidget,
      reason: 'the day is formatted with the app locale',
    );
    expect(find.text('Count: 2'), findsOneWidget, reason: 'active version');
    expect(find.text('Count: 1'), findsOneWidget, reason: 'retained version');
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Retained'), findsOneWidget);
    expect(find.text('Read-only; nothing to resolve.'), findsOneWidget);
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
      conflictId: 'c-owner',
      day: '2026-11-10',
      itemId: 'm1',
      activeCount: 2,
      retainedCount: 1,
    );
    await seed(
      tester,
      owner: 'foreign-owner',
      conflictId: 'c-foreign',
      day: '2026-11-11',
      itemId: 'm2',
      activeCount: 5,
      retainedCount: 3,
    );
    await pumpView(tester);
    expect(find.textContaining('m2'), findsNothing);
    expect(find.text('Count: 5'), findsNothing);
    expect(find.text('Morning adhkar \u00b7 item 1'), findsOneWidget);
    await closeStore(tester);
  });

  testWidgets('an unknown item falls back to the list name alone', (
    tester,
  ) async {
    await openStore(tester);
    await seed(
      tester,
      owner: 'owner',
      conflictId: 'c-unknown',
      day: '2026-11-10',
      itemId: 'm9',
      activeCount: 2,
      retainedCount: 1,
    );
    await pumpView(tester);
    expect(
      find.text('Morning adhkar'),
      findsOneWidget,
      reason: 'no position for an item the catalog does not know',
    );
    expect(find.textContaining('m9'), findsNothing);
    await closeStore(tester);
  });

  testWidgets('an empty store renders nothing', (tester) async {
    await openStore(tester);
    await pumpView(tester);
    expect(find.text('Sync differences'), findsNothing);
    await closeStore(tester);
  });
}

/// The catalog port the view uses for positions: the reviewed fixture item
/// only (IDs and targets, never text).
final class _FixtureCatalog implements AdhkarCatalogPort {
  @override
  Future<AppResult<AdhkarCatalog>> snapshot(String ownerId) async {
    return AppResult.success(
      AdhkarCatalog.fromJson(const {
        'catalog_version': 1,
        'attribution': 'test attribution line',
        'items': [
          {
            'item_id': 'm1',
            'list': 'morning',
            'position': 1,
            'target': 1,
            'kind': 'dhikr',
            'text_ar': 'fixture',
            'virtue_ar': 'fixture',
            'reference_ar': 'fixture',
            'approved': true,
          },
        ],
        'qiyam_supplications': <Map<String, Object>>[],
      }),
    );
  }
}

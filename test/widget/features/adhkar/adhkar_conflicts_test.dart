import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/data/drift_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/drift_my_adhkar_repository.dart';
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

  Future<void> pumpView(
    WidgetTester tester, {
    AdhkarCatalogPort? catalog,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: Scaffold(
          body: AdhkarConflictsView(
            conflicts: repository.watchConflicts('owner'),
            catalog: catalog ?? _FixtureCatalog(),
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

  testWidgets('the day shows once when the catalog is not loaded', (
    tester,
  ) async {
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
    await pumpView(tester, catalog: _FailingCatalog());
    expect(
      find.textContaining('Nov'),
      findsOneWidget,
      reason: 'the title falls back to the day; it is not repeated below',
    );
    expect(find.text('Count: 2'), findsOneWidget);
    await closeStore(tester);
  });

  group('My Adhkar conflicts (T098)', () {
    late DriftMyAdhkarRepository myRepository;

    Future<void> seedMine(
      WidgetTester tester, {
      required String owner,
      required String conflictId,
      required String entityType,
      required Map<String, Object?> active,
      required Map<String, Object?> retained,
    }) async {
      await tester.runAsync(() async {
        await db
            .into(db.conflictRecords)
            .insert(
              ConflictRecordsCompanion.insert(
                conflictId: conflictId,
                accountId: owner,
                entityType: entityType,
                entityId: 'entity-$conflictId',
                activeSource: VersionSource.remote,
                activeTimestamp: DateTime.utc(2026, 11, 16, 10),
                activePayload: jsonEncode(active),
                retainedSource: VersionSource.remote,
                retainedTimestamp: DateTime.utc(2026, 11, 16, 9),
                retainedPayload: jsonEncode(retained),
                detectedAt: DateTime.utc(2026, 11, 16, 10, 5),
              ),
            );
      });
    }

    Map<String, Object?> entryVersion(
      String text, {
      String? source,
      String updatedAt = '2026-11-16T10:00:00.000Z',
      String? deletedAt,
    }) => {
      'item_id': 'entity',
      'text': text,
      'source': source,
      'group_ids': ['g1'],
      'created_at': '2026-11-16T08:00:00.000Z',
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };

    Map<String, Object?> groupVersion(String name, {String? deletedAt}) => {
      'group_id': 'entity',
      'name': name,
      'created_at': '2026-11-16T08:00:00.000Z',
      'updated_at': '2026-11-16T10:00:00.000Z',
      'deleted_at': deletedAt,
    };

    Future<void> pumpMine(WidgetTester tester) async {
      myRepository = DriftMyAdhkarRepository(db);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdhkarConflictsView(
                conflicts: repository.watchConflicts('owner'),
                myAdhkarConflicts: myRepository.watchConflicts('owner'),
                catalog: _FixtureCatalog(),
                ownerId: 'owner',
                locale: 'en',
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump();
    }

    testWidgets('a group and an entry conflict show both versions, with '
        'long text shortened and no resolve action', (tester) async {
      await openStore(tester);
      await seedMine(
        tester,
        owner: 'owner',
        conflictId: 'c-group',
        entityType: 'my_adhkar_group',
        active: groupVersion('group active name'),
        retained: groupVersion('group retained name'),
      );
      final longText = 'long entry text ${'word ' * 60}end';
      await seedMine(
        tester,
        owner: 'owner',
        conflictId: 'c-item',
        entityType: 'my_adhkar_item',
        active: entryVersion(longText, source: 'active source'),
        retained: entryVersion('retained entry text'),
      );
      await pumpMine(tester);
      expect(find.text('Sync differences'), findsOneWidget);
      expect(find.text('My Adhkar · group'), findsOneWidget);
      expect(find.text('My Adhkar · entry'), findsOneWidget);
      expect(find.text('group active name'), findsOneWidget);
      expect(find.text('group retained name'), findsOneWidget);
      expect(find.text('retained entry text'), findsOneWidget);
      expect(find.text('active source'), findsOneWidget);
      expect(find.text('Active'), findsNWidgets(2));
      expect(find.text('Retained'), findsNWidgets(2));
      expect(
        find.text(longText),
        findsNothing,
        reason: 'the full long text is shortened',
      );
      expect(find.textContaining('long entry text word'), findsOneWidget);
      expect(find.textContaining('…'), findsOneWidget);
      expect(find.text('Read-only; nothing to resolve.'), findsNWidgets(2));
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
      expect(tester.takeException(), isNull);
      await closeStore(tester);
    });

    testWidgets('a deleted version reads as Deleted, and a foreign-owner '
        'conflict never appears', (tester) async {
      await openStore(tester);
      await seedMine(
        tester,
        owner: 'owner',
        conflictId: 'c-item',
        entityType: 'my_adhkar_item',
        active: entryVersion(
          'deleted version text',
          deletedAt: '2026-11-16T10:00:00.000Z',
        ),
        retained: entryVersion('edited entry text'),
      );
      await seedMine(
        tester,
        owner: 'foreign-owner',
        conflictId: 'c-foreign',
        entityType: 'my_adhkar_group',
        active: groupVersion('foreign group name'),
        retained: groupVersion('foreign group retained'),
      );
      await pumpMine(tester);
      expect(find.text('Deleted'), findsOneWidget);
      expect(find.text('deleted version text'), findsNothing);
      expect(find.text('edited entry text'), findsOneWidget);
      expect(find.textContaining('foreign'), findsNothing);
      expect(find.text('My Adhkar · group'), findsNothing);
      await closeStore(tester);
    });

    testWidgets('the Adhkar and My Adhkar conflicts share one heading', (
      tester,
    ) async {
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
      await seedMine(
        tester,
        owner: 'owner',
        conflictId: 'c-group',
        entityType: 'my_adhkar_group',
        active: groupVersion('group active name'),
        retained: groupVersion('group retained name'),
      );
      await pumpMine(tester);
      expect(find.text('Sync differences'), findsOneWidget);
      expect(find.text('Morning adhkar · item 1'), findsOneWidget);
      expect(find.text('My Adhkar · group'), findsOneWidget);
      await closeStore(tester);
    });

    testWidgets('only My Adhkar conflicts still show the heading', (
      tester,
    ) async {
      await openStore(tester);
      await seedMine(
        tester,
        owner: 'owner',
        conflictId: 'c-group',
        entityType: 'my_adhkar_group',
        active: groupVersion('group active name'),
        retained: groupVersion('group retained name'),
      );
      await pumpMine(tester);
      expect(find.text('Sync differences'), findsOneWidget);
      await closeStore(tester);
    });
  });
}

final class _FailingCatalog implements AdhkarCatalogPort {
  @override
  Future<AppResult<AdhkarCatalog>> snapshot(String ownerId) async =>
      AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'adhkar.catalog.unavailable',
          occurredAt: DateTime.utc(2026, 11, 10),
        ),
      );
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

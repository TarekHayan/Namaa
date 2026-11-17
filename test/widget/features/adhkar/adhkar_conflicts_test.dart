import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/data/drift_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/drift_my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_conflict_evidence.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_conflicts_view.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_state.dart';
import 'package:namma_project/features/adhkar/presentation/widgets/adhkar_style.dart';

import '../../../support/adhkar_screen_harness.dart';
import '../../../support/adhkar_test_support.dart';
import '../../../support/foundation_test_support.dart';

/// T065 and T106: the read-only "Sync differences" row and page inside
/// `/adhkar` (contracts/adhkar-qiyam-ui.md, "Conflicts"): both versions of
/// every retained conflict, stacked on a phone and side by side on a wide
/// window, with their times and values, a dhikr's text cut to three lines,
/// "Deleted", the footer, no resolve action, no foreign-owner data, and the
/// device back that returns to the Adhkar page.
void main() {
  late FoundationDatabase db;
  late DriftAdhkarRepository repository;
  late DriftMyAdhkarRepository myRepository;
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
      myRepository = DriftMyAdhkarRepository(db);
    });
  }

  Future<void> closeStore(WidgetTester tester) async {
    await tester.runAsync(() async {
      await db.close();
      temp.dispose();
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

  Map<String, Object?> groupVersion(
    String name, {
    String? deletedAt,
    String updatedAt = '2026-11-16T10:00:00.000Z',
  }) => {
    'group_id': 'entity',
    'name': name,
    'created_at': '2026-11-16T08:00:00.000Z',
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };

  AdhkarConflictsSource source({
    AdhkarCatalogPort? catalog,
    String locale = 'en',
    DateTime? now,
    bool mine = true,
  }) => AdhkarConflictsSource(
    conflicts: repository.watchConflicts('owner'),
    myAdhkarConflicts: mine ? myRepository.watchConflicts('owner') : null,
    catalog: catalog ?? FakeCatalog(),
    ownerId: 'owner',
    locale: locale,
    now: () => now ?? DateTime(2026, 12),
  );

  Future<void> deliver(WidgetTester tester) async {
    // The drift watch delivers its first rows through the background
    // isolate; wait on the real event loop, then settle.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
  }

  Future<void> pumpPage(
    WidgetTester tester,
    AdhkarConflictsSource conflicts, {
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
    Size size = const Size(400, 1400),
    double textScale = 1.0,
    VoidCallback? onBack,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        locale: locale,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        theme: ThemeData(brightness: brightness, useMaterial3: true),
        home: AdhkarConflictsPage(source: conflicts, onBack: onBack ?? () {}),
      ),
    );
    await deliver(tester);
  }

  Finder key(String value) => find.byKey(Key(value));

  Finder noResolveAction() => find.byWidgetPredicate(
    (widget) =>
        widget is TextButton ||
        widget is ElevatedButton ||
        widget is IconButton ||
        widget is FilledButton ||
        widget is OutlinedButton,
  );

  group('count conflicts', () {
    testWidgets('both versions with their time and value, the footer, and '
        'no resolve action', (tester) async {
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
      await pumpPage(tester, source());
      expect(find.text('Sync differences'), findsOneWidget);
      expect(find.text('Morning adhkar · Dhikr 1'), findsOneWidget);
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
      expect(find.text('Active version'), findsOneWidget);
      expect(find.text('Saved version'), findsOneWidget);
      expect(find.text('Count: 2'), findsOneWidget);
      expect(find.text('Count: 1'), findsOneWidget);
      expect(
        find.textContaining('Nov 10, 2026'),
        findsNWidgets(2),
        reason: 'each version shows when it was saved, with the app locale',
      );
      expect(
        find.text('View only; there is no action to take.'),
        findsOneWidget,
      );
      expect(find.text('Back to Adhkar'), findsOneWidget);
      expect(noResolveAction(), findsNothing, reason: 'no resolve action');
      expect(tester.takeException(), isNull);
      await closeStore(tester);
    });

    testWidgets('the back control calls back', (tester) async {
      await openStore(tester);
      var backed = 0;
      await pumpPage(tester, source(), onBack: () => backed++);
      await tester.tap(key('adhkar_sync_back'));
      expect(backed, 1);
      await closeStore(tester);
    });

    testWidgets('today and yesterday read as words; older times show the '
        'date', (tester) async {
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
      final activeLocal = DateTime.utc(2026, 11, 10, 9).toLocal();
      await pumpPage(tester, source(now: activeLocal));
      expect(find.textContaining('Today'), findsNWidgets(2));
      await pumpPage(
        tester,
        source(now: activeLocal.add(const Duration(days: 1))),
      );
      expect(find.textContaining('Yesterday'), findsNWidgets(2));
      await pumpPage(
        tester,
        source(now: activeLocal),
        locale: const Locale('ar'),
      );
      expect(find.textContaining('اليوم'), findsNWidgets(2));
      await closeStore(tester);
    });

    testWidgets('stacked on a phone, side by side on a wide window', (
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
      await pumpPage(tester, source());
      var active = tester.getTopLeft(find.text('Active version'));
      var saved = tester.getTopLeft(find.text('Saved version'));
      expect(saved.dy, greaterThan(active.dy));
      expect(saved.dx, closeTo(active.dx, 2), reason: 'stacked, same column');

      await pumpPage(tester, source(), size: const Size(1200, 900));
      active = tester.getTopLeft(find.text('Active version'));
      saved = tester.getTopLeft(find.text('Saved version'));
      expect(saved.dy, closeTo(active.dy, 2), reason: 'side by side');
      expect(saved.dx, isNot(active.dx));
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
      await pumpPage(tester, source());
      expect(find.textContaining('m2'), findsNothing);
      expect(find.text('Count: 5'), findsNothing);
      expect(find.text('Morning adhkar · Dhikr 1'), findsOneWidget);
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
      await pumpPage(tester, source());
      expect(
        find.text('Morning adhkar'),
        findsOneWidget,
        reason: 'no position for an item the catalog does not know',
      );
      expect(find.textContaining('m9'), findsNothing);
      await closeStore(tester);
    });

    testWidgets('the title falls back to the day when the catalog is not '
        'loaded', (tester) async {
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
      await pumpPage(tester, source(catalog: FailingCatalog()));
      expect(find.text('Tue, Nov 10'), findsOneWidget);
      expect(find.text('Count: 2'), findsOneWidget);
      await closeStore(tester);
    });

    testWidgets('Arabic names the list and the dhikr from the catalog', (
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
      await pumpPage(tester, source(locale: 'ar'), locale: const Locale('ar'));
      expect(find.text('أذكار الصباح · الذكر 1'), findsOneWidget);
      expect(find.text('النسخة النشطة'), findsOneWidget);
      expect(find.text('النسخة المحفوظة'), findsOneWidget);
      expect(find.text('للعرض فقط؛ لا يوجد إجراء.'), findsOneWidget);
      await closeStore(tester);
    });
  });

  group('My Adhkar conflicts (T098)', () {
    testWidgets('a group and an entry conflict show both versions, the '
        'entry text cut to three lines, and no resolve action', (tester) async {
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
      await pumpPage(tester, source());
      expect(find.text('Sync differences'), findsOneWidget);
      expect(find.text('My adhkar · Group'), findsOneWidget);
      expect(find.text('My adhkar · Dhikr'), findsOneWidget);
      expect(find.text('group active name'), findsOneWidget);
      expect(find.text('group retained name'), findsOneWidget);
      expect(find.text('retained entry text'), findsOneWidget);
      expect(find.text('Active version'), findsNWidgets(2));
      expect(find.text('Saved version'), findsNWidgets(2));
      final cut = tester.widget<Text>(find.textContaining('long entry text'));
      expect(cut.maxLines, 3, reason: 'the dhikr text is cut to three lines');
      expect(cut.overflow, TextOverflow.ellipsis);
      expect(cut.style?.fontFamily, kDhikrFontFamily);
      expect(
        find.text('active source'),
        findsNothing,
        reason: 'the page shows the text only',
      );
      expect(
        find.text('View only; there is no action to take.'),
        findsOneWidget,
      );
      expect(noResolveAction(), findsNothing, reason: 'no resolve action');
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
      await pumpPage(tester, source());
      expect(find.text('Deleted'), findsOneWidget);
      expect(key('adhkar_sync_deleted'), findsOneWidget);
      expect(find.text('deleted version text'), findsNothing);
      expect(find.text('edited entry text'), findsOneWidget);
      expect(find.textContaining('foreign'), findsNothing);
      expect(find.text('My adhkar · Group'), findsNothing);
      await closeStore(tester);
    });

    testWidgets('a deleted group reads «محذوف» in Arabic', (tester) async {
      await openStore(tester);
      await seedMine(
        tester,
        owner: 'owner',
        conflictId: 'c-group',
        entityType: 'my_adhkar_group',
        active: groupVersion('اسم المجموعة'),
        retained: groupVersion(
          'اسم قديم',
          deletedAt: '2026-11-16T09:00:00.000Z',
        ),
      );
      await pumpPage(tester, source(locale: 'ar'), locale: const Locale('ar'));
      expect(find.text('محذوف'), findsOneWidget);
      expect(find.text('أذكاري · مجموعة'), findsOneWidget);
      expect(find.text('اسم المجموعة'), findsOneWidget);
      await closeStore(tester);
    });

    testWidgets('the Adhkar and My Adhkar conflicts share one page', (
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
      await pumpPage(tester, source());
      expect(find.text('Sync differences'), findsOneWidget);
      expect(find.text('Morning adhkar · Dhikr 1'), findsOneWidget);
      expect(find.text('My adhkar · Group'), findsOneWidget);
      await closeStore(tester);
    });
  });

  group('the row', () {
    testWidgets('shows nothing without conflicts, and opens the page when '
        'there are some', (tester) async {
      await openStore(tester);
      var opened = 0;
      Future<void> pumpRow() async {
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            locale: const Locale('en'),
            supportedLocales: FoundationLocalizations.supportedLocales,
            localizationsDelegates:
                FoundationLocalizations.localizationsDelegates,
            home: Scaffold(
              body: AdhkarConflictsRow(
                source: source(),
                onOpen: () => opened++,
              ),
            ),
          ),
        );
        await deliver(tester);
      }

      await pumpRow();
      expect(key('adhkar_sync_row'), findsNothing);
      await seed(
        tester,
        owner: 'owner',
        conflictId: 'c-1',
        day: '2026-11-10',
        itemId: 'm1',
        activeCount: 2,
        retainedCount: 1,
      );
      await pumpRow();
      expect(key('adhkar_sync_row'), findsOneWidget);
      expect(find.text('Sync differences'), findsOneWidget);
      await tester.tap(key('adhkar_sync_row'));
      expect(opened, 1);
      await closeStore(tester);
    });
  });

  group('inside the Adhkar screen', () {
    // The screen wiring is tested over plain streams (the encrypted store's
    // own delivery is covered by the page tests above).
    final evidence = AdhkarConflictEvidence(
      id: 'c-1',
      adhkarDay: '2026-11-10',
      itemId: 'm1',
      list: 'morning',
      activeCount: 2,
      retainedCount: 1,
      activeAt: DateTime.utc(2026, 11, 10, 9),
      retainedAt: DateTime.utc(2026, 11, 10, 8),
    );

    AdhkarConflictsSource streamSource(
      Stream<List<AdhkarConflictEvidence>> stream,
    ) => AdhkarConflictsSource(
      conflicts: stream,
      catalog: FakeCatalog(),
      ownerId: 'owner',
      locale: 'en',
      now: () => DateTime(2026, 12),
    );

    adhkarTestWidgets('the row opens the page above the Adhkar page, and '
        'device back returns to it, then Home', (tester) async {
      final harness = AdhkarHarness();
      await harness.pump(
        tester,
        conflicts: streamSource(Stream.value([evidence]).asBroadcastStream()),
        useRouter: true,
      );
      await tester.pump();
      expect(key('adhkar_sync_row'), findsOneWidget);
      await tester.tap(key('adhkar_sync_row'));
      await tester.pumpAndSettle();
      expect(key('adhkar_sync_page'), findsOneWidget);
      expect(key('adhkar_main_button'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(key('adhkar_sync_page'), findsNothing);
      expect(
        key('adhkar_main_button'),
        findsOneWidget,
        reason: 'back on the Adhkar page, same tab',
      );
      expect(find.text('home page'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('home page'), findsOneWidget);
    });

    adhkarTestWidgets('the back control returns to the same tab; the row is '
        'absent without conflicts', (tester) async {
      var harness = AdhkarHarness();
      await harness.pump(
        tester,
        conflicts: streamSource(Stream.value(const <AdhkarConflictEvidence>[])),
      );
      await tester.pump();
      expect(key('adhkar_sync_row'), findsNothing);

      harness = AdhkarHarness();
      await harness.pump(
        tester,
        conflicts: streamSource(Stream.value([evidence]).asBroadcastStream()),
      );
      await tester.pump();
      await tester.tap(key('adhkar_switch_evening'));
      await tester.pump();
      await tester.tap(key('adhkar_sync_row'));
      await tester.pumpAndSettle();
      expect(key('adhkar_sync_page'), findsOneWidget);
      await tester.tap(key('adhkar_sync_back'));
      await tester.pumpAndSettle();
      expect(key('adhkar_sync_page'), findsNothing);
      expect(harness.cubit.state.selectedTab, AdhkarTab.evening);
    });
  });

  group('layout matrix', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      for (final brightness in Brightness.values) {
        testWidgets('${locale.languageCode} ${brightness.name}: every kind of '
            'entry at 320 px and 200% text, and wide, without overflow', (
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
            active: groupVersion('اسم مجموعة طويل جدا يلتف على أكثر من سطر'),
            retained: groupVersion('x', deletedAt: '2026-11-16T09:00:00.000Z'),
          );
          await seedMine(
            tester,
            owner: 'owner',
            conflictId: 'c-item',
            entityType: 'my_adhkar_item',
            active: entryVersion('نص طويل ${'يتكرر ' * 80} with Latin words'),
            retained: entryVersion('x', deletedAt: '2026-11-16T09:00:00.000Z'),
          );
          for (final size in const [Size(320, 4000), Size(1200, 800)]) {
            await pumpPage(
              tester,
              source(locale: locale.languageCode),
              locale: locale,
              brightness: brightness,
              size: size,
              textScale: size.width < 400 ? 2.0 : 1.0,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${locale.languageCode} ${brightness.name} $size',
            );
          }
          await closeStore(tester);
        });
      }
    }
  });
}

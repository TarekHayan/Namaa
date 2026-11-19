import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_theme.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/domain/values/version_source.dart';
import 'package:namma_project/features/qiyam/data/drift_qiyam_repository.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_conflicts_view.dart';

import '../../../support/foundation_test_support.dart';

/// T065/T107: the read-only Qiyam "Sync differences" row and page (approved
/// design, 2026-11-18) — both versions of every retained night conflict
/// with the answer, times and note, stacked on a phone and side by side when
/// wide, no resolve action, and no foreign-owner data ever leaves the
/// owner-scoped store. The word "missed" never appears.
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
    bool activeWitr = true,
    String? activeNote,
  }) async {
    await tester.runAsync(() async {
      String payload(bool performed, {required bool witr, String? note}) =>
          '{"night_date":"$night","record_id":"rec-$night","performed":$performed,'
          '"rakahs":${performed ? 4 : null},"witr":${performed && witr},'
          '"start_time":${performed ? '"22:10"' : null},'
          '"end_time":${performed ? '"02:40"' : null},'
          '"note":${performed && note != null ? '"$note"' : null},'
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
              activePayload: payload(
                activePerformed,
                witr: activeWitr,
                note: activeNote,
              ),
              retainedSource: VersionSource.remote,
              retainedTimestamp: DateTime.utc(2026, 11, 11, 20),
              retainedPayload: payload(retainedPerformed, witr: false),
              detectedAt: DateTime.utc(2026, 11, 11, 21, 10),
            ),
          );
    });
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
    Size size = const Size(390, 1400),
    double textScale = 1,
    String? currentNight = '2026-11-11',
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
        locale: locale,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: QiyamConflictsPage(
          conflicts: repository.watchConflicts('owner'),
          currentNight: currentNight,
          onBack: onBack ?? () {},
          now: () => DateTime.utc(2026, 11, 11, 22),
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

  Future<void> seedTonight(WidgetTester tester, {String? note}) => seed(
    tester,
    owner: 'owner',
    conflictId: 'q-1',
    night: '2026-11-11',
    activePerformed: true,
    retainedPerformed: false,
    activeNote: note,
  );

  testWidgets("shows both versions of tonight's conflict with the answer, "
      'times and note, read-only', (tester) async {
    await openStore(tester);
    await seed(
      tester,
      owner: 'owner',
      conflictId: 'q-1',
      night: '2026-11-11',
      activePerformed: true,
      retainedPerformed: false,
      activeNote: 'a quiet night',
    );
    var backs = 0;
    await pumpPage(tester, onBack: () => backs++);
    expect(find.text('Sync differences'), findsOneWidget);
    expect(find.text('Qiyam · Tonight'), findsOneWidget);
    expect(
      find.text('2026-11-11'),
      findsNothing,
      reason: 'raw ISO dates never reach the UI',
    );
    expect(find.text('Yes · 4 rak’ahs · with Witr'), findsOneWidget);
    expect(find.text('Not yet'), findsOneWidget);
    expect(find.text('22:10 – 02:40'), findsOneWidget);
    expect(find.text('a quiet night'), findsOneWidget);
    expect(find.text('Active version'), findsOneWidget);
    expect(find.text('Saved version'), findsOneWidget);
    expect(find.text('View only; there is no action to take.'), findsOneWidget);
    expect(find.textContaining('issed'), findsNothing);
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
    await tester.tap(find.byKey(const Key('qiyam_sync_back')));
    expect(backs, 1);
    await closeStore(tester);
  });

  testWidgets('another night is titled with its date in the app locale', (
    tester,
  ) async {
    await openStore(tester);
    await seed(
      tester,
      owner: 'owner',
      conflictId: 'q-old',
      night: '2026-11-09',
      activePerformed: true,
      retainedPerformed: true,
    );
    await pumpPage(tester);
    expect(find.textContaining('Nov 9'), findsOneWidget);
    expect(find.text('Qiyam · Tonight'), findsNothing);
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
    await pumpPage(tester);
    expect(find.textContaining('Nov 10'), findsNothing);
    expect(find.text('Qiyam · Tonight'), findsOneWidget);
    await closeStore(tester);
  });

  testWidgets('versions stack on a phone', (tester) async {
    await openStore(tester);
    await seedTonight(tester);
    await pumpPage(tester);
    final active = tester.getTopLeft(find.text('Active version')).dy;
    final saved = tester.getTopLeft(find.text('Saved version')).dy;
    expect(saved, greaterThan(active));
    await closeStore(tester);
  });

  testWidgets('versions sit side by side when wide', (tester) async {
    await openStore(tester);
    await seedTonight(tester);
    await pumpPage(tester, size: const Size(1100, 900));
    expect(
      tester.getTopLeft(find.text('Saved version')).dy,
      closeTo(tester.getTopLeft(find.text('Active version')).dy, 2),
    );
    await closeStore(tester);
  });

  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final brightness in Brightness.values) {
      testWidgets('renders at 320 px and 200% without overflow - $locale '
          '$brightness', (tester) async {
        await openStore(tester);
        await seedTonight(tester, note: 'a quiet night');
        await pumpPage(
          tester,
          locale: locale,
          brightness: brightness,
          size: const Size(320, 900),
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        await closeStore(tester);
      });
    }
  }

  testWidgets('the Arabic page uses the approved copy', (tester) async {
    await openStore(tester);
    await seedTonight(tester);
    await pumpPage(tester, locale: const Locale('ar'));
    expect(find.text('اختلافات المزامنة'), findsOneWidget);
    expect(find.text('قيام الليل · الليلة'), findsOneWidget);
    expect(find.text('النسخة النشطة'), findsOneWidget);
    expect(find.text('النسخة المحفوظة'), findsOneWidget);
    expect(find.text('للعرض فقط؛ لا يوجد إجراء.'), findsOneWidget);
    expect(find.text('العودة إلى القيام'), findsOneWidget);
    await closeStore(tester);
  });

  Future<void> pumpRow(WidgetTester tester, VoidCallback onOpen) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: Scaffold(
          body: QiyamConflictsRow(
            conflicts: repository.watchConflicts('owner'),
            onOpen: onOpen,
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  testWidgets('the row stays hidden while there is no conflict', (
    tester,
  ) async {
    await openStore(tester);
    await pumpRow(tester, () {});
    expect(find.byKey(const Key('qiyam_sync_row')), findsNothing);
    await closeStore(tester);
  });

  testWidgets('the row shows with a conflict and opens the page', (
    tester,
  ) async {
    await openStore(tester);
    await seedTonight(tester);
    var opened = 0;
    await pumpRow(tester, () => opened++);
    expect(find.byKey(const Key('qiyam_sync_row')), findsOneWidget);
    expect(find.text('Sync differences'), findsOneWidget);
    await tester.tap(find.byKey(const Key('qiyam_sync_row')));
    expect(opened, 1);
    await closeStore(tester);
  });
}

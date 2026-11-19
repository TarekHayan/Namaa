import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/composition/prayer_adhkar_times_adapter.dart';
import 'package:namma_project/app/composition/prayer_qiyam_night_adapter.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_theme.dart';
import 'package:namma_project/core/data/local/adhkar_unit_of_work.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    hide XpAward;
import 'package:namma_project/core/data/local/qiyam_unit_of_work.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_clock_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_commands.dart';
import 'package:namma_project/features/adhkar/data/drift_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/data/uuid_adhkar_identity.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart'
    show AdhkarList;
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_cubit.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_screen.dart';
import 'package:namma_project/features/adhkar/presentation/adhkar_state.dart';
import 'package:namma_project/features/prayer/application/prayer_clock_port.dart';
import 'package:namma_project/features/prayer/application/prayer_day_boundaries.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';
import 'package:namma_project/features/qiyam/application/qiyam_clock_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_supplications_port.dart';
import 'package:namma_project/features/qiyam/application/save_qiyam_night.dart';
import 'package:namma_project/features/qiyam/data/drift_qiyam_repository.dart';
import 'package:namma_project/features/qiyam/data/uuid_qiyam_identity.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night_record.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_supplication.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_cubit.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_screen.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../test/support/adhkar_test_support.dart' show FakeCatalog;
import '../test/support/foundation_test_support.dart';

/// T050 (Qiyam) and T036 (Adhkar): the flows on one real encrypted store with
/// a fake clock and a fixed Prayer schedule (no network, no Supabase).
///
/// The fake clock opens at 03:00 on Thursday 2026-11-12: that belongs to
/// Wednesday's night (night D starts at Maghrib on D), so the record is saved
/// under 2026-11-11 and stays editable at 10:00. A Yes -> No -> Yes sequence
/// leaves exactly one record and one `qiyam_done` award. After the next
/// Maghrib the new night is unanswered and Wednesday's is read-only: a late
/// save for it writes nothing. A restart (the store closed and reopened)
/// restores the saved answer with its details and still only one award.
///
/// The Adhkar journey (T036) crosses Fajr and Maghrib on the same fixed
/// schedule: at 03:00 the running Adhkar day is Wednesday's (its Evening
/// period), so Morning is locked; after Fajr the new day opens Morning, which
/// is counted to completion (one award); a restart restores every count; after
/// Maghrib Evening opens and Morning locks again; Evening completes with its
/// own single award; the next Fajr opens a fresh day, and a command captured
/// for the old day writes nothing. The lists use the placeholder fixture
/// catalog (no real religious text).
///
/// Run locally on Windows:
/// `flutter test integration_test/adhkar_qiyam_flow_test.dart -d windows`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const owner = 'qiyam-flow-owner';
  final key = List<int>.generate(32, (i) => i + 77);

  // The fixed schedule in UTC (the location's zone is UTC), around the
  // Wednesday night.
  final fajr = {
    '2026-11-11': DateTime.utc(2026, 11, 11, 4, 30),
    '2026-11-12': DateTime.utc(2026, 11, 12, 4, 29),
    '2026-11-13': DateTime.utc(2026, 11, 13, 4, 28),
    '2026-11-14': DateTime.utc(2026, 11, 14, 4, 27),
  };
  final maghrib = {
    '2026-11-11': DateTime.utc(2026, 11, 11, 16, 50),
    '2026-11-12': DateTime.utc(2026, 11, 12, 16, 49),
    '2026-11-13': DateTime.utc(2026, 11, 13, 16, 49),
  };

  testWidgets('Qiyam: the night follows Maghrib, one award, restart '
      'persistence', (tester) async {
    final temp = TemporaryDatabasePath();
    final path = temp.allocate();
    final clock = _FlowClock(DateTime.utc(2026, 11, 12, 3));
    final boundaries = _FixedBoundaries({
      for (final day in maghrib.keys)
        PrayerLocalDate.parse(day): PrayerDayBoundariesAvailable(
          date: PrayerLocalDate.parse(day),
          fajrUtc: fajr[day]!,
          maghribUtc: maghrib[day]!,
          nextFajrUtc: fajr[_nextDay(day)]!,
          zoneId: 'UTC',
        ),
    });
    final preferences = _FixedPreferences(owner);

    FoundationDatabase? db;
    QiyamCubit? cubit;
    late DriftQiyamRepository repository;
    late SaveQiyamNight command;

    Future<void> openApp() async {
      db = await FoundationDatabase.openEncrypted(path: path, key: key);
      repository = DriftQiyamRepository(db!);
      final nights = PrayerQiyamNightAdapter(
        boundaries: boundaries,
        preferences: preferences,
        clock: clock,
      );
      command = SaveQiyamNight(
        ownerId: owner,
        nightPort: nights,
        repository: repository,
        commits: DriftQiyamUnitOfWork(
          database: db!,
          repository: repository,
          awards: DriftAwardLedger(db!),
        ),
        clock: clock,
        identity: const UuidQiyamIdentity(),
      );
      cubit = QiyamCubit(
        ownerId: owner,
        nightPort: nights,
        repository: repository,
        supplications: const _NoSupplications(),
        commands: command,
        clock: clock,
      );
      await cubit!.load();
    }

    Future<void> closeApp() async {
      await cubit?.close();
      cubit = null;
      await db?.close();
      db = null;
    }

    addTearDown(() async {
      await closeApp();
      temp.dispose();
    });

    Future<int> awards() async =>
        (await db!.rawScalar(
              "SELECT count(*) FROM xp_awards WHERE source = 'qiyam_done'",
            ))!
            as int;
    Future<int> records() async =>
        (await db!.rawScalar('SELECT count(*) FROM qiyam_nights'))! as int;
    Future<QiyamNightRecord?> stored(String night) async =>
        (await repository.readFresh(
          accountId: owner,
          nightDate: night,
        )).valueOrNull;
    // Lets the cubit's own streams deliver what the store just wrote.
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 150));

    // 1. 03:00 Thursday is still Wednesday's night, and editable.
    await openApp();
    expect(cubit!.state.night?.nightDate, '2026-11-11');
    expect(cubit!.state.night?.editable, isTrue);
    expect(cubit!.state.form, isNull, reason: 'nothing answered yet');
    await cubit!.answerYes();
    await settle();
    final first = await stored('2026-11-11');
    expect(first, isNotNull, reason: 'the record is on Wednesday night');
    expect(first!.performed, isTrue);
    expect(first.rakahs, 4);
    expect(first.witr, isTrue);
    expect(await stored('2026-11-12'), isNull);
    expect(await awards(), 1);
    expect(cubit!.state.celebration, isTrue, reason: 'the first Yes');

    // 2. 10:00 Thursday: still Wednesday's night and still editable.
    clock.now = DateTime.utc(2026, 11, 12, 10);
    await cubit!.resume();
    await settle();
    expect(cubit!.state.night?.nightDate, '2026-11-11');
    expect(cubit!.state.night?.editable, isTrue);
    await cubit!.selectRakahs(8);
    await settle();
    expect((await stored('2026-11-11'))!.rakahs, 8);
    expect(await records(), 1);

    // 3. Yes -> No -> Yes: one record, one award, never revoked.
    await cubit!.answerNo();
    await settle();
    expect((await stored('2026-11-11'))!.performed, isFalse);
    expect(await awards(), 1, reason: 'No does not revoke the award');
    await cubit!.answerYes();
    await settle();
    final again = await stored('2026-11-11');
    expect(again!.performed, isTrue);
    expect(again.rakahs, 4, reason: 'the Yes defaults come back');
    expect(await records(), 1);
    expect(await awards(), 1, reason: 'Yes after No awards nothing new');

    // 4. Restart: the store is closed and reopened; the saved answer and its
    // details come back, and there is still one award.
    await closeApp();
    await openApp();
    expect(cubit!.state.night?.nightDate, '2026-11-11');
    expect(cubit!.state.form?.performed, isTrue);
    expect(cubit!.state.form?.rakahs, 4);
    expect(cubit!.state.celebration, isFalse, reason: 'no badge on reopening');
    expect(await records(), 1);
    expect(await awards(), 1);

    // 5. After Maghrib the new night is unanswered, and Wednesday's night is
    // read-only: a late save for it writes nothing.
    clock.now = DateTime.utc(2026, 11, 12, 17);
    await cubit!.resume();
    await settle();
    expect(cubit!.state.night?.nightDate, '2026-11-12');
    expect(cubit!.state.form, isNull, reason: 'the new night is unanswered');
    final lateSave = await command.execute(
      capturedNight: '2026-11-11',
      draft: const QiyamNightDraft(performed: false),
    );
    expect(lateSave.valueOrNull, isA<QiyamNightChanged>());
    expect((await stored('2026-11-11'))!.performed, isTrue);
    expect(await records(), 1);
    // The history shows Wednesday's night, read-only.
    expect(
      cubit!.state.history.map((entry) => entry.nightDate),
      contains('2026-11-11'),
    );

    // 6. A Yes on the new night is a second night with its own award.
    await cubit!.answerYes();
    await settle();
    expect(await records(), 2);
    expect(await awards(), 2, reason: 'one award per night');

    // The screen shows the saved state after a restart, with no badge.
    await closeApp();
    await openApp();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: AppTheme.light,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: BlocProvider.value(value: cubit!, child: const QiyamScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('qiyam_answer_switch')), findsOneWidget);
    expect(find.byKey(const Key('qiyam_celebration')), findsNothing);
    expect(find.byKey(const Key('qiyam_rakah_chip_4')), findsOneWidget);
    expect(find.text('Details (optional)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Adhkar: a Morning journey across Fajr and Maghrib, restart '
      'persistence, one award per set', (tester) async {
    const adhkarOwner = 'adhkar-flow-owner';
    final temp = TemporaryDatabasePath();
    final path = temp.allocate();
    final clock = _FlowClock(DateTime.utc(2026, 11, 12, 3));
    final boundaries = _FixedBoundaries({
      for (final day in maghrib.keys)
        PrayerLocalDate.parse(day): PrayerDayBoundariesAvailable(
          date: PrayerLocalDate.parse(day),
          fajrUtc: fajr[day]!,
          maghribUtc: maghrib[day]!,
          nextFajrUtc: fajr[_nextDay(day)]!,
          zoneId: 'UTC',
        ),
    });
    final preferences = _FixedPreferences(adhkarOwner);
    final catalog = FakeCatalog();

    FoundationDatabase? db;
    AdhkarCubit? cubit;
    late AdhkarCommands commands;

    Future<void> openApp() async {
      db = await FoundationDatabase.openEncrypted(path: path, key: key);
      final repository = DriftAdhkarRepository(db!);
      final times = PrayerAdhkarTimesAdapter(
        boundaries: boundaries,
        preferences: preferences,
        clock: clock,
      );
      commands = AdhkarCommands(
        ownerId: adhkarOwner,
        times: times,
        catalog: catalog,
        repository: repository,
        commits: DriftAdhkarUnitOfWork(
          database: db!,
          repository: repository,
          awards: DriftAwardLedger(db!),
        ),
        clock: clock,
        identity: const UuidAdhkarIdentity(),
        queueForSync: false,
      );
      cubit = AdhkarCubit(
        ownerId: adhkarOwner,
        times: times,
        catalog: catalog,
        repository: repository,
        commands: commands,
        clock: clock,
      );
      await cubit!.load();
    }

    Future<void> closeApp() async {
      await cubit?.close();
      cubit = null;
      await db?.close();
      db = null;
    }

    addTearDown(() async {
      await closeApp();
      temp.dispose();
    });

    Future<int> awards() async =>
        (await db!.rawScalar(
              'SELECT count(*) FROM xp_awards WHERE source = '
              "'$kAdhkarSetDoneAwardSource'",
            ))!
            as int;
    Future<int> rows(String day) async =>
        (await db!.rawScalar(
              'SELECT count(*) FROM adhkar_item_counts WHERE adhkar_day = '
              "'$day'",
            ))!
            as int;
    // Lets the cubit's own streams deliver what the store just wrote.
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 150));
    // Taps one item `times` times, as a user would.
    Future<void> tap(String item, int times) async {
      for (var i = 0; i < times; i++) {
        await cubit!.increment(item, cubit!.state.clock!.day!);
      }
      await settle();
    }

    // 1. 03:00 Thursday is before Fajr: the running Adhkar day is
    // Wednesday's, in its Evening period. Morning is locked there.
    await openApp();
    expect(cubit!.state.clock?.day, '2026-11-11');
    expect(cubit!.state.clock?.period, AdhkarPeriod.evening);
    expect(cubit!.state.selectedTab, AdhkarTab.evening);
    await cubit!.increment('m1', '2026-11-11');
    await settle();
    expect(
      cubit!.state.itemStatus['m1'],
      AdhkarActionStatus.outsidePeriod,
      reason: 'Morning does not count before Fajr',
    );
    expect(cubit!.state.outsidePeriodStartsAtUtc, fajr['2026-11-12']);
    expect(await rows('2026-11-11'), 0, reason: 'a locked tap writes nothing');
    expect(await awards(), 0);

    // 2. After Fajr the new day opens Morning.
    clock.now = DateTime.utc(2026, 11, 12, 6);
    await cubit!.resume();
    await settle();
    expect(cubit!.state.clock?.day, '2026-11-12');
    expect(cubit!.state.clock?.period, AdhkarPeriod.morning);
    expect(cubit!.state.selectedTab, AdhkarTab.morning);
    expect(cubit!.state.completedOf(AdhkarList.morning), 0);
    expect(cubit!.state.totalOf(AdhkarList.morning), 4);

    // 3. Counting the Morning list item by item: m1 (1x), m2 (3x), m3 (2x),
    // m4 (1x). The set completes on the last tap, with one celebration.
    await tap('m1', 1);
    expect(cubit!.state.countOf('m1'), 1);
    expect(cubit!.state.completedOf(AdhkarList.morning), 1);
    await tap('m2', 2);
    expect(cubit!.state.countOf('m2'), 2);
    expect(cubit!.state.completedOf(AdhkarList.morning), 1, reason: 'm2 2/3');
    await tap('m2', 1);
    await tap('m3', 2);
    expect(cubit!.state.completedOf(AdhkarList.morning), 3);
    expect(await awards(), 0, reason: 'the set is not complete yet');
    expect(cubit!.state.celebration, isNull);
    await tap('m4', 1);
    expect(cubit!.state.completedOf(AdhkarList.morning), 4);
    expect(cubit!.state.celebration, AdhkarTab.morning);
    expect(await awards(), 1, reason: 'one award for the Morning set');
    expect(await rows('2026-11-12'), 4);

    // 4. Counting past the target, and a reset and recount, never award
    // again.
    await tap('m1', 1);
    expect(cubit!.state.countOf('m1'), 1, reason: 'a tap at target is a no-op');
    expect(await awards(), 1);
    await cubit!.reset('m1', '2026-11-12');
    await settle();
    expect(cubit!.state.countOf('m1'), 0);
    expect(cubit!.state.completedOf(AdhkarList.morning), 3);
    await tap('m1', 1);
    expect(cubit!.state.completedOf(AdhkarList.morning), 4);
    expect(await awards(), 1, reason: 'the set award is never repeated');

    // 5. Restart: the store is closed and reopened; every count comes back,
    // there is no new celebration and still one award.
    await closeApp();
    await openApp();
    await settle();
    expect(cubit!.state.clock?.day, '2026-11-12');
    expect(cubit!.state.completedOf(AdhkarList.morning), 4);
    expect(cubit!.state.countOf('m2'), 3);
    expect(cubit!.state.countOf('m3'), 2);
    expect(cubit!.state.celebration, isNull);
    expect(await awards(), 1);

    // 6. After Maghrib the Evening period opens and Morning locks again.
    clock.now = DateTime.utc(2026, 11, 12, 17);
    await cubit!.resume();
    await settle();
    expect(cubit!.state.clock?.day, '2026-11-12', reason: 'same Adhkar day');
    expect(cubit!.state.clock?.period, AdhkarPeriod.evening);
    expect(cubit!.state.selectedTab, AdhkarTab.evening);
    await cubit!.reset('m2', '2026-11-12');
    await settle();
    expect(
      cubit!.state.countOf('m2'),
      0,
      reason: 'a reset is allowed outside the period',
    );
    await cubit!.increment('m2', '2026-11-12');
    await settle();
    expect(
      cubit!.state.itemStatus['m2'],
      AdhkarActionStatus.outsidePeriod,
      reason: 'a Morning count after Maghrib is refused',
    );
    expect(cubit!.state.countOf('m2'), 0);
    // The Morning set stays awarded; Evening is counted to completion: e1
    // (1x) and e2 (2x).
    await tap('e1', 1);
    expect(cubit!.state.completedOf(AdhkarList.evening), 1);
    await tap('e2', 2);
    expect(cubit!.state.completedOf(AdhkarList.evening), 2);
    expect(cubit!.state.celebration, AdhkarTab.evening);
    expect(await awards(), 2, reason: 'one award per list, per day');

    // 7. The next Fajr opens a new day: a fresh Morning, and a command
    // captured for the old day writes nothing.
    clock.now = DateTime.utc(2026, 11, 13, 5);
    await cubit!.resume();
    await settle();
    expect(cubit!.state.clock?.day, '2026-11-13');
    expect(cubit!.state.clock?.period, AdhkarPeriod.morning);
    expect(cubit!.state.selectedTab, AdhkarTab.morning);
    expect(cubit!.state.completedOf(AdhkarList.morning), 0);
    expect(cubit!.state.completedOf(AdhkarList.evening), 0);
    final rowsBefore = await rows('2026-11-12');
    await cubit!.increment('m1', '2026-11-12');
    await settle();
    expect(await rows('2026-11-12'), rowsBefore, reason: 'stale day: no write');
    expect(await rows('2026-11-13'), 0);
    expect(await awards(), 2);

    // The screen shows the saved state after a restart, with no badge.
    await closeApp();
    clock.now = DateTime.utc(2026, 11, 12, 10);
    await openApp();
    await settle();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: AppTheme.light,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        home: BlocProvider.value(value: cubit!, child: const AdhkarScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('adhkar_header')), findsOneWidget);
    expect(find.byKey(const Key('adhkar_progress_card')), findsOneWidget);
    // On 2026-11-12 the Morning list stands at 3 of 4 (the set was awarded
    // before m2 was reset): the page continues from the second dhikr.
    expect(find.text('Morning adhkar (3 / 4)'), findsOneWidget);
    expect(find.text('Continue from dhikr 2'), findsOneWidget);
    expect(find.byKey(const Key('adhkar_finished_card')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

String _nextDay(String day) {
  final next = DateTime.parse('${day}T00:00:00Z').add(const Duration(days: 1));
  return '${next.year.toString().padLeft(4, '0')}-'
      '${next.month.toString().padLeft(2, '0')}-'
      '${next.day.toString().padLeft(2, '0')}';
}

/// A manually moved clock that serves the Prayer and the Qiyam ports (the
/// location's zone is UTC, so the city date is the UTC date).
final class _FlowClock
    implements PrayerClockPort, QiyamClockPort, AdhkarClockPort {
  _FlowClock(this.now);

  DateTime now;

  @override
  DateTime nowUtc() => now;

  @override
  PrayerLocalDate cityDate(DateTime nowUtc, String timeZoneId) =>
      PrayerLocalDate.parse(
        '${nowUtc.year.toString().padLeft(4, '0')}-'
        '${nowUtc.month.toString().padLeft(2, '0')}-'
        '${nowUtc.day.toString().padLeft(2, '0')}',
      );

  @override
  int cityOffsetMinutes(DateTime nowUtc, String timeZoneId) => 0;
}

final class _FixedBoundaries implements PrayerDayBoundariesPort {
  _FixedBoundaries(this.results);

  final Map<PrayerLocalDate, PrayerDayBoundariesResult> results;

  @override
  Future<PrayerDayBoundariesResult> boundaries(
    String ownerId,
    PrayerLocalDate civilDate,
  ) async =>
      results[civilDate] ??
      const PrayerDayBoundariesUnavailable(reason: 'outside the fixed days');

  @override
  Stream<void> changes(String ownerId) => const Stream.empty();
}

final class _FixedPreferences implements PrayerPreferencesPort {
  _FixedPreferences(this.owner);

  final String owner;

  @override
  Future<AppResult<PrayerPreferences?>> read(String accountId) async =>
      AppResult.success(
        PrayerPreferences(
          accountId: owner,
          city: PrayerCity(
            provider: 'device',
            providerCityId: 'device-fix',
            name: 'Cairo',
            countryCode: 'EG',
            countryName: 'Egypt',
            latitude: 30.0444,
            longitude: 31.2357,
            timeZoneId: 'UTC',
          ),
          calculationMethod: 'Umm al-Qura',
          revision: 1,
          updatedAt: DateTime.utc(2026, 11, 10),
        ),
      );

  @override
  Stream<PrayerPreferences?> watch(String accountId) => const Stream.empty();

  @override
  Future<AppResult<PrayerPreferences>> save(
    PrayerPreferences preferences, {
    required int? expectedRevision,
  }) => throw UnimplementedError();
}

final class _NoSupplications implements QiyamSupplicationsPort {
  const _NoSupplications();

  @override
  Future<AppResult<List<QiyamSupplication>>> supplications(
    String ownerId,
  ) async => const AppResult.success([]);
}

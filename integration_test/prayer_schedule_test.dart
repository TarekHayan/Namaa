import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart'
    show FoundationDatabase, PrayerReportsCompanion;
import 'package:namma_project/features/prayer/application/prayer_context_service.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_commands.dart';
import 'package:namma_project/features/prayer/data/adhan_prayer_calculator.dart';
import 'package:namma_project/features/prayer/data/drift_prayer_preferences.dart';
import 'package:namma_project/features/prayer/data/drift_prayer_repository.dart';
import 'package:namma_project/features/prayer/data/uuid_prayer_report_identity.dart';
import 'package:namma_project/features/prayer/data/zoned_prayer_clock.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_day_snapshot.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';
import 'package:namma_project/features/today/data/prayer_today_adapter.dart';

import '../test/support/foundation_test_support.dart';

const _owner = 'prayer-preview-owner';
final _cairo = PrayerCity(
  provider: 'fixture',
  providerCityId: 'cairo',
  name: 'Cairo',
  countryCode: 'EG',
  countryName: 'Egypt',
  latitude: 30.0444,
  longitude: 31.2357,
  timeZoneId: 'Africa/Cairo',
);
final _newYork = PrayerCity(
  provider: 'fixture',
  providerCityId: 'new-york',
  name: 'New York',
  countryCode: 'US',
  countryName: 'United States',
  latitude: 40.7128,
  longitude: -74.0060,
  timeZoneId: 'America/New_York',
);

const _historyDays = 3660;

String _dateValue(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saved city and Home agree across offline days and restart', (
    tester,
  ) async {
    const target = String.fromEnvironment(
      'PRAYER_TEST_TARGET',
      defaultValue: 'unspecified',
    );
    final path = TemporaryDatabasePath();
    final file = path.allocate();
    final key = List<int>.generate(32, (index) => index + 11);
    var database = await FoundationDatabase.openEncrypted(path: file, key: key);
    addTearDown(() async {
      await database.close();
      path.dispose();
    });
    var now = DateTime.utc(2026, 3, 7, 12);
    final clock = ZonedPrayerClock(now: () => now);
    final calculator = AdhanPrayerCalculator();

    PrayerContextService service() => PrayerContextService(
      preferences: DriftPrayerPreferences(database),
      reports: DriftPrayerRepository(database),
      calculator: calculator,
      clock: clock,
      tick: const Duration(milliseconds: 20),
    );

    Future<PrayerDaySnapshot> snapshot(PrayerContextService context) => context
        .watch(_owner)
        .firstWhere((value) => value.schedule != null && value.reportsAvailable)
        .timeout(const Duration(seconds: 5));

    final preferences = DriftPrayerPreferences(database);
    final commands = PrayerPreferencesCommands(preferences);
    final saved = await commands.confirm(
      ownerId: _owner,
      city: _cairo,
      method: 'egyptian',
      expectedRevision: null,
      nowUtc: now,
    );
    expect(saved.valueOrNull?.revision, 1);

    // SC-006 fixture: ten years of retained history (3,660 days x 5 =
    // 18,300 reports) before the journey's first day. Day reads must stay
    // indexed, so this volume must not slow the visible day.
    final identity = UuidPrayerReportIdentity();
    final firstJourneyDay = DateTime.utc(2026, 3, 7);
    await database.batch((batch) {
      for (var offset = _historyDays; offset >= 1; offset--) {
        final day = firstJourneyDay.subtract(Duration(days: offset));
        final date = PrayerLocalDate.parse(_dateValue(day));
        for (final name in PrayerName.values) {
          final done = (offset + name.index).isEven;
          final at = day
              .add(Duration(hours: 3 + name.index * 3))
              .toIso8601String();
          batch.insert(
            database.prayerReports,
            PrayerReportsCompanion.insert(
              accountId: _owner,
              localDate: date.value,
              prayerName: name.wireName,
              reportId: identity.reportId(date, name),
              status: done ? 'completed_on_time' : 'missed',
              reportedCompletionAt: Value(done ? at : null),
              recordedZoneId: 'Africa/Cairo',
              recordedOffsetMinutes: 120,
              createdAt: at,
              updatedAt: at,
            ),
          );
        }
      }
    });
    final stored = await database.prayerReports.count().getSingle();
    expect(stored, _historyDays * PrayerName.values.length);
    expect(stored, 18300);

    // Cold start on the full history: encrypted reopen until the first
    // readable day snapshot (schedule plus its reports).
    await database.close();
    final coldWatch = Stopwatch()..start();
    database = await FoundationDatabase.openEncrypted(path: file, key: key);
    final cold = await snapshot(service());
    coldWatch.stop();
    expect(cold.localDate?.value, '2026-03-07');
    expect(cold.completedCount, 0);

    // One status action: the local write until the visible day shows it.
    final actionContext = service();
    final actionStream = actionContext.watch(_owner);
    final completedSeen = actionStream
        .firstWhere((value) => value.completedCount == 1)
        .timeout(const Duration(seconds: 5));
    final today = PrayerLocalDate.parse('2026-03-07');
    final actionWatch = Stopwatch()..start();
    final written = await DriftPrayerRepository(database).writeLocal(
      PrayerReport(
        accountId: _owner,
        reportId: identity.reportId(today, PrayerName.fajr),
        date: today,
        name: PrayerName.fajr,
        status: PrayerStatus.completedOnTime,
        reportedCompletionAt: now,
        recordedZoneId: 'Africa/Cairo',
        recordedOffsetMinutes: 120,
        createdAt: now,
        updatedAt: now,
      ),
      operationId: 'fixture-action',
      acknowledgedBase: null,
      expectedCurrentVersion: null,
      queueForSync: false,
    );
    expect(written.failureOrNull, isNull);
    await completedSeen;
    actionWatch.stop();

    // ignore: avoid_print
    print(
      'PRAYER_HISTORY_FIXTURE target=$target reports=$stored '
      'cold_readable_ms=${coldWatch.elapsedMilliseconds} '
      'action_visible_ms=${actionWatch.elapsedMilliseconds}',
    );
    // Limits apply to named measurement runs (T125/T126). An unnamed CI run
    // still records numbers but does not fail on a slow shared emulator.
    if (target != 'unspecified') {
      expect(coldWatch.elapsedMilliseconds, lessThanOrEqualTo(2000));
      expect(actionWatch.elapsedMilliseconds, lessThanOrEqualTo(1000));
    }

    // A network attempt fails this journey. It uses only saved coordinates,
    // bundled IANA zone data and the on-device calculator.
    final offlineCalculationWatch = Stopwatch()..start();
    await HttpOverrides.runZoned(
      () async {
        for (var day = 7; day <= 13; day++) {
          now = DateTime.utc(2026, 3, day, 12);
          final context = service();
          final prayer = await snapshot(context);
          final home = await PrayerTodayAdapter(context)
              .watchPrayer(_owner)
              .firstWhere((value) => value.localDate != null)
              .timeout(const Duration(seconds: 5));
          expect(prayer.health, PrayerSnapshotHealth.available);
          expect(
            prayer.localDate?.value,
            '2026-03-${day.toString().padLeft(2, '0')}',
          );
          expect(
            prayer.tomorrow?.date.value,
            '2026-03-${(day + 1).toString().padLeft(2, '0')}',
          );
          expect(prayer.schedule!.times.length, 5);
          expect(
            prayer.schedule!.times.values.every(
              (time) => time.instantUtc != null,
            ),
            isTrue,
          );
          expect(home.ownerId, _owner);
          expect(home.city, prayer.preferences!.city.name);
          expect(home.localDate, prayer.localDate!.value);
          expect(home.timeZoneId, prayer.preferences!.city.timeZoneId);
          expect(home.nextName, prayer.projection?.next?.name);
          expect(home.nextUtc, prayer.projection?.next?.instantUtc);
        }
      },
      createHttpClient: (_) =>
          throw StateError('offline schedule attempted HTTP'),
    );
    offlineCalculationWatch.stop();
    // A named timing hook for later phone/desktop runs. This measures the
    // seven-day local journey only; it is not a UI latency acceptance result.
    // ignore: avoid_print
    print(
      'PRAYER_OFFLINE_SEVEN_DAY_MS target=$target '
      'elapsed=${offlineCalculationWatch.elapsedMilliseconds}',
    );

    final crossing = <PrayerDaySnapshot>[];
    final crossingSubscription = service().watch(_owner).listen(crossing.add);
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(crossing.last.localDate?.value, '2026-03-13');
    now = DateTime.utc(2026, 3, 13, 22, 1);
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(crossing.last.localDate?.value, '2026-03-14');
    await crossingSubscription.cancel();

    await database.close();
    database = await FoundationDatabase.openEncrypted(path: file, key: key);
    expect(
      (await DriftPrayerPreferences(database).read(_owner)).valueOrNull?.city,
      _cairo,
    );

    // New York changes its UTC offset at the March DST boundary. The locally
    // saved city and method are read again after a process-style DB restart.
    final switched =
        await PrayerPreferencesCommands(
          DriftPrayerPreferences(database),
        ).confirm(
          ownerId: _owner,
          city: _newYork,
          method: 'muslimWorldLeague',
          expectedRevision: 1,
          nowUtc: now,
        );
    expect(switched.valueOrNull?.revision, 2);
    expect(
      clock.offsetMinutes(DateTime.utc(2026, 3, 8, 6), 'America/New_York'),
      -300,
    );
    expect(
      clock.offsetMinutes(DateTime.utc(2026, 3, 8, 8), 'America/New_York'),
      -240,
    );
    now = DateTime.utc(2026, 3, 8, 12);
    final afterSwitch = await snapshot(service());
    expect(afterSwitch.preferences?.city, _newYork);
    expect(afterSwitch.preferences?.calculationMethod, 'muslimWorldLeague');
    expect(afterSwitch.localDate?.value, '2026-03-08');
    expect(afterSwitch.tomorrow?.date.value, '2026-03-09');
    expect(afterSwitch.schedule!.times[PrayerName.fajr]?.instantUtc, isNotNull);
    expect(afterSwitch.completedCount, 0);
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/prayer/application/prayer_annual_schedule_port.dart';
import 'package:namma_project/features/prayer/application/prayer_context_service.dart';
import 'package:namma_project/features/prayer/application/prayer_preferences_port.dart';
import 'package:namma_project/features/prayer/application/prayer_repository.dart';
import 'package:namma_project/features/prayer/application/prayer_schedule_calculator_port.dart';
import 'package:namma_project/features/prayer/data/zoned_prayer_clock.dart';
import 'package:namma_project/features/prayer/domain/prayer_city.dart';
import 'package:namma_project/features/prayer/domain/prayer_day_snapshot.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_preferences.dart';
import 'package:namma_project/features/prayer/domain/prayer_report.dart';
import 'package:namma_project/features/prayer/domain/prayer_schedule.dart';
import 'package:namma_project/features/prayer/domain/prayer_status.dart';

class _Preferences extends Fake implements PrayerPreferencesPort {
  final controller = StreamController<PrayerPreferences?>.broadcast(sync: true);
  @override
  Stream<PrayerPreferences?> watch(String accountId) => controller.stream;
}

class _Reports extends Fake implements PrayerRepository {
  final days = <String>[];
  bool fail = false;
  @override
  Stream<List<PrayerReport>> watchDay({
    required String accountId,
    required PrayerLocalDate date,
  }) {
    days.add('$accountId/${date.value}');
    return fail
        ? Stream.error(StateError('unreadable'))
        : Stream.value(const []);
  }
}

class _ControlledReports extends Fake implements PrayerRepository {
  final watches = <String, List<StreamController<List<PrayerReport>>>>{};

  @override
  Stream<List<PrayerReport>> watchDay({
    required String accountId,
    required PrayerLocalDate date,
  }) {
    final key = '$accountId/${date.value}';
    final controller = StreamController<List<PrayerReport>>.broadcast(
      sync: true,
    );
    watches.putIfAbsent(key, () => []).add(controller);
    return controller.stream;
  }

  Future<void> close() async {
    for (final controllers in watches.values) {
      for (final controller in controllers) {
        await controller.close();
      }
    }
  }
}

class _Calculator extends Fake implements PrayerScheduleCalculatorPort {
  int calls = 0;
  @override
  AppResult<PrayerSchedule> calculate({
    required PrayerPreferences preferences,
    required PrayerLocalDate date,
  }) {
    calls++;
    final day = DateTime.parse('${date.value}T00:00:00Z');
    final times = <PrayerName, PrayerTime>{};
    for (final name in PrayerName.values) {
      times[name] = PrayerTime(
        name: name,
        instantUtc: day.add(Duration(hours: 2 + name.index * 4)),
      );
    }
    return AppResult.success(
      PrayerSchedule(
        date: date,
        contextRevision: preferences.revision,
        times: times,
        provenance: 'fixture',
      ),
    );
  }
}

class _Annual extends Fake implements PrayerAnnualSchedulePort {
  _Annual(this.calculator);
  final _Calculator calculator;

  @override
  Future<PrayerSchedule?> forDate({
    required PrayerPreferences preferences,
    required PrayerLocalDate date,
  }) async => date.value.startsWith('2026-')
      ? calculator
            .calculate(preferences: preferences, date: date)
            .valueOrNull
            ?.copyWith(provenance: 'AlAdhan API')
      : null;
}

PrayerCity _city(String id, String zone) => PrayerCity(
  provider: 'fixture',
  providerCityId: id,
  name: id,
  countryCode: 'EG',
  countryName: 'Egypt',
  latitude: 30.0444,
  longitude: 31.2357,
  timeZoneId: zone,
);

PrayerPreferences _preference({required int revision, required DateTime now}) =>
    PrayerPreferences(
      accountId: 'owner',
      city: _city('cairo', 'Africa/Cairo'),
      calculationMethod: 'egyptian',
      revision: revision,
      updatedAt: now,
    );

PrayerReport _report(PrayerStatus status, DateTime at) => PrayerReport(
  accountId: 'owner',
  reportId: 'report-fajr',
  date: PrayerLocalDate.parse('2026-03-20'),
  name: PrayerName.fajr,
  status: status,
  reportedCompletionAt: status.isCompleted ? at : null,
  recordedZoneId: 'Africa/Cairo',
  recordedOffsetMinutes: 120,
  createdAt: at,
  updatedAt: at,
);

void main() {
  test(
    'cached year wins; after coverage ends offline local fallback is labelled',
    () async {
      final preferences = _Preferences();
      final calculator = _Calculator();
      var now = DateTime.utc(2026, 12, 31, 12);
      final context = PrayerContextService(
        preferences: preferences,
        reports: _Reports(),
        calculator: calculator,
        annualSchedules: _Annual(calculator),
        clock: ZonedPrayerClock(now: () => now),
        tick: const Duration(milliseconds: 10),
      );
      final snapshots = <PrayerDaySnapshot>[];
      final subscription = context.watch('owner').listen(snapshots.add);
      addTearDown(() async {
        await subscription.cancel();
        await preferences.controller.close();
      });
      preferences.controller.add(
        PrayerPreferences(
          accountId: 'owner',
          city: PrayerCity(
            provider: 'fixture',
            providerCityId: 'cairo',
            name: 'Cairo',
            countryCode: 'EG',
            countryName: 'Egypt',
            latitude: 30.0444,
            longitude: 31.2357,
            timeZoneId: 'Africa/Cairo',
          ),
          calculationMethod: 'egyptian',
          revision: 1,
          updatedAt: now,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(snapshots.last.schedule!.provenance, 'AlAdhan API');
      expect(
        snapshots.last.tomorrow!.provenance,
        startsWith('Local calculation'),
      );
      now = DateTime.utc(2026, 12, 31, 22, 1);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(snapshots.last.localDate?.value, '2027-01-01');
      expect(
        snapshots.last.schedule!.provenance,
        startsWith('Local calculation'),
      );
    },
  );

  test(
    'one owner stream recalculates the selected city day at midnight',
    () async {
      final preferences = _Preferences();
      final reports = _Reports();
      final calculator = _Calculator();
      var now = DateTime.utc(2026, 3, 20, 21, 59, 59);
      final clock = ZonedPrayerClock(now: () => now);
      final context = PrayerContextService(
        preferences: preferences,
        reports: reports,
        calculator: calculator,
        clock: clock,
        tick: const Duration(milliseconds: 20),
      );
      final snapshots = <PrayerDaySnapshot>[];
      final subscription = context.watch('owner').listen(snapshots.add);
      addTearDown(() async {
        await subscription.cancel();
        await preferences.controller.close();
      });
      preferences.controller.add(
        PrayerPreferences(
          accountId: 'owner',
          city: PrayerCity(
            provider: 'fixture',
            providerCityId: 'cairo',
            name: 'Cairo',
            countryCode: 'EG',
            countryName: 'Egypt',
            latitude: 30.0444,
            longitude: 31.2357,
            timeZoneId: 'Africa/Cairo',
          ),
          calculationMethod: 'egyptian',
          revision: 1,
          updatedAt: now,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(snapshots.last.localDate?.value, '2026-03-20');
      expect(snapshots.last.health, PrayerSnapshotHealth.available);
      expect(reports.days, contains('owner/2026-03-20'));
      final beforeTick = calculator.calls;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(
        calculator.calls,
        beforeTick,
        reason: 'countdown only projects time',
      );
      now = DateTime.utc(2026, 3, 20, 22, 0, 1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(snapshots.last.localDate?.value, '2026-03-21');
      expect(reports.days, contains('owner/2026-03-21'));
      expect(calculator.calls, beforeTick + 2);
    },
  );

  test(
    'report read failure leaves calculated times but no false 0/5',
    () async {
      final preferences = _Preferences();
      final reports = _Reports()..fail = true;
      final now = DateTime.utc(2026, 3, 20, 12);
      final context = PrayerContextService(
        preferences: preferences,
        reports: reports,
        calculator: _Calculator(),
        clock: ZonedPrayerClock(now: () => now),
      );
      final snapshots = <PrayerDaySnapshot>[];
      final subscription = context.watch('owner').listen(snapshots.add);
      addTearDown(() async {
        await subscription.cancel();
        await preferences.controller.close();
      });
      preferences.controller.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.last.health, PrayerSnapshotHealth.setupRequired);
      preferences.controller.add(
        PrayerPreferences(
          accountId: 'owner',
          city: PrayerCity(
            provider: 'fixture',
            providerCityId: 'cairo',
            name: 'Cairo',
            countryCode: 'EG',
            countryName: 'Egypt',
            latitude: 30.0444,
            longitude: 31.2357,
            timeZoneId: 'Africa/Cairo',
          ),
          calculationMethod: 'egyptian',
          revision: 1,
          updatedAt: now,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(snapshots.last.schedule, isNotNull);
      expect(snapshots.last.health, PrayerSnapshotHealth.available);
      expect(snapshots.last.reportsAvailable, isFalse);
      expect(snapshots.last.completedCount, isNull);
    },
  );
  test('a preference from another owner is never projected', () async {
    final preferences = _Preferences();
    final context = PrayerContextService(
      preferences: preferences,
      reports: _Reports(),
      calculator: _Calculator(),
      clock: ZonedPrayerClock(now: () => DateTime.utc(2026, 3, 20)),
    );
    final snapshots = <PrayerDaySnapshot>[];
    final subscription = context.watch('owner-a').listen(snapshots.add);
    addTearDown(() async {
      await subscription.cancel();
      await preferences.controller.close();
    });
    preferences.controller.add(
      PrayerPreferences(
        accountId: 'owner-b',
        city: PrayerCity(
          provider: 'fixture',
          providerCityId: 'cairo',
          name: 'Cairo',
          countryCode: 'EG',
          countryName: 'Egypt',
          latitude: 30.0444,
          longitude: 31.2357,
          timeZoneId: 'Africa/Cairo',
        ),
        calculationMethod: 'egyptian',
        revision: 1,
        updatedAt: DateTime.utc(2026, 3, 20),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(snapshots.last.health, PrayerSnapshotHealth.unavailable);
    expect(snapshots.last.preferences, isNull);
    expect(snapshots.last.schedule, isNull);
  });

  test(
    'late report emissions from a replaced preference are ignored',
    () async {
      final preferences = _Preferences();
      final reports = _ControlledReports();
      final now = DateTime.utc(2026, 3, 20, 12);
      final context = PrayerContextService(
        preferences: preferences,
        reports: reports,
        calculator: _Calculator(),
        clock: ZonedPrayerClock(now: () => now),
      );
      final snapshots = <PrayerDaySnapshot>[];
      final subscription = context.watch('owner').listen(snapshots.add);
      addTearDown(() async {
        await subscription.cancel();
        await reports.close();
        await preferences.controller.close();
      });

      preferences.controller.add(_preference(revision: 1, now: now));
      await Future<void>.delayed(Duration.zero);
      final first = reports.watches['owner/2026-03-20']!.first;
      first.add([_report(PrayerStatus.completedOnTime, now)]);
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.last.completedCount, 1);

      preferences.controller.add(_preference(revision: 2, now: now));
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.last.completedCount, isNull);
      first.add([_report(PrayerStatus.completedOnTime, now)]);
      await Future<void>.delayed(Duration.zero);
      expect(
        snapshots.last.completedCount,
        isNull,
        reason: 'An obsolete generation must not repopulate the new context.',
      );
    },
  );

  test('explicit reset changes count without changing the schedule', () async {
    final preferences = _Preferences();
    final reports = _ControlledReports();
    final now = DateTime.utc(2026, 3, 20, 12);
    final context = PrayerContextService(
      preferences: preferences,
      reports: reports,
      calculator: _Calculator(),
      clock: ZonedPrayerClock(now: () => now),
    );
    final snapshots = <PrayerDaySnapshot>[];
    final subscription = context.watch('owner').listen(snapshots.add);
    addTearDown(() async {
      await subscription.cancel();
      await reports.close();
      await preferences.controller.close();
    });

    preferences.controller.add(_preference(revision: 1, now: now));
    await Future<void>.delayed(Duration.zero);
    final stream = reports.watches['owner/2026-03-20']!.single;
    stream.add([_report(PrayerStatus.completedLate, now)]);
    await Future<void>.delayed(Duration.zero);
    final schedule = snapshots.last.schedule;
    expect(snapshots.last.completedCount, 1);

    stream.add([
      _report(PrayerStatus.pending, now.add(const Duration(microseconds: 1))),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(snapshots.last.completedCount, 0);
    expect(snapshots.last.schedule, same(schedule));
  });
}

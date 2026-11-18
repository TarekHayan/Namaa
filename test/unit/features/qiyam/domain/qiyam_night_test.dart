import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';
import 'package:namma_project/features/prayer/domain/prayer_name.dart';
import 'package:namma_project/features/prayer/domain/prayer_schedule.dart';
import 'package:namma_project/features/prayer/domain/prayer_schedule_projection.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';

/// T037: QiyamNight vectors (research.md R4). Night D starts at Maghrib on D
/// and a record belongs to the most recent night that has started, so 03:00
/// and 10:00 on Thursday both belong to Wednesday's night and 20:00 on
/// Thursday belongs to Thursday's night. The caller (the composition adapter,
/// T043) requests the boundaries of the night in progress; the vectors
/// express the attribution through those boundaries. Without a schedule the
/// 12:00 local rule applies; an unavailable schedule locks recording with no
/// calendar fallback (owner decision, 2026-11-10).
void main() {
  // Thursday is 2026-11-12; Wednesday's night is night 2026-11-11, which
  // starts at Maghrib on 2026-11-11 (16:50Z) and runs to Maghrib on
  // 2026-11-12. Its last Fajr is 04:29Z on 2026-11-12.
  final wednesdayMaghrib = DateTime.utc(2026, 11, 11, 16, 50);
  final thursdayFajr = DateTime.utc(2026, 11, 12, 4, 29);
  final thursdayMaghrib = DateTime.utc(2026, 11, 12, 16, 50);
  final fridayFajr = DateTime.utc(2026, 11, 13, 4, 29);

  QiyamNightBoundaries nightBoundaries(
    String nightDay,
    DateTime maghribUtc,
    DateTime nextFajrUtc, {
    DateTime? lastThirdUtc,
  }) => QiyamNightBoundaries(
    maghribUtc: maghribUtc,
    nextFajrUtc: nextFajrUtc,
    lastThirdUtc:
        lastThirdUtc ??
        maghribUtc.add(nextFajrUtc.difference(maghribUtc) * 2 ~/ 3),
    nightDay: nightDay,
    zoneId: 'UTC',
  );

  /// The last third exactly as the shared Prayer projection computes it for
  /// night [nightDay] (research.md R2): `from(today: D, tomorrow: D+1)`.
  DateTime projectedLastThird(
    String nightDay,
    DateTime maghribUtc,
    DateTime nextFajrUtc,
  ) {
    final day = PrayerLocalDate.parse(nightDay);
    final carrier = DateTime.parse('${nightDay}T00:00:00Z');
    final nextCarrier = carrier.add(const Duration(days: 1));
    final nextDay = PrayerLocalDate.parse(
      '${nextCarrier.year.toString().padLeft(4, '0')}-'
      '${nextCarrier.month.toString().padLeft(2, '0')}-'
      '${nextCarrier.day.toString().padLeft(2, '0')}',
    );
    return PrayerScheduleProjection.from(
      today: _boundarySchedule(day, maghribUtc, PrayerName.maghrib),
      tomorrow: _boundarySchedule(nextDay, nextFajrUtc, PrayerName.fajr),
      nowUtc: maghribUtc,
    ).lastThirdUtc!;
  }

  test('03:00 on Thursday belongs to Wednesday\'s night', () {
    final state = QiyamNight.resolve(
      nowUtc: DateTime.utc(2026, 11, 12, 3),
      input: QiyamScheduledNight(
        zoneOffsetMinutes: 0,
        boundaries: nightBoundaries(
          '2026-11-11',
          wednesdayMaghrib,
          thursdayFajr,
        ),
        nextMaghribUtc: thursdayMaghrib,
      ),
    );
    expect(state.scheduleState, QiyamScheduleState.available);
    expect(state.nightDate, '2026-11-11');
    expect(state.editable, isTrue);
    expect(state.nextBoundaryUtc, thursdayMaghrib);
  });

  test('10:00 on Thursday is still Wednesday\'s night until Maghrib', () {
    // The night runs to the NEXT Maghrib, well past its Fajr: recording last
    // night stays possible until today's Maghrib (spec clarification Q2).
    final state = QiyamNight.resolve(
      nowUtc: DateTime.utc(2026, 11, 12, 10),
      input: QiyamScheduledNight(
        zoneOffsetMinutes: 0,
        boundaries: nightBoundaries(
          '2026-11-11',
          wednesdayMaghrib,
          thursdayFajr,
        ),
        nextMaghribUtc: thursdayMaghrib,
      ),
    );
    expect(state.nightDate, '2026-11-11');
    expect(state.editable, isTrue);
  });

  test('20:00 on Thursday belongs to Thursday\'s night', () {
    final state = QiyamNight.resolve(
      nowUtc: DateTime.utc(2026, 11, 12, 20),
      input: QiyamScheduledNight(
        zoneOffsetMinutes: 0,
        boundaries: nightBoundaries('2026-11-12', thursdayMaghrib, fridayFajr),
      ),
    );
    expect(state.nightDate, '2026-11-12');
    expect(state.editable, isTrue);
  });

  test('at the night\'s own Maghrib the new night is already active', () {
    final state = QiyamNight.resolve(
      nowUtc: thursdayMaghrib,
      input: QiyamScheduledNight(
        zoneOffsetMinutes: 0,
        boundaries: nightBoundaries('2026-11-12', thursdayMaghrib, fridayFajr),
      ),
    );
    expect(state.nightDate, '2026-11-12');
  });

  test('a now before the night started is a composition error', () {
    expect(
      () => QiyamNight.resolve(
        nowUtc: wednesdayMaghrib.subtract(const Duration(minutes: 1)),
        input: QiyamScheduledNight(
          zoneOffsetMinutes: 0,
          boundaries: nightBoundaries(
            '2026-11-11',
            wednesdayMaghrib,
            thursdayFajr,
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('a now at the known next Maghrib is a composition error', () {
    // The caller must already be asking for the new night; a lapsed window is
    // a composition bug, not a clock decision.
    expect(
      () => QiyamNight.resolve(
        nowUtc: thursdayMaghrib,
        input: QiyamScheduledNight(
          zoneOffsetMinutes: 0,
          boundaries: nightBoundaries(
            '2026-11-11',
            wednesdayMaghrib,
            thursdayFajr,
          ),
          nextMaghribUtc: thursdayMaghrib,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('without a schedule 11:59 local is the previous night and 12:00 is '
      'the current one', () {
    final beforeNoon = QiyamNight.resolve(
      nowUtc: DateTime.utc(2026, 11, 12, 9, 59),
      input: QiyamNoSchedule(
        deviceLocal: DateTime(2026, 11, 12, 11, 59),
        zoneId: 'UTC',
        zoneOffsetMinutes: 0,
      ),
    );
    expect(beforeNoon.scheduleState, QiyamScheduleState.setupRequired);
    expect(beforeNoon.nightDate, '2026-11-11');
    expect(beforeNoon.editable, isTrue);
    expect(beforeNoon.lastThirdUtc, isNull);

    final atNoon = QiyamNight.resolve(
      nowUtc: DateTime.utc(2026, 11, 12, 10),
      input: QiyamNoSchedule(
        deviceLocal: DateTime(2026, 11, 12, 12),
        zoneId: 'UTC',
        zoneOffsetMinutes: 0,
      ),
    );
    expect(atNoon.nightDate, '2026-11-12');
    expect(atNoon.editable, isTrue);
  });

  test('without a schedule a morning on the 1st belongs to the previous '
      'month\'s last night', () {
    final state = QiyamNight.resolve(
      nowUtc: DateTime.utc(2027, 3, 1, 8),
      input: QiyamNoSchedule(
        deviceLocal: DateTime(2027, 3, 1, 10),
        zoneId: 'UTC',
        zoneOffsetMinutes: 0,
      ),
    );
    expect(state.nightDate, '2027-02-28');
  });

  test('without a schedule the next refresh is the next local noon', () {
    final state = QiyamNight.resolve(
      nowUtc: DateTime.utc(2026, 11, 12, 9, 59),
      input: QiyamNoSchedule(
        deviceLocal: DateTime(2026, 11, 12, 11, 59),
        zoneId: 'UTC',
        zoneOffsetMinutes: 0,
      ),
    );
    expect(state.nextBoundaryUtc, DateTime(2026, 11, 12, 12).toUtc());
  });

  test('the last third equals the shared Prayer projection', () {
    final projected = projectedLastThird(
      '2026-11-11',
      wednesdayMaghrib,
      thursdayFajr,
    );
    final state = QiyamNight.resolve(
      nowUtc: DateTime.utc(2026, 11, 12, 3),
      input: QiyamScheduledNight(
        zoneOffsetMinutes: 0,
        boundaries: nightBoundaries(
          '2026-11-11',
          wednesdayMaghrib,
          thursdayFajr,
          lastThirdUtc: projected,
        ),
      ),
    );
    expect(state.lastThirdUtc, projected);
    expect(state.lastThirdAvailable, isTrue);
  });

  test('a DST shift keeps the resolution instant-based', () {
    // Europe/Oslo ends DST on 2026-10-25: Maghrib 17:20 local (16:20Z), the
    // next Fajr 06:29 local (05:29Z).
    final dstMaghrib = DateTime.utc(2026, 10, 25, 16, 20);
    final dstFajr = DateTime.utc(2026, 10, 26, 5, 29);
    final state = QiyamNight.resolve(
      nowUtc: DateTime.utc(2026, 10, 26, 3),
      input: QiyamScheduledNight(
        zoneOffsetMinutes: 0,
        boundaries: QiyamNightBoundaries(
          maghribUtc: dstMaghrib,
          nextFajrUtc: dstFajr,
          lastThirdUtc: projectedLastThird('2026-10-25', dstMaghrib, dstFajr),
          nightDay: '2026-10-25',
          zoneId: 'Europe/Oslo',
        ),
      ),
    );
    expect(state.nightDate, '2026-10-25');
    expect(
      state.lastThirdUtc,
      projectedLastThird('2026-10-25', dstMaghrib, dstFajr),
    );
  });

  test('an unavailable schedule locks recording with no fallback', () {
    final state = QiyamNight.resolve(
      nowUtc: DateTime.utc(2026, 11, 12, 3),
      input: const QiyamScheduleUnavailable(),
    );
    expect(state.scheduleState, QiyamScheduleState.unavailable);
    expect(state.nightDate, isNull);
    expect(state.editable, isFalse);
    expect(state.lastThirdUtc, isNull);
    expect(state.nextBoundaryUtc, isNull);
  });

  group('the night\'s Isha (the window of the start and end times)', () {
    final isha = DateTime.utc(2026, 11, 11, 18, 20);

    QiyamNightBoundaries withIsha(DateTime? ishaUtc) => QiyamNightBoundaries(
      maghribUtc: wednesdayMaghrib,
      nextFajrUtc: thursdayFajr,
      lastThirdUtc: DateTime.utc(2026, 11, 12, 1, 36),
      nightDay: '2026-11-11',
      zoneId: 'UTC',
      ishaUtc: ishaUtc,
    );

    test('an Isha between Maghrib and the next Fajr is kept', () {
      expect(withIsha(isha).ishaUtc, isha);
    });

    test('Isha is optional', () {
      expect(withIsha(null).ishaUtc, isNull);
    });

    test('an Isha at or before Maghrib, at or after the next Fajr, or not in '
        'UTC is rejected', () {
      expect(() => withIsha(wednesdayMaghrib), throwsArgumentError);
      expect(
        () => withIsha(wednesdayMaghrib.subtract(const Duration(minutes: 1))),
        throwsArgumentError,
      );
      expect(() => withIsha(thursdayFajr), throwsArgumentError);
      expect(
        () => withIsha(thursdayFajr.add(const Duration(minutes: 1))),
        throwsArgumentError,
      );
      expect(
        () => withIsha(DateTime(2026, 11, 11, 20, 20)),
        throwsArgumentError,
        reason: 'a local-time instant is not UTC',
      );
    });

    test('the resolved night carries Isha and the last Fajr', () {
      final state = QiyamNight.resolve(
        nowUtc: DateTime.utc(2026, 11, 12, 3),
        input: QiyamScheduledNight(
          zoneOffsetMinutes: 0,
          boundaries: withIsha(isha),
          nextMaghribUtc: thursdayMaghrib,
        ),
      );
      expect(state.ishaUtc, isha);
      expect(state.nextFajrUtc, thursdayFajr);
    });

    test('a night with no Isha still carries the last Fajr', () {
      final state = QiyamNight.resolve(
        nowUtc: DateTime.utc(2026, 11, 12, 3),
        input: QiyamScheduledNight(
          zoneOffsetMinutes: 0,
          boundaries: withIsha(null),
        ),
      );
      expect(state.ishaUtc, isNull);
      expect(state.nextFajrUtc, thursdayFajr);
    });

    test('no schedule and an unavailable schedule have no window', () {
      final none = QiyamNight.resolve(
        nowUtc: DateTime.utc(2026, 11, 12, 3),
        input: QiyamNoSchedule(
          deviceLocal: DateTime(2026, 11, 12, 5),
          zoneId: 'UTC+02:00',
          zoneOffsetMinutes: 120,
        ),
      );
      expect(none.ishaUtc, isNull);
      expect(none.nextFajrUtc, isNull);
      final unavailable = QiyamNight.resolve(
        nowUtc: DateTime.utc(2026, 11, 12, 3),
        input: const QiyamScheduleUnavailable(),
      );
      expect(unavailable.ishaUtc, isNull);
      expect(unavailable.nextFajrUtc, isNull);
    });
  });

  test('unordered boundary instants are rejected at construction', () {
    expect(
      () => QiyamNightBoundaries(
        maghribUtc: thursdayMaghrib,
        nextFajrUtc: thursdayFajr,
        lastThirdUtc: thursdayFajr,
        nightDay: '2026-11-12',
        zoneId: 'UTC',
      ),
      throwsArgumentError,
    );
    expect(
      () => QiyamNightBoundaries(
        maghribUtc: wednesdayMaghrib,
        nextFajrUtc: thursdayFajr,
        lastThirdUtc: wednesdayMaghrib.subtract(const Duration(minutes: 1)),
        nightDay: '2026-11-11',
        zoneId: 'UTC',
      ),
      throwsArgumentError,
    );
  });
}

/// A minimal schedule carrying only the one boundary instant the Qiyam night
/// window needs; the other prayers report unavailable.
PrayerSchedule _boundarySchedule(
  PrayerLocalDate date,
  DateTime instantUtc,
  PrayerName available,
) => PrayerSchedule(
  date: date,
  contextRevision: 1,
  provenance: 'qiyam night boundaries',
  times: {
    for (final name in PrayerName.values)
      name: name == available
          ? PrayerTime(name: name, instantUtc: instantUtc)
          : PrayerTime(
              name: name,
              instantUtc: null,
              unavailableReason: 'not used for the Qiyam night window',
            ),
  },
);

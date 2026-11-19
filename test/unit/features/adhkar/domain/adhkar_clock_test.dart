import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';

/// T020: AdhkarClock vectors. The Adhkar day is the civil date of the Fajr
/// that opened it; Morning runs Fajr->Maghrib and Evening Maghrib->next
/// Fajr. Before Fajr the caller asks for the previous day's boundaries, so
/// the vectors express "previous day's Evening" through those boundaries
/// (research.md R3). Unavailable keeps the lists visible but locks counting
/// (owner decision, 2026-11-10); it never falls back to calendar days.
void main() {
  // A scheduled day D: Fajr 04:30, Maghrib 16:50, next Fajr (D+1) 04:29.
  final fajr = DateTime.utc(2026, 11, 10, 4, 30);
  final maghrib = DateTime.utc(2026, 11, 10, 16, 50);
  final nextFajr = DateTime.utc(2026, 11, 11, 4, 29);
  final day = AdhkarDayBoundaries(
    fajrUtc: fajr,
    maghribUtc: maghrib,
    nextFajrUtc: nextFajr,
    fajrDay: '2026-11-10',
    zoneId: 'UTC',
  );

  test('before Fajr the previous day is still in its Evening', () {
    // The caller asked for D-1: its Evening runs to Fajr of D.
    final previousDay = AdhkarDayBoundaries(
      fajrUtc: DateTime.utc(2026, 11, 9, 4, 31),
      maghribUtc: DateTime.utc(2026, 11, 9, 16, 51),
      nextFajrUtc: fajr,
      fajrDay: '2026-11-09',
      zoneId: 'UTC',
    );
    final state = AdhkarClock.resolve(
      nowUtc: DateTime.utc(2026, 11, 10, 1),
      input: AdhkarScheduledDay(boundaries: previousDay),
    );
    expect(state.scheduleState, AdhkarScheduleState.available);
    expect(state.day, '2026-11-09');
    expect(state.period, AdhkarPeriod.evening);
    expect(state.eveningCountable, isTrue);
    expect(state.morningCountable, isFalse);
    expect(state.nextBoundaryUtc, fajr);
  });

  test('Fajr to Maghrib is Morning on the Fajr day', () {
    final state = AdhkarClock.resolve(
      nowUtc: DateTime.utc(2026, 11, 10, 12),
      input: AdhkarScheduledDay(boundaries: day),
    );
    expect(state.day, '2026-11-10');
    expect(state.period, AdhkarPeriod.morning);
    expect(state.morningCountable, isTrue);
    expect(state.eveningCountable, isFalse);
    expect(state.nextBoundaryUtc, maghrib);
  });

  test('Maghrib to midnight and midnight to Fajr are the same Evening', () {
    final eveningState = AdhkarClock.resolve(
      nowUtc: DateTime.utc(2026, 11, 10, 23),
      input: AdhkarScheduledDay(boundaries: day),
    );
    expect(eveningState.day, '2026-11-10');
    expect(eveningState.period, AdhkarPeriod.evening);
    expect(eveningState.eveningCountable, isTrue);
    expect(eveningState.nextBoundaryUtc, nextFajr);
    // Counting Evening after midnight still belongs to the same Adhkar day.
    final afterMidnightState = AdhkarClock.resolve(
      nowUtc: DateTime.utc(2026, 11, 11, 0, 30),
      input: AdhkarScheduledDay(boundaries: day),
    );
    expect(afterMidnightState.day, '2026-11-10');
    expect(afterMidnightState.period, AdhkarPeriod.evening);
    expect(afterMidnightState.eveningCountable, isTrue);
    expect(afterMidnightState.nextBoundaryUtc, nextFajr);
  });

  test('at the boundaries themselves the new period is already active', () {
    final atFajr = AdhkarClock.resolve(
      nowUtc: fajr,
      input: AdhkarScheduledDay(boundaries: day),
    );
    expect(atFajr.period, AdhkarPeriod.morning);
    final atMaghrib = AdhkarClock.resolve(
      nowUtc: maghrib,
      input: AdhkarScheduledDay(boundaries: day),
    );
    expect(atMaghrib.period, AdhkarPeriod.evening);
    // At next Fajr the caller must already be asking for the next day; the
    // clock rejects a day whose window has ended.
    expect(
      () => AdhkarClock.resolve(
        nowUtc: nextFajr,
        input: AdhkarScheduledDay(boundaries: day),
      ),
      throwsArgumentError,
    );
  });

  test('no schedule is unrestricted on the device calendar day', () {
    final state = AdhkarClock.resolve(
      nowUtc: DateTime.utc(2026, 11, 10, 23),
      input: const AdhkarNoSchedule(deviceDay: '2026-11-10'),
    );
    expect(state.scheduleState, AdhkarScheduleState.setupRequired);
    expect(state.day, '2026-11-10');
    expect(state.period, AdhkarPeriod.unrestricted);
    expect(state.morningCountable, isTrue);
    expect(state.eveningCountable, isTrue);
    expect(state.nextBoundaryUtc, isNull);
  });

  test('unavailable keeps the lists visible but locks both counts', () {
    final state = AdhkarClock.resolve(
      nowUtc: DateTime.utc(2026, 11, 10, 12),
      input: const AdhkarScheduleUnavailable(),
    );
    expect(state.scheduleState, AdhkarScheduleState.unavailable);
    expect(state.day, isNull);
    expect(state.period, isNull);
    expect(state.morningCountable, isFalse);
    expect(state.eveningCountable, isFalse);
    expect(state.nextBoundaryUtc, isNull);
  });

  test('a DST shift keeps the resolution instant-based', () {
    // Europe/Oslo ends DST on 2026-10-25: Fajr 06:30 local (04:30 UTC),
    // Maghrib 17:20 local (16:20 UTC), next Fajr 06:29 local (05:29 UTC).
    final dstDay = AdhkarDayBoundaries(
      fajrUtc: DateTime.utc(2026, 10, 25, 4, 30),
      maghribUtc: DateTime.utc(2026, 10, 25, 16, 20),
      nextFajrUtc: DateTime.utc(2026, 10, 26, 5, 29),
      fajrDay: '2026-10-25',
      zoneId: 'Europe/Oslo',
    );
    final morning = AdhkarClock.resolve(
      nowUtc: DateTime.utc(2026, 10, 25, 12),
      input: AdhkarScheduledDay(boundaries: dstDay),
    );
    expect(morning.period, AdhkarPeriod.morning);
    expect(morning.day, '2026-10-25');
    final evening = AdhkarClock.resolve(
      nowUtc: DateTime.utc(2026, 10, 25, 21),
      input: AdhkarScheduledDay(boundaries: dstDay),
    );
    expect(evening.period, AdhkarPeriod.evening);
    expect(evening.nextBoundaryUtc, DateTime.utc(2026, 10, 26, 5, 29));
  });

  test('the state exposes the notice instants for the read-only list', () {
    final state = AdhkarClock.resolve(
      nowUtc: DateTime.utc(2026, 11, 10, 12),
      input: AdhkarScheduledDay(boundaries: day),
    );
    // Morning is countable; the Evening notice can show when it starts.
    expect(state.maghribUtc, maghrib);
    expect(state.fajrUtc, fajr);
  });
}

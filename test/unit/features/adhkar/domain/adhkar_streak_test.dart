import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_streak.dart';

/// T022: the Adhkar streak is derived, never stored (FR-006b): consecutive
/// Adhkar days on which BOTH lists were complete. The current day does not
/// break the streak before it ends. The walk trusts the per-day completion
/// it is given (the repository judges each day against that day's recorded
/// catalog version), so a version change keeps past days valid.
void main() {
  AdhkarDayCompletion both() =>
      const AdhkarDayCompletion(morningComplete: true, eveningComplete: true);
  AdhkarDayCompletion morningOnly() =>
      const AdhkarDayCompletion(morningComplete: true, eveningComplete: false);

  test('three complete days plus a partial today give 3, then 4', () {
    final completions = {
      '2026-11-07': both(),
      '2026-11-08': both(),
      '2026-11-09': both(),
      '2026-11-10': morningOnly(),
    };
    expect(adhkarStreak(completions: completions, today: '2026-11-10'), 3);
    final completeToday = Map.of(completions)..['2026-11-10'] = both();
    expect(adhkarStreak(completions: completeToday, today: '2026-11-10'), 4);
  });

  test('a gap resets the count', () {
    final completions = {
      '2026-11-06': both(),
      '2026-11-07': both(),
      // 11-08 missing entirely.
      '2026-11-09': both(),
      '2026-11-10': both(),
    };
    expect(adhkarStreak(completions: completions, today: '2026-11-10'), 2);
  });

  test('one list only does not count', () {
    final completions = {
      '2026-11-08': both(),
      '2026-11-09': morningOnly(),
      '2026-11-10': both(),
    };
    expect(adhkarStreak(completions: completions, today: '2026-11-10'), 1);
  });

  test('an explicit incomplete record and a missing record behave alike', () {
    final explicit = {
      '2026-11-09': const AdhkarDayCompletion(
        morningComplete: false,
        eveningComplete: false,
      ),
      '2026-11-10': both(),
    };
    expect(adhkarStreak(completions: explicit, today: '2026-11-10'), 1);
  });

  test('the walk caps at 3650 days', () {
    var day = DateTime.utc(2026, 11, 10);
    final completions = <String, AdhkarDayCompletion>{};
    for (var i = 0; i < 3700; i++) {
      completions[_key(day)] = both();
      day = day.subtract(const Duration(days: 1));
    }
    expect(adhkarStreak(completions: completions, today: '2026-11-10'), 3650);
  });

  test('a catalog version change keeps past days valid', () {
    // The completion values arrive already judged against each day's own
    // recorded catalog version; the walk itself never filters by version.
    final completions = {
      '2026-11-08': both(), // completed under catalog v1
      '2026-11-09': both(), // completed under catalog v2
      '2026-11-10': both(),
    };
    expect(adhkarStreak(completions: completions, today: '2026-11-10'), 3);
  });
}

String _key(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

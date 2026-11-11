import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_streak.dart';

/// T051: the derived Qiyam streak (research.md R9): consecutive performed
/// nights walked back from the current night with an early exit at the
/// first night that breaks the run, capped at 3,650 visited nights. An
/// unanswered current night does not break the run (the night is still
/// ahead); an explicit "No" is definitive and breaks it, and so does an
/// earlier night with no record. A failed lookup propagates — a failed read
/// is never a streak of 0.
void main() {
  final counts = <String, int>{};

  setUp(counts.clear);

  /// A lookup over [performed] and [no] night-date keys; it counts every
  /// call so the tests can prove the walk stops asking once the run breaks.
  QiyamNightVerdictLookup lookup({
    Iterable<String> performed = const [],
    Iterable<String> no = const [],
  }) {
    final performedNights = performed.toSet();
    final noNights = no.toSet();
    return (nightDate) async {
      counts[nightDate] = (counts[nightDate] ?? 0) + 1;
      if (performedNights.contains(nightDate)) {
        return QiyamNightVerdict.performed;
      }
      if (noNights.contains(nightDate)) {
        return QiyamNightVerdict.notPerformed;
      }
      return null;
    };
  }

  test(
    'counts consecutive performed nights back from the current one',
    () async {
      final streak = await qiyamStreak(
        currentNight: '2026-11-11',
        verdictOf: lookup(
          performed: ['2026-11-11', '2026-11-10', '2026-11-09', '2026-11-08'],
        ),
      );
      expect(streak, 4);
    },
  );

  test('a gap — a night with no record — ends the run', () async {
    final streak = await qiyamStreak(
      currentNight: '2026-11-11',
      verdictOf: lookup(performed: ['2026-11-11', '2026-11-10', '2026-11-08']),
    );
    expect(streak, 2);
    expect(counts['2026-11-07'], isNull, reason: 'the walk stopped early');
  });

  test('an earlier explicit "No" ends the run', () async {
    final streak = await qiyamStreak(
      currentNight: '2026-11-11',
      verdictOf: lookup(
        performed: ['2026-11-11', '2026-11-10'],
        no: ['2026-11-09'],
      ),
    );
    expect(streak, 2);
  });

  test('an explicit "No" tonight is definitive and breaks the run', () async {
    final streak = await qiyamStreak(
      currentNight: '2026-11-11',
      verdictOf: lookup(
        performed: ['2026-11-10', '2026-11-09'],
        no: ['2026-11-11'],
      ),
    );
    expect(streak, 0);
    expect(counts['2026-11-10'], isNull, reason: 'the walk stopped early');
  });

  test(
    'an unanswered current night does not break the run behind it',
    () async {
      final streak = await qiyamStreak(
        currentNight: '2026-11-11',
        verdictOf: lookup(performed: ['2026-11-10', '2026-11-09']),
      );
      expect(streak, 2);
    },
  );

  test('the walk is capped at 3,650 visited nights and stops asking', () async {
    final performed = <String>[
      for (var i = 0; i < 3651; i++) _day(DateTime.utc(2026, 11, 11 - i)),
    ];
    var calls = 0;
    final streak = await qiyamStreak(
      currentNight: '2026-11-11',
      verdictOf: (nightDate) async {
        calls++;
        return performed.contains(nightDate)
            ? QiyamNightVerdict.performed
            : null;
      },
    );
    expect(streak, kQiyamStreakWalkCapNights);
    expect(
      calls,
      kQiyamStreakWalkCapNights,
      reason: 'the cap bounds the walk; the nights beyond it are not read',
    );
  });

  test('exactly the cap is reached without truncation', () async {
    final streak = await qiyamStreak(
      currentNight: '2026-11-11',
      verdictOf: lookup(
        performed: [
          for (var i = 0; i < 3650; i++) _day(DateTime.utc(2026, 11, 11 - i)),
        ],
      ),
    );
    expect(streak, 3650);
  });

  test(
    'a time-zone change that skips a night date breaks at the absent '
    'night; nights from either zone count while they are consecutive',
    () async {
      // The records were made in Cairo up to 2026-11-08; after the zone change
      // the resolved current night is 2026-11-10 — 2026-11-09 has no row.
      final streak = await qiyamStreak(
        currentNight: '2026-11-10',
        verdictOf: lookup(
          performed: ['2026-11-10', '2026-11-08', '2026-11-07'],
        ),
      );
      expect(streak, 1);
    },
  );

  test(
    'a failed lookup propagates; a failed read is never a streak of 0',
    () async {
      await expectLater(
        qiyamStreak(
          currentNight: '2026-11-11',
          verdictOf: (nightDate) => throw StateError('store unavailable'),
        ),
        throwsStateError,
      );
    },
  );
}

String _day(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

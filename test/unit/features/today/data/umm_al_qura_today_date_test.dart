import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/presentation/umm_al_qura_today_date.dart';

void main() {
  group('UmmAlQuraTodayDate', () {
    test('matches verified Umm al-Qura month and year boundaries', () {
      expect(
        UmmAlQuraTodayDate.fromLocalDate(TodayLocalDate(2024, 3, 10)),
        const UmmAlQuraTodayDate(year: 1445, month: 8, day: 29),
      );
      expect(
        UmmAlQuraTodayDate.fromLocalDate(TodayLocalDate(2024, 3, 11)),
        const UmmAlQuraTodayDate(year: 1445, month: 9, day: 1),
      );
      expect(
        UmmAlQuraTodayDate.fromLocalDate(TodayLocalDate(2024, 7, 7)),
        const UmmAlQuraTodayDate(year: 1446, month: 1, day: 1),
      );
    });

    test(
      'uses the supplied local civil day and never samples another clock',
      () {
        final beforeMidnight = TodayLocalDate(2024, 3, 10);
        final afterMidnight = TodayLocalDate(2024, 3, 11);

        expect(
          UmmAlQuraTodayDate.fromLocalDate(beforeMidnight),
          isNot(UmmAlQuraTodayDate.fromLocalDate(afterMidnight)),
        );
      },
    );

    test(
      'returns unavailable outside the verified table instead of guessing',
      () {
        expect(
          UmmAlQuraTodayDate.fromLocalDate(TodayLocalDate(1800, 1, 1)),
          isNull,
        );
      },
    );
  });
}

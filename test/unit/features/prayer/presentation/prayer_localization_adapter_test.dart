import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:namma_project/app/l10n/prayer_localization_adapter.dart';
import 'package:namma_project/features/prayer/domain/prayer_local_date.dart';

void main() {
  test('city civil date is formatted in the chosen UI language', () async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
    final date = PrayerLocalDate.parse('2026-03-08');
    final english = prayerLocalDateLabel(date, 'en');
    final arabic = prayerLocalDateLabel(date, 'ar');
    expect(english, contains('March'));
    expect(arabic, contains('مارس'));
    expect(english, isNot(arabic));
  });
}

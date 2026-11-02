import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/prayer/data/prayer_timezone_initializer.dart';
import '../../features/prayer/domain/prayer_local_date.dart';
import '../../features/prayer/domain/prayer_name.dart';
import 'generated/app_localizations.dart';

String prayerNameLabel(FoundationLocalizations copy, PrayerName name) =>
    switch (name) {
      PrayerName.fajr => copy.prayerFajr,
      PrayerName.dhuhr => copy.prayerDhuhr,
      PrayerName.asr => copy.prayerAsr,
      PrayerName.maghrib => copy.prayerMaghrib,
      PrayerName.isha => copy.prayerIsha,
    };

String prayerMethodLabel(FoundationLocalizations copy, String key) =>
    switch (key) {
      'egyptian' => copy.prayerEgyptian,
      'muslimWorldLeague' => copy.prayerMwl,
      'ummAlQura' => copy.prayerUmmAlQura,
      'dubai' => copy.prayerDubai,
      'northAmerica' => copy.prayerNorthAmerica,
      'kuwait' => copy.prayerKuwait,
      'qatar' => copy.prayerQatar,
      _ => key,
    };

String prayerLocalTime(DateTime instantUtc, String zone, String locale) {
  initializePrayerTimeZones();
  final cityTime = tz.TZDateTime.from(instantUtc, tz.getLocation(zone));
  return DateFormat.jm(locale).format(cityTime);
}

String prayerLocalDateLabel(PrayerLocalDate date, String locale) {
  final parts = date.value.split('-').map(int.parse).toList();
  return DateFormat.yMMMMEEEEd(
    locale,
  ).format(DateTime.utc(parts[0], parts[1], parts[2]));
}

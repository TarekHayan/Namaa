import '../domain/today_prayer_reference.dart';

abstract interface class TodayPrayerPort {
  Stream<TodayPrayerReference> watchPrayer(String ownerId);
}

import 'package:namma_project/core/domain/results/app_result.dart';
import '../domain/adhkar_clock.dart';

/// The Adhkar time authority for one owner (contracts/
/// adhkar-qiyam-application.md): implemented in composition by a
/// `PrayerDayBoundaries` adapter (T028). It resolves the clock state for the
/// given instant, which the caller samples once per command.
abstract interface class AdhkarTimesPort {
  Future<AppResult<AdhkarClockState>> resolve(String ownerId, DateTime nowUtc);
}

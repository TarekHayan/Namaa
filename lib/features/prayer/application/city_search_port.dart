import 'package:namma_project/core/domain/results/app_result.dart';
import '../domain/prayer_city.dart';

abstract interface class CitySearchPort {
  Future<AppResult<List<PrayerCity>>> search({
    required String query,
    required String locale,
    required String ownerId,
    required int generation,
  });

  void cancel({required String ownerId, required int generation});
}

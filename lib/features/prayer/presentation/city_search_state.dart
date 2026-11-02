import 'package:namma_project/core/domain/failures/app_failure.dart';

import '../domain/prayer_city.dart';

enum CitySearchPhase {
  idle,
  searching,
  results,
  noResults,
  offline,
  throttled,
  invalidResponse,
  unavailable,
  saving,
  saved,
}

final class CitySearchState {
  const CitySearchState({
    this.phase = CitySearchPhase.idle,
    this.query = '',
    this.results = const [],
    this.candidate,
    this.failure,
  });
  final CitySearchPhase phase;
  final String query;
  final List<PrayerCity> results;
  final PrayerCity? candidate;
  final AppFailure? failure;
}

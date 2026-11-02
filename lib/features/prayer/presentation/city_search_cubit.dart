import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/city_search_port.dart';
import '../application/prayer_preferences_commands.dart';
import '../domain/prayer_city.dart';
import 'city_search_state.dart';

final class CitySearchCubit extends Cubit<CitySearchState> {
  CitySearchCubit({
    required CitySearchPort search,
    required PrayerPreferencesCommands commands,
    required String ownerId,
    required String locale,
    Duration debounce = const Duration(milliseconds: 350),
  }) : _search = search,
       _commands = commands,
       _ownerId = ownerId,
       _locale = locale,
       _debounce = debounce,
       super(const CitySearchState());

  final CitySearchPort _search;
  final PrayerPreferencesCommands _commands;
  final String _ownerId;
  final Duration _debounce;
  String _locale;
  Timer? _timer;
  int _generation = 0;

  void updateLocale(String locale) {
    if (locale == _locale) return;
    _locale = locale;
    updateQuery(state.query);
  }

  void updateQuery(String query) {
    final previous = _generation++;
    _timer?.cancel();
    _search.cancel(ownerId: _ownerId, generation: previous);
    final trimmed = query.trim();
    if (trimmed.length < 2 || trimmed.length > 100) {
      emit(CitySearchState(query: query));
      return;
    }
    emit(CitySearchState(query: query, phase: CitySearchPhase.searching));
    final generation = _generation;
    _timer = Timer(_debounce, () => unawaited(_run(query, generation)));
  }

  Future<void> _run(String query, int generation) async {
    final result = await _search.search(
      query: query,
      locale: _locale,
      ownerId: _ownerId,
      generation: generation,
    );
    if (isClosed || generation != _generation) return;
    final cities = result.valueOrNull;
    if (cities != null) {
      emit(
        CitySearchState(
          query: query,
          results: cities,
          phase: cities.isEmpty
              ? CitySearchPhase.noResults
              : CitySearchPhase.results,
        ),
      );
      return;
    }
    final failure = result.failureOrNull!;
    emit(
      CitySearchState(
        query: query,
        failure: failure,
        phase: switch (failure.messageKey) {
          'prayerSearchThrottled' => CitySearchPhase.throttled,
          'prayerSearchInvalidResponse' => CitySearchPhase.invalidResponse,
          'prayerSearchUnavailable' => CitySearchPhase.unavailable,
          _ => CitySearchPhase.offline,
        },
      ),
    );
  }

  void select(PrayerCity city) {
    if (!state.results.contains(city)) return;
    emit(
      CitySearchState(
        query: state.query,
        results: state.results,
        phase: CitySearchPhase.results,
        candidate: city,
      ),
    );
  }

  Future<bool> confirm({
    required String method,
    required int? expectedRevision,
  }) async {
    final city = state.candidate;
    if (city == null) return false;
    final generation = _generation;
    emit(
      CitySearchState(
        query: state.query,
        results: state.results,
        candidate: city,
        phase: CitySearchPhase.saving,
      ),
    );
    final result = await _commands.confirm(
      ownerId: _ownerId,
      city: city,
      method: method,
      expectedRevision: expectedRevision,
      nowUtc: DateTime.now().toUtc(),
    );
    if (isClosed || generation != _generation) return false;
    if (result.failureOrNull case final failure?) {
      emit(
        CitySearchState(
          query: state.query,
          results: state.results,
          candidate: city,
          phase: CitySearchPhase.results,
          failure: failure,
        ),
      );
      return false;
    }
    emit(
      CitySearchState(
        query: state.query,
        results: state.results,
        candidate: city,
        phase: CitySearchPhase.saved,
      ),
    );
    return true;
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _search.cancel(ownerId: _ownerId, generation: _generation);
    await super.close();
  }
}

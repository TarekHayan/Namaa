import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/features/mind_maps/application/map_queries.dart';
import 'package:namma_project/features/mind_maps/application/map_sync_service.dart';

sealed class MapLibraryState {
  const MapLibraryState();
}

final class MapLibraryInitial extends MapLibraryState {
  const MapLibraryInitial();
}

final class MapLibraryLoading extends MapLibraryState {
  const MapLibraryLoading();
}

final class MapLibraryFailure extends MapLibraryState {
  const MapLibraryFailure(this.failure);
  final AppFailure failure;
}

final class MapLibraryReady extends MapLibraryState {
  MapLibraryReady({
    required this.ownerId,
    required this.hasMaps,
    required Iterable<MapSummary> maps,
    required this.searchText,
    this.lastFailure,
    this.syncStatus = MapSyncStatus.idle,
  }) : maps = List.unmodifiable(maps);

  final String ownerId;
  final bool hasMaps;
  final List<MapSummary> maps;
  final String searchText;
  final AppFailure? lastFailure;
  final MapSyncStatus syncStatus;
}

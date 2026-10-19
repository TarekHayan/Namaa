import 'package:namma_project/core/domain/failures/app_failure.dart';

import '../application/map_queries.dart';
import '../application/map_reconciliation.dart';
import '../application/map_repository.dart';
import '../application/map_sync_service.dart';
import '../application/map_task_link_port.dart';

sealed class MapEditorState {
  const MapEditorState();
}

final class MapEditorLoading extends MapEditorState {
  const MapEditorLoading();
}

final class MapEditorUnavailable extends MapEditorState {
  const MapEditorUnavailable(this.failure);
  final AppFailure? failure;
}

final class MapEditorReady extends MapEditorState {
  MapEditorReady({
    required this.graph,
    required this.selectedId,
    required this.canUndo,
    required this.canRedo,
    required this.busy,
    this.failure,
    this.linkedTasks = const {},
    this.syncStatus = MapSyncStatus.idle,
    this.conflicts = const [],
  }) : summary = MapQueries.summary(graph, tasks: linkedTasks);

  final MapGraph graph;
  final MapSummary summary;
  final String selectedId;
  final bool canUndo;
  final bool canRedo;
  final bool busy;
  final AppFailure? failure;
  final Map<String, MapLinkedTask> linkedTasks;
  final MapSyncStatus syncStatus;
  final List<MapConflictView> conflicts;
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../application/map_editor_history.dart';
import '../application/map_graph_commands.dart';
import '../application/map_repository.dart';
import '../domain/mind_map.dart';
import '../domain/mind_map_node.dart';
import 'map_editor_state.dart';

final class MapEditorCubit extends Cubit<MapEditorState> {
  MapEditorCubit({
    required MapRepository repository,
    required MapGraphCommands commands,
    required MapEditorHistory history,
    required this.ownerId,
    required this.mapId,
  }) : _repository = repository,
       _commands = commands,
       _history = history,
       super(const MapEditorLoading()) {
    _subscription = _repository
        .watchGraph(ownerId: ownerId, mapId: mapId)
        .listen(
          (graph) {
            if (isClosed) return;
            if (graph == null) {
              emit(const MapEditorUnavailable(null));
            } else {
              _graph = graph;
              if (!graph.nodes.any((n) => n.id == _selectedId)) {
                _selectedId = graph.map.centralNodeId;
              }
              _emitReady();
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!isClosed) emit(MapEditorUnavailable(_failure()));
          },
        );
  }

  final MapRepository _repository;
  final MapGraphCommands _commands;
  final MapEditorHistory _history;
  final String ownerId;
  final String mapId;
  StreamSubscription<MapGraph?>? _subscription;
  MapGraph? _graph;
  String? _selectedId;
  AppFailure? _lastFailure;
  bool _busy = false;

  void select(String id) {
    if (_graph?.nodes.any((node) => node.id == id) ?? false) {
      _selectedId = id;
      _emitReady();
    }
  }

  Future<bool> addNode({
    required MindMapNodeKind kind,
    required String title,
    String? description,
    MindMapNodePriority priority = MindMapNodePriority.medium,
    String? parentId,
    double x = 0,
    double y = 0,
  }) => _perform(
    () => _commands.addNode(
      mapId: mapId,
      kind: kind,
      title: title,
      description: description,
      priority: priority,
      parentId: parentId,
      x: x,
      y: y,
      expectedOwnerId: ownerId,
    ),
    selectNew: true,
  );

  Future<bool> editNode({
    required String nodeId,
    String? title,
    String? description,
    bool editDescription = false,
    MindMapNodePriority? priority,
    MindMapNodeStatus? status,
    double? x,
    double? y,
  }) => _perform(
    () => _commands.editNode(
      mapId: mapId,
      nodeId: nodeId,
      title: title,
      description: description,
      editDescription: editDescription,
      priority: priority,
      status: status,
      x: x,
      y: y,
      expectedOwnerId: ownerId,
    ),
  );

  Future<bool> deleteNode(String id) => _perform(
    () => _commands.deleteNode(
      mapId: mapId,
      nodeId: id,
      confirmed: true,
      expectedOwnerId: ownerId,
    ),
  );

  Future<bool> setParent(String child, String? parent) => _perform(
    () => _commands.setParent(
      mapId: mapId,
      childId: child,
      parentId: parent,
      expectedOwnerId: ownerId,
    ),
  );

  Future<bool> setSideLink(String a, String b, bool connected) => _perform(
    () => _commands.setSideLink(
      mapId: mapId,
      firstId: a,
      secondId: b,
      connected: connected,
      expectedOwnerId: ownerId,
    ),
  );

  Future<bool> updateSettings(MindMapSettings settings) => _perform(
    () => _commands.updateSettings(
      mapId: mapId,
      settings: settings,
      expectedOwnerId: ownerId,
    ),
  );

  Future<bool> undo() => _historyAction(_history.undo);
  Future<bool> redo() => _historyAction(_history.redo);

  Future<bool> _perform(
    Future<AppResult<GraphEdit>> Function() action, {
    bool selectNew = false,
  }) async {
    if (_busy) return false;
    _busy = true;
    _emitReady();
    final result = await action();
    _busy = false;
    _lastFailure = result.failureOrNull;
    if (result.valueOrNull case final edit?) {
      _history.record(edit);
      if (selectNew && edit.nodes.isNotEmpty) {
        _selectedId = edit.nodes.first.after.id;
      }
      await _refreshConfirmedGraph();
    }
    _emitReady();
    return result.failureOrNull == null;
  }

  Future<bool> _historyAction(Future<AppResult<void>> Function() action) async {
    if (_busy) return false;
    _busy = true;
    _emitReady();
    final result = await action();
    _busy = false;
    _lastFailure = result.failureOrNull;
    if (result.failureOrNull == null) {
      await _refreshConfirmedGraph();
    }
    _emitReady();
    return result.failureOrNull == null;
  }

  void clearFailure() {
    _lastFailure = null;
    _emitReady();
  }

  Future<void> _refreshConfirmedGraph() async {
    final read = await _repository.readGraph(ownerId: ownerId, mapId: mapId);
    if (read.valueOrNull case final graph?) {
      _graph = graph;
      if (!graph.nodes.any((node) => node.id == _selectedId)) {
        _selectedId = graph.map.centralNodeId;
      }
    } else if (read.failureOrNull case final failure?) {
      _lastFailure = failure;
    }
  }

  void _emitReady() {
    final graph = _graph;
    if (isClosed || graph == null) return;
    emit(
      MapEditorReady(
        graph: graph,
        selectedId: _selectedId ?? graph.map.centralNodeId,
        canUndo: _history.canUndo,
        canRedo: _history.canRedo,
        busy: _busy,
        failure: _lastFailure,
      ),
    );
  }

  AppFailure _failure() => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: 'mind_maps.error.load',
    occurredAt: DateTime.now().toUtc(),
  );

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}

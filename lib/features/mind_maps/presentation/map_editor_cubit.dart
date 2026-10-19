import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../application/map_editor_history.dart';
import '../application/map_graph_commands.dart';
import '../application/map_reconciliation.dart';
import '../application/map_repository.dart';
import '../application/map_settings_commands.dart';
import '../application/map_sync_service.dart';
import '../application/map_task_link_commands.dart';
import '../application/map_task_link_port.dart';
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
    MapTaskLinkPort? tasks,
    MapTaskLinkCommands? taskLinks,
    MapSettingsCommands? settingsCommands,
    MapSyncService? syncService,
    MapConflictReaderPort? conflictReader,
    CloudSessionPort? session,
  }) : _repository = repository,
       _commands = commands,
       _history = history,
       _tasks = tasks,
       _taskLinks = taskLinks,
       _settingsCommands = settingsCommands,
       _syncService = syncService,
       _session = session,
       super(const MapEditorLoading()) {
    if (syncService != null) {
      _syncSubscription = syncService.snapshots.listen((_) => _emitReady());
      unawaited(syncService.synchronize());
    }
    if (conflictReader != null) {
      _conflictSubscription = conflictReader
          .watchConflicts(ownerId, mapId)
          .listen((items) {
            _conflicts = items;
            _emitReady();
          });
    }
    if (session != null) {
      _sessionSubscription = session.observeSession().listen((snapshot) {
        if (snapshot.status != CloudSessionStatus.signedIn ||
            snapshot.accountId != ownerId) {
          _graph = null;
          _linkedTasks = {};
          _conflicts = [];
          if (!isClosed) emit(const MapEditorUnavailable(null));
        }
      });
    }
    if (tasks != null) {
      _taskSubscription = tasks
          .watchAccessibleTasks(ownerId)
          .listen(
            (items) {
              _linkedTasks = {for (final item in items) item.id: item};
              _emitReady();
            },
            onError: (_, _) {
              _linkedTasks = {};
              _lastFailure = _failure();
              _emitReady();
            },
          );
    }
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
  final MapTaskLinkPort? _tasks;
  final MapTaskLinkCommands? _taskLinks;
  final MapSettingsCommands? _settingsCommands;
  final MapSyncService? _syncService;
  final CloudSessionPort? _session;
  CloudSessionPort? get session => _session;
  final String ownerId;
  final String mapId;
  StreamSubscription<MapGraph?>? _subscription;
  StreamSubscription<List<MapLinkedTask>>? _taskSubscription;
  StreamSubscription<MapSyncSnapshot>? _syncSubscription;
  StreamSubscription<List<MapConflictView>>? _conflictSubscription;
  StreamSubscription<CloudSessionSnapshot>? _sessionSubscription;
  List<MapConflictView> _conflicts = [];
  Map<String, MapLinkedTask> _linkedTasks = {};
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
    MapNodeAppearance? appearance,
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
      appearance: appearance,
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
    MapNodeAppearance? appearance,
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
      appearance: appearance,
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

  Future<bool> saveSettings(MindMapSettings settings, {required bool rtl}) {
    final commands = _settingsCommands;
    final graph = _graph;
    if (commands == null || graph == null) return Future.value(false);
    final layoutChanged =
        settings.layout != graph.map.settings.layout ||
        settings.spacing != graph.map.settings.spacing;
    return _perform(
      () => layoutChanged && settings.layout != MapLayout.freeform
          ? commands.applyLayout(
              mapId: mapId,
              layout: settings.layout,
              rtl: rtl,
              settings: settings,
              expectedOwnerId: ownerId,
            )
          : commands.saveSettings(
              mapId: mapId,
              settings: settings,
              expectedOwnerId: ownerId,
            ),
    );
  }

  Future<bool> applyLayout(MapLayout layout, {required bool rtl}) {
    final commands = _settingsCommands;
    if (commands == null) return Future.value(false);
    return _perform(
      () => commands.applyLayout(
        mapId: mapId,
        layout: layout,
        rtl: rtl,
        expectedOwnerId: ownerId,
      ),
    );
  }

  MapTaskLinkPort? get taskPort => _tasks;

  Future<bool> setTaskLink(String nodeId, String? taskId) {
    final commands = _taskLinks;
    if (commands == null) return Future.value(false);
    return _perform(
      () => commands.setLink(
        ownerId: ownerId,
        mapId: mapId,
        nodeId: nodeId,
        taskId: taskId,
      ),
    );
  }

  Future<bool> setLinkedInProgress(String nodeId) =>
      editNode(nodeId: nodeId, status: MindMapNodeStatus.inProgress);

  Future<bool> completeLinkedTask(String taskId) => _taskAction(taskId, true);
  Future<bool> reopenLinkedTask(String taskId) => _taskAction(taskId, false);

  Future<bool> _taskAction(String taskId, bool complete) async {
    final tasks = _tasks;
    if (tasks == null || _busy) return false;
    _busy = true;
    _emitReady();
    final result = complete
        ? await tasks.complete(ownerId, taskId)
        : await tasks.reopen(ownerId, taskId);
    _busy = false;
    _lastFailure = result.failureOrNull;
    if (result.failureOrNull == null) {
      final refreshed = await tasks.readLinkedTask(ownerId, taskId);
      if (refreshed.valueOrNull case final task?) {
        _linkedTasks = {..._linkedTasks, taskId: task};
      }
    }
    _emitReady();
    return result.failureOrNull == null;
  }

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
      if (_syncService != null) unawaited(_syncService.synchronize());
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
      if (_syncService != null) unawaited(_syncService.synchronize());
    }
    _emitReady();
    return result.failureOrNull == null;
  }

  void clearFailure() {
    _lastFailure = null;
    _emitReady();
  }

  Future<void> retrySync() async {
    await _syncService?.synchronize();
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
        linkedTasks: _linkedTasks,
        syncStatus: _syncService?.snapshot.status ?? MapSyncStatus.idle,
        conflicts: _conflicts,
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
    await _taskSubscription?.cancel();
    await _syncSubscription?.cancel();
    await _conflictSubscription?.cancel();
    await _sessionSubscription?.cancel();
    await super.close();
  }
}

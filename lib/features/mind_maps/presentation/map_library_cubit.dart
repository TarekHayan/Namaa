import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_queries.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/application/map_task_link_port.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';

import 'map_library_state.dart';

final class MapLibraryCubit extends Cubit<MapLibraryState> {
  MapLibraryCubit({
    required MapRepository repository,
    required MapCommands commands,
    this.session,
    this.tasks,
  }) : _repository = repository,
       _commands = commands,
       super(const MapLibraryInitial());

  final MapRepository _repository;
  final MapCommands _commands;
  MapRepository get repository => _repository;
  final CloudSessionPort? session;
  final MapTaskLinkPort? tasks;
  StreamSubscription<List<MapGraph>>? _subscription;
  StreamSubscription<List<MapLinkedTask>>? _taskSubscription;
  Map<String, MapLinkedTask> _linkedTasks = {};
  String? _ownerId;
  String _search = '';
  List<MapGraph>? _graphs;
  AppFailure? _lastFailure;

  Future<void> load(String ownerId) async {
    if (_ownerId == ownerId && _subscription != null) return;
    await _subscription?.cancel();
    await _taskSubscription?.cancel();
    _ownerId = ownerId;
    _graphs = null;
    _search = '';
    _lastFailure = null;
    _linkedTasks = {};
    emit(const MapLibraryLoading());
    if (tasks != null) {
      _taskSubscription = tasks!.watchAccessibleTasks(ownerId).listen((items) {
        if (isClosed || _ownerId != ownerId) return;
        _linkedTasks = {for (final item in items) item.id: item};
        _emitReady();
      });
    }
    _subscription = _repository
        .watchGraphs(ownerId)
        .listen(
          (graphs) {
            if (isClosed || _ownerId != ownerId) return;
            _graphs = graphs;
            _emitReady();
          },
          onError: (Object error, StackTrace stack) {
            if (isClosed || _ownerId != ownerId) return;
            emit(MapLibraryFailure(_failure('mind_maps.error.load')));
          },
        );
  }

  Future<void> retry() async {
    final owner = _ownerId;
    if (owner == null) return;
    await _subscription?.cancel();
    _subscription = null;
    await load(owner);
  }

  void search(String text) {
    _search = text;
    _emitReady();
  }

  Future<AppResult<MindMap>> create(String title, String? description) =>
      _capture(
        _commands.createMap(
          title: title,
          description: description,
          expectedOwnerId: _ownerId,
        ),
      );

  Future<AppResult<MindMap>> rename(String mapId, String title) => _capture(
    _commands.renameMap(mapId: mapId, title: title, expectedOwnerId: _ownerId),
  );

  Future<AppResult<MindMap>> describe(String mapId, String? description) =>
      _capture(
        _commands.describeMap(
          mapId: mapId,
          description: description,
          expectedOwnerId: _ownerId,
        ),
      );

  Future<AppResult<MindMap>> duplicate(String mapId) =>
      _capture(_commands.duplicateMap(mapId: mapId, expectedOwnerId: _ownerId));

  Future<AppResult<MindMap>> delete(String mapId, {required bool confirmed}) =>
      _capture(
        _commands.deleteMap(
          mapId: mapId,
          confirmed: confirmed,
          expectedOwnerId: _ownerId,
        ),
      );

  Future<AppResult<MindMap>> _capture(Future<AppResult<MindMap>> action) async {
    final owner = _ownerId;
    final result = await action;
    if (!isClosed && owner == _ownerId) {
      _lastFailure = result.failureOrNull;
      _emitReady();
    }
    return result;
  }

  void clearFailure() {
    _lastFailure = null;
    _emitReady();
  }

  void _emitReady() {
    if (isClosed || _ownerId == null || _graphs == null) return;
    final all = MapQueries.search(
      ownerId: _ownerId!,
      graphs: _graphs!,
      text: '',
      tasks: _linkedTasks,
    );
    emit(
      MapLibraryReady(
        ownerId: _ownerId!,
        hasMaps: all.isNotEmpty,
        maps: MapQueries.search(
          ownerId: _ownerId!,
          graphs: _graphs!,
          text: _search,
          tasks: _linkedTasks,
        ),
        searchText: _search,
        lastFailure: _lastFailure,
      ),
    );
  }

  AppFailure _failure(String key) => AppFailure.recoverable(
    category: AppFailureCategory.persistence,
    messageKey: key,
    occurredAt: DateTime.now().toUtc(),
  );

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _taskSubscription?.cancel();
    await super.close();
  }
}

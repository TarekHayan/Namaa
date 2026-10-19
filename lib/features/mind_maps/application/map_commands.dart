import 'dart:math';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import 'map_repository.dart';

typedef MapIdSource = String Function();
typedef MapClock = DateTime Function();

/// Owner-bound local commands. Each result represents a confirmed transaction.
final class MapCommands {
  MapCommands({
    required MapRepository repository,
    required CloudSessionPort session,
    MapIdSource? nextId,
    MapClock? nowUtc,
  }) : _repository = repository,
       _session = session,
       _nextId = nextId ?? _newUuid,
       _nowUtc = nowUtc ?? _systemUtc;

  final MapRepository _repository;
  final CloudSessionPort _session;
  final MapIdSource _nextId;
  final MapClock _nowUtc;

  Future<AppResult<MindMap>> createMap({
    required String title,
    String? description,
    String? expectedOwnerId,
  }) async {
    if (title.trim().isEmpty) {
      return AppResult.failure(
        _failure(AppFailureCategory.validation, 'mind_maps.validation.title'),
      );
    }
    final owner = await _owner(expectedOwnerId);
    if (owner.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final now = _nowUtc();
    final ownerId = owner.valueOrNull!;
    try {
      final nodeId = _nextId();
      final map = MindMap(
        ownerId: ownerId,
        id: _nextId(),
        title: title,
        description: description?.trim(),
        centralNodeId: nodeId,
        revisionId: _nextId(),
        createdAt: now,
        updatedAt: now,
      );
      final node = MindMapNode(
        ownerId: ownerId,
        mapId: map.id,
        id: nodeId,
        kind: MindMapNodeKind.central,
        title: map.title,
        x: 0,
        y: 0,
        appearance: map.settings.defaultNode,
        revisionId: _nextId(),
        createdAt: now,
        updatedAt: now,
      );
      final result = await _repository.commit(
        MapWriteBatch(
          ownerId: ownerId,
          queuedAt: now,
          verifyOwner: () => _stillOwner(ownerId),
          maps: [
            MapChange(
              value: map,
              operationId: _nextId(),
              kind: ChangeKind.create,
            ),
          ],
          nodes: [
            MapChange(
              value: node,
              operationId: _nextId(),
              kind: ChangeKind.create,
            ),
          ],
        ),
      );
      return result.failureOrNull == null
          ? AppResult.success(map)
          : AppResult.failure(result.failureOrNull!);
    } on ArgumentError {
      return AppResult.failure(
        _failure(AppFailureCategory.validation, 'mind_maps.validation.invalid'),
      );
    }
  }

  Future<AppResult<MindMap>> renameMap({
    required String mapId,
    required String title,
    String? expectedOwnerId,
  }) => _editMap(mapId: mapId, title: title, expectedOwnerId: expectedOwnerId);

  Future<AppResult<MindMap>> describeMap({
    required String mapId,
    required String? description,
    String? expectedOwnerId,
  }) => _editMap(
    mapId: mapId,
    description: description,
    editDescription: true,
    expectedOwnerId: expectedOwnerId,
  );

  Future<AppResult<MindMap>> _editMap({
    required String mapId,
    String? title,
    String? description,
    bool editDescription = false,
    String? expectedOwnerId,
  }) async {
    if (title != null && title.trim().isEmpty) {
      return AppResult.failure(
        _failure(AppFailureCategory.validation, 'mind_maps.validation.title'),
      );
    }
    final graph = await _currentGraph(mapId, expectedOwnerId);
    if (graph.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final old = graph.valueOrNull!.map;
    final now = _after(old.updatedAt);
    final updated = MindMap(
      ownerId: old.ownerId,
      id: old.id,
      title: title ?? old.title,
      description: editDescription ? description?.trim() : old.description,
      centralNodeId: old.centralNodeId,
      settings: old.settings,
      revisionId: _nextId(),
      createdAt: old.createdAt,
      updatedAt: now,
    );
    final result = await _repository.commit(
      MapWriteBatch(
        ownerId: old.ownerId,
        queuedAt: now,
        verifyOwner: () => _stillOwner(old.ownerId),
        maps: [
          MapChange(
            value: updated,
            operationId: _nextId(),
            kind: ChangeKind.update,
            expectedRevisionId: old.revisionId,
          ),
        ],
      ),
    );
    return result.failureOrNull == null
        ? AppResult.success(updated)
        : AppResult.failure(result.failureOrNull!);
  }

  Future<AppResult<MindMap>> duplicateMap({
    required String mapId,
    String? expectedOwnerId,
  }) async {
    final read = await _currentGraph(mapId, expectedOwnerId);
    if (read.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final graph = read.valueOrNull!;
    final source = graph.map;
    final now = _nowUtc();
    final newMapId = _nextId();
    final ids = <String, String>{
      for (final node in graph.nodes.where((n) => !n.isDeleted))
        node.id: _nextId(),
    };
    final centralId = ids[source.centralNodeId];
    if (centralId == null) {
      return AppResult.failure(
        _failure(AppFailureCategory.persistence, 'mind_maps.error.save'),
      );
    }
    final copy = MindMap(
      ownerId: source.ownerId,
      id: newMapId,
      title: source.title,
      description: source.description,
      centralNodeId: centralId,
      settings: source.settings,
      revisionId: _nextId(),
      createdAt: now,
      updatedAt: now,
    );
    final nodes = [
      for (final old in graph.nodes.where((node) => !node.isDeleted))
        MindMapNode(
          ownerId: source.ownerId,
          mapId: newMapId,
          id: ids[old.id]!,
          kind: old.kind,
          title: old.title,
          description: old.description,
          x: old.x,
          y: old.y,
          status: old.status,
          statusChangedAt: old.statusChangedAt,
          priority: old.priority,
          appearance: old.appearance,
          taskId: old.taskId,
          revisionId: _nextId(),
          createdAt: now,
          updatedAt: now,
        ),
    ];
    final slots = [
      for (final old in graph.parentSlots.where((edge) => !edge.isDeleted))
        if (ids.containsKey(old.childNodeId) &&
            ids.containsKey(old.parentNodeId))
          ParentSlot(
            ownerId: source.ownerId,
            mapId: newMapId,
            childNodeId: ids[old.childNodeId]!,
            parentNodeId: ids[old.parentNodeId]!,
            appearance: old.appearance,
            revisionId: _nextId(),
            updatedAt: now,
          ),
    ];
    final links = [
      for (final old in graph.sideLinks.where((edge) => !edge.isDeleted))
        if (ids.containsKey(old.firstNodeId) &&
            ids.containsKey(old.secondNodeId))
          SideLink(
            ownerId: source.ownerId,
            mapId: newMapId,
            firstNodeId: ids[old.firstNodeId]!,
            secondNodeId: ids[old.secondNodeId]!,
            appearance: old.appearance,
            revisionId: _nextId(),
            updatedAt: now,
          ),
    ];
    final result = await _repository.commit(
      MapWriteBatch(
        ownerId: source.ownerId,
        queuedAt: now,
        verifyOwner: () => _stillOwner(source.ownerId),
        maps: [
          MapChange(
            value: copy,
            operationId: _nextId(),
            kind: ChangeKind.create,
          ),
        ],
        nodes: [
          for (final node in nodes)
            MapChange(
              value: node,
              operationId: _nextId(),
              kind: ChangeKind.create,
            ),
        ],
        parentSlots: [
          for (final slot in slots)
            MapChange(
              value: slot,
              operationId: _nextId(),
              kind: ChangeKind.create,
            ),
        ],
        sideLinks: [
          for (final link in links)
            MapChange(
              value: link,
              operationId: _nextId(),
              kind: ChangeKind.create,
            ),
        ],
      ),
    );
    return result.failureOrNull == null
        ? AppResult.success(copy)
        : AppResult.failure(result.failureOrNull!);
  }

  Future<AppResult<MindMap>> deleteMap({
    required String mapId,
    required bool confirmed,
    String? expectedOwnerId,
  }) async {
    if (!confirmed) {
      return AppResult.failure(
        _failure(
          AppFailureCategory.validation,
          'mind_maps.validation.confirm_delete',
        ),
      );
    }
    final read = await _currentGraph(mapId, expectedOwnerId);
    if (read.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final old = read.valueOrNull!.map;
    final now = _after(old.updatedAt);
    final deleted = MindMap(
      ownerId: old.ownerId,
      id: old.id,
      title: old.title,
      description: old.description,
      centralNodeId: old.centralNodeId,
      settings: old.settings,
      revisionId: _nextId(),
      createdAt: old.createdAt,
      updatedAt: now,
      deletedAt: now,
    );
    final result = await _repository.commit(
      MapWriteBatch(
        ownerId: old.ownerId,
        queuedAt: now,
        verifyOwner: () => _stillOwner(old.ownerId),
        maps: [
          MapChange(
            value: deleted,
            operationId: _nextId(),
            kind: ChangeKind.delete,
            expectedRevisionId: old.revisionId,
          ),
        ],
      ),
    );
    return result.failureOrNull == null
        ? AppResult.success(deleted)
        : AppResult.failure(result.failureOrNull!);
  }

  Future<AppResult<MapGraph>> _currentGraph(
    String mapId,
    String? expectedOwnerId,
  ) async {
    final owner = await _owner(expectedOwnerId);
    if (owner.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final read = await _repository.readGraph(
      ownerId: owner.valueOrNull!,
      mapId: mapId,
    );
    if (read.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final graph = read.valueOrNull;
    if (graph == null || graph.map.isDeleted) {
      return AppResult.failure(
        _failure(AppFailureCategory.notFound, 'mind_maps.error.not_found'),
      );
    }
    return AppResult.success(graph);
  }

  Future<AppResult<String>> _owner(String? expected) async {
    final context = await _session.obtainSyncContext();
    final owner = context.valueOrNull?.accountId;
    if (owner == null ||
        owner.isEmpty ||
        (expected != null && expected != owner)) {
      return AppResult.failure(
        _failure(AppFailureCategory.authorization, 'mind_maps.error.account'),
      );
    }
    return AppResult.success(owner);
  }

  Future<bool> _stillOwner(String ownerId) async =>
      (await _session.obtainSyncContext()).valueOrNull?.accountId == ownerId;

  DateTime _after(DateTime previous) {
    final now = _nowUtc();
    return now.isAfter(previous)
        ? now
        : previous.add(const Duration(microseconds: 1));
  }

  AppFailure _failure(AppFailureCategory category, String key) =>
      AppFailure.recoverable(
        category: category,
        messageKey: key,
        occurredAt: _nowUtc(),
      );

  static DateTime _systemUtc() => DateTime.now().toUtc();

  static String _newUuid() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

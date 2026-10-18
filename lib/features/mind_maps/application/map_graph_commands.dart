import 'dart:math';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/map_connection.dart';
import '../domain/map_graph_rules.dart';
import '../domain/mind_map.dart';
import '../domain/mind_map_node.dart';
import 'map_commands.dart';
import 'map_repository.dart';

final class GraphDelta<T> {
  const GraphDelta(this.before, this.after);
  final T? before;
  final T after;
}

/// Only map-owned records are captured. No Task or XP record enters history.
final class GraphEdit {
  GraphEdit({
    required this.ownerId,
    required this.mapId,
    this.maps = const [],
    this.nodes = const [],
    this.parentSlots = const [],
    this.sideLinks = const [],
  });
  final String ownerId;
  final String mapId;
  final List<GraphDelta<MindMap>> maps;
  final List<GraphDelta<MindMapNode>> nodes;
  final List<GraphDelta<ParentSlot>> parentSlots;
  final List<GraphDelta<SideLink>> sideLinks;
}

final class MapGraphCommands {
  MapGraphCommands({
    required MapRepository repository,
    required CloudSessionPort session,
    MapIdSource? nextId,
    MapClock? nowUtc,
  }) : _repository = repository,
       _session = session,
       _nextId = nextId ?? _uuid,
       _nowUtc = nowUtc ?? DateTime.now;

  final MapRepository _repository;
  final CloudSessionPort _session;
  final MapIdSource _nextId;
  final MapClock _nowUtc;

  Future<AppResult<GraphEdit>> addNode({
    required String mapId,
    required MindMapNodeKind kind,
    required String title,
    String? description,
    MindMapNodePriority priority = MindMapNodePriority.medium,
    double x = 0,
    double y = 0,
    String? parentId,
    String? expectedOwnerId,
  }) => _run(mapId, expectedOwnerId, (graph, now) {
    if (kind == MindMapNodeKind.central ||
        title.trim().isEmpty ||
        !x.isFinite ||
        !y.isFinite ||
        (parentId != null && MapGraphRules(graph).node(parentId) == null)) {
      throw const _InvalidGraph();
    }
    final id = _nextId();
    final node = MindMapNode(
      ownerId: graph.map.ownerId,
      mapId: mapId,
      id: id,
      kind: kind,
      title: title,
      description: description?.trim(),
      x: x,
      y: y,
      priority: priority,
      appearance: graph.map.settings.defaultNode,
      revisionId: _nextId(),
      createdAt: now,
      updatedAt: now,
    );
    final slot = parentId == null
        ? null
        : ParentSlot(
            ownerId: graph.map.ownerId,
            mapId: mapId,
            childNodeId: id,
            parentNodeId: parentId,
            appearance: graph.map.settings.defaultConnection,
            revisionId: _nextId(),
            updatedAt: now,
          );
    return GraphEdit(
      ownerId: graph.map.ownerId,
      mapId: mapId,
      nodes: [GraphDelta(null, node)],
      parentSlots: slot == null ? [] : [GraphDelta(null, slot)],
    );
  });

  Future<AppResult<GraphEdit>> editNode({
    required String mapId,
    required String nodeId,
    String? title,
    String? description,
    bool editDescription = false,
    MindMapNodePriority? priority,
    MindMapNodeStatus? status,
    double? x,
    double? y,
    String? expectedOwnerId,
  }) => _run(mapId, expectedOwnerId, (graph, now) {
    final old = MapGraphRules(graph).node(nodeId);
    if (old == null ||
        (title != null && title.trim().isEmpty) ||
        (x != null && !x.isFinite) ||
        (y != null && !y.isFinite) ||
        (old.taskId != null && status != null)) {
      throw const _InvalidGraph();
    }
    final updated = copyMapNode(
      old,
      revisionId: _nextId(),
      updatedAt: _after(now, old.updatedAt),
      title: title,
      description: description,
      editDescription: editDescription,
      priority: priority,
      status: status,
      x: x,
      y: y,
    );
    return GraphEdit(
      ownerId: old.ownerId,
      mapId: mapId,
      nodes: [GraphDelta(old, updated)],
    );
  });

  Future<AppResult<GraphEdit>> deleteNode({
    required String mapId,
    required String nodeId,
    required bool confirmed,
    String? expectedOwnerId,
  }) => _run(mapId, expectedOwnerId, (graph, now) {
    final rules = MapGraphRules(graph);
    final old = rules.node(nodeId);
    if (!confirmed || old == null || old.kind == MindMapNodeKind.central) {
      throw const _InvalidGraph();
    }
    final at = _after(now, old.updatedAt);
    return GraphEdit(
      ownerId: old.ownerId,
      mapId: mapId,
      nodes: [
        GraphDelta(
          old,
          copyMapNode(old, revisionId: _nextId(), updatedAt: at, deletedAt: at),
        ),
      ],
      parentSlots: [
        for (final slot in rules.incidentParentSlots(nodeId))
          GraphDelta(
            slot,
            copyParentSlot(
              slot,
              revisionId: _nextId(),
              updatedAt: _after(at, slot.updatedAt),
              deletedAt: _after(at, slot.updatedAt),
            ),
          ),
      ],
      sideLinks: [
        for (final link in rules.incidentSideLinks(nodeId))
          GraphDelta(
            link,
            copySideLink(
              link,
              revisionId: _nextId(),
              updatedAt: _after(at, link.updatedAt),
              deletedAt: _after(at, link.updatedAt),
            ),
          ),
      ],
    );
  });

  Future<AppResult<GraphEdit>> setParent({
    required String mapId,
    required String childId,
    required String? parentId,
    String? expectedOwnerId,
  }) => _run(mapId, expectedOwnerId, (graph, now) {
    final rules = MapGraphRules(graph);
    final old = rules.parentSlot(childId);
    if (rules.node(childId) == null ||
        rules.node(childId)!.kind == MindMapNodeKind.central ||
        (parentId != null && !rules.canParent(childId, parentId))) {
      throw const _InvalidGraph();
    }
    if (parentId == null && old == null) throw const _InvalidGraph();
    if (old?.parentNodeId == parentId) throw const _InvalidGraph();
    final at = old == null ? now : _after(now, old.updatedAt);
    final updated = ParentSlot(
      ownerId: graph.map.ownerId,
      mapId: mapId,
      childNodeId: childId,
      parentNodeId: parentId ?? old!.parentNodeId,
      appearance: old?.appearance ?? graph.map.settings.defaultConnection,
      revisionId: _nextId(),
      updatedAt: at,
      deletedAt: parentId == null ? at : null,
    );
    return GraphEdit(
      ownerId: graph.map.ownerId,
      mapId: mapId,
      parentSlots: [GraphDelta(old, updated)],
    );
  });

  Future<AppResult<GraphEdit>> setSideLink({
    required String mapId,
    required String firstId,
    required String secondId,
    required bool connected,
    String? expectedOwnerId,
  }) => _run(mapId, expectedOwnerId, (graph, now) {
    final rules = MapGraphRules(graph);
    final old = rules.sideLink(firstId, secondId);
    if (connected ? !rules.canSideLink(firstId, secondId) : old == null) {
      throw const _InvalidGraph();
    }
    final at = old == null ? now : _after(now, old.updatedAt);
    final updated = SideLink(
      ownerId: graph.map.ownerId,
      mapId: mapId,
      firstNodeId: firstId,
      secondNodeId: secondId,
      appearance: old?.appearance ?? graph.map.settings.defaultConnection,
      revisionId: _nextId(),
      updatedAt: at,
      deletedAt: connected ? null : at,
    );
    return GraphEdit(
      ownerId: graph.map.ownerId,
      mapId: mapId,
      sideLinks: [GraphDelta(old, updated)],
    );
  });

  Future<AppResult<GraphEdit>> updateSettings({
    required String mapId,
    required MindMapSettings settings,
    String? expectedOwnerId,
  }) => _run(mapId, expectedOwnerId, (graph, now) {
    final old = graph.map;
    final updated = copyMindMap(
      old,
      revisionId: _nextId(),
      updatedAt: _after(now, old.updatedAt),
      settings: settings,
    );
    return GraphEdit(
      ownerId: old.ownerId,
      mapId: mapId,
      maps: [GraphDelta(old, updated)],
    );
  });

  Future<AppResult<GraphEdit>> _run(
    String mapId,
    String? expectedOwnerId,
    GraphEdit Function(MapGraph, DateTime) build,
  ) async {
    final context = await _session.obtainSyncContext();
    final owner = context.valueOrNull?.accountId;
    if (owner == null ||
        (expectedOwnerId != null && owner != expectedOwnerId)) {
      return AppResult.failure(
        _failure(AppFailureCategory.authorization, 'mind_maps.error.account'),
      );
    }
    final read = await _repository.readGraph(ownerId: owner, mapId: mapId);
    if (read.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final graph = read.valueOrNull;
    if (graph == null) {
      return AppResult.failure(
        _failure(AppFailureCategory.notFound, 'mind_maps.error.not_found'),
      );
    }
    try {
      final edit = build(graph, _nowUtc().toUtc());
      final saved = await _repository.commit(
        batchForGraphEdit(
          edit,
          queuedAt: _nowUtc().toUtc(),
          nextId: _nextId,
          verifyOwner: () async =>
              (await _session.obtainSyncContext()).valueOrNull?.accountId ==
              owner,
        ),
      );
      return saved.failureOrNull == null
          ? AppResult.success(edit)
          : AppResult.failure(saved.failureOrNull!);
    } on _InvalidGraph {
      return AppResult.failure(
        _failure(AppFailureCategory.validation, 'mind_maps.validation.graph'),
      );
    } on ArgumentError {
      return AppResult.failure(
        _failure(AppFailureCategory.validation, 'mind_maps.validation.graph'),
      );
    }
  }

  DateTime _after(DateTime now, DateTime previous) => now.isAfter(previous)
      ? now
      : previous.add(const Duration(microseconds: 1));

  AppFailure _failure(AppFailureCategory category, String key) =>
      AppFailure.recoverable(
        category: category,
        messageKey: key,
        occurredAt: _nowUtc().toUtc(),
      );

  static String _uuid() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

MapWriteBatch batchForGraphEdit(
  GraphEdit edit, {
  required DateTime queuedAt,
  required MapIdSource nextId,
  required Future<bool> Function() verifyOwner,
}) => MapWriteBatch(
  ownerId: edit.ownerId,
  queuedAt: queuedAt,
  verifyOwner: verifyOwner,
  maps: [
    for (final change in edit.maps)
      MapChange(
        value: change.after,
        operationId: nextId(),
        kind: change.before == null
            ? ChangeKind.create
            : change.after.isDeleted
            ? ChangeKind.delete
            : ChangeKind.update,
        expectedRevisionId: change.before?.revisionId,
      ),
  ],
  nodes: [
    for (final change in edit.nodes)
      MapChange(
        value: change.after,
        operationId: nextId(),
        kind: change.before == null
            ? ChangeKind.create
            : change.after.isDeleted
            ? ChangeKind.delete
            : ChangeKind.update,
        expectedRevisionId: change.before?.revisionId,
      ),
  ],
  parentSlots: [
    for (final change in edit.parentSlots)
      MapChange(
        value: change.after,
        operationId: nextId(),
        kind: change.before == null
            ? ChangeKind.create
            : change.after.isDeleted
            ? ChangeKind.delete
            : ChangeKind.update,
        expectedRevisionId: change.before?.revisionId,
      ),
  ],
  sideLinks: [
    for (final change in edit.sideLinks)
      MapChange(
        value: change.after,
        operationId: nextId(),
        kind: change.before == null
            ? ChangeKind.create
            : change.after.isDeleted
            ? ChangeKind.delete
            : ChangeKind.update,
        expectedRevisionId: change.before?.revisionId,
      ),
  ],
);

MindMapNode copyMapNode(
  MindMapNode old, {
  required String revisionId,
  required DateTime updatedAt,
  String? title,
  String? description,
  bool editDescription = false,
  MindMapNodePriority? priority,
  MindMapNodeStatus? status,
  double? x,
  double? y,
  DateTime? deletedAt,
  bool restore = false,
}) => MindMapNode(
  ownerId: old.ownerId,
  mapId: old.mapId,
  id: old.id,
  kind: old.kind,
  title: title ?? old.title,
  description: editDescription ? description?.trim() : old.description,
  x: x ?? old.x,
  y: y ?? old.y,
  status: status ?? old.status,
  statusChangedAt: status == null ? old.statusChangedAt : updatedAt,
  priority: priority ?? old.priority,
  appearance: old.appearance,
  taskId: old.taskId,
  revisionId: revisionId,
  createdAt: old.createdAt,
  updatedAt: updatedAt,
  deletedAt: restore ? null : deletedAt ?? old.deletedAt,
);

ParentSlot copyParentSlot(
  ParentSlot old, {
  required String revisionId,
  required DateTime updatedAt,
  DateTime? deletedAt,
  bool restore = false,
}) => ParentSlot(
  ownerId: old.ownerId,
  mapId: old.mapId,
  childNodeId: old.childNodeId,
  parentNodeId: old.parentNodeId,
  appearance: old.appearance,
  revisionId: revisionId,
  updatedAt: updatedAt,
  deletedAt: restore ? null : deletedAt ?? old.deletedAt,
);

SideLink copySideLink(
  SideLink old, {
  required String revisionId,
  required DateTime updatedAt,
  DateTime? deletedAt,
  bool restore = false,
}) => SideLink(
  ownerId: old.ownerId,
  mapId: old.mapId,
  firstNodeId: old.firstNodeId,
  secondNodeId: old.secondNodeId,
  appearance: old.appearance,
  revisionId: revisionId,
  updatedAt: updatedAt,
  deletedAt: restore ? null : deletedAt ?? old.deletedAt,
);

MindMap copyMindMap(
  MindMap old, {
  required String revisionId,
  required DateTime updatedAt,
  MindMapSettings? settings,
}) => MindMap(
  ownerId: old.ownerId,
  id: old.id,
  title: old.title,
  description: old.description,
  centralNodeId: old.centralNodeId,
  settings: settings ?? old.settings,
  revisionId: revisionId,
  createdAt: old.createdAt,
  updatedAt: updatedAt,
);

final class _InvalidGraph implements Exception {
  const _InvalidGraph();
}

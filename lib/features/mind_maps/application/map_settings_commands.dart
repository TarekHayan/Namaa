import 'dart:math';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/map_layout.dart';
import '../domain/mind_map.dart';
import 'map_commands.dart';
import 'map_graph_commands.dart';
import 'map_repository.dart';

/// Appearance and layout mutations share the graph's atomic local/outbox batch.
final class MapSettingsCommands {
  MapSettingsCommands({
    required MapRepository repository,
    required CloudSessionPort session,
    MapIdSource? nextId,
    MapClock? nowUtc,
  }) : _repository = repository,
       _session = session,
       _nextId = nextId ?? _newId,
       _nowUtc = nowUtc ?? DateTime.now;

  final MapRepository _repository;
  final CloudSessionPort _session;
  final MapIdSource _nextId;
  final MapClock _nowUtc;
  static String _newId() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<AppResult<GraphEdit>> saveSettings({
    required String mapId,
    required MindMapSettings settings,
    String? expectedOwnerId,
  }) => _run(mapId, expectedOwnerId, (graph, now) {
    settings.validate();
    final old = graph.map;
    return GraphEdit(
      ownerId: old.ownerId,
      mapId: mapId,
      maps: [
        GraphDelta(
          old,
          copyMindMap(
            old,
            revisionId: _nextId(),
            updatedAt: _after(now, old.updatedAt),
            settings: settings,
          ),
        ),
      ],
    );
  });

  /// A layout change saves map settings and every changed node in one batch.
  Future<AppResult<GraphEdit>> applyLayout({
    required String mapId,
    required MapLayout layout,
    required bool rtl,
    double? spacing,
    MindMapSettings? settings,
    String? expectedOwnerId,
  }) => _run(mapId, expectedOwnerId, (graph, now) {
    final old = graph.map;
    final newSettings =
        settings ??
        MindMapSettings(
          layout: layout,
          backgroundArgb: old.settings.backgroundArgb,
          backgroundPattern: old.settings.backgroundPattern,
          defaultNode: old.settings.defaultNode,
          defaultConnection: old.settings.defaultConnection,
          spacing: spacing ?? old.settings.spacing,
        );
    if (newSettings.layout != layout) throw const _InvalidSettings();
    newSettings.validate();
    final positions = MapLayoutEngine.place(
      graph,
      layout: layout,
      spacing: newSettings.spacing,
      rtl: rtl,
    );
    return GraphEdit(
      ownerId: old.ownerId,
      mapId: mapId,
      maps: [
        GraphDelta(
          old,
          copyMindMap(
            old,
            revisionId: _nextId(),
            updatedAt: _after(now, old.updatedAt),
            settings: newSettings,
          ),
        ),
      ],
      nodes: [
        for (final node in graph.nodes)
          if (positions[node.id] case final point?
              when point.x != node.x || point.y != node.y)
            GraphDelta(
              node,
              copyMapNode(
                node,
                revisionId: _nextId(),
                updatedAt: _after(now, node.updatedAt),
                x: point.x,
                y: point.y,
              ),
            ),
      ],
    );
  });

  Future<AppResult<GraphEdit>> setNodeAppearance({
    required String mapId,
    required String nodeId,
    required MapNodeAppearance appearance,
    String? expectedOwnerId,
  }) => _run(mapId, expectedOwnerId, (graph, now) {
    appearance.validate();
    final node = graph.nodes
        .where((n) => n.id == nodeId && !n.isDeleted)
        .firstOrNull;
    if (node == null) throw const _InvalidSettings();
    return GraphEdit(
      ownerId: graph.map.ownerId,
      mapId: mapId,
      nodes: [
        GraphDelta(
          node,
          copyMapNode(
            node,
            revisionId: _nextId(),
            updatedAt: _after(now, node.updatedAt),
            appearance: appearance,
          ),
        ),
      ],
    );
  });

  Future<AppResult<GraphEdit>> setConnectionAppearance({
    required String mapId,
    required String connectionId,
    required MapConnectionAppearance appearance,
    String? expectedOwnerId,
  }) => _run(mapId, expectedOwnerId, (graph, now) {
    appearance.validate();
    final parent = graph.parentSlots
        .where((s) => s.id == connectionId && !s.isDeleted)
        .firstOrNull;
    final side = graph.sideLinks
        .where((s) => s.id == connectionId && !s.isDeleted)
        .firstOrNull;
    if (parent == null && side == null) throw const _InvalidSettings();
    return GraphEdit(
      ownerId: graph.map.ownerId,
      mapId: mapId,
      parentSlots: parent == null
          ? []
          : [
              GraphDelta(
                parent,
                copyParentSlot(
                  parent,
                  revisionId: _nextId(),
                  updatedAt: _after(now, parent.updatedAt),
                  appearance: appearance,
                ),
              ),
            ],
      sideLinks: side == null
          ? []
          : [
              GraphDelta(
                side,
                copySideLink(
                  side,
                  revisionId: _nextId(),
                  updatedAt: _after(now, side.updatedAt),
                  appearance: appearance,
                ),
              ),
            ],
    );
  });

  Future<AppResult<GraphEdit>> _run(
    String mapId,
    String? expectedOwnerId,
    GraphEdit Function(MapGraph, DateTime) build,
  ) async {
    Future<String?> owner() async =>
        (await _session.obtainSyncContext()).valueOrNull?.accountId;
    final accountId = await owner();
    if (accountId == null ||
        (expectedOwnerId != null && accountId != expectedOwnerId)) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    final read = await _repository.readGraph(ownerId: accountId, mapId: mapId);
    if (read.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final graph = read.valueOrNull;
    if (graph == null || graph.map.isDeleted) {
      return AppResult.failure(_failure(AppFailureCategory.notFound));
    }
    try {
      final now = _nowUtc().toUtc();
      final edit = build(graph, now);
      final saved = await _repository.commit(
        batchForGraphEdit(
          edit,
          queuedAt: now,
          nextId: _nextId,
          verifyOwner: () async => await owner() == accountId,
        ),
      );
      return saved.failureOrNull == null
          ? AppResult.success(edit)
          : AppResult.failure(saved.failureOrNull!);
    } on ArgumentError {
      return AppResult.failure(_failure(AppFailureCategory.validation));
    } on _InvalidSettings {
      return AppResult.failure(_failure(AppFailureCategory.validation));
    }
  }

  static DateTime _after(DateTime now, DateTime old) =>
      now.isAfter(old) ? now : old.add(const Duration(microseconds: 1));

  AppFailure _failure(AppFailureCategory category) => AppFailure.recoverable(
    category: category,
    messageKey: 'mind_maps.validation.settings',
    occurredAt: _nowUtc().toUtc(),
  );
}

final class _InvalidSettings implements Exception {
  const _InvalidSettings();
}

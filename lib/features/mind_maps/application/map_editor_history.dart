import 'dart:math';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/map_connection.dart';
import '../domain/mind_map.dart';
import '../domain/mind_map_node.dart';
import 'map_commands.dart';
import 'map_graph_commands.dart';
import 'map_repository.dart';

/// A bounded, editor-local journal of map records only.
final class MapEditorHistory {
  MapEditorHistory({
    required MapRepository repository,
    required CloudSessionPort session,
    required this.ownerId,
    required this.mapId,
    this.maxDepth = 30,
    MapIdSource? nextId,
    MapClock? nowUtc,
  }) : _repository = repository,
       _session = session,
       _nextId = nextId ?? _uuid,
       _nowUtc = nowUtc ?? DateTime.now {
    if (maxDepth < 1) throw ArgumentError.value(maxDepth, 'maxDepth');
  }

  final MapRepository _repository;
  final CloudSessionPort _session;
  final String ownerId;
  final String mapId;
  final int maxDepth;
  final MapIdSource _nextId;
  final MapClock _nowUtc;
  final List<GraphEdit> _undo = [];
  final List<GraphEdit> _redo = [];
  final Map<String, String> _versions = {};
  final Map<String, DateTime> _timestamps = {};

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void record(GraphEdit edit) {
    if (edit.ownerId != ownerId || edit.mapId != mapId) {
      throw ArgumentError('History owner/map mismatch');
    }
    _undo.add(edit);
    if (_undo.length > maxDepth) _undo.removeAt(0);
    _redo.clear();
    for (final delta in edit.maps) {
      _versions['map:${delta.after.id}'] = delta.after.revisionId;
      _timestamps['map:${delta.after.id}'] = delta.after.updatedAt;
    }
    for (final delta in edit.nodes) {
      _versions['node:${delta.after.id}'] = delta.after.revisionId;
      _timestamps['node:${delta.after.id}'] = delta.after.updatedAt;
    }
    for (final delta in edit.parentSlots) {
      _versions['parent:${delta.after.id}'] = delta.after.revisionId;
      _timestamps['parent:${delta.after.id}'] = delta.after.updatedAt;
    }
    for (final delta in edit.sideLinks) {
      _versions['side:${delta.after.id}'] = delta.after.revisionId;
      _timestamps['side:${delta.after.id}'] = delta.after.updatedAt;
    }
  }

  Future<AppResult<void>> undo() => _replay(reverse: true);
  Future<AppResult<void>> redo() => _replay(reverse: false);

  Future<AppResult<void>> _replay({required bool reverse}) async {
    final source = reverse ? _undo : _redo;
    if (source.isEmpty) {
      return AppResult.failure(
        _failure(AppFailureCategory.validation, 'mind_maps.validation.history'),
      );
    }
    final edit = source.last;
    final now = _nowUtc().toUtc();
    final revisions = <String, String>{};
    final timestamps = <String, DateTime>{};
    DateTime after(String key, DateTime old) {
      final last = _timestamps[key];
      final previous = last != null && last.isAfter(old) ? last : old;
      final next = now.isAfter(previous)
          ? now
          : previous.add(const Duration(microseconds: 1));
      timestamps[key] = next;
      return next;
    }

    MapChange<MindMap> mapChange(GraphDelta<MindMap> delta) {
      final target = reverse ? delta.before : delta.after;
      if (target == null) {
        throw StateError('Map creation history is unsupported');
      }
      final key = 'map:${delta.after.id}';
      final rev = _nextId();
      revisions[key] = rev;
      return MapChange(
        value: copyMindMap(
          target,
          revisionId: rev,
          updatedAt: after(key, delta.after.updatedAt),
        ),
        operationId: _nextId(),
        kind: ChangeKind.update,
        expectedRevisionId: _versions[key],
      );
    }

    MapChange<MindMapNode> nodeChange(GraphDelta<MindMapNode> delta) {
      final target = reverse ? delta.before : delta.after;
      final key = 'node:${delta.after.id}';
      final rev = _nextId();
      revisions[key] = rev;
      final at = after(key, delta.after.updatedAt);
      final deleted = target == null || target.isDeleted;
      final value = copyMapNode(
        target ?? delta.after,
        revisionId: rev,
        updatedAt: at,
        deletedAt: deleted ? at : null,
        restore: !deleted,
      );
      return MapChange(
        value: value,
        operationId: _nextId(),
        kind: deleted ? ChangeKind.delete : ChangeKind.update,
        expectedRevisionId: _versions[key],
      );
    }

    MapChange<ParentSlot> slotChange(GraphDelta<ParentSlot> delta) {
      final target = reverse ? delta.before : delta.after;
      final key = 'parent:${delta.after.id}';
      final rev = _nextId();
      revisions[key] = rev;
      final at = after(key, delta.after.updatedAt);
      final deleted = target == null || target.isDeleted;
      final value = copyParentSlot(
        target ?? delta.after,
        revisionId: rev,
        updatedAt: at,
        deletedAt: deleted ? at : null,
        restore: !deleted,
      );
      return MapChange(
        value: value,
        operationId: _nextId(),
        kind: deleted ? ChangeKind.delete : ChangeKind.update,
        expectedRevisionId: _versions[key],
      );
    }

    MapChange<SideLink> linkChange(GraphDelta<SideLink> delta) {
      final target = reverse ? delta.before : delta.after;
      final key = 'side:${delta.after.id}';
      final rev = _nextId();
      revisions[key] = rev;
      final at = after(key, delta.after.updatedAt);
      final deleted = target == null || target.isDeleted;
      final value = copySideLink(
        target ?? delta.after,
        revisionId: rev,
        updatedAt: at,
        deletedAt: deleted ? at : null,
        restore: !deleted,
      );
      return MapChange(
        value: value,
        operationId: _nextId(),
        kind: deleted ? ChangeKind.delete : ChangeKind.update,
        expectedRevisionId: _versions[key],
      );
    }

    final batch = MapWriteBatch(
      ownerId: ownerId,
      queuedAt: now,
      verifyOwner: () async =>
          (await _session.obtainSyncContext()).valueOrNull?.accountId ==
          ownerId,
      maps: edit.maps.map(mapChange),
      nodes: edit.nodes.map(nodeChange),
      parentSlots: edit.parentSlots.map(slotChange),
      sideLinks: edit.sideLinks.map(linkChange),
    );
    final result = await _repository.commit(batch);
    if (result.failureOrNull != null) return result;
    _versions.addAll(revisions);
    _timestamps.addAll(timestamps);
    source.removeLast();
    (reverse ? _redo : _undo).add(edit);
    return const AppResult.success(null);
  }

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

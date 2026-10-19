import 'dart:math';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import 'map_graph_commands.dart';
import 'map_repository.dart';
import 'map_task_link_port.dart';

/// Changes only the map-owned Task reference. The bridge validates new IDs.
final class MapTaskLinkCommands {
  MapTaskLinkCommands({
    required MapRepository repository,
    required MapTaskLinkPort tasks,
    required CloudSessionPort session,
    DateTime Function()? nowUtc,
    String Function()? nextId,
  }) : _repository = repository,
       _tasks = tasks,
       _session = session,
       _nowUtc = nowUtc ?? DateTime.now,
       _nextId = nextId ?? _uuid;

  final MapRepository _repository;
  final MapTaskLinkPort _tasks;
  final CloudSessionPort _session;
  final DateTime Function() _nowUtc;
  final String Function() _nextId;

  Future<AppResult<GraphEdit>> setLink({
    required String ownerId,
    required String mapId,
    required String nodeId,
    required String? taskId,
  }) async {
    Future<bool> current() async =>
        (await _session.obtainSyncContext()).valueOrNull?.accountId == ownerId;
    if (!await current()) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    final read = await _repository.readGraph(ownerId: ownerId, mapId: mapId);
    if (read.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final graph = read.valueOrNull;
    if (graph == null) {
      return AppResult.failure(_failure(AppFailureCategory.notFound));
    }
    final nodes = graph.nodes.where(
      (node) => node.id == nodeId && !node.isDeleted,
    );
    if (nodes.isEmpty) {
      return AppResult.failure(_failure(AppFailureCategory.notFound));
    }
    final old = nodes.single;
    if (old.taskId == taskId || (taskId != null && taskId.trim().isEmpty)) {
      return AppResult.failure(_failure(AppFailureCategory.validation));
    }
    if (taskId != null) {
      final readTask = await _tasks.readLinkedTask(ownerId, taskId);
      if (readTask.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      if (readTask.valueOrNull?.available != true) {
        return AppResult.failure(_failure(AppFailureCategory.notFound));
      }
    }
    if (!await current()) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    final requestedAt = _nowUtc().toUtc();
    final at = requestedAt.isAfter(old.updatedAt)
        ? requestedAt
        : old.updatedAt.add(const Duration(microseconds: 1));
    final updated = copyMapNode(
      old,
      revisionId: _nextId(),
      updatedAt: at,
      taskId: taskId,
    );
    final edit = GraphEdit(
      ownerId: ownerId,
      mapId: mapId,
      nodes: [GraphDelta(old, updated)],
    );
    final saved = await _repository.commit(
      batchForGraphEdit(
        edit,
        queuedAt: at,
        nextId: _nextId,
        verifyOwner: current,
      ),
    );
    return saved.failureOrNull == null
        ? AppResult.success(edit)
        : AppResult.failure(saved.failureOrNull!);
  }

  AppFailure _failure(AppFailureCategory category) => AppFailure.recoverable(
    category: category,
    messageKey: category == AppFailureCategory.authorization
        ? 'mind_maps.error.account'
        : 'mind_maps.error.task_link',
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

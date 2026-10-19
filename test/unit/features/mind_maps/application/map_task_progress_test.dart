import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/mind_maps/application/map_queries.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/application/map_task_link_port.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

void main() {
  final at = DateTime.utc(2026, 10, 19, 8);
  MindMapNode node(
    String id, {
    String? taskId,
    MindMapNodeStatus status = MindMapNodeStatus.notStarted,
    DateTime? statusChangedAt,
  }) => MindMapNode(
    ownerId: 'owner',
    mapId: 'map',
    id: id,
    kind: id == 'center' ? MindMapNodeKind.central : MindMapNodeKind.task,
    title: id,
    x: 0,
    y: 0,
    revisionId: 'v',
    createdAt: at,
    updatedAt: at,
    taskId: taskId,
    status: status,
    statusChangedAt: statusChangedAt,
  );
  final graph = MapGraph(
    map: MindMap(
      ownerId: 'owner',
      id: 'map',
      title: 'Map',
      centralNodeId: 'center',
      revisionId: 'v',
      createdAt: at,
      updatedAt: at,
    ),
    nodes: [
      node('center'),
      node(
        'linked',
        taskId: 'task',
        status: MindMapNodeStatus.inProgress,
        statusChangedAt: at.add(const Duration(hours: 3)),
      ),
      node('unlinked', status: MindMapNodeStatus.completed),
      node('foreign', taskId: 'foreign', status: MindMapNodeStatus.completed),
    ],
    parentSlots: const [],
    sideLinks: const [],
  );

  test('linked status follows Task completion and reopen transition', () {
    final completed = MapLinkedTask.available(
      id: 'task',
      title: 'Task',
      completed: true,
      completionChangedAt: at.add(const Duration(hours: 1)),
    );
    expect(
      MapQueries.summary(graph, tasks: {'task': completed}).completedCount,
      2,
    );
    final reopened = MapLinkedTask.available(
      id: 'task',
      title: 'Task',
      completed: false,
      completionChangedAt: at.add(const Duration(hours: 2)),
    );
    expect(
      MapQueries.visibleStatus(graph.nodes[1], {'task': reopened}),
      MindMapNodeStatus.inProgress,
    );
    final reopenedLater = MapLinkedTask.available(
      id: 'task',
      title: 'Task',
      completed: false,
      completionChangedAt: at.add(const Duration(hours: 4)),
    );
    expect(
      MapQueries.visibleStatus(graph.nodes[1], {'task': reopenedLater}),
      MindMapNodeStatus.notStarted,
    );
    expect(
      MapQueries.summary(graph, tasks: {'task': reopenedLater}).completedCount,
      1,
    );
  });

  test(
    'unavailable link stays incomplete and unlinked task-kind stays map-owned',
    () {
      expect(MapQueries.visibleStatus(graph.nodes[3], {}), isNull);
      expect(
        MapQueries.visibleStatus(graph.nodes[2], {}),
        MindMapNodeStatus.completed,
      );
      expect(MapQueries.summary(graph).progressPercent, 25);
    },
  );
}

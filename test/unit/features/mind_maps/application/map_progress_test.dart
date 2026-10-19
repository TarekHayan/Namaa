import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/mind_maps/application/map_queries.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

void main() {
  final at = DateTime.utc(2026);
  MindMapNode node(
    String id,
    MindMapNodeStatus status, {
    String? taskId,
    DateTime? deletedAt,
  }) => MindMapNode(
    ownerId: 'o',
    mapId: 'm',
    id: id,
    kind: id == 'center' ? MindMapNodeKind.central : MindMapNodeKind.note,
    title: id,
    x: 0,
    y: 0,
    status: status,
    taskId: taskId,
    revisionId: 'v',
    createdAt: at,
    updatedAt: at,
    deletedAt: deletedAt,
  );
  test(
    'central included; linked unavailable incomplete; tombstones excluded',
    () {
      final graph = MapGraph(
        map: MindMap(
          ownerId: 'o',
          id: 'm',
          title: 'M',
          centralNodeId: 'center',
          revisionId: 'v',
          createdAt: at,
          updatedAt: at,
        ),
        nodes: [
          node('center', MindMapNodeStatus.completed),
          node('a', MindMapNodeStatus.completed),
          node('b', MindMapNodeStatus.completed, taskId: 'task'),
          node('old', MindMapNodeStatus.completed, deletedAt: at),
        ],
        parentSlots: [
          ParentSlot(
            ownerId: 'o',
            mapId: 'm',
            childNodeId: 'old',
            parentNodeId: 'center',
            revisionId: 'v',
            updatedAt: at,
          ),
        ],
        sideLinks: [
          SideLink(
            ownerId: 'o',
            mapId: 'm',
            firstNodeId: 'old',
            secondNodeId: 'a',
            revisionId: 'v',
            updatedAt: at,
          ),
        ],
      );
      final summary = MapQueries.summary(graph);
      expect(summary.nodeCount, 3);
      expect(summary.completedCount, 2);
      expect(summary.progressPercent, 67);
      expect(MapQueries.graph(graph).parentSlots, isEmpty);
      expect(MapQueries.graph(graph).sideLinks, isEmpty);
    },
  );
}

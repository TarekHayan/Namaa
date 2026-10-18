import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/mind_maps/application/map_queries.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import '../../../../support/mind_maps_test_support.dart';

void main() {
  final now = DateTime.utc(2026, 10, 18);
  final ids = MindMapsTestIds();

  test('title validation, default layout and central-inclusive summary', () {
    expect(
      () => MindMap(
        ownerId: kMindMapsTestAccountA,
        id: kMindMapsTestMapId,
        title: ' ',
        centralNodeId: kMindMapsTestNodeId,
        revisionId: 'r',
        createdAt: now,
        updatedAt: now,
      ),
      throwsArgumentError,
    );
    final map = MindMap(
      ownerId: kMindMapsTestAccountA,
      id: kMindMapsTestMapId,
      title: '  Ideas  ',
      centralNodeId: kMindMapsTestNodeId,
      revisionId: 'r',
      createdAt: now,
      updatedAt: now,
    );
    expect(map.title, 'Ideas');
    expect(map.settings.layout, MapLayout.radial);
    expect(
      () => MindMapNode(
        ownerId: map.ownerId,
        mapId: map.id,
        id: map.centralNodeId,
        kind: MindMapNodeKind.central,
        title: 'Ideas',
        x: 0,
        y: 0,
        revisionId: 'deleted-center',
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      ),
      throwsArgumentError,
    );
    final center = MindMapNode(
      ownerId: map.ownerId,
      mapId: map.id,
      id: map.centralNodeId,
      kind: MindMapNodeKind.central,
      title: map.title,
      x: 0,
      y: 0,
      revisionId: 'n',
      createdAt: now,
      updatedAt: now,
    );
    final summary = MapQueries.summary(
      MapGraph(map: map, nodes: [center], parentSlots: [], sideLinks: []),
    );
    expect(
      (summary.nodeCount, summary.completedCount, summary.progressPercent),
      (1, 0, 0),
    );
  });

  test(
    'search is case-insensitive, includes description, and hides deleted/foreign maps',
    () {
      MapGraph graph(
        String owner,
        String title,
        String? description, {
        bool deleted = false,
      }) {
        final map = MindMap(
          ownerId: owner,
          id: ids.nextMapId(),
          title: title,
          description: description,
          centralNodeId: ids.nextNodeId(),
          revisionId: ids.nextOperationId(),
          createdAt: now,
          updatedAt: now,
          deletedAt: deleted ? now : null,
        );
        return MapGraph(map: map, nodes: [], parentSlots: [], sideLinks: []);
      }

      final all = [
        graph(kMindMapsTestAccountA, 'Biology', 'Plants'),
        graph(kMindMapsTestAccountA, 'Study', 'BRAIN'),
        graph(kMindMapsTestAccountB, 'Brain foreign', null),
        graph(kMindMapsTestAccountA, 'Brain deleted', null, deleted: true),
      ];
      expect(
        MapQueries.search(
          ownerId: kMindMapsTestAccountA,
          graphs: all,
          text: 'brain',
        ).map((item) => item.map.title),
        ['Study'],
      );
      expect(
        MapQueries.search(
          ownerId: kMindMapsTestAccountA,
          graphs: all,
          text: 'BIOLOGY',
        ).single.map.title,
        'Biology',
      );
    },
  );
}

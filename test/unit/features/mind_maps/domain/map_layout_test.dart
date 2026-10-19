import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/map_layout.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

void main() {
  final at = DateTime.utc(2026, 10, 19);
  MapGraph graph({bool sideLink = true}) => MapGraph(
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
      for (final id in ['center', 'a', 'b', 'child', 'detached'])
        MindMapNode(
          ownerId: 'owner',
          mapId: 'map',
          id: id,
          kind: id == 'center'
              ? MindMapNodeKind.central
              : MindMapNodeKind.branch,
          title: id,
          x: id.length.toDouble(),
          y: -id.length.toDouble(),
          revisionId: 'v',
          createdAt: at,
          updatedAt: at,
        ),
    ],
    parentSlots: [
      for (final (child, parent) in [
        ('a', 'center'),
        ('b', 'center'),
        ('child', 'a'),
      ])
        ParentSlot(
          ownerId: 'owner',
          mapId: 'map',
          childNodeId: child,
          parentNodeId: parent,
          revisionId: 'v',
          updatedAt: at,
        ),
    ],
    sideLinks: sideLink
        ? [
            SideLink(
              ownerId: 'owner',
              mapId: 'map',
              firstNodeId: 'detached',
              secondNodeId: 'child',
              revisionId: 'v',
              updatedAt: at,
            ),
          ]
        : [],
  );

  test('all layouts retain every node and side links never move nodes', () {
    for (final layout in MapLayout.values) {
      final withSide = MapLayoutEngine.place(
        graph(),
        layout: layout,
        spacing: 120,
      );
      final withoutSide = MapLayoutEngine.place(
        graph(sideLink: false),
        layout: layout,
        spacing: 120,
      );
      expect(
        withSide.keys,
        containsAll(['center', 'a', 'b', 'child', 'detached']),
      );
      expect(withSide, withoutSide);
      expect(
        MapLayoutEngine.place(graph(), layout: layout, spacing: 120),
        withSide,
      );
    }
  });

  test('freeform uses saved coordinates and detached node is its own root', () {
    final source = graph();
    final free = MapLayoutEngine.place(
      source,
      layout: MapLayout.freeform,
      spacing: 120,
    );
    for (final node in source.nodes) {
      expect(free[node.id], MapPoint(node.x, node.y));
    }
    final horizontal = MapLayoutEngine.place(
      source,
      layout: MapLayout.horizontal,
      spacing: 120,
    );
    expect(horizontal['child']!.x, greaterThan(horizontal['a']!.x));
    expect(horizontal['detached']!.x, horizontal['center']!.x);
  });

  test('RTL reverses horizontal depth without changing graph identity', () {
    final ltr = MapLayoutEngine.place(
      graph(),
      layout: MapLayout.horizontal,
      spacing: 120,
    );
    final rtl = MapLayoutEngine.place(
      graph(),
      layout: MapLayout.horizontal,
      spacing: 120,
      rtl: true,
    );
    expect(rtl.keys, ltr.keys);
    for (final id in ltr.keys) {
      expect(rtl[id]!.x, -ltr[id]!.x);
      expect(rtl[id]!.y, ltr[id]!.y);
    }
  });
}

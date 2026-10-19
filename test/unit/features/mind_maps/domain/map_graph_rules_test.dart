import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/map_graph_rules.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

void main() {
  final at = DateTime.utc(2026);
  const owner = 'owner';
  const mapId = 'map';
  MindMapNode node(
    String id, {
    MindMapNodeKind kind = MindMapNodeKind.branch,
  }) => MindMapNode(
    ownerId: owner,
    mapId: mapId,
    id: id,
    kind: kind,
    title: id,
    x: 0,
    y: 0,
    revisionId: 'v1',
    createdAt: at,
    updatedAt: at,
  );
  ParentSlot slot(String child, String parent) => ParentSlot(
    ownerId: owner,
    mapId: mapId,
    childNodeId: child,
    parentNodeId: parent,
    revisionId: 'v1',
    updatedAt: at,
  );
  SideLink link(String a, String b) => SideLink(
    ownerId: owner,
    mapId: mapId,
    firstNodeId: a,
    secondNodeId: b,
    revisionId: 'v1',
    updatedAt: at,
  );
  MapGraph graph({
    List<ParentSlot> slots = const [],
    List<SideLink> links = const [],
  }) => MapGraph(
    map: MindMap(
      ownerId: owner,
      id: mapId,
      title: 'Map',
      centralNodeId: 'center',
      revisionId: 'v1',
      createdAt: at,
      updatedAt: at,
    ),
    nodes: [
      node('center', kind: MindMapNodeKind.central),
      node('a'),
      node('b'),
      node('c'),
    ],
    parentSlots: slots,
    sideLinks: links,
  );

  test(
    'parent traversal rejects self, central child, cycles and pair duplicates',
    () {
      final rules = MapGraphRules(
        graph(slots: [slot('a', 'center'), slot('b', 'a')]),
      );
      expect(rules.canParent('center', 'a'), false);
      expect(rules.canParent('a', 'a'), false);
      expect(rules.canParent('a', 'b'), false);
      expect(rules.canParent('c', 'b'), true);
      expect(rules.canParent('b', 'a'), true); // existing relationship
    },
  );

  test('side links are canonical, visual and cannot duplicate parent pair', () {
    final rules = MapGraphRules(
      graph(slots: [slot('a', 'center')], links: [link('b', 'c')]),
    );
    expect(rules.canSideLink('center', 'a'), false);
    expect(rules.canSideLink('c', 'b'), false);
    expect(rules.canSideLink('a', 'a'), false);
    expect(rules.canSideLink('a', 'c'), true);
  });

  test(
    'deleted parent leaves children independent without removing descendants',
    () {
      final rules = MapGraphRules(
        graph(
          slots: [slot('a', 'center'), slot('b', 'a'), slot('c', 'b')],
          links: [link('a', 'c')],
        ),
      );
      expect(
        rules.incidentParentSlots('a').map((e) => e.childNodeId),
        containsAll(['a', 'b']),
      );
      expect(rules.incidentSideLinks('a').length, 1);
      expect(
        rules.incidentParentSlots('a').any((e) => e.childNodeId == 'c'),
        false,
      );
    },
  );

  test('foreign-map endpoints cannot be connected', () {
    final foreign = MindMapNode(
      ownerId: owner,
      mapId: 'other',
      id: 'foreign',
      kind: MindMapNodeKind.note,
      title: 'Foreign',
      x: 0,
      y: 0,
      revisionId: 'v1',
      createdAt: at,
      updatedAt: at,
    );
    final mixed = MapGraph(
      map: graph().map,
      nodes: [...graph().nodes, foreign],
      parentSlots: [],
      sideLinks: [],
    );
    final rules = MapGraphRules(mixed);
    expect(rules.canParent('a', 'foreign'), false);
    expect(rules.canSideLink('a', 'foreign'), false);
  });
}

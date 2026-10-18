import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import '../../../../support/mind_maps_test_support.dart';

void main() {
  const codec = MapPayloadCodec();
  final created = DateTime.utc(2026, 10, 18, 9);
  final updated = created.add(const Duration(minutes: 2));
  const connectionStyle = MapConnectionAppearance(argb: 0xff123456, width: 3.5);
  const nodeStyle = MapNodeAppearance(
    argb: 0xffabcdef,
    icon: 'star',
    shape: MapNodeShape.hexagon,
    nodeSize: MapSize.large,
    textSize: MapSize.small,
  );

  test('map settings, identity and tombstone survive independent payload', () {
    final map = MindMap(
      ownerId: kMindMapsTestAccountA,
      id: kMindMapsTestMapId,
      title: '  Planning  ',
      description: 'A description',
      centralNodeId: kMindMapsTestNodeId,
      settings: const MindMapSettings(
        layout: MapLayout.freeform,
        backgroundArgb: 0xff112233,
        defaultNode: nodeStyle,
        defaultConnection: connectionStyle,
        spacing: 180,
      ),
      revisionId: 'revision-map',
      createdAt: created,
      updatedAt: updated,
      deletedAt: updated,
    );
    final restored = codec.decodeMap(codec.encodeMap(map));
    expect(restored.ownerId, map.ownerId);
    expect(restored.id, map.id);
    expect(restored.title, 'Planning');
    expect(restored.centralNodeId, map.centralNodeId);
    expect(restored.settings.layout, MapLayout.freeform);
    expect(restored.settings.defaultNode.shape, MapNodeShape.hexagon);
    expect(restored.settings.defaultConnection.width, 3.5);
    expect(restored.settings.spacing, 180);
    expect(restored.revisionId, 'revision-map');
    expect(restored.deletedAt, updated);
  });

  test('node status, appearance and Task reference survive payload', () {
    final node = MindMapNode(
      ownerId: kMindMapsTestAccountA,
      mapId: kMindMapsTestMapId,
      id: kMindMapsTestNodeId,
      kind: MindMapNodeKind.task,
      title: 'Linked task',
      x: 12.5,
      y: -8.25,
      status: MindMapNodeStatus.inProgress,
      statusChangedAt: updated,
      priority: MindMapNodePriority.high,
      appearance: nodeStyle,
      taskId: kMindMapsTestTaskId,
      revisionId: 'revision-node',
      createdAt: created,
      updatedAt: updated,
    );
    final restored = codec.decodeNode(codec.encodeNode(node));
    expect(restored.ownerId, node.ownerId);
    expect(restored.mapId, node.mapId);
    expect(restored.id, node.id);
    expect(restored.x, 12.5);
    expect(restored.y, -8.25);
    expect(restored.status, MindMapNodeStatus.inProgress);
    expect(restored.statusChangedAt, updated);
    expect(restored.priority, MindMapNodePriority.high);
    expect(restored.appearance.argb, nodeStyle.argb);
    expect(restored.taskId, kMindMapsTestTaskId);
    expect(restored.revisionId, 'revision-node');
  });

  test(
    'parent and side relationships preserve stable identities and style',
    () {
      final ids = MindMapsTestIds();
      final child = ids.nextNodeId();
      final parentId = ids.nextNodeId();
      final slot = ParentSlot(
        ownerId: kMindMapsTestAccountA,
        mapId: kMindMapsTestMapId,
        childNodeId: child,
        parentNodeId: parentId,
        appearance: connectionStyle,
        revisionId: 'revision-slot',
        updatedAt: updated,
        deletedAt: updated,
      );
      final restoredSlot = codec.decodeParentSlot(codec.encodeParentSlot(slot));
      expect(restoredSlot.id, 'parent:$child');
      expect(restoredSlot.parentNodeId, parentId);
      expect(restoredSlot.appearance.width, 3.5);
      expect(restoredSlot.deletedAt, updated);

      final link = SideLink(
        ownerId: kMindMapsTestAccountA,
        mapId: kMindMapsTestMapId,
        firstNodeId: parentId,
        secondNodeId: child,
        appearance: connectionStyle,
        revisionId: 'revision-side',
        updatedAt: updated,
      );
      final restoredLink = codec.decodeSideLink(codec.encodeSideLink(link));
      expect(
        restoredLink.firstNodeId.compareTo(restoredLink.secondNodeId),
        lessThan(0),
      );
      expect(restoredLink.id, link.id);
      expect(restoredLink.appearance.argb, connectionStyle.argb);
      expect(restoredLink.revisionId, 'revision-side');
    },
  );

  test(
    'rejects invalid owner, blank title, self-link and malformed payload',
    () {
      expect(
        () => MindMap(
          ownerId: '',
          id: kMindMapsTestMapId,
          title: 'Name',
          centralNodeId: kMindMapsTestNodeId,
          revisionId: 'r',
          createdAt: created,
          updatedAt: updated,
        ),
        throwsArgumentError,
      );
      expect(
        () => MindMapNode(
          ownerId: kMindMapsTestAccountA,
          mapId: kMindMapsTestMapId,
          id: kMindMapsTestNodeId,
          kind: MindMapNodeKind.note,
          title: '  ',
          x: 0,
          y: 0,
          revisionId: 'r',
          createdAt: created,
          updatedAt: updated,
        ),
        throwsArgumentError,
      );
      expect(
        () => SideLink(
          ownerId: kMindMapsTestAccountA,
          mapId: kMindMapsTestMapId,
          firstNodeId: kMindMapsTestNodeId,
          secondNodeId: kMindMapsTestNodeId,
          revisionId: 'r',
          updatedAt: updated,
        ),
        throwsArgumentError,
      );
      expect(() => codec.decodeNode('{}'), throwsFormatException);
    },
  );
}

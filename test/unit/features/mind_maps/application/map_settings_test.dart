import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_settings_commands.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';

import '../../../../support/foundation_test_support.dart';
import '../../../../support/mind_maps_test_support.dart';

void main() {
  test(
    'defaults affect new elements only and appearance survives restart',
    () async {
      final temp = TemporaryDatabasePath();
      final path = temp.allocate();
      final key = List<int>.generate(32, (i) => i + 29);
      var db = await FoundationDatabase.openEncrypted(path: path, key: key);
      final session = MindMapsTestSession();
      final ids = MindMapsTestIds();
      final clock = MindMapsTestClock();
      DriftMapRepository repo() =>
          DriftMapRepository(database: db, codec: const MapPayloadCodec());
      final maps = MapCommands(
        repository: repo(),
        session: session,
        nextId: ids.nextOperationId,
        nowUtc: clock.nextVersion,
      );
      final graphCommands = MapGraphCommands(
        repository: repo(),
        session: session,
        nextId: ids.nextOperationId,
        nowUtc: clock.nextVersion,
      );
      final mapId = (await maps.createMap(title: 'First')).valueOrNull!.id;
      final otherId = (await maps.createMap(title: 'Second')).valueOrNull!.id;
      final beforeSettings =
          (await db.rawScalar('SELECT count(*) FROM pending_changes')) as int;
      final first = (await graphCommands.addNode(
        mapId: mapId,
        kind: MindMapNodeKind.branch,
        title: 'Old',
      )).valueOrNull!.nodes.single.after;
      final commands = MapSettingsCommands(
        repository: repo(),
        session: session,
        nextId: ids.nextOperationId,
        nowUtc: clock.nextVersion,
      );
      const defaults = MindMapSettings(
        layout: MapLayout.horizontal,
        backgroundArgb: 0xff101820,
        defaultNode: MapNodeAppearance(
          argb: 0xffabcdef,
          icon: 'star',
          shape: MapNodeShape.pill,
          nodeSize: MapSize.large,
          textSize: MapSize.small,
        ),
        defaultConnection: MapConnectionAppearance(argb: 0xff123456, width: 4),
        spacing: 180,
      );
      expect(
        (await commands.saveSettings(
          mapId: mapId,
          settings: defaults,
        )).failureOrNull,
        isNull,
      );
      final later = (await graphCommands.addNode(
        mapId: mapId,
        kind: MindMapNodeKind.branch,
        title: 'New',
        parentId: first.id,
      )).valueOrNull!.nodes.single.after;
      expect(later.appearance.argb, 0xffabcdef);
      final connected = (await repo().readGraph(
        ownerId: kMindMapsTestAccountA,
        mapId: mapId,
      )).valueOrNull!.parentSlots.single;
      expect(connected.appearance.argb, 0xff123456);
      expect(
        (await commands.setConnectionAppearance(
          mapId: mapId,
          connectionId: connected.id,
          appearance: const MapConnectionAppearance(argb: 0xff654321, width: 3),
        )).failureOrNull,
        isNull,
      );
      final styled = const MapNodeAppearance(
        argb: 0xff112233,
        icon: 'flag',
        shape: MapNodeShape.glass,
        nodeSize: MapSize.small,
        textSize: MapSize.large,
      );
      expect(
        (await commands.setNodeAppearance(
          mapId: mapId,
          nodeId: first.id,
          appearance: styled,
        )).failureOrNull,
        isNull,
      );
      expect(
        (await commands.applyLayout(
          mapId: mapId,
          layout: MapLayout.horizontal,
          rtl: true,
        )).failureOrNull,
        isNull,
      );
      await db.close();
      db = await FoundationDatabase.openEncrypted(path: path, key: key);
      final restored = (await repo().readGraph(
        ownerId: kMindMapsTestAccountA,
        mapId: mapId,
      )).valueOrNull!;
      final old = restored.nodes.singleWhere((n) => n.id == first.id);
      expect(old.appearance.shape, MapNodeShape.glass);
      expect(old.appearance.argb, 0xff112233);
      expect(restored.map.settings.backgroundArgb, 0xff101820);
      expect(
        restored.nodes.singleWhere((n) => n.id == later.id).appearance.icon,
        'star',
      );
      expect(restored.parentSlots.single.appearance.argb, 0xff654321);
      expect(
        await db.rawScalar('SELECT count(*) FROM pending_changes'),
        greaterThan(beforeSettings),
      );
      expect(
        (await repo().readGraph(
          ownerId: kMindMapsTestAccountA,
          mapId: otherId,
        )).valueOrNull!.map.settings.backgroundArgb,
        0xffffffff,
      );
      await session.dispose();
      await db.close();
      temp.dispose();
    },
  );
}

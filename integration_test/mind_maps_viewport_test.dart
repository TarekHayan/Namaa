import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/mind_maps_strings_adapter.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/application/map_settings_commands.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';
import 'package:namma_project/features/mind_maps/presentation/map_canvas.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/mind_maps_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('50 nodes and 60 links remain responsive and durable', (
    tester,
  ) async {
    final temp = TemporaryDatabasePath();
    final path = temp.allocate();
    final key = List<int>.generate(32, (i) => i + 39);
    var db = await FoundationDatabase.openEncrypted(path: path, key: key);
    final session = MindMapsTestSession();
    final ids = MindMapsTestIds();
    final clock = MindMapsTestClock();
    DriftMapRepository repo() =>
        DriftMapRepository(database: db, codec: const MapPayloadCodec());
    final map = (await MapCommands(
      repository: repo(),
      session: session,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    ).createMap(title: 'Fifty nodes')).valueOrNull!;
    final nodeIds = [
      map.centralNodeId,
      for (var i = 1; i < 50; i++) ids.nextNodeId(),
    ];
    final at = clock.nextVersion();
    final nodes = [
      for (var i = 1; i < 50; i++)
        MindMapNode(
          ownerId: kMindMapsTestAccountA,
          mapId: map.id,
          id: nodeIds[i],
          kind: MindMapNodeKind.branch,
          title: 'Idea $i',
          x: (i % 10) * 155.0 - 700,
          y: (i ~/ 10) * 105.0 - 200,
          revisionId: ids.nextOperationId(),
          createdAt: at,
          updatedAt: at,
        ),
    ];
    final slots = [
      for (var i = 1; i < 50; i++)
        ParentSlot(
          ownerId: kMindMapsTestAccountA,
          mapId: map.id,
          childNodeId: nodeIds[i],
          parentNodeId: nodeIds[(i - 1) ~/ 2],
          revisionId: ids.nextOperationId(),
          updatedAt: at,
        ),
    ];
    final sides = [
      for (var i = 1; i <= 11; i++)
        SideLink(
          ownerId: kMindMapsTestAccountA,
          mapId: map.id,
          firstNodeId: nodeIds[i],
          secondNodeId: nodeIds[i + 20],
          revisionId: ids.nextOperationId(),
          updatedAt: at,
        ),
    ];
    expect(
      (await repo().commit(
        MapWriteBatch(
          ownerId: kMindMapsTestAccountA,
          queuedAt: at,
          verifyOwner: () async => true,
          nodes: [
            for (final node in nodes)
              MapChange(
                value: node,
                operationId: ids.nextOperationId(),
                kind: ChangeKind.create,
              ),
          ],
          parentSlots: [
            for (final slot in slots)
              MapChange(
                value: slot,
                operationId: ids.nextOperationId(),
                kind: ChangeKind.create,
              ),
          ],
          sideLinks: [
            for (final side in sides)
              MapChange(
                value: side,
                operationId: ids.nextOperationId(),
                kind: ChangeKind.create,
              ),
          ],
        ),
      )).failureOrNull,
      isNull,
    );
    var graph = (await repo().readGraph(
      ownerId: kMindMapsTestAccountA,
      mapId: map.id,
    )).valueOrNull!;
    expect(graph.nodes.length, 50);
    expect(graph.parentSlots.length + graph.sideLinks.length, 60);
    final settings = MapSettingsCommands(
      repository: repo(),
      session: session,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    );
    expect(
      (await settings.applyLayout(
        mapId: map.id,
        layout: MapLayout.horizontal,
        rtl: false,
      )).failureOrNull,
      isNull,
    );
    graph = (await repo().readGraph(
      ownerId: kMindMapsTestAccountA,
      mapId: map.id,
    )).valueOrNull!;
    String? selected;
    Widget view() => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      supportedLocales: FoundationLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => MapCanvas(
            graph: graph,
            selectedId: selected ?? map.centralNodeId,
            onSelect: (id) => selected = id,
            onMove: (id, x, y) async =>
                (await MapGraphCommands(
                      repository: repo(),
                      session: session,
                      nextId: ids.nextOperationId,
                      nowUtc: clock.nextVersion,
                    ).editNode(mapId: map.id, nodeId: id, x: x, y: y))
                    .failureOrNull ==
                null,
            strings: resolveMindMapsStrings(context),
          ),
        ),
      ),
    );

    for (final size in [const Size(390, 844), const Size(1200, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(view());
      await tester.pump();
      Future<void> check(Future<void> Function() action) async {
        final watch = Stopwatch()..start();
        await action();
        await tester.pump();
        expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      }

      await check(() => tester.tap(find.byKey(kMindMapZoomInKey)));
      await check(() => tester.tap(find.byKey(kMindMapFitKey)));
      await check(
        () => tester.tap(
          find.byKey(ValueKey('mind-map-canvas-node-${map.centralNodeId}')),
        ),
      );
      expect(selected, map.centralNodeId);
      await check(() => tester.tap(find.byTooltip('Pan left')));
      await check(() async {
        final result = await MapGraphCommands(
          repository: repo(),
          session: session,
          nextId: ids.nextOperationId,
          nowUtc: clock.nextVersion,
        ).editNode(mapId: map.id, nodeId: nodeIds[1], title: 'Edited offline');
        expect(result.failureOrNull, isNull);
        graph = (await repo().readGraph(
          ownerId: kMindMapsTestAccountA,
          mapId: map.id,
        )).valueOrNull!;
        await tester.pumpWidget(view());
      });
      expect(find.byKey(kMindMapCanvasKey), findsOneWidget);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
    db = await FoundationDatabase.openEncrypted(path: path, key: key);
    final restored = (await repo().readGraph(
      ownerId: kMindMapsTestAccountA,
      mapId: map.id,
    )).valueOrNull!;
    expect(restored.nodes.length, 50);
    expect(restored.parentSlots.length + restored.sideLinks.length, 60);
    expect(restored.map.settings.layout, MapLayout.horizontal);
    expect(
      restored.nodes.singleWhere((n) => n.id == nodeIds[1]).title,
      'Edited offline',
    );
    await session.dispose();
    await db.close();
    temp.dispose();
  });
}

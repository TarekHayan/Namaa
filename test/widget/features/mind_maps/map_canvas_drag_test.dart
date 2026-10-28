import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/mind_maps_strings_adapter.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/map_graph.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';
import 'package:namma_project/features/mind_maps/presentation/map_canvas.dart';

Future<int> _visibleEdgePixels(WidgetTester tester) async {
  return (await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find
          .ancestor(
            of: find.byKey(kMindMapEdgesKey),
            matching: find.byType(RepaintBoundary),
          )
          .first,
    );
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!;
    var visible = 0;
    // The child edge ends around (665, 448) after the 80 px downward drag.
    for (var y = 438; y <= 455; y++) {
      for (var x = 655; x <= 672; x++) {
        if (bytes.getUint8((y * image.width + x) * 4 + 3) > 20) {
          visible++;
        }
      }
    }
    image.dispose();
    return visible;
  }))!;
}

void main() {
  testWidgets('connection stays attached while dragging and saving a node', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final at = DateTime.utc(2026, 10, 26);
    MindMapNode node(String id, double x, double y) => MindMapNode(
      ownerId: 'owner',
      mapId: 'map',
      id: id,
      kind: id == 'root' ? MindMapNodeKind.central : MindMapNodeKind.branch,
      title: id,
      x: x,
      y: y,
      revisionId: 'v1',
      createdAt: at,
      updatedAt: at,
    );
    final root = node('root', -150, 0);
    final child = node('child', 150, 0);
    final map = MindMap(
      ownerId: 'owner',
      id: 'map',
      title: 'Map',
      centralNodeId: root.id,
      revisionId: 'v1',
      createdAt: at,
      updatedAt: at,
      settings: const MindMapSettings(layout: MapLayout.horizontal),
    );
    final slot = ParentSlot(
      ownerId: 'owner',
      mapId: map.id,
      childNodeId: child.id,
      parentNodeId: root.id,
      revisionId: 'v1',
      updatedAt: at,
      appearance: const MapConnectionAppearance(argb: 0xffff0000, width: 4),
    );
    MapGraph graphWith(MindMapNode currentChild) => MapGraph(
      map: map,
      nodes: [root, currentChild],
      parentSlots: [slot],
      sideLinks: const [],
    );

    var graph = graphWith(child);
    final save = Completer<bool>();
    StateSetter? redraw;
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              redraw = setState;
              return MapCanvas(
                graph: graph,
                selectedId: child.id,
                onSelect: (id) => selected = id,
                onMove: (id, x, y) async {
                  final accepted = await save.future;
                  if (accepted) {
                    redraw!(() => graph = graphWith(node(id, x, y)));
                  }
                  return accepted;
                },
                strings: resolveMindMapsStrings(context),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(await _visibleEdgePixels(tester), 0);

    final childFinder = find.byKey(
      const ValueKey('mind-map-canvas-node-child'),
    );
    final beforeDrag = tester.getCenter(childFinder);
    final gesture = await tester.startGesture(beforeDrag);
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    expect(selected, child.id);
    expect(tester.getCenter(childFinder).dy, closeTo(beforeDrag.dy + 80, 1));
    expect(await _visibleEdgePixels(tester), greaterThan(0));

    await gesture.up();
    await tester.pump();
    expect(await _visibleEdgePixels(tester), greaterThan(0));
    expect(tester.getCenter(childFinder).dy, closeTo(beforeDrag.dy + 80, 1));

    save.complete(true);
    await tester.pumpAndSettle();
    expect(tester.getCenter(childFinder).dy, closeTo(beforeDrag.dy + 80, 1));
  });
}

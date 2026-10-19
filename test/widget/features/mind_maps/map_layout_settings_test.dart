import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/mind_maps_strings_adapter.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';
import 'package:namma_project/features/mind_maps/presentation/map_canvas.dart';
import 'package:namma_project/features/mind_maps/presentation/map_node_editor.dart';
import 'package:namma_project/features/mind_maps/presentation/map_settings_panel.dart';

void main() {
  Widget localized(
    Widget Function(BuildContext) child, {
    String language = 'en',
  }) => MaterialApp(
    locale: Locale(language),
    localizationsDelegates: FoundationLocalizations.localizationsDelegates,
    supportedLocales: FoundationLocalizations.supportedLocales,
    home: Builder(builder: (context) => Scaffold(body: child(context))),
  );

  testWidgets('settings expose five layouts and save a map-scoped choice', (
    tester,
  ) async {
    MindMapSettings? saved;
    await tester.pumpWidget(
      localized(
        (context) => FilledButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => MapSettingsPanel(
              initial: const MindMapSettings(),
              strings: resolveMindMapsStrings(context),
              onSave: (value) async {
                saved = value;
                return true;
              },
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kMindMapLayoutFieldKey));
    await tester.pumpAndSettle();
    for (final label in [
      'Radial',
      'Tree',
      'Horizontal',
      'Vertical',
      'Freeform',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Horizontal').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(kMindMapSettingsSaveKey));
    await tester.tap(find.byKey(kMindMapSettingsSaveKey));
    await tester.pumpAndSettle();
    expect(saved!.layout, MapLayout.horizontal);
  });

  testWidgets('node editor offers shape, icon and text size', (tester) async {
    MapNodeDraft? draft;
    await tester.pumpWidget(
      localized(
        (context) => FilledButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => MapNodeEditor(
              strings: resolveMindMapsStrings(context),
              onSave: (value) async {
                draft = value;
                return true;
              },
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(kMindMapNodeTitleFieldKey), 'Mixed فكرة');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('shape-roundedRectangle')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Node shape'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('shape-roundedRectangle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pill').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('icon-idea')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('icon-idea')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Star').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('size-Node size-medium')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('size-Node size-medium')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Large').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(kMindMapNodeSaveKey));
    await tester.tap(find.byKey(kMindMapNodeSaveKey));
    await tester.pumpAndSettle();
    expect(draft!.title, 'Mixed فكرة');
    expect(draft!.appearance.shape, MapNodeShape.pill);
    expect(draft!.appearance.icon, 'star');
    expect(draft!.appearance.nodeSize, MapSize.large);
  });

  testWidgets('RTL canvas has visible viewport controls and keyboard focus', (
    tester,
  ) async {
    final at = DateTime.utc(2026, 10, 19);
    final node = MindMapNode(
      ownerId: 'owner',
      mapId: 'map',
      id: 'center',
      kind: MindMapNodeKind.central,
      title: 'Mind فكرة',
      x: 0,
      y: 0,
      revisionId: 'v',
      createdAt: at,
      updatedAt: at,
    );
    final graph = MapGraph(
      map: MindMap(
        ownerId: 'owner',
        id: 'map',
        title: 'Mind فكرة',
        centralNodeId: 'center',
        revisionId: 'v',
        createdAt: at,
        updatedAt: at,
      ),
      nodes: [node],
      parentSlots: const [],
      sideLinks: const [],
    );
    String? selected;
    await tester.pumpWidget(
      localized(
        (context) => MapCanvas(
          graph: graph,
          selectedId: node.id,
          onSelect: (id) => selected = id,
          onMove: (_, _, _) async => true,
          strings: resolveMindMapsStrings(context),
        ),
        language: 'ar',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kMindMapFitKey), findsOneWidget);
    expect(find.byKey(kMindMapCenterKey), findsOneWidget);
    expect(find.byTooltip('تكبير'), findsOneWidget);
    expect(find.byTooltip('تحريك لليسار'), findsOneWidget);
    final controller = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    final scale = controller.value.getMaxScaleOnAxis();
    await tester.tap(find.byKey(kMindMapZoomInKey));
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(scale));
    final focus = tester
        .widget<Focus>(
          find
              .ancestor(
                of: find.byKey(kMindMapCanvasKey),
                matching: find.byType(Focus),
              )
              .first,
        )
        .focusNode!;
    focus.requestFocus();
    await tester.pump();
    final previous = controller.value.entry(0, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(controller.value.entry(0, 3), greaterThan(previous));
    await tester.tap(find.byKey(const ValueKey('mind-map-canvas-node-center')));
    expect(selected, 'center');
    final beforeMove = tester.getCenter(
      find.byKey(const ValueKey('mind-map-canvas-node-center')),
    );
    final moved = MindMapNode(
      ownerId: node.ownerId,
      mapId: node.mapId,
      id: node.id,
      kind: node.kind,
      title: node.title,
      x: 100,
      y: 0,
      revisionId: 'v2',
      createdAt: at,
      updatedAt: at,
    );
    await tester.pumpWidget(
      localized(
        (context) => MapCanvas(
          graph: MapGraph(
            map: graph.map,
            nodes: [moved],
            parentSlots: const [],
            sideLinks: const [],
          ),
          selectedId: moved.id,
          onSelect: (id) => selected = id,
          onMove: (_, _, _) async => true,
          strings: resolveMindMapsStrings(context),
        ),
        language: 'ar',
      ),
    );
    await tester.pump();
    final afterMove = tester.getCenter(
      find.byKey(const ValueKey('mind-map-canvas-node-center')),
    );
    expect(afterMove.dx - beforeMove.dx, greaterThan(50));
  });
}

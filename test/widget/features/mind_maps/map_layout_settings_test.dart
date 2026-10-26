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

  testWidgets(
    'settings expose prototype layouts and save a map-scoped choice',
    (tester) async {
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
      await tester.ensureVisible(find.byKey(kMindMapLayoutFieldKey));
      await tester.pumpAndSettle();
      for (final label in ['Radial', 'Tree', 'Horizontal', 'Freeform']) {
        expect(find.text(label), findsWidgets);
      }
      await tester.ensureVisible(find.text('Horizontal').last);
      await tester.tap(find.text('Horizontal').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(kMindMapSettingsSaveKey));
      await tester.tap(find.byKey(kMindMapSettingsSaveKey));
      await tester.pumpAndSettle();
      expect(saved!.layout, MapLayout.horizontal);
    },
  );

  testWidgets('node editor saves prototype color, shape, icon and size', (
    tester,
  ) async {
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
    await tester.ensureVisible(find.byKey(const Key('node-shape-field')));
    expect(find.text('Node shape'), findsOneWidget);
    await tester.tap(find.byKey(const Key('node-shape-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pill').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('node-size-field')));
    await tester.tap(find.byKey(const Key('node-size-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Large').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('node-color-${0xffa855f7}')),
    );
    await tester.tap(find.byKey(const ValueKey('node-color-${0xffa855f7}')));
    await tester.ensureVisible(find.byKey(const ValueKey('node-icon-star')));
    await tester.tap(find.byKey(const ValueKey('node-icon-star')));
    await tester.tap(find.byKey(kMindMapNodeSaveKey));
    await tester.pumpAndSettle();
    expect(draft!.title, 'Mixed فكرة');
    expect(draft!.appearance.shape, MapNodeShape.pill);
    expect(draft!.appearance.icon, 'star');
    expect(draft!.appearance.argb, 0xffa855f7);
    expect(draft!.appearance.nodeSize, MapSize.large);
    expect(draft!.appearance.textSize, MapSize.large);
  });

  testWidgets(
    'glass node shows a blurred surface and icon badge in both themes',
    (tester) async {
      final at = DateTime.utc(2026, 10, 26);
      final node = MindMapNode(
        ownerId: 'owner',
        mapId: 'map',
        id: 'glass',
        kind: MindMapNodeKind.central,
        title: 'Glass',
        x: 0,
        y: 0,
        appearance: const MapNodeAppearance(
          shape: MapNodeShape.glass,
          icon: 'sparkles',
          argb: 0xffa855f7,
        ),
        revisionId: 'v',
        createdAt: at,
        updatedAt: at,
      );
      final graph = MapGraph(
        map: MindMap(
          ownerId: 'owner',
          id: 'map',
          title: 'Glass',
          centralNodeId: node.id,
          revisionId: 'v',
          createdAt: at,
          updatedAt: at,
        ),
        nodes: [node],
        parentSlots: const [],
        sideLinks: const [],
      );
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            locale: const Locale('en'),
            localizationsDelegates:
                FoundationLocalizations.localizationsDelegates,
            supportedLocales: FoundationLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: MapCanvas(
                  graph: graph,
                  selectedId: '',
                  onSelect: (_) {},
                  onMove: (_, _, _) async => true,
                  strings: resolveMindMapsStrings(context),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final tile = find.byKey(const ValueKey('mind-map-canvas-node-glass'));
        expect(tile, findsOneWidget);
        expect(
          find.ancestor(of: tile, matching: find.byType(BackdropFilter)),
          findsOneWidget,
        );
        final badge = tester.widget<Container>(
          find.byKey(const ValueKey('mind-map-node-icon-badge-glass')),
        );
        final decoration = badge.decoration! as BoxDecoration;
        expect(decoration.color!.a, greaterThan(0));
        expect(decoration.color!.a, lessThan(1));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'round node controls stay inside the circle and text is centered',
    (tester) async {
      final at = DateTime.utc(2026, 10, 26);
      for (final size in MapSize.values) {
        final node = MindMapNode(
          ownerId: 'owner',
          mapId: 'map',
          id: 'circle',
          kind: MindMapNodeKind.central,
          title: 'pro',
          x: 0,
          y: 0,
          appearance: MapNodeAppearance(
            shape: MapNodeShape.circle,
            icon: 'compass',
            nodeSize: size,
            textSize: size,
          ),
          revisionId: 'v',
          createdAt: at,
          updatedAt: at,
        );
        final graph = MapGraph(
          map: MindMap(
            ownerId: 'owner',
            id: 'map',
            title: 'Circle',
            centralNodeId: node.id,
            revisionId: 'v',
            createdAt: at,
            updatedAt: at,
          ),
          nodes: [node],
          parentSlots: const [],
          sideLinks: const [],
        );
        await tester.pumpWidget(
          localized(
            (context) => MapCanvas(
              graph: graph,
              selectedId: '',
              onSelect: (_) {},
              onMove: (_, _, _) async => true,
              onStatusTap: (_) {},
              strings: resolveMindMapsStrings(context),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final circle = tester.getRect(
          find.byKey(const ValueKey('mind-map-canvas-node-circle')),
        );
        final center = circle.center;
        final radius = circle.width / 2;
        for (final key in [
          const ValueKey('mind-map-node-status-badge-circle'),
          const ValueKey('mind-map-node-icon-badge-circle'),
        ]) {
          final badge = tester.getRect(find.byKey(key));
          for (final corner in [
            badge.topLeft,
            badge.topRight,
            badge.bottomLeft,
            badge.bottomRight,
          ]) {
            expect((corner - center).distance, lessThan(radius));
          }
        }
        expect(
          (tester.getCenter(find.text('pro')) - center).distance,
          lessThan(1),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('authored text grows each node shape instead of being clipped', (
    tester,
  ) async {
    final at = DateTime.utc(2026, 10, 26);
    const longTitle =
        'خطة التعلم والعمل اليومي ومتابعة العادات والمهام المهمة بالتفصيل';
    const longDescription =
        'شرح طويل أكتبه داخل العقدة حتى يظهر كاملًا، مع خطوات العمل وملاحظات إضافية يمكن الرجوع إليها في أي وقت.';

    Future<Size> render(
      MapNodeShape shape,
      String title,
      String? description, {
      double textScale = 1,
    }) async {
      final node = MindMapNode(
        ownerId: 'owner',
        mapId: 'map',
        id: 'sized',
        kind: MindMapNodeKind.central,
        title: title,
        description: description,
        x: 0,
        y: 0,
        appearance: MapNodeAppearance(shape: shape, icon: 'book'),
        revisionId: 'v',
        createdAt: at,
        updatedAt: at,
      );
      final graph = MapGraph(
        map: MindMap(
          ownerId: 'owner',
          id: 'map',
          title: 'Sized',
          centralNodeId: node.id,
          revisionId: 'v',
          createdAt: at,
          updatedAt: at,
        ),
        nodes: [node],
        parentSlots: const [],
        sideLinks: const [],
      );
      await tester.pumpWidget(
        localized(
          (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: MapCanvas(
              graph: graph,
              selectedId: '',
              onSelect: (_) {},
              onMove: (_, _, _) async => true,
              onStatusTap: (_) {},
              strings: resolveMindMapsStrings(context),
            ),
          ),
          language: 'ar',
        ),
      );
      await tester.pumpAndSettle();
      final titleWidget = tester.widget<Text>(find.text(title));
      expect(titleWidget.maxLines, isNull);
      expect(titleWidget.overflow, isNull);
      if (description != null) {
        expect(find.text(description), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      final controller = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;
      final scale = controller.value.getMaxScaleOnAxis();
      final rendered = tester.getSize(
        find.byKey(const ValueKey('mind-map-canvas-node-sized')),
      );
      final nodeRect = tester.getRect(
        find.byKey(const ValueKey('mind-map-canvas-node-sized')),
      );
      final titleRect = tester.getRect(find.text(title));
      if (shape != MapNodeShape.pill) {
        final badgeRect = tester.getRect(
          find.byKey(const ValueKey('mind-map-node-status-badge-sized')),
        );
        expect(titleRect.top, greaterThan(badgeRect.bottom));
      }
      final contentCorners = <Offset>[
        titleRect.topLeft,
        titleRect.bottomRight,
        if (description != null) ...[
          tester.getRect(find.text(description)).topLeft,
          tester.getRect(find.text(description)).bottomRight,
        ],
      ];
      for (final corner in contentCorners) {
        expect(nodeRect.contains(corner), isTrue);
        if (shape == MapNodeShape.circle) {
          expect(
            (corner - nodeRect.center).distance,
            lessThan(nodeRect.width / 2),
          );
        }
      }
      return Size(rendered.width / scale, rendered.height / scale);
    }

    for (final shape in [
      MapNodeShape.circle,
      MapNodeShape.ellipse,
      MapNodeShape.roundedRectangle,
      MapNodeShape.glass,
      MapNodeShape.pill,
    ]) {
      final short = await render(shape, 'قصير', null);
      final long = await render(shape, longTitle, longDescription);
      expect(long.width > short.width || long.height > short.height, isTrue);
      final enlarged = await render(
        shape,
        longTitle,
        longDescription,
        textScale: 1.8,
      );
      expect(enlarged.height, greaterThanOrEqualTo(long.height));
    }
    final unbroken = await render(
      MapNodeShape.circle,
      List.filled(18, 'LongUnbrokenNodeTitle').join(),
      longDescription,
      textScale: 2,
    );
    expect(unbroken.width, greaterThan(144));
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
    await tester.tap(find.byTooltip('تحريك العقدة'));
    await tester.pumpAndSettle();
    expect(find.text('تحريك لليسار'), findsOneWidget);
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/mind_maps_strings_adapter.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_editor_history.dart';
import 'package:namma_project/features/mind_maps/application/map_graph_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';
import 'package:namma_project/features/mind_maps/presentation/map_canvas.dart';
import 'package:namma_project/features/mind_maps/presentation/map_editor_cubit.dart';
import 'package:namma_project/features/mind_maps/presentation/map_editor_screen.dart';
import 'package:namma_project/features/mind_maps/presentation/map_editor_state.dart';
import 'package:namma_project/features/mind_maps/presentation/map_node_editor.dart';

import '../../../support/mind_maps_test_support.dart';

void main() {
  late MindMapsTestSession session;
  late _MemoryMapRepository repo;
  late MapEditorCubit cubit;

  setUp(() async {
    session = MindMapsTestSession();
    final ids = MindMapsTestIds();
    final clock = MindMapsTestClock();
    repo = _MemoryMapRepository();
    final map = (await MapCommands(
      repository: repo,
      session: session,
      nextId: ids.nextOperationId,
      nowUtc: clock.nextVersion,
    ).createMap(title: 'Ideas')).valueOrNull!;
    cubit = MapEditorCubit(
      repository: repo,
      commands: MapGraphCommands(
        repository: repo,
        session: session,
        nextId: ids.nextOperationId,
        nowUtc: clock.nextVersion,
      ),
      history: MapEditorHistory(
        repository: repo,
        session: session,
        ownerId: kMindMapsTestAccountA,
        mapId: map.id,
        nextId: ids.nextOperationId,
        nowUtc: clock.nextVersion,
      ),
      ownerId: kMindMapsTestAccountA,
      mapId: map.id,
    );
  });
  tearDown(() async {
    await session.dispose();
    await repo.close();
  });

  testWidgets('node controls validate, update progress and undo/redo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: MapEditorScreen(
          cubit: cubit,
          stringsResolver: resolveMindMapsStrings,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kMindMapEditorKey), findsOneWidget);
    final centerId = (cubit.state as MapEditorReady).graph.map.centralNodeId;
    final center = tester.getCenter(find.byKey(
      ValueKey('mind-map-canvas-node-$centerId')));
    expect(tester.getRect(find.byKey(kMindMapCanvasKey)).contains(center), true);
    expect(find.textContaining('Completed: 0/1'), findsOneWidget);
    await tester.tap(find.byKey(kMindMapAddNodeKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(kMindMapNodeTitleFieldKey), '   ');
    await tester.tap(find.byKey(kMindMapNodeSaveKey));
    await tester.pumpAndSettle();
    expect(find.text('Enter a node title'), findsOneWidget);
    await tester.enterText(find.byKey(kMindMapNodeTitleFieldKey), 'Branch A');
    await tester.tap(find.byKey(kMindMapNodeSaveKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kMindMapNodeSaveKey), findsNothing);
    expect(find.textContaining('Completed: 0/2'), findsOneWidget);
    expect(find.text('Branch A'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('mind_map_parent_picker')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Parent branch'), findsOneWidget);
    expect(find.text('Visual link'), findsWidgets);
    await tester.tap(find.text('Detach from parent'));
    await tester.pumpAndSettle();
    expect((cubit.state as MapEditorReady).graph.parentSlots, isEmpty);
    await tester.tap(find.byKey(kMindMapUndoKey));
    await tester.pumpAndSettle();
    expect((cubit.state as MapEditorReady).graph.parentSlots, hasLength(1));
    final edit = find.text('Edit node');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not started').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completed').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kMindMapNodeSaveKey));
    await tester.pumpAndSettle();
    expect((cubit.state as MapEditorReady).summary.progressPercent, 50);
    await tester.tap(find.byKey(kMindMapUndoKey));
    await tester.pumpAndSettle();
    expect((cubit.state as MapEditorReady).summary.completedCount, 0);
    await tester.tap(find.byKey(kMindMapRedoKey));
    await tester.pumpAndSettle();
    expect((cubit.state as MapEditorReady).summary.completedCount, 1);
    await tester.ensureVisible(find.byKey(kMindMapDeleteNodeKey));
    await tester.tap(find.byKey(kMindMapDeleteNodeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete node').last);
    await tester.pumpAndSettle();
    expect((cubit.state as MapEditorReady).summary.nodeCount, 1);
  });
}

final class _MemoryMapRepository implements MapRepository {
  final _changes = StreamController<MapGraph?>.broadcast(sync: true);
  MindMap? _map;
  final _nodes = <String, MindMapNode>{};
  final _slots = <String, ParentSlot>{};
  final _links = <String, SideLink>{};

  MapGraph? _snapshot(String ownerId, String mapId) {
    final map = _map;
    if (map == null ||
        map.ownerId != ownerId ||
        map.id != mapId ||
        map.isDeleted) {
      return null;
    }
    final nodes = _nodes.values.where((node) => !node.isDeleted).toList();
    final ids = nodes.map((node) => node.id).toSet();
    return MapGraph(
      map: map,
      nodes: nodes,
      parentSlots: _slots.values.where(
        (slot) =>
            !slot.isDeleted &&
            ids.contains(slot.childNodeId) &&
            ids.contains(slot.parentNodeId),
      ),
      sideLinks: _links.values.where(
        (link) =>
            !link.isDeleted &&
            ids.contains(link.firstNodeId) &&
            ids.contains(link.secondNodeId),
      ),
    );
  }

  @override
  Future<AppResult<MapGraph?>> readGraph({
    required String ownerId,
    required String mapId,
  }) async => AppResult.success(_snapshot(ownerId, mapId));

  @override
  Stream<MapGraph?> watchGraph({
    required String ownerId,
    required String mapId,
  }) => Stream.multi((controller) {
    final subscription = _changes.stream.listen(
      (_) => controller.add(_snapshot(ownerId, mapId)),
    );
    controller.add(_snapshot(ownerId, mapId));
    controller.onCancel = subscription.cancel;
  });

  @override
  Stream<List<MapGraph>> watchGraphs(String ownerId) => watchGraph(
    ownerId: ownerId,
    mapId: _map?.id ?? '',
  ).map((graph) => graph == null ? [] : [graph]);

  @override
  Future<AppResult<void>> commit(MapWriteBatch batch) async {
    if (!await batch.verifyOwner()) throw StateError('owner changed');
    for (final change in batch.maps) {
      _map = change.value;
    }
    for (final change in batch.nodes) {
      _nodes[change.value.id] = change.value;
    }
    for (final change in batch.parentSlots) {
      _slots[change.value.id] = change.value;
    }
    for (final change in batch.sideLinks) {
      _links[change.value.id] = change.value;
    }
    _changes.add(_snapshot(batch.ownerId, _map!.id));
    return const AppResult.success(null);
  }

  Future<void> close() => _changes.close();
}

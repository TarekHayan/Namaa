import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/mind_maps_strings_adapter.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/domain/map_connection.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';
import 'package:namma_project/features/mind_maps/presentation/map_library_cubit.dart';
import 'package:namma_project/features/mind_maps/presentation/map_library_screen.dart';
import 'package:namma_project/features/mind_maps/presentation/map_library_state.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/mind_maps_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'preview library creates, searches, copies full graph, deletes and reopens offline',
    (tester) async {
      final temp = TemporaryDatabasePath();
      final path = temp.allocate();
      final key = List<int>.generate(32, (i) => 0xb0 + i);
      var db = await FoundationDatabase.openEncrypted(path: path, key: key);
      DriftMapRepository store() =>
          DriftMapRepository(database: db, codec: const MapPayloadCodec());
      var repo = store();
      final ids = MindMapsTestIds();
      final clock = MindMapsTestClock();
      MapCommands actions(DriftMapRepository repository) => MapCommands(
        repository: repository,
        session: const TasksPreviewSession(),
        nextId: ids.nextOperationId,
        nowUtc: clock.nextVersion,
      );
      var commands = actions(repo);
      var cubit = MapLibraryCubit(repository: repo, commands: commands);
      Future<void> waitFor(bool Function(MapLibraryReady) matches) async {
        final current = cubit.state;
        if (current is MapLibraryReady && matches(current)) return;
        await cubit.stream
            .where((state) => state is MapLibraryReady)
            .cast<MapLibraryReady>()
            .firstWhere(matches)
            .timeout(const Duration(seconds: 10));
      }

      Future<void> selectMapAction(String mapId, String action) async {
        final menu = find.byKey(ValueKey('mind-map-menu-$mapId'));
        await tester.ensureVisible(menu);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        final item = find.byKey(ValueKey('mind-map-$action-$mapId'));
        expect(item, findsOneWidget);
        await tester.tap(item);
        await tester.pumpAndSettle();
      }

      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await cubit.close();
        await db.close();
        temp.dispose();
      });

      await cubit.load(kTasksPreviewAccountId);
      if (cubit.state is! MapLibraryReady) {
        await cubit.stream
            .firstWhere((state) => state is MapLibraryReady)
            .timeout(const Duration(seconds: 10));
      }
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          supportedLocales: FoundationLocalizations.supportedLocales,
          home: MapLibraryScreen(
            cubit: cubit,
            ownerId: kTasksPreviewAccountId,
            stringsResolver: resolveMindMapsStrings,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kMapLibraryCreateKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(kMapLibraryTitleFieldKey), 'First map');
      await tester.tap(find.text('Save'));
      await waitFor(
        (ready) => ready.maps.any((item) => item.map.title == 'First map'),
      );
      await tester.pumpAndSettle();
      expect(find.text('First map'), findsOneWidget);
      final first = (await repo.watchGraphs(kTasksPreviewAccountId).first)
          .singleWhere((graph) => graph.map.title == 'First map')
          .map;
      await selectMapAction(first.id, 'rename');
      await tester.enterText(
        find.byKey(kMapLibraryTitleFieldKey),
        'Renamed map',
      );
      await tester.tap(find.byKey(kMapLibrarySaveKey));
      await waitFor(
        (ready) => ready.maps.any((item) => item.map.title == 'Renamed map'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Renamed map'), findsOneWidget);

      await tester.tap(find.byKey(kMapLibraryCreateKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(kMapLibraryTitleFieldKey),
        'Second map',
      );
      await tester.enterText(
        find.byKey(kMapLibraryDescriptionFieldKey),
        'Project ideas',
      );
      await tester.tap(find.text('Save'));
      await waitFor(
        (ready) => ready.maps.any((item) => item.map.title == 'Second map'),
      );
      await tester.pumpAndSettle();
      final second = (await repo.watchGraphs(kTasksPreviewAccountId).first)
          .singleWhere((graph) => graph.map.title == 'Second map')
          .map;
      final firstChild = MindMapNode(
        ownerId: second.ownerId,
        mapId: second.id,
        id: ids.nextNodeId(),
        kind: MindMapNodeKind.task,
        title: 'Linked thought',
        x: 20,
        y: 20,
        taskId: kMindMapsTestTaskId,
        revisionId: ids.nextOperationId(),
        createdAt: clock.nextVersion(),
        updatedAt: clock.nextVersion(),
      );
      final otherChild = MindMapNode(
        ownerId: second.ownerId,
        mapId: second.id,
        id: ids.nextNodeId(),
        kind: MindMapNodeKind.note,
        title: 'Side thought',
        x: 40,
        y: 40,
        revisionId: ids.nextOperationId(),
        createdAt: clock.nextVersion(),
        updatedAt: clock.nextVersion(),
      );
      final slot = ParentSlot(
        ownerId: second.ownerId,
        mapId: second.id,
        childNodeId: firstChild.id,
        parentNodeId: second.centralNodeId,
        revisionId: ids.nextOperationId(),
        updatedAt: clock.nextVersion(),
      );
      final side = SideLink(
        ownerId: second.ownerId,
        mapId: second.id,
        firstNodeId: firstChild.id,
        secondNodeId: otherChild.id,
        revisionId: ids.nextOperationId(),
        updatedAt: clock.nextVersion(),
      );
      expect(
        (await repo.commit(
          MapWriteBatch(
            ownerId: second.ownerId,
            queuedAt: clock.nextVersion(),
            verifyOwner: () async => true,
            nodes: [
              for (final node in [firstChild, otherChild])
                MapChange(
                  value: node,
                  operationId: ids.nextOperationId(),
                  kind: ChangeKind.create,
                ),
            ],
            parentSlots: [
              MapChange(
                value: slot,
                operationId: ids.nextOperationId(),
                kind: ChangeKind.create,
              ),
            ],
            sideLinks: [
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

      await tester.enterText(find.byKey(kMapLibrarySearchKey), 'PROJECT');
      await tester.pumpAndSettle();
      expect(find.text('Second map'), findsOneWidget);
      expect(find.text('First map'), findsNothing);
      await tester.enterText(find.byKey(kMapLibrarySearchKey), '');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await selectMapAction(second.id, 'duplicate');
      await waitFor(
        (ready) =>
            ready.maps.where((item) => item.map.title == 'Second map').length ==
            2,
      );
      await tester.pumpAndSettle();
      final copy = (await repo.watchGraphs(kTasksPreviewAccountId).first)
          .singleWhere(
            (graph) =>
                graph.map.title == 'Second map' && graph.map.id != second.id,
          )
          .map;
      final copied = (await repo.readGraph(
        ownerId: kTasksPreviewAccountId,
        mapId: copy.id,
      )).valueOrNull!;
      expect(copied.nodes, hasLength(3));
      expect(copied.parentSlots, hasLength(1));
      expect(copied.sideLinks, hasLength(1));
      expect(
        copied.nodes
            .singleWhere((node) => node.title == 'Linked thought')
            .taskId,
        kMindMapsTestTaskId,
      );
      expect(
        copied.nodes.map((node) => node.id).toSet().intersection({
          second.centralNodeId,
          firstChild.id,
          otherChild.id,
        }),
        isEmpty,
      );
      await selectMapAction(second.id, 'delete');
      await tester.tap(find.byKey(kMapLibraryConfirmDeleteKey));
      await waitFor(
        (ready) =>
            ready.maps.where((item) => item.map.title == 'Second map').length ==
            1,
      );
      await tester.pumpAndSettle();
      expect(
        (await repo.readGraph(
          ownerId: kTasksPreviewAccountId,
          mapId: second.id,
        )).valueOrNull,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
      await db.close();
      db = await FoundationDatabase.openEncrypted(path: path, key: key);
      repo = store();
      commands = actions(repo);
      cubit = MapLibraryCubit(repository: repo, commands: commands);
      final afterRestart = (await repo.readGraph(
        ownerId: kTasksPreviewAccountId,
        mapId: copy.id,
      )).valueOrNull!;
      expect(afterRestart.nodes, hasLength(3));
      expect(
        afterRestart.nodes
            .singleWhere((node) => node.title == 'Linked thought')
            .taskId,
        kMindMapsTestTaskId,
      );
      expect(
        (await repo.readGraph(
          ownerId: kTasksPreviewAccountId,
          mapId: second.id,
        )).valueOrNull,
        isNull,
      );
      await cubit.load(kTasksPreviewAccountId);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          supportedLocales: FoundationLocalizations.supportedLocales,
          home: MapLibraryScreen(
            cubit: cubit,
            ownerId: kTasksPreviewAccountId,
            stringsResolver: resolveMindMapsStrings,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Renamed map'), findsOneWidget);
      expect(find.text('Second map'), findsOneWidget);
      await tester.enterText(find.byKey(kMapLibrarySearchKey), 'PROJECT');
      await tester.pumpAndSettle();
      expect(find.text('Second map'), findsOneWidget);
      expect(find.text('Renamed map'), findsNothing);
    },
  );
}

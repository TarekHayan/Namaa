import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/mind_maps_strings_adapter.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/local/task_completion_unit_of_work.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/data/drift_map_repository.dart';
import 'package:namma_project/features/mind_maps/data/map_payload_codec.dart';
import 'package:namma_project/features/mind_maps/data/tasks_map_link_adapter.dart';
import 'package:namma_project/features/mind_maps/domain/mind_map_node.dart';
import 'package:namma_project/features/mind_maps/presentation/map_canvas.dart';
import 'package:namma_project/features/mind_maps/presentation/map_editor_screen.dart';
import 'package:namma_project/features/mind_maps/presentation/map_editor_state.dart';
import 'package:namma_project/features/mind_maps/presentation/map_library_cubit.dart';
import 'package:namma_project/features/mind_maps/presentation/map_library_screen.dart';
import 'package:namma_project/features/mind_maps/presentation/map_library_state.dart';
import 'package:namma_project/features/mind_maps/presentation/map_node_editor.dart';
import 'package:namma_project/features/mind_maps/presentation/map_task_picker.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/mind_maps_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Arabic touch route and English desktop keyboard controls', (
    tester,
  ) async {
    final temp = TemporaryDatabasePath();
    final database = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (index) => 0x70 + index),
    );
    const session = TasksPreviewSession();
    final ids = MindMapsTestIds();
    final clock = MindMapsTestClock();
    final maps = DriftMapRepository(
      database: database,
      codec: const MapPayloadCodec(),
    );
    final tasks = DriftTaskRepository(
      database: database,
      codec: const TaskPayloadCodec(),
    );
    final task = Task.create(
      id: kMindMapsTestTaskId,
      accountId: kTasksPreviewAccountId,
      title: 'Review Namaa خطة',
      scheduledDate: DateTime(2026, 10, 19),
      createdAt: DateTime.utc(2026, 10, 19),
    );
    expect(
      (await tasks.commitTask(
        TaskWriteRequest(
          task: task,
          operationId: 'localized-route-task',
          kind: ChangeKind.create,
          queuedAt: task.createdAt,
        ),
      )).failureOrNull,
      isNull,
    );
    final bridge = TasksMapLinkAdapter(
      repository: tasks,
      completionService: TaskCompletionService(
        repository: tasks,
        unitOfWork: DriftTaskCompletionUnitOfWork(
          database: database,
          codec: const TaskPayloadCodec(),
          awardLedger: DriftAwardLedger(database),
        ),
        session: session,
      ),
      session: session,
    );
    final cubit = MapLibraryCubit(
      repository: maps,
      commands: MapCommands(
        repository: maps,
        session: session,
        nextId: ids.nextOperationId,
        nowUtc: clock.nextVersion,
      ),
      session: session,
      tasks: bridge,
    );
    final router = FoundationAppRouter(
      rootBuilder: (_) => const Scaffold(body: Text('root')),
      mindMapsSession: session,
      mindMapsBuilder: (_, owner) => MapLibraryScreen(
        cubit: cubit,
        ownerId: owner,
        stringsResolver: resolveMindMapsStrings,
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await cubit.close();
      await database.close();
      temp.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Widget app(Locale locale) => MaterialApp.router(
      locale: locale,
      localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      supportedLocales: FoundationLocalizations.supportedLocales,
      routerConfig: router.router,
    );

    final mobile =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    if (!mobile) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
    }
    await tester.pumpWidget(app(const Locale('ar')));
    router.go(kMindMapsRoute);
    await tester.pumpAndSettle();
    expect(find.text('الخرائط الذهنية'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(kMapLibraryCreateKey))),
      TextDirection.rtl,
    );
    await tester.tap(find.byKey(kMapLibraryCreateKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(kMapLibraryTitleFieldKey),
      'خطة Namaa 2026',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kMapLibrarySaveKey));
    final current = cubit.state;
    if (current is! MapLibraryReady ||
        !current.maps.any((item) => item.map.title == 'خطة Namaa 2026')) {
      await cubit.stream
          .where((state) => state is MapLibraryReady)
          .cast<MapLibraryReady>()
          .firstWhere(
            (ready) =>
                ready.maps.any((item) => item.map.title == 'خطة Namaa 2026'),
          )
          .timeout(const Duration(seconds: 10));
    }
    await tester.pumpAndSettle();
    expect(find.text('خطة Namaa 2026'), findsWidgets);
    await tester.tap(find.text('خطة Namaa 2026').first);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(kMindMapEditorKey), findsOneWidget);
    final editor = tester
        .widget<MapEditorScreen>(find.byType(MapEditorScreen))
        .cubit;
    Future<void> waitForEditor(bool Function(MapEditorReady) matches) async {
      final current = editor.state;
      if (current is MapEditorReady && matches(current)) return;
      await editor.stream
          .where((state) => state is MapEditorReady)
          .cast<MapEditorReady>()
          .firstWhere(matches)
          .timeout(const Duration(seconds: 10));
    }

    expect(find.textContaining('المكتملة: 0/1'), findsOneWidget);
    final rootId = (editor.state as MapEditorReady).graph.nodes.single.id;
    await tester.tap(find.byKey(ValueKey('mind-map-canvas-node-$rootId')));
    await tester.pump();

    await tester.tap(find.byKey(kMindMapAddNodeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mind_map_quick_branch')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(kMindMapNodeTitleFieldKey), 'فرع Alpha');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kMindMapNodeSaveKey));
    await waitForEditor((ready) => ready.summary.nodeCount == 2);
    await tester.pumpAndSettle();
    expect(find.textContaining('المكتملة: 0/2'), findsOneWidget);

    await tester.tap(find.byKey(kMindMapAddNodeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mind_map_quick_note')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(kMindMapNodeTitleFieldKey),
      'ملاحظة Beta',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kMindMapNodeSaveKey));
    await waitForEditor((ready) => ready.summary.nodeCount == 3);
    await tester.pumpAndSettle();
    expect(find.textContaining('المكتملة: 0/3'), findsOneWidget);
    final graph = (await maps.readGraph(
      ownerId: kTasksPreviewAccountId,
      mapId:
          (await maps.watchGraphs(kTasksPreviewAccountId).first).single.map.id,
    )).valueOrNull!;
    expect(graph.parentSlots, hasLength(2));
    expect(graph.nodes.any((node) => node.kind == MindMapNodeKind.note), true);

    expect(editor.taskPort, isNotNull);
    await tester.tap(find.widgetWithText(OutlinedButton, 'تعديل العقدة'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(kMindMapNodeTaskFieldKey));
    await tester.tap(find.byKey(kMindMapNodeTaskFieldKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kMindMapTaskPickerKey), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('mind-map-task-${task.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Review Namaa خطة'), findsOneWidget);
    await tester.tap(find.byKey(kMindMapNodeSaveKey));
    await waitForEditor(
      (ready) => ready.graph.nodes.any((node) => node.taskId == task.id),
    );
    await tester.pumpAndSettle();

    if (!mobile) tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpWidget(app(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.byKey(kMindMapEditorKey), findsOneWidget);
    expect(find.textContaining('Completed:'), findsOneWidget);
    expect(find.byKey(kMindMapCanvasKey), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(kMindMapCanvasKey))),
      TextDirection.ltr,
    );
    final canvasFocus = tester.widget<Focus>(
      find
          .ancestor(
            of: find.byKey(kMindMapCanvasKey),
            matching: find.byType(Focus),
          )
          .first,
    );
    canvasFocus.focusNode!.requestFocus();
    await tester.pump();
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final before = viewer.transformationController!.value.clone();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(viewer.transformationController!.value, isNot(before));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(find.byKey(kMindMapFitKey), findsOneWidget);
  });

  testWidgets('English keyboard walkthrough uses visible map controls', (
    tester,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.windows) return;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    final temp = TemporaryDatabasePath();
    final database = await FoundationDatabase.openEncrypted(
      path: temp.allocate(),
      key: List<int>.generate(32, (index) => 0x90 + index),
    );
    const session = TasksPreviewSession();
    final ids = MindMapsTestIds();
    final clock = MindMapsTestClock();
    final maps = DriftMapRepository(
      database: database,
      codec: const MapPayloadCodec(),
    );
    final tasks = DriftTaskRepository(
      database: database,
      codec: const TaskPayloadCodec(),
    );
    final task = Task.create(
      id: kMindMapsTestTaskId,
      accountId: kTasksPreviewAccountId,
      title: 'Keyboard Task',
      scheduledDate: DateTime(2026, 10, 19),
      createdAt: DateTime.utc(2026, 10, 19),
    );
    expect(
      (await tasks.commitTask(
        TaskWriteRequest(
          task: task,
          operationId: 'keyboard-walkthrough-task',
          kind: ChangeKind.create,
          queuedAt: task.createdAt,
        ),
      )).failureOrNull,
      isNull,
    );
    final bridge = TasksMapLinkAdapter(
      repository: tasks,
      completionService: TaskCompletionService(
        repository: tasks,
        unitOfWork: DriftTaskCompletionUnitOfWork(
          database: database,
          codec: const TaskPayloadCodec(),
          awardLedger: DriftAwardLedger(database),
        ),
        session: session,
      ),
      session: session,
    );
    final cubit = MapLibraryCubit(
      repository: maps,
      commands: MapCommands(
        repository: maps,
        session: session,
        nextId: ids.nextOperationId,
        nowUtc: clock.nextVersion,
      ),
      session: session,
      tasks: bridge,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
      await database.close();
      temp.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
        home: MapLibraryScreen(
          cubit: cubit,
          ownerId: kTasksPreviewAccountId,
          stringsResolver: resolveMindMapsStrings,
        ),
      ),
    );
    await tester.pumpAndSettle();

    bool focusWithin(Finder target) {
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused == null) return false;
      final targetElement = tester.element(target);
      if (identical(focused, targetElement)) return true;
      var found = false;
      focused.visitAncestorElements((ancestor) {
        if (identical(ancestor, targetElement)) found = true;
        return !found;
      });
      return found;
    }

    Future<void> tabTo(Finder target) async {
      expect(target, findsOneWidget);
      for (var step = 0; step < 120; step++) {
        if (focusWithin(target)) return;
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      fail('Tab could not reach $target');
    }

    Future<void> enter(Finder target) async {
      await tabTo(target);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }

    await enter(find.byKey(kMapLibraryCreateKey));
    await tabTo(find.byKey(kMapLibraryTitleFieldKey));
    await tester.enterText(
      find.byKey(kMapLibraryTitleFieldKey),
      'Keyboard map',
    );
    await enter(find.byKey(kMapLibrarySaveKey));
    final libraryState = cubit.state;
    if (libraryState is! MapLibraryReady ||
        !libraryState.maps.any((item) => item.map.title == 'Keyboard map')) {
      await cubit.stream
          .where((state) => state is MapLibraryReady)
          .cast<MapLibraryReady>()
          .firstWhere(
            (ready) =>
                ready.maps.any((item) => item.map.title == 'Keyboard map'),
          )
          .timeout(const Duration(seconds: 10));
    }
    await tester.pumpAndSettle();
    final graph = (await maps.watchGraphs(kTasksPreviewAccountId).first).single;
    final card = find.byKey(ValueKey('mind-map-${graph.map.id}'));
    await enter(
      find.descendant(of: card, matching: find.byType(InkWell)).first,
    );
    expect(find.byKey(kMindMapEditorKey), findsOneWidget);
    await enter(
      find.byKey(ValueKey('mind-map-canvas-node-${graph.nodes.single.id}')),
    );

    await enter(find.byKey(kMindMapAddNodeKey));
    await enter(find.byKey(const ValueKey('mind_map_quick_branch')));
    await tabTo(find.byKey(kMindMapNodeTitleFieldKey));
    await tester.enterText(find.byKey(kMindMapNodeTitleFieldKey), 'Child idea');
    await enter(find.byKey(kMindMapNodeSaveKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Completed: 0/2'), findsOneWidget);

    await enter(find.byKey(kMindMapAddNodeKey));
    await enter(find.byKey(const ValueKey('mind_map_quick_note')));
    await tabTo(find.byKey(kMindMapNodeTitleFieldKey));
    await tester.enterText(
      find.byKey(kMindMapNodeTitleFieldKey),
      'Keyboard note',
    );
    await enter(find.byKey(kMindMapNodeSaveKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Completed: 0/3'), findsOneWidget);
    expect(
      (await maps.readGraph(
        ownerId: kTasksPreviewAccountId,
        mapId: graph.map.id,
      )).valueOrNull!.nodes.any((node) => node.kind == MindMapNodeKind.note),
      isTrue,
    );

    await enter(find.widgetWithText(OutlinedButton, 'Edit node'));
    await tabTo(find.byKey(kMindMapNodeTaskFieldKey));
    await enter(find.byKey(kMindMapNodeTaskFieldKey));
    await enter(find.byKey(ValueKey('mind-map-task-${task.id}')));
    expect(find.text('Keyboard Task'), findsOneWidget);
    await enter(find.byKey(kMindMapNodeSaveKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Completed: 0/3'), findsOneWidget);
  });
}

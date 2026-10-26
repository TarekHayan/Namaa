import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/mind_maps_strings_adapter.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/mind_maps/application/map_commands.dart';
import 'package:namma_project/features/mind_maps/application/map_repository.dart';
import 'package:namma_project/features/mind_maps/presentation/map_editor_screen.dart';
import 'package:namma_project/features/mind_maps/presentation/map_library_cubit.dart';
import 'package:namma_project/features/mind_maps/presentation/map_library_screen.dart';
import 'package:namma_project/features/mind_maps/presentation/map_library_state.dart';

import '../../../support/mind_maps_test_support.dart';

void main() {
  late MindMapsTestSession session;
  late MapLibraryCubit cubit;
  late _WidgetMapRepository repo;

  setUp(() async {
    session = MindMapsTestSession();
    repo = _WidgetMapRepository();
    cubit = MapLibraryCubit(
      repository: repo,
      commands: MapCommands(repository: repo, session: session),
    );
  });
  tearDown(() async {
    await cubit.close();
    await session.dispose();
    await repo.close();
  });

  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: FoundationLocalizations.supportedLocales,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: MapLibraryScreen(
          cubit: cubit,
          ownerId: kMindMapsTestAccountA,
          stringsResolver: resolveMindMapsStrings,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'empty library differs from empty search; create, rename, open and delete',
    (tester) async {
      await open(tester);
      expect(find.byKey(kMapLibraryEmptyKey), findsOneWidget);
      await tester.tap(find.byKey(kMapLibraryCreateKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(kMapLibraryTitleFieldKey), 'Biology');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Biology'), findsOneWidget);
      expect(find.textContaining('Nodes: 1'), findsOneWidget);
      final mapId = (cubit.state as MapLibraryReady).maps.single.map.id;

      await tester.enterText(find.byKey(kMapLibrarySearchKey), 'unmatched');
      await tester.pumpAndSettle();
      expect(find.byKey(kMapLibraryEmptySearchKey), findsOneWidget);
      await tester.enterText(find.byKey(kMapLibrarySearchKey), 'BIO');
      await tester.pumpAndSettle();
      expect(find.text('Biology'), findsOneWidget);

      final rename = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'mind-map-rename-',
            ),
      );
      await tester.tap(find.byKey(ValueKey('mind-map-menu-$mapId')));
      await tester.pumpAndSettle();
      await tester.tap(rename);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(kMapLibraryTitleFieldKey),
        'Biology notes',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Biology notes'), findsOneWidget);

      await tester.tap(find.text('Biology notes'));
      await tester.pumpAndSettle();
      expect(find.text('Central idea'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      final delete = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'mind-map-delete-',
            ),
      );
      await tester.tap(find.byKey(ValueKey('mind-map-menu-$mapId')));
      await tester.pumpAndSettle();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Biology notes'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('mind-map-menu-$mapId')));
      await tester.pumpAndSettle();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kMapLibraryConfirmDeleteKey));
      await tester.pumpAndSettle();
      expect(find.byKey(kMapLibraryEmptyKey), findsOneWidget);
    },
  );

  testWidgets('Arabic title validation and account error are localized', (
    tester,
  ) async {
    await open(tester, locale: const Locale('ar'));
    await tester.tap(find.byKey(kMapLibraryCreateKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('اكتب عنوانًا للخريطة'), findsOneWidget);
    await tester.enterText(find.byKey(kMapLibraryTitleFieldKey), 'خريطة');
    session.signOut();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('لا يمكن لهذا الحساب تعديل الخريطة.'), findsOneWidget);
    expect(find.byKey(kMapLibraryEmptyKey), findsOneWidget);
  });

  testWidgets('an owned map opens its canvas directly', (tester) async {
    await cubit.close();
    cubit = MapLibraryCubit(
      repository: repo,
      commands: MapCommands(repository: repo, session: session),
      session: session,
    );
    await open(tester);
    await tester.tap(find.byKey(kMapLibraryCreateKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(kMapLibraryTitleFieldKey), 'Roadmap');
    await tester.tap(find.byKey(kMapLibrarySaveKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roadmap'));
    await tester.pumpAndSettle();
    expect(find.byKey(kMindMapEditorKey), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    session.signOut();
    await tester.pumpAndSettle();
    expect(find.byKey(kMindMapEditorKey), findsNothing);
  });

  testWidgets('create dialog fits a small phone with the keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await open(tester, locale: const Locale('ar'));
    await tester.tap(find.byKey(kMapLibraryCreateKey));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(find.byKey(kMapLibraryTitleFieldKey), findsOneWidget);
    expect(find.byKey(kMapLibraryDescriptionFieldKey), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(kMapLibraryTitleFieldKey), 'خريطة صغيرة');
    await tester.tap(find.byKey(kMapLibrarySaveKey));
    await tester.pumpAndSettle();
    expect(find.text('خريطة صغيرة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map cards fit a narrow phone with larger Arabic text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await open(tester, locale: const Locale('ar'), textScale: 1.5);
    await tester.tap(find.byKey(kMapLibraryCreateKey));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(kMapLibraryTitleFieldKey), 'خطة التعلم');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(kMapLibrarySaveKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kMapLibraryGridKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Persistence and rollback are tested against Drift separately.
final class _WidgetMapRepository implements MapRepository {
  final _changes = StreamController<List<MapGraph>>.broadcast(sync: true);
  final _graphs = <String, MapGraph>{};

  @override
  Future<AppResult<MapGraph?>> readGraph({
    required String ownerId,
    required String mapId,
  }) async => AppResult.success(
    _graphs[mapId]?.map.ownerId == ownerId ? _graphs[mapId] : null,
  );

  @override
  Stream<List<MapGraph>> watchGraphs(String ownerId) =>
      Stream.multi((controller) {
        final subscription = _changes.stream.listen(
          (_) => controller.add(_owned(ownerId)),
        );
        controller.add(_owned(ownerId));
        controller.onCancel = subscription.cancel;
      });

  @override
  Stream<MapGraph?> watchGraph({
    required String ownerId,
    required String mapId,
  }) => watchGraphs(ownerId).map((graphs) {
    for (final graph in graphs) {
      if (graph.map.id == mapId) return graph;
    }
    return null;
  });

  @override
  Future<AppResult<void>> commit(MapWriteBatch batch) async {
    if (!await batch.verifyOwner()) throw StateError('owner changed');
    for (final change in batch.maps) {
      final map = change.value;
      final old = _graphs[map.id];
      _graphs[map.id] = MapGraph(
        map: map,
        nodes: old?.nodes ?? [],
        parentSlots: old?.parentSlots ?? [],
        sideLinks: old?.sideLinks ?? [],
      );
    }
    for (final change in batch.nodes) {
      final node = change.value;
      final old = _graphs[node.mapId]!;
      _graphs[node.mapId] = MapGraph(
        map: old.map,
        nodes: [...old.nodes.where((item) => item.id != node.id), node],
        parentSlots: old.parentSlots,
        sideLinks: old.sideLinks,
      );
    }
    _changes.add(_graphs.values.toList());
    return const AppResult.success(null);
  }

  List<MapGraph> _owned(String ownerId) => _graphs.values
      .where((graph) => graph.map.ownerId == ownerId && !graph.map.isDeleted)
      .toList();

  Future<void> close() => _changes.close();
}

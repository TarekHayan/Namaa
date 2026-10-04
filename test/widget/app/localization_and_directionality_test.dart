import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/app.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/foundation/application/foundation_use_cases.dart';
import 'package:namma_project/features/foundation/application/locale_preferences.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';

class _WidgetLocaleStore implements LocalStorePort {
  _WidgetLocaleStore({Map<String, String>? preferences})
    : preferences = <String, String>{...?preferences};

  final Map<String, String> preferences;

  @override
  Future<AppResult<String?>> readPreference(String key) async =>
      AppResult<String?>.success(preferences[key]);
  @override
  Future<AppResult<void>> savePreference(String key, String value) async {
    preferences[key] = value;
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> acknowledgeChange(String a, String b) async =>
      AppResult<void>.success(null);
  @override
  Future<AppResult<void>> commitLocalChange(
    LocalRecordChange a,
    PendingChangeRequest b,
  ) async => AppResult<void>.success(null);
  @override
  Future<AppResult<void>> markChangeConflicted(String a) async =>
      AppResult<void>.success(null);
  @override
  Future<AppResult<List<PendingChangeRecord>>> readPendingChanges(
    String a,
  ) async => AppResult<List<PendingChangeRecord>>.success(const []);
  @override
  Future<AppResult<void>> recordConflict(ConflictRecordInput a) async =>
      AppResult<void>.success(null);
  @override
  Future<AppResult<void>> recordConflictAndFinalize({
    required ConflictRecordInput conflict,
    required String operationId,
  }) async => AppResult<void>.success(null);
  @override
  Future<AppResult<void>> recordRecoverableFailure(String a, String b) async =>
      AppResult<void>.success(null);
  @override
  Future<AppResult<MigrationOutcome>> runMigration(int a) async =>
      AppResult<MigrationOutcome>.success(
        MigrationOutcome(completedVersion: a, recovered: false),
      );
}

FoundationCubit _readyFoundationCubit() =>
    FoundationCubit(BootstrapUseCase(cloudSession: _ReadyCloudSession()));

class _ReadyCloudSession implements CloudSessionPort {
  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);
  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();
  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult<CloudSyncContext>.success(
        const CloudSyncContext(accountId: 'account-1'),
      );
}

LocaleCubit _localeCubit(_WidgetLocaleStore store) => LocaleCubit(
  restore: RestoreLocalePreferenceUseCase(localStore: store),
  save: SaveLocalePreferenceUseCase(localStore: store),
);

Future<void> _pumpApp(
  WidgetTester tester, {
  required FoundationCubit foundationCubit,
  required LocaleCubit localeCubit,
}) async {
  await tester.pumpWidget(
    FoundationApp(
      cubitOverride: foundationCubit,
      localeCubitOverride: localeCubit,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Arabic root text renders RTL', (tester) async {
    final foundationCubit = _readyFoundationCubit();
    final localeCubit = _localeCubit(
      _WidgetLocaleStore(preferences: {'locale': 'ar'}),
    );
    addTearDown(foundationCubit.close);
    addTearDown(localeCubit.close);

    await _pumpApp(
      tester,
      foundationCubit: foundationCubit,
      localeCubit: localeCubit,
    );

    expect(find.text('نماء جاهز'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(kFoundationRootReadyKey))),
      TextDirection.rtl,
    );
  });

  testWidgets('English root text renders LTR', (tester) async {
    final foundationCubit = _readyFoundationCubit();
    final localeCubit = _localeCubit(
      _WidgetLocaleStore(preferences: {'locale': 'en'}),
    );
    addTearDown(foundationCubit.close);
    addTearDown(localeCubit.close);

    await _pumpApp(
      tester,
      foundationCubit: foundationCubit,
      localeCubit: localeCubit,
    );

    expect(find.text('Namaa is ready'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(kFoundationRootReadyKey))),
      TextDirection.ltr,
    );
  });

  testWidgets('the root uses Thmanyah Sans as the default UI font', (
    tester,
  ) async {
    final foundationCubit = _readyFoundationCubit();
    final localeCubit = _localeCubit(_WidgetLocaleStore());
    addTearDown(foundationCubit.close);
    addTearDown(localeCubit.close);

    await _pumpApp(
      tester,
      foundationCubit: foundationCubit,
      localeCubit: localeCubit,
    );

    final context = tester.element(find.byKey(kFoundationRootReadyKey));
    expect(
      Theme.of(context).textTheme.bodyMedium?.fontFamily,
      kProjectFontFamily,
    );
  });

  testWidgets('switching the language updates root text and directionality', (
    tester,
  ) async {
    final foundationCubit = _readyFoundationCubit();
    final localeCubit = _localeCubit(_WidgetLocaleStore());
    addTearDown(foundationCubit.close);
    addTearDown(localeCubit.close);

    await _pumpApp(
      tester,
      foundationCubit: foundationCubit,
      localeCubit: localeCubit,
    );
    await localeCubit.selectLanguage('ar');
    await tester.pumpAndSettle();

    expect(find.text('نماء جاهز'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(kFoundationRootReadyKey))),
      TextDirection.rtl,
    );
  });

  testWidgets('a selected locale is restored after an app restart', (
    tester,
  ) async {
    final store = _WidgetLocaleStore();
    final firstFoundationCubit = _readyFoundationCubit();
    final firstLocaleCubit = _localeCubit(store);
    await _pumpApp(
      tester,
      foundationCubit: firstFoundationCubit,
      localeCubit: firstLocaleCubit,
    );
    await firstLocaleCubit.selectLanguage('ar');
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await firstFoundationCubit.close();
    await firstLocaleCubit.close();

    final restartedFoundationCubit = _readyFoundationCubit();
    final restartedLocaleCubit = _localeCubit(store);
    addTearDown(restartedFoundationCubit.close);
    addTearDown(restartedLocaleCubit.close);
    await _pumpApp(
      tester,
      foundationCubit: restartedFoundationCubit,
      localeCubit: restartedLocaleCubit,
    );

    expect(find.text('نماء جاهز'), findsOneWidget);
  });
}

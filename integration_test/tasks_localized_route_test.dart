import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/tasks_strings_adapter.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/local/foundation_database.dart';
import 'package:namma_project/core/data/local/task_completion_unit_of_work.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/data/drift_task_repository.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/tasks/presentation/tasks_cubit.dart';
import 'package:namma_project/features/tasks/presentation/tasks_screen.dart';
import 'package:namma_project/features/xp/data/drift_award_ledger.dart';

import '../test/support/foundation_test_support.dart';
import '../test/support/tasks_test_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Tasks route keeps Arabic/English direction and Task identity', (
    tester,
  ) async {
    final path = TemporaryDatabasePath();
    final database = await FoundationDatabase.openEncrypted(
      path: path.allocate(),
      key: List<int>.generate(32, (index) => 0x41 + index),
    );
    const codec = TaskPayloadCodec();
    final repository = DriftTaskRepository(database: database, codec: codec);
    final awards = DriftAwardLedger(database);
    final clock = TasksTestClock();
    final ids = TasksTestIds();
    const session = _Session();
    final task = Task.create(
      id: kTasksTestTaskId,
      accountId: kTasksTestAccountA,
      title: 'Native parity task',
      scheduledDate: clock.localDate(),
      createdAt: clock.utcNow(),
    );
    expect(
      (await repository.commitTask(
        TaskWriteRequest(
          task: task,
          operationId: 'native-route-seed',
          kind: ChangeKind.create,
          queuedAt: clock.utcNow(),
        ),
      )).failureOrNull,
      isNull,
    );
    final cubit = TasksCubit(
      repository: repository,
      commands: TaskCommands(
        repository: repository,
        session: session,
        nowUtc: clock.utcNow,
        localDate: clock.localDate,
        nextTaskId: ids.nextTaskId,
        nextOperationId: ids.nextOperationId,
      ),
      completionService: TaskCompletionService(
        repository: repository,
        unitOfWork: DriftTaskCompletionUnitOfWork(
          database: database,
          codec: codec,
          awardLedger: awards,
        ),
        session: session,
        nowUtc: clock.utcNow,
        nextOperationId: ids.nextOperationId,
      ),
      awardLedger: awards,
      localDate: clock.localDate,
    );
    addTearDown(() async {
      await cubit.close();
      await database.close();
      path.dispose();
    });

    final nativeMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    for (final locale in const <Locale>[Locale('en'), Locale('ar')]) {
      final router = FoundationAppRouter(
        rootBuilder: (_) => const Scaffold(body: Text('Root')),
        cloudSession: session,
        tasksBuilder: (_, accountId) => TasksScreen(
          cubit: cubit,
          accountId: accountId,
          stringsResolver: resolveTasksStrings,
          session: session,
        ),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: locale,
          supportedLocales: FoundationLocalizations.supportedLocales,
          localizationsDelegates:
              FoundationLocalizations.localizationsDelegates,
          routerConfig: router.router,
        ),
      );
      router.go(kTasksRoute);
      await tester.pumpAndSettle();

      final layout = find.byKey(
        nativeMobile ? kTasksMobileLayoutKey : kTasksDesktopLayoutKey,
      );
      expect(layout, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('task-$kTasksTestTaskId')),
        findsOneWidget,
      );
      expect(
        Directionality.of(tester.element(layout)),
        locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
      expect(
        find.text(
          FoundationLocalizations.of(tester.element(layout)).tasksTitle,
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(kTasksMatrixToggleKey));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('matrix-task-$kTasksTestTaskId')),
        findsOneWidget,
      );
      cubit.showList();
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    }
  });
}

final class _Session implements CloudSessionPort {
  const _Session();

  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult<CloudSyncContext>.success(
        const CloudSyncContext(accountId: kTasksTestAccountA),
      );

  @override
  Stream<CloudSessionSnapshot> observeSession() =>
      Stream<CloudSessionSnapshot>.value(
        const CloudSessionSnapshot(
          status: CloudSessionStatus.signedIn,
          accountId: kTasksTestAccountA,
        ),
      );
}

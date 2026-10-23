import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/tasks_strings_adapter.dart';
import 'package:namma_project/app/routing/owner_entry_intent.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_completion_unit_of_work.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/domain/checklist_item.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/tasks/presentation/tasks_cubit.dart';
import 'package:namma_project/features/tasks/presentation/tasks_screen.dart';
import 'package:namma_project/features/tasks/presentation/tasks_state.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

import '../../../support/tasks_test_support.dart';

void main() {
  late TasksTestClock clock;
  late _WidgetTaskRepository repository;
  late _WidgetAwardLedger awardLedger;
  late TasksCubit cubit;

  setUp(() {
    clock = TasksTestClock();
    repository = _WidgetTaskRepository();
    awardLedger = _WidgetAwardLedger();
    final ids = TasksTestIds();
    const session = _Session(kTasksTestAccountA);
    cubit = TasksCubit(
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
        unitOfWork: _WidgetCompletionUnitOfWork(repository, awardLedger),
        session: session,
        nowUtc: clock.utcNow,
        nextOperationId: ids.nextOperationId,
      ),
      awardLedger: awardLedger,
      localDate: clock.localDate,
    );
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
    await repository.close();
    await awardLedger.close();
  });

  void taskTestWidgets(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        cubit.pause();
      }
    });
  }

  taskTestWidgets('title-only form applies verified defaults immediately', (
    tester,
  ) async {
    await _pumpTasks(tester, cubit: cubit);

    await tester.tap(find.byKey(kTaskAddButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(kTaskTitleFieldKey), 'Plan the week');
    await tester.tap(find.byKey(kTaskSaveButtonKey));
    await tester.pumpAndSettle();

    final saved = repository.tasks.single;
    expect(saved.title, 'Plan the week');
    expect(saved.scheduledDate, clock.localDate());
    expect(saved.category, TaskCategory.work);
    expect(saved.quadrant, EisenhowerQuadrant.urgentImportant);
    expect(saved.estimatedDurationMinutes, 30);
    expect(find.byKey(ValueKey<String>('task-${saved.id}')), findsOneWidget);
  });

  taskTestWidgets(
    'new-Task entry intent opens owner editor once and cancel writes nothing',
    (tester) async {
      await _pumpTasks(
        tester,
        cubit: cubit,
        entryIntent: OwnerEntryIntent.newTask,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(kTaskTitleFieldKey), findsOneWidget);
      final editor = tester.widget<TaskEditor>(find.byType(TaskEditor));
      final now = DateTime.now();
      expect(
        editor.initialScheduledDate,
        DateTime(now.year, now.month, now.day),
      );
      Navigator.of(tester.element(find.byType(TaskEditor))).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(kTaskTitleFieldKey), findsNothing);
      expect(repository.tasks, isEmpty);
      await tester.pump();
      expect(find.byKey(kTaskTitleFieldKey), findsNothing);
    },
  );

  taskTestWidgets(
    'blank title shows localized validation and persists nothing',
    (tester) async {
      await _pumpTasks(tester, cubit: cubit);

      await tester.tap(find.byKey(kTaskAddButtonKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(kTaskTitleFieldKey), '   ');
      await tester.tap(find.byKey(kTaskSaveButtonKey));
      await tester.pumpAndSettle();

      expect(find.byKey(kTaskTitleValidationKey), findsOneWidget);
      expect(repository.tasks, isEmpty);
    },
  );

  taskTestWidgets('editor exposes the supported scheduling fields', (
    tester,
  ) async {
    await _pumpTasks(tester, cubit: cubit);

    await tester.tap(find.byKey(kTaskAddButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(kTaskScheduledDateButtonKey), findsOneWidget);
    expect(find.byKey(kTaskScheduledTimeButtonKey), findsOneWidget);
    expect(find.byKey(kTaskDeadlineButtonKey), findsOneWidget);
  });

  taskTestWidgets('editor closes when the active account changes', (
    tester,
  ) async {
    final session = _MutableSession(kTasksTestAccountA);
    addTearDown(session.close);
    await _pumpTasks(tester, cubit: cubit, session: session);
    await tester.tap(find.byKey(kTaskAddButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(kTaskTitleFieldKey), findsOneWidget);

    session.switchTo(kTasksTestAccountB);
    await tester.pumpAndSettle();

    expect(find.byKey(kTaskTitleFieldKey), findsNothing);
    expect(repository.tasks, isEmpty);
  });

  taskTestWidgets(
    'detailed edit preserves identity and delete hides the tombstone',
    (tester) async {
      final original = _task(id: kTasksTestTaskId, title: 'Original');
      repository.replace(<Task>[original]);
      await _pumpTasks(tester, cubit: cubit);

      await tester.tap(
        find.byKey(ValueKey<String>('task-edit-${original.id}')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(kTaskTitleFieldKey), 'Edited title');
      await tester.enterText(find.byKey(kTaskDescriptionFieldKey), 'Details');
      await tester.enterText(find.byKey(kTaskDurationFieldKey), '45');
      await tester.tap(find.byKey(kTaskSaveButtonKey));
      await tester.pumpAndSettle();

      expect(repository.tasks.single.id, original.id);
      expect(repository.tasks.single.title, 'Edited title');
      expect(repository.tasks.single.description, 'Details');
      expect(repository.tasks.single.estimatedDurationMinutes, 45);

      await tester.tap(
        find.byKey(ValueKey<String>('task-delete-${original.id}')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey<String>('task-${original.id}')), findsNothing);
      expect(repository.stored.single.isDeleted, isTrue);
    },
  );

  taskTestWidgets('editing a Task with no duration keeps it unset', (
    tester,
  ) async {
    final original = _task(
      id: 'no-duration',
      title: 'Optional duration',
    ).copyWith(estimatedDurationMinutes: null);
    repository.replace(<Task>[original]);
    await _pumpTasks(tester, cubit: cubit);

    await tester.tap(
      find.byKey(const ValueKey<String>('task-edit-no-duration')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(kTaskDurationFieldKey))
          .controller
          ?.text,
      isEmpty,
    );
    await tester.enterText(find.byKey(kTaskTitleFieldKey), 'Still optional');
    await tester.tap(find.byKey(kTaskSaveButtonKey));
    await tester.pumpAndSettle();

    expect(repository.tasks.single.estimatedDurationMinutes, isNull);
  });

  taskTestWidgets(
    'list and matrix reuse identity with filters and categories',
    (tester) async {
      final work = _task(id: 'work-id', title: 'Work');
      final study = _task(
        id: 'study-id',
        title: 'Study',
        category: TaskCategory.study,
        quadrant: EisenhowerQuadrant.notUrgentImportant,
      );
      repository.replace(<Task>[work, study]);
      await _pumpTasks(tester, cubit: cubit);

      await tester.tap(find.byKey(kTasksAllFilterKey));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('task-work-id')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('task-study-id')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(kTasksCategoryFilterKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('category-study')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('task-work-id')), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('task-study-id')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(kTasksMatrixToggleKey));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('matrix-task-study-id')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(kTasksCategoryFilterKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All Categories'));
      await tester.pumpAndSettle();
      expect((cubit.state as TasksReady).selectedCategory, isNull);
      expect(
        find.byKey(const ValueKey<String>('matrix-task-work-id')),
        findsOneWidget,
      );
      expect(repository.tasks.map((task) => task.id).toSet(), {
        'work-id',
        'study-id',
      });
    },
  );

  taskTestWidgets(
    'recoverable conflict remains visible beside local Task state',
    (tester) async {
      repository.replace(<Task>[
        _task(id: 'conflicted', title: 'Active local'),
      ]);
      await _pumpTasks(tester, cubit: cubit);
      expect(cubit.state, isA<TasksReady>());
      cubit.reportSynchronization(
        status: TasksSyncStatus.recoverableFailure,
        conflicts: const <TaskConflictView>[
          TaskConflictView(
            conflictId: 'conflict-1',
            taskId: 'conflicted',
            activeTitle: 'Active local',
            retainedTitle: 'Remote candidate',
          ),
        ],
      );
      expect((cubit.state as TasksReady).conflicts, hasLength(1));
      await tester.pumpAndSettle();

      expect(find.byKey(kTasksConflictBannerKey), findsOneWidget);
      expect(find.text('Active local'), findsWidgets);
      expect(find.text('Remote candidate'), findsOneWidget);
    },
  );

  taskTestWidgets(
    'explicit complete and reopen controls preserve an incomplete checklist',
    (tester) async {
      final incompleteStep = ChecklistItem(
        id: 'step-1',
        text: 'Still open',
        completed: false,
        order: 0,
      );
      final task = _task(
        id: 'completion-control',
        title: 'Use the explicit control',
        checklistItems: <ChecklistItem>[incompleteStep],
      );
      repository.replace(<Task>[task]);
      await _pumpTasks(tester, cubit: cubit);
      await tester.tap(find.byKey(kTasksAllFilterKey));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('task-complete-completion-control')),
      );
      await tester.pumpAndSettle();

      expect(repository.tasks.single.isCompleted, isTrue);
      expect(repository.tasks.single.checklistItems, <ChecklistItem>[
        incompleteStep,
      ]);
      expect(
        find.byKey(const ValueKey<String>('task-reopen-completion-control')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('task-completed-at-completion-control'),
        ),
        findsOneWidget,
      );
      expect((cubit.state as TasksReady).earnedTaskXp, 20);

      await tester.tap(
        find.byKey(const ValueKey<String>('task-reopen-completion-control')),
      );
      await tester.pumpAndSettle();

      expect(repository.tasks.single.isCompleted, isFalse);
      expect(repository.tasks.single.checklistItems, <ChecklistItem>[
        incompleteStep,
      ]);
      expect(
        find.byKey(const ValueKey<String>('task-complete-completion-control')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('task-completed-at-completion-control'),
        ),
        findsNothing,
      );
      expect((cubit.state as TasksReady).earnedTaskXp, 20);
      expect(awardLedger.awards, hasLength(1));
    },
  );

  taskTestWidgets('signed-out access renders guard and never reads Task data', (
    tester,
  ) async {
    await _pumpTasks(tester, cubit: cubit, accountId: null);

    expect(find.byKey(kTasksSignedOutGuardKey), findsOneWidget);
    expect(repository.watchCount, 0);
    expect(find.byKey(kTaskAddButtonKey), findsNothing);
  });

  taskTestWidgets('mobile and desktop layouts expose the same Task identity', (
    tester,
  ) async {
    repository.replace(<Task>[_task(id: 'responsive', title: 'Responsive')]);

    await _pumpTasks(tester, cubit: cubit, size: const Size(390, 844));
    expect(find.byKey(kTasksMobileLayoutKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('task-responsive')),
      findsOneWidget,
    );

    await _pumpTasks(tester, cubit: cubit, size: const Size(1280, 800));
    expect(find.byKey(kTasksDesktopLayoutKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('task-responsive')),
      findsOneWidget,
    );
  });

  taskTestWidgets('Arabic Tasks content inherits RTL directionality', (
    tester,
  ) async {
    repository.replace(<Task>[_task(id: 'rtl', title: 'مهمة')]);

    await _pumpTasks(
      tester,
      cubit: cubit,
      locale: const Locale('ar'),
      size: const Size(390, 844),
    );

    expect(find.text('المهام'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(kTasksMobileLayoutKey))),
      TextDirection.rtl,
    );
  });
}

Future<void> _pumpTasks(
  WidgetTester tester, {
  required TasksCubit cubit,
  String? accountId = kTasksTestAccountA,
  Size size = const Size(800, 700),
  Locale locale = const Locale('en'),
  CloudSessionPort? session,
  OwnerEntryIntent? entryIntent,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: FoundationLocalizations.supportedLocales,
      localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      home: TasksScreen(
        cubit: cubit,
        accountId: accountId,
        stringsResolver: resolveTasksStrings,
        session: session,
        entryIntent: entryIntent,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Task _task({
  required String id,
  required String title,
  TaskCategory category = TaskCategory.work,
  EisenhowerQuadrant quadrant = EisenhowerQuadrant.urgentImportant,
  List<ChecklistItem> checklistItems = const <ChecklistItem>[],
  DateTime? completedAt,
}) => Task.create(
  id: id,
  accountId: kTasksTestAccountA,
  title: title,
  scheduledDate: DateTime(2026, 10, 8),
  category: category,
  quadrant: quadrant,
  checklistItems: checklistItems,
  completedAt: completedAt,
  createdAt: DateTime.utc(2026, 10, 8, 9),
);

final class _Session implements CloudSessionPort {
  const _Session(this.accountId);

  final String accountId;

  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult<CloudSyncContext>.success(
        CloudSyncContext(accountId: accountId),
      );

  @override
  Stream<CloudSessionSnapshot> observeSession() =>
      Stream<CloudSessionSnapshot>.value(
        CloudSessionSnapshot(
          status: CloudSessionStatus.signedIn,
          accountId: accountId,
        ),
      );
}

final class _MutableSession implements CloudSessionPort {
  _MutableSession(this.accountId);

  String accountId;
  final _changes = StreamController<CloudSessionSnapshot>.broadcast(sync: true);

  void switchTo(String id) {
    accountId = id;
    _changes.add(
      CloudSessionSnapshot(status: CloudSessionStatus.signedIn, accountId: id),
    );
  }

  Future<void> close() => _changes.close();

  @override
  Future<AppResult<void>> initialize() async => AppResult<void>.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => _changes.stream;

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult<CloudSyncContext>.success(
        CloudSyncContext(accountId: accountId),
      );
}

final class _WidgetTaskRepository implements TaskRepository {
  @override
  Stream<List<TaskConflictRecord>> watchConflicts(String accountId) =>
      Stream<List<TaskConflictRecord>>.value(const []);
  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => action();
  final StreamController<List<Task>> _controller =
      StreamController<List<Task>>.broadcast(sync: true);
  final Map<String, Task> _stored = <String, Task>{};
  int watchCount = 0;

  List<Task> get stored => _stored.values.toList(growable: false);
  List<Task> get tasks => stored.where((task) => !task.isDeleted).toList();

  void replace(List<Task> tasks) {
    _stored
      ..clear()
      ..addEntries(
        tasks.map((task) => MapEntry('${task.accountId}/${task.id}', task)),
      );
  }

  Future<void> close() => _controller.close();

  @override
  Future<AppResult<void>> applyInboundTask(Task task) async {
    _stored['${task.accountId}/${task.id}'] = task;
    _emit(task.accountId);
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> commitTask(TaskWriteRequest request) async {
    final task = request.task;
    _stored['${task.accountId}/${task.id}'] = task;
    _emit(task.accountId);
    return AppResult<void>.success(null);
  }

  void _emit(String accountId) {
    _controller.add(
      stored.where((task) => task.accountId == accountId).toList(),
    );
  }

  @override
  Future<AppResult<bool>> hasPendingChange({
    required String accountId,
    required String taskId,
  }) async => AppResult<bool>.success(false);

  @override
  Future<AppResult<Task?>> readTask({
    required String accountId,
    required String taskId,
  }) async => AppResult<Task?>.success(_stored['$accountId/$taskId']);

  @override
  Stream<List<Task>> watchTasks(String accountId) {
    watchCount++;
    return Stream<List<Task>>.multi((controller) {
      controller.add(
        stored.where((task) => task.accountId == accountId).toList(),
      );
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }
}

final class _WidgetCompletionUnitOfWork implements TaskCompletionUnitOfWork {
  _WidgetCompletionUnitOfWork(this.repository, this.awardLedger);

  final _WidgetTaskRepository repository;
  final _WidgetAwardLedger awardLedger;

  @override
  Future<AppResult<void>> commit(TaskCompletionCommit request) async {
    final award = request.firstAward;
    if (award != null) {
      final awardResult = await awardLedger.insertOnce(award);
      if (awardResult.failureOrNull != null) {
        return AppResult<void>.failure(awardResult.failureOrNull!);
      }
    }
    return repository.commitTask(
      TaskWriteRequest(
        task: request.task,
        operationId: request.operationId,
        kind: ChangeKind.update,
        queuedAt: request.queuedAt,
      ),
    );
  }
}

final class _WidgetAwardLedger implements AwardLedgerPort {
  final Map<String, TaskCompletionAward> _stored =
      <String, TaskCompletionAward>{};
  final StreamController<List<TaskCompletionAward>> _controller =
      StreamController<List<TaskCompletionAward>>.broadcast(sync: true);

  List<TaskCompletionAward> get awards =>
      _stored.values.toList(growable: false);

  Future<void> close() => _controller.close();

  void _emit(String accountId) {
    _controller.add(
      awards
          .where((award) => award.accountId == accountId)
          .toList(growable: false),
    );
  }

  @override
  Future<AppResult<AwardInsertOutcome>> insertOnce(
    TaskCompletionAward award,
  ) async {
    final previous = _stored.putIfAbsent(award.uniqueKey, () => award);
    _emit(award.accountId);
    return AppResult<AwardInsertOutcome>.success(
      identical(previous, award)
          ? AwardInsertOutcome.inserted
          : AwardInsertOutcome.alreadyExists,
    );
  }

  @override
  Future<AppResult<void>> applyRemoteAward(TaskCompletionAward award) async {
    _stored[award.uniqueKey] = award;
    _emit(award.accountId);
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<TaskCompletionAward?>> readAward({
    required String accountId,
    required String source,
    required String sourceId,
  }) async => AppResult<TaskCompletionAward?>.success(
    _stored['$accountId/$source/$sourceId'],
  );

  @override
  Stream<List<TaskCompletionAward>> watchAwards(String accountId) =>
      Stream<List<TaskCompletionAward>>.multi((controller) {
        controller.add(
          awards
              .where((award) => award.accountId == accountId)
              .toList(growable: false),
        );
        final subscription = _controller.stream.listen(controller.add);
        controller.onCancel = subscription.cancel;
      });
}

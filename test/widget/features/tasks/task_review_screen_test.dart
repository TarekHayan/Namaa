import 'dart:async';
import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/tasks_strings_adapter.dart';
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
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

import '../../../support/tasks_test_support.dart';

void main() {
  late TasksTestClock clock;
  late _TaskRepository repository;
  late _AwardLedger awardLedger;
  late TasksCubit cubit;

  setUp(() {
    clock = TasksTestClock();
    repository = _TaskRepository();
    awardLedger = _AwardLedger();
    final ids = TasksTestIds();
    const session = _Session();
    cubit = TasksCubit(
      repository: repository,
      commands: TaskCommands(
        repository: repository,
        session: session,
        nowUtc: clock.utcNow,
        localDate: clock.localDate,
        nextTaskId: ids.nextTaskId,
        nextOperationId: ids.nextOperationId,
        nextChecklistItemId: ids.nextTaskId,
      ),
      completionService: TaskCompletionService(
        repository: repository,
        unitOfWork: _CompletionUnitOfWork(repository, awardLedger),
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

  testWidgets(
    'checklist controls do not auto-complete or award and parent may complete with an unfinished step',
    (tester) async {
      repository.replace(<Task>[
        _task(
          id: 'checklist-parent',
          checklistItems: const <ChecklistItem>[
            ChecklistItem(
              id: 'step-a',
              text: 'Existing step',
              completed: false,
              order: 0,
            ),
          ],
        ),
      ]);
      await _pump(tester, cubit: cubit);

      await tester.tap(
        find.byKey(const ValueKey<String>('task-edit-checklist-parent')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('task-checklist-row-step-a')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('task-checklist-toggle-step-a')),
      );
      await tester.pumpAndSettle();
      expect(
        repository.task('checklist-parent').checklistItems.single.completed,
        isTrue,
      );
      expect(repository.task('checklist-parent').isCompleted, isFalse);
      expect(awardLedger.awards, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey<String>('task-checklist-toggle-step-a')),
      );
      await tester.enterText(
        find.byKey(const Key('task_checklist_new_field')),
        'New step',
      );
      await tester.tap(find.byKey(const Key('task_checklist_add_button')));
      await tester.pumpAndSettle();
      expect(repository.task('checklist-parent').checklistItems, hasLength(2));
      expect(awardLedger.awards, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey<String>('task-checklist-text-step-a')),
        'Edited step',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('task-checklist-save-step-a')),
      );
      await tester.pumpAndSettle();
      expect(
        repository.task('checklist-parent').checklistItems.first.text,
        'Edited step',
      );

      final addedId = repository
          .task('checklist-parent')
          .checklistItems
          .firstWhere((item) => item.id != 'step-a')
          .id;
      await tester.tap(
        find.byKey(ValueKey<String>('task-checklist-remove-$addedId')),
      );
      await tester.pumpAndSettle();
      expect(repository.task('checklist-parent').checklistItems, hasLength(1));
      expect(
        repository.task('checklist-parent').checklistItems.single.completed,
        isFalse,
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('task-complete-checklist-parent')),
      );
      await tester.pumpAndSettle();

      expect(repository.task('checklist-parent').isCompleted, isTrue);
      expect(
        repository.task('checklist-parent').checklistItems.single.completed,
        isFalse,
      );
      expect(awardLedger.awards, hasLength(1));
      expect(awardLedger.awards.single.sourceId, 'checklist-parent');
    },
  );

  testWidgets(
    'editor keeps unsaved step text while observing checklist updates',
    (tester) async {
      repository.replace(<Task>[
        _task(
          id: 'draft-parent',
          checklistItems: const <ChecklistItem>[
            ChecklistItem(
              id: 'step-a',
              text: 'Original',
              completed: false,
              order: 0,
            ),
            ChecklistItem(
              id: 'step-b',
              text: 'Toggle me',
              completed: false,
              order: 1,
            ),
          ],
        ),
      ]);
      await _pump(tester, cubit: cubit);
      await tester.tap(
        find.byKey(const ValueKey<String>('task-edit-draft-parent')),
      );
      await tester.pumpAndSettle();

      const draftKey = ValueKey<String>('task-checklist-text-step-a');
      await tester.enterText(find.byKey(draftKey), 'Unsaved draft');
      await tester.tap(
        find.byKey(const ValueKey<String>('task-checklist-toggle-step-b')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byKey(draftKey)).controller!.text,
        'Unsaved draft',
      );

      final current = repository.task('draft-parent');
      await repository.applyInboundTask(
        current.copyWith(
          checklistItems: <ChecklistItem>[
            ...current.checklistItems,
            const ChecklistItem(
              id: 'step-c',
              text: 'Remote step',
              completed: false,
              order: 2,
            ),
          ],
          updatedAt: current.updatedAt.add(const Duration(seconds: 1)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('task-checklist-row-step-c')),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byKey(draftKey)).controller!.text,
        'Unsaved draft',
      );
    },
  );

  testWidgets('checklist toggle exposes its label and checked semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    repository.replace(<Task>[
      _task(
        id: 'accessible',
        checklistItems: const <ChecklistItem>[
          ChecklistItem(
            id: 'step-a',
            text: 'Accessible step',
            completed: false,
            order: 0,
          ),
        ],
      ),
    ]);
    await _pump(tester, cubit: cubit);
    await tester.tap(
      find.byKey(const ValueKey<String>('task-edit-accessible')),
    );
    await tester.pumpAndSettle();
    final toggle = find.byKey(
      const ValueKey<String>('task-checklist-toggle-step-a'),
    );
    expect(tester.getSemantics(toggle).label, contains('Accessible step'));
    expect(
      tester.getSemantics(toggle).flagsCollection.isChecked,
      CheckedState.isFalse,
    );

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(toggle).flagsCollection.isChecked,
      CheckedState.isTrue,
    );
    semantics.dispose();
  });

  testWidgets(
    'overdue and history filters show the correct identity and date',
    (tester) async {
      repository.replace(<Task>[
        _task(id: 'overdue', scheduledDate: DateTime(2026, 10, 7)),
        _task(id: 'today-time-only', scheduledTime: DateTime(2026, 10, 8, 8)),
        _task(id: 'completed', completedAt: DateTime.utc(2026, 10, 8, 8)),
      ]);
      await _pump(tester, cubit: cubit);

      await tester.tap(find.byKey(const Key('tasks_overdue_filter')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('task-overdue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('task-today-time-only')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('task-completed')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('tasks_history_filter')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('task-completed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('task-completed-at-completed')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('task-overdue')), findsNothing);
    },
  );

  testWidgets('Arabic overdue/history review remains RTL with readable dates', (
    tester,
  ) async {
    repository.replace(<Task>[
      _task(
        id: 'arabic-history',
        title: 'مهمة مكتملة',
        completedAt: DateTime.utc(2026, 10, 8, 8),
      ),
    ]);
    await _pump(
      tester,
      cubit: cubit,
      locale: const Locale('ar'),
      size: const Size(390, 844),
    );

    await tester.tap(find.byKey(const Key('tasks_history_filter')));
    await tester.pumpAndSettle();

    expect(find.text('مهمة مكتملة'), findsOneWidget);
    final dateFinder = find.byKey(
      const ValueKey<String>('task-completed-at-arabic-history'),
    );
    expect(dateFinder, findsOneWidget);
    expect(Directionality.of(tester.element(dateFinder)), TextDirection.rtl);
    expect(tester.widget<Text>(dateFinder).data, isNotEmpty);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required TasksCubit cubit,
  Locale locale = const Locale('en'),
  Size size = const Size(800, 700),
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
        accountId: kTasksTestAccountA,
        stringsResolver: resolveTasksStrings,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Task _task({
  required String id,
  String? title,
  DateTime? scheduledDate,
  DateTime? scheduledTime,
  DateTime? completedAt,
  List<ChecklistItem> checklistItems = const <ChecklistItem>[],
}) => Task.create(
  id: id,
  accountId: kTasksTestAccountA,
  title: title ?? id,
  scheduledDate: scheduledDate ?? DateTime(2026, 10, 8),
  scheduledTime: scheduledTime,
  checklistItems: checklistItems,
  completedAt: completedAt,
  createdAt: DateTime.utc(2026, 10),
  updatedAt: completedAt ?? DateTime.utc(2026, 10),
);

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

final class _TaskRepository implements TaskRepository {
  final Map<String, Task> _stored = <String, Task>{};
  final StreamController<List<Task>> _changes =
      StreamController<List<Task>>.broadcast(sync: true);

  Task task(String id) => _stored['$kTasksTestAccountA/$id']!;
  void replace(List<Task> tasks) {
    _stored
      ..clear()
      ..addEntries(
        tasks.map((task) => MapEntry('${task.accountId}/${task.id}', task)),
      );
  }

  void _emit(String accountId) => _changes.add(
    _stored.values.where((task) => task.accountId == accountId).toList(),
  );

  Future<void> close() => _changes.close();

  @override
  Future<AppResult<T>> runInTransaction<T>(
    Future<AppResult<T>> Function() action,
  ) => action();

  @override
  Future<AppResult<Task?>> readTask({
    required String accountId,
    required String taskId,
  }) async => AppResult<Task?>.success(_stored['$accountId/$taskId']);

  @override
  Future<AppResult<void>> commitTask(TaskWriteRequest request) async {
    _stored['${request.task.accountId}/${request.task.id}'] = request.task;
    _emit(request.task.accountId);
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> applyInboundTask(Task task) async {
    _stored['${task.accountId}/${task.id}'] = task;
    _emit(task.accountId);
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<bool>> hasPendingChange({
    required String accountId,
    required String taskId,
  }) async => AppResult<bool>.success(false);

  @override
  Stream<List<Task>> watchTasks(String accountId) =>
      Stream<List<Task>>.multi((controller) {
        controller.add(
          _stored.values.where((task) => task.accountId == accountId).toList(),
        );
        final subscription = _changes.stream.listen(controller.add);
        controller.onCancel = subscription.cancel;
      });

  @override
  Stream<List<TaskConflictRecord>> watchConflicts(String accountId) =>
      Stream<List<TaskConflictRecord>>.value(const <TaskConflictRecord>[]);
}

final class _CompletionUnitOfWork implements TaskCompletionUnitOfWork {
  const _CompletionUnitOfWork(this.repository, this.ledger);

  final _TaskRepository repository;
  final _AwardLedger ledger;

  @override
  Future<AppResult<void>> commit(TaskCompletionCommit request) async {
    final award = request.firstAward;
    if (award != null) await ledger.insertOnce(award);
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

final class _AwardLedger implements AwardLedgerPort {
  final Map<String, TaskCompletionAward> _stored =
      <String, TaskCompletionAward>{};
  final StreamController<List<TaskCompletionAward>> _changes =
      StreamController<List<TaskCompletionAward>>.broadcast(sync: true);

  List<TaskCompletionAward> get awards => _stored.values.toList();
  Future<void> close() => _changes.close();

  void _emit(String accountId) => _changes.add(
    awards.where((award) => award.accountId == accountId).toList(),
  );

  @override
  Future<AppResult<AwardInsertOutcome>> insertOnce(
    TaskCompletionAward award,
  ) async {
    final existed = _stored.containsKey(award.uniqueKey);
    _stored.putIfAbsent(award.uniqueKey, () => award);
    _emit(award.accountId);
    return AppResult<AwardInsertOutcome>.success(
      existed ? AwardInsertOutcome.alreadyExists : AwardInsertOutcome.inserted,
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
          awards.where((award) => award.accountId == accountId).toList(),
        );
        final subscription = _changes.stream.listen(controller.add);
        controller.onCancel = subscription.cancel;
      });
}

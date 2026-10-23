import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:namma_project/app/composition/tasks_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/tasks_strings_adapter.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/app/routing/owner_entry_intent.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_completion_service.dart';
import 'package:namma_project/features/tasks/application/task_completion_unit_of_work.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/tasks/presentation/tasks_cubit.dart';
import 'package:namma_project/features/tasks/presentation/tasks_screen.dart';
import 'package:namma_project/features/xp/application/award_ledger.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

final class _Repository implements TaskRepository {
  final tasks = [
    Task.create(
      id: 'late',
      accountId: kTasksPreviewAccountId,
      title: 'Owner overdue work',
      scheduledDate: DateTime(2026, 10, 22),
      createdAt: DateTime.utc(2026, 10, 22),
    ),
  ];

  @override
  Stream<List<Task>> watchTasks(String accountId) => Stream.value(tasks);
  @override
  Stream<List<TaskConflictRecord>> watchConflicts(String accountId) =>
      Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Ledger implements AwardLedgerPort {
  @override
  Stream<List<TaskCompletionAward>> watchAwards(String accountId) =>
      Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnitOfWork implements TaskCompletionUnitOfWork {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Owner extends StatefulWidget {
  const _Owner({required this.accountId, required this.repository});
  final String accountId;
  final _Repository repository;
  @override
  State<_Owner> createState() => _OwnerState();
}

class _OwnerState extends State<_Owner> {
  late final cubit = TasksCubit(
    repository: widget.repository,
    commands: TaskCommands(
      repository: widget.repository,
      session: const TasksPreviewSession(),
      localDate: () => DateTime(2026, 10, 23),
    ),
    completionService: TaskCompletionService(
      repository: widget.repository,
      unitOfWork: _UnitOfWork(),
      session: const TasksPreviewSession(),
    ),
    awardLedger: _Ledger(),
    localDate: () => DateTime(2026, 10, 23),
    nowUtc: () => DateTime.utc(2026, 10, 23, 12),
  );

  @override
  void dispose() {
    unawaited(cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TasksScreen(
    cubit: cubit,
    accountId: widget.accountId,
    stringsResolver: resolveTasksStrings,
    entryIntent: OwnerEntryIntentScope.maybeOf(context),
  );
}

void main() {
  testWidgets('matrix and overdue intents open the existing owner view once', (
    tester,
  ) async {
    final repository = _Repository();
    final routing = FoundationAppRouter(
      rootBuilder: (context) => Scaffold(
        body: Column(
          children: [
            TextButton(
              key: const Key('enter_matrix'),
              onPressed: () => unawaited(
                GoRouter.of(
                  context,
                ).push<void>(kTasksRoute, extra: OwnerEntryIntent.taskMatrix),
              ),
              child: const Text('Matrix'),
            ),
            TextButton(
              key: const Key('enter_overdue'),
              onPressed: () => unawaited(
                GoRouter.of(
                  context,
                ).push<void>(kTasksRoute, extra: OwnerEntryIntent.taskOverdue),
              ),
              child: const Text('Overdue'),
            ),
          ],
        ),
      ),
      cloudSession: const TasksPreviewSession(),
      tasksBuilder: (_, accountId) =>
          _Owner(accountId: accountId, repository: repository),
    );
    addTearDown(routing.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: routing.router,
        localizationsDelegates: FoundationLocalizations.localizationsDelegates,
        supportedLocales: FoundationLocalizations.supportedLocales,
      ),
    );

    await tester.tap(find.byKey(const Key('enter_matrix')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.view_list), findsOneWidget);
    expect(find.text('Owner overdue work'), findsOneWidget);
    await tester.pump();
    expect(find.byIcon(Icons.view_list), findsOneWidget);

    routing.router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enter_overdue')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilterChip>(find.byKey(kTasksOverdueFilterKey)).selected,
      isTrue,
    );
    expect(find.text('Owner overdue work'), findsOneWidget);

    routing.router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('enter_matrix')), findsOneWidget);
  });
}

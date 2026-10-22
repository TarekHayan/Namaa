import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/core/application/navigation/owner_entry_intent.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/tasks/presentation/task_editor.dart';
import 'package:namma_project/features/tasks/presentation/tasks_cubit.dart';
import 'package:namma_project/features/tasks/presentation/tasks_state.dart';
import 'package:namma_project/features/tasks/presentation/tasks_strings.dart';

export 'task_editor.dart'
    show
        kTaskTitleFieldKey,
        kTaskDescriptionFieldKey,
        kTaskDurationFieldKey,
        kTaskScheduledDateButtonKey,
        kTaskScheduledTimeButtonKey,
        kTaskDeadlineButtonKey,
        kTaskSaveButtonKey,
        kTaskTitleValidationKey,
        kTaskChecklistNewFieldKey,
        kTaskChecklistAddButtonKey,
        TaskEditor;

const Key kTaskAddButtonKey = Key('task_add_button');
const Key kTasksAllFilterKey = Key('tasks_all_filter');
const Key kTasksOverdueFilterKey = Key('tasks_overdue_filter');
const Key kTasksHistoryFilterKey = Key('tasks_history_filter');
const Key kTasksCategoryFilterKey = Key('tasks_category_filter');
const Key kTasksMatrixToggleKey = Key('tasks_matrix_toggle');
const Key kTasksConflictBannerKey = Key('tasks_conflict_banner');
const Key kTasksSignedOutGuardKey = Key('tasks_signed_out_guard');
const Key kTasksMobileLayoutKey = Key('tasks_mobile_layout');
const Key kTasksDesktopLayoutKey = Key('tasks_desktop_layout');

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    super.key,
    required this.cubit,
    required this.accountId,
    required this.stringsResolver,
    this.session,
    this.entryIntent,
  });

  final TasksCubit cubit;
  final String? accountId;
  final TasksStringsResolver stringsResolver;
  final CloudSessionPort? session;
  final OwnerEntryIntent? entryIntent;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with WidgetsBindingObserver {
  bool _intentConsumed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.accountId != null) {
      widget.cubit.load(widget.accountId!);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.accountId != null) {
      widget.cubit.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.cubit.pause();
    super.dispose();
  }

  @override
  void didUpdateWidget(TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entryIntent != oldWidget.entryIntent ||
        widget.accountId != oldWidget.accountId) {
      _intentConsumed = false;
    }
    if (widget.accountId != null && widget.accountId != oldWidget.accountId) {
      widget.cubit.load(widget.accountId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.stringsResolver(context);
    final accountId = widget.accountId;

    if (accountId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            l10n.tasksSignInRequired,
            key: kTasksSignedOutGuardKey,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return BlocBuilder<TasksCubit, TasksState>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (!_intentConsumed &&
            state is TasksReady &&
            widget.entryIntent != null) {
          _intentConsumed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || widget.accountId != accountId) return;
            switch (widget.entryIntent) {
              case OwnerEntryIntent.newTask:
                final now = DateTime.now();
                TaskEditor.show(
                  context,
                  cubit: widget.cubit,
                  stringsResolver: widget.stringsResolver,
                  accountId: accountId,
                  session: widget.session,
                  initialScheduledDate: DateTime(now.year, now.month, now.day),
                );
              case OwnerEntryIntent.taskMatrix:
                widget.cubit.showMatrix();
              case OwnerEntryIntent.taskOverdue:
                widget.cubit.selectFilter(TaskListFilter.overdue);
              default:
                break;
            }
          });
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tasksTitle),
            actions: [
              IconButton(
                key: kTasksMatrixToggleKey,
                icon: Icon(
                  state is TasksReady && state.viewMode == TasksViewMode.matrix
                      ? Icons.view_list
                      : Icons.grid_view,
                ),
                tooltip:
                    state is TasksReady &&
                        state.viewMode == TasksViewMode.matrix
                    ? l10n.tasksViewList
                    : l10n.tasksViewMatrix,
                onPressed: () {
                  if (state is TasksReady) {
                    if (state.viewMode == TasksViewMode.list) {
                      widget.cubit.showMatrix();
                    } else {
                      widget.cubit.showList();
                    }
                  }
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            key: kTaskAddButtonKey,
            onPressed: () => TaskEditor.show(
              context,
              cubit: widget.cubit,
              stringsResolver: widget.stringsResolver,
              accountId: accountId,
              session: widget.session,
            ),
            child: const Icon(Icons.add),
          ),
          body: switch (state) {
            TasksInitial() ||
            TasksLoading() => const Center(child: CircularProgressIndicator()),
            TasksFailure() => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.tasksFailure,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => widget.cubit.load(accountId),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
            TasksReady() => LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 720;
                return KeyedSubtree(
                  key: isDesktop
                      ? kTasksDesktopLayoutKey
                      : kTasksMobileLayoutKey,
                  child: _buildReadyView(context, state, isDesktop),
                );
              },
            ),
          },
        );
      },
    );
  }

  Widget _buildReadyView(
    BuildContext context,
    TasksReady state,
    bool isDesktop,
  ) {
    final l10n = widget.stringsResolver(context);
    final showConflictBanner =
        state.syncStatus == TasksSyncStatus.recoverableFailure ||
        state.conflicts.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showConflictBanner) _buildConflictBanner(context, state, l10n),
        _buildControls(context, state, l10n),
        Expanded(
          child: state.viewMode == TasksViewMode.matrix
              ? _buildMatrixView(context, state, l10n, isDesktop)
              : _buildListView(context, state, l10n),
        ),
      ],
    );
  }

  Widget _buildConflictBanner(
    BuildContext context,
    TasksReady state,
    TasksStrings l10n,
  ) {
    final theme = Theme.of(context);
    return Card(
      key: kTasksConflictBannerKey,
      color: theme.colorScheme.errorContainer,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.tasksConflictNotice,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            for (final conflict in state.conflicts) ...[
              const SizedBox(height: 8),
              Text(
                conflict.activeTitle,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
              Text(
                conflict.retainedTitle,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    TasksReady state,
    TasksStrings l10n,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          FilterChip(
            label: Text(l10n.tasksFilterToday),
            selected: state.filter == TaskListFilter.today,
            onSelected: (_) => widget.cubit.selectFilter(TaskListFilter.today),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: kTasksOverdueFilterKey,
            label: Text(l10n.tasksFilterOverdue),
            selected: state.filter == TaskListFilter.overdue,
            onSelected: (_) =>
                widget.cubit.selectFilter(TaskListFilter.overdue),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: kTasksHistoryFilterKey,
            label: Text(l10n.tasksFilterHistory),
            selected: state.filter == TaskListFilter.completed,
            onSelected: (_) =>
                widget.cubit.selectFilter(TaskListFilter.completed),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(l10n.tasksFilterUrgent),
            selected: state.filter == TaskListFilter.urgent,
            onSelected: (_) => widget.cubit.selectFilter(TaskListFilter.urgent),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: kTasksAllFilterKey,
            label: Text(l10n.tasksFilterAll),
            selected: state.filter == TaskListFilter.all,
            onSelected: (_) => widget.cubit.selectFilter(TaskListFilter.all),
          ),
          const SizedBox(width: 16),
          PopupMenuButton<Object>(
            key: kTasksCategoryFilterKey,
            tooltip: l10n.tasksCategoryFilter,
            initialValue: state.selectedCategory,
            onSelected: (selection) => widget.cubit.selectCategory(
              selection is TaskCategory ? selection : null,
            ),
            itemBuilder: (context) => [
              PopupMenuItem<Object>(
                value: 'all',
                child: Text(l10n.tasksAllCategories),
              ),
              const PopupMenuDivider(),
              for (final cat in TaskCategory.values)
                PopupMenuItem<Object>(
                  key: ValueKey<String>('category-${cat.name}'),
                  value: cat,
                  child: Text(_localizedCategory(cat, l10n)),
                ),
            ],
            child: Chip(
              avatar: const Icon(Icons.filter_list, size: 18),
              label: Text(
                state.selectedCategory != null
                    ? _localizedCategory(state.selectedCategory!, l10n)
                    : l10n.tasksCategoryFilter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    TasksReady state,
    TasksStrings l10n,
  ) {
    if (state.visibleTasks.isEmpty) {
      return Center(
        child: Text(
          l10n.tasksEmpty,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: state.visibleTasks.length,
      itemBuilder: (context, index) {
        final task = state.visibleTasks[index];
        return _buildTaskCard(context, task, l10n);
      },
    );
  }

  Widget _buildMatrixView(
    BuildContext context,
    TasksReady state,
    TasksStrings l10n,
    bool isDesktop,
  ) {
    final quadrants = [
      (
        EisenhowerQuadrant.urgentImportant,
        l10n.quadrantDo,
        l10n.quadrantUrgentImportant,
        state.matrix[EisenhowerQuadrant.urgentImportant] ?? const <Task>[],
      ),
      (
        EisenhowerQuadrant.notUrgentImportant,
        l10n.quadrantSchedule,
        l10n.quadrantNotUrgentImportant,
        state.matrix[EisenhowerQuadrant.notUrgentImportant] ?? const <Task>[],
      ),
      (
        EisenhowerQuadrant.urgentNotImportant,
        l10n.quadrantDelegate,
        l10n.quadrantUrgentNotImportant,
        state.matrix[EisenhowerQuadrant.urgentNotImportant] ?? const <Task>[],
      ),
      (
        EisenhowerQuadrant.notUrgentNotImportant,
        l10n.quadrantEliminate,
        l10n.quadrantNotUrgentNotImportant,
        state.matrix[EisenhowerQuadrant.notUrgentNotImportant] ??
            const <Task>[],
      ),
    ];

    if (isDesktop) {
      return GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        childAspectRatio: 1.2,
        children: quadrants.map((q) {
          return _buildQuadrantSection(
            context,
            q.$2,
            q.$3,
            q.$4,
            l10n,
            constrainTaskList: true,
          );
        }).toList(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: quadrants.map((q) {
        return _buildQuadrantSection(
          context,
          q.$2,
          q.$3,
          q.$4,
          l10n,
          constrainTaskList: false,
        );
      }).toList(),
    );
  }

  Widget _buildQuadrantSection(
    BuildContext context,
    String shortLabel,
    String fullLabel,
    List<Task> tasks,
    TasksStrings l10n, {
    required bool constrainTaskList,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shortLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              fullLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(),
            if (constrainTaskList)
              Expanded(child: _buildQuadrantTasks(context, tasks, l10n))
            else
              _buildQuadrantTasks(context, tasks, l10n, shrinkWrap: true),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrantTasks(
    BuildContext context,
    List<Task> tasks,
    TasksStrings l10n, {
    bool shrinkWrap = false,
  }) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            l10n.tasksEmpty,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: tasks.length,
      itemBuilder: (context, index) =>
          _buildTaskCard(context, tasks[index], l10n, isMatrix: true),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Task task,
    TasksStrings l10n, {
    bool isMatrix = false,
  }) {
    final theme = Theme.of(context);
    final cardKey = isMatrix
        ? ValueKey<String>('matrix-task-${task.id}')
        : ValueKey<String>('task-${task.id}');

    return Card(
      key: cardKey,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: IconButton(
          key: ValueKey<String>(
            task.isCompleted
                ? 'task-reopen-${task.id}'
                : 'task-complete-${task.id}',
          ),
          icon: Icon(
            task.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
          ),
          color: task.isCompleted ? theme.colorScheme.primary : null,
          tooltip: task.isCompleted ? l10n.taskReopen : l10n.taskComplete,
          onPressed: () => _changeCompletion(context, task, l10n),
        ),
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Text(
                  _localizedCategory(task.category, l10n),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (task.estimatedDurationMinutes != null)
                  Text(
                    '${task.estimatedDurationMinutes} ${l10n.taskDurationUnit}',
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
            if (task.completedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.taskCompletedAt(
                  _localizedTimestamp(context, task.completedAt!),
                ),
                key: ValueKey<String>('task-completed-at-${task.id}'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: ValueKey<String>('task-edit-${task.id}'),
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: l10n.taskEdit,
              onPressed: () => TaskEditor.show(
                context,
                cubit: widget.cubit,
                stringsResolver: widget.stringsResolver,
                initialTask: task,
                accountId: widget.accountId!,
                session: widget.session,
              ),
            ),
            IconButton(
              key: ValueKey<String>('task-delete-${task.id}'),
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: l10n.taskDelete,
              onPressed: () async {
                final result = await widget.cubit.deleteTask(task.id);
                if (result.failureOrNull != null && context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.tasksFailure)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeCompletion(
    BuildContext context,
    Task task,
    TasksStrings l10n,
  ) async {
    final result = task.isCompleted
        ? await widget.cubit.reopenTask(task.id)
        : await widget.cubit.completeTask(task.id);
    if (result.failureOrNull != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tasksFailure)));
    }
  }

  static String _localizedTimestamp(BuildContext context, DateTime timestamp) {
    final local = timestamp.toLocal();
    final material = MaterialLocalizations.of(context);
    final date = material.formatMediumDate(local);
    final time = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '$date, $time';
  }

  static String _localizedCategory(TaskCategory category, TasksStrings l10n) =>
      switch (category) {
        TaskCategory.work => l10n.taskCategoryWork,
        TaskCategory.study => l10n.taskCategoryStudy,
        TaskCategory.personal => l10n.taskCategoryPersonal,
        TaskCategory.health => l10n.taskCategoryHealth,
        TaskCategory.spiritual => l10n.taskCategorySpiritual,
        TaskCategory.finance => l10n.taskCategoryFinance,
        TaskCategory.other => l10n.taskCategoryOther,
      };
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_hover_surface.dart';
import 'package:namma_project/app/widgets/app_status_view.dart';
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
        kTaskMoreDetailsButtonKey,
        kTaskInlineEditorKey,
        kTaskInlineCancelKey,
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
const Key kTasksListTabKey = Key('tasks_list_tab');
const Key kTasksMindMapsTabKey = Key('tasks_mind_maps_tab');

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    super.key,
    required this.cubit,
    required this.accountId,
    required this.stringsResolver,
    this.session,
    this.entryIntent,
    this.onMindMaps,
  });

  final TasksCubit cubit;
  final String? accountId;
  final TasksStringsResolver stringsResolver;
  final CloudSessionPort? session;
  final OwnerEntryIntent? entryIntent;
  final VoidCallback? onMindMaps;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with WidgetsBindingObserver {
  bool _intentConsumed = false;
  bool _showAddForm = false;
  DateTime? _inlineScheduledDate;
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
        final colors = Theme.of(context).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light;
        final entryIntent = widget.entryIntent;
        if (!_intentConsumed && state is TasksReady && entryIntent != null) {
          _intentConsumed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted ||
                widget.accountId != accountId ||
                widget.entryIntent != entryIntent) {
              return;
            }
            switch (entryIntent) {
              case OwnerEntryIntent.newTask:
                final now = DateTime.now();
                setState(() {
                  _inlineScheduledDate = DateTime(now.year, now.month, now.day);
                  _showAddForm = true;
                });
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
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background,
            surfaceTintColor: Colors.transparent,
            title: Text(
              l10n.tasksTitle,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: switch (state) {
            TasksInitial() || TasksLoading() => const AppStatusView.loading(),
            TasksFailure() => AppStatusView.error(
              title: l10n.tasksFailure,
              actionLabel: l10n.retry,
              onAction: () => widget.cubit.load(accountId),
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
    final colors = _colors(context);
    final showConflictBanner =
        state.syncStatus == TasksSyncStatus.recoverableFailure ||
        state.conflicts.isNotEmpty;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1220),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              _buildTopBar(context, state, l10n, colors, isDesktop),
              if (showConflictBanner)
                _buildConflictBanner(context, state, l10n),
              const SizedBox(height: 12),
              _buildControls(context, state, l10n, colors),
              const SizedBox(height: 14),
              Expanded(
                child: _showAddForm
                    ? _buildInlineCreateView(context, state, l10n, isDesktop)
                    : state.viewMode == TasksViewMode.matrix
                    ? _buildMatrixView(context, state, l10n, isDesktop)
                    : _buildListView(context, state, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineCreateView(
    BuildContext context,
    TasksReady state,
    TasksStrings l10n,
    bool isDesktop,
  ) {
    final editor = TaskEditor(
      key: const ValueKey('new_task_inline_form'),
      cubit: widget.cubit,
      stringsResolver: widget.stringsResolver,
      accountId: widget.accountId!,
      session: widget.session,
      initialScheduledDate: _inlineScheduledDate,
      inline: true,
      onFinished: () {
        if (mounted) {
          setState(() {
            _showAddForm = false;
            _inlineScheduledDate = null;
          });
        }
      },
    );

    if (state.viewMode == TasksViewMode.matrix) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            editor,
            const SizedBox(height: 20),
            _buildMatrixView(context, state, l10n, isDesktop, shrinkWrap: true),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          editor,
          const SizedBox(height: 20),
          if (state.visibleTasks.isEmpty)
            _buildEmptyCard(context, l10n)
          else
            for (final task in state.visibleTasks)
              _buildTaskCard(context, task, l10n),
        ],
      ),
    );
  }

  AppColors _colors(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;

  Widget _buildTopBar(
    BuildContext context,
    TasksReady state,
    TasksStrings l10n,
    AppColors colors,
    bool isDesktop,
  ) {
    final modes = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _modeButton(
              key: kTasksListTabKey,
              icon: Icons.view_list_rounded,
              label: l10n.tasksViewList,
              selected: state.viewMode == TasksViewMode.list,
              colors: colors,
              onTap: widget.cubit.showList,
            ),
            _modeButton(
              key: kTasksMatrixToggleKey,
              icon: Icons.grid_view_rounded,
              label: l10n.tasksViewMatrix,
              selected: state.viewMode == TasksViewMode.matrix,
              colors: colors,
              onTap: widget.cubit.showMatrix,
            ),
            if (widget.onMindMaps != null)
              _modeButton(
                key: kTasksMindMapsTabKey,
                icon: Icons.hub_outlined,
                label: l10n.mindMapsTitle,
                selected: false,
                colors: colors,
                onTap: widget.onMindMaps!,
              ),
          ],
        ),
      ),
    );
    final addButton = AppButton(
      key: kTaskAddButtonKey,
      onPressed: () => setState(() {
        _showAddForm = !_showAddForm;
        _inlineScheduledDate = null;
      }),
      icon: Icons.add_rounded,
      label: l10n.taskCreate,
    );
    if (isDesktop) {
      return Row(
        children: [
          Flexible(child: modes),
          const SizedBox(width: 12),
          addButton,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [modes, const SizedBox(height: 10), addButton],
    );
  }

  Widget _modeButton({
    required Key key,
    required IconData icon,
    required String label,
    required bool selected,
    required AppColors colors,
    required VoidCallback onTap,
  }) => InkWell(
    key: key,
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? Colors.white : colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

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
    AppColors colors,
  ) {
    final category = PopupMenuButton<Object>(
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_rounded, size: 16, color: colors.textMuted),
            const SizedBox(width: 6),
            Text(
              state.selectedCategory != null
                  ? _localizedCategory(state.selectedCategory!, l10n)
                  : l10n.tasksCategoryFilter,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
    if (state.viewMode == TasksViewMode.matrix) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: category,
      );
    }
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  l10n.tasksFilterToday,
                  TaskListFilter.today,
                  state,
                  colors,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  l10n.tasksFilterUrgent,
                  TaskListFilter.urgent,
                  state,
                  colors,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  l10n.tasksFilterAll,
                  TaskListFilter.all,
                  state,
                  colors,
                  key: kTasksAllFilterKey,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  l10n.tasksFilterCompleted,
                  TaskListFilter.completed,
                  state,
                  colors,
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 22, color: colors.border),
                const SizedBox(width: 8),
                _filterChip(
                  l10n.tasksFilterOverdue,
                  TaskListFilter.overdue,
                  state,
                  colors,
                  key: kTasksOverdueFilterKey,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  l10n.tasksFilterHistory,
                  TaskListFilter.completed,
                  state,
                  colors,
                  key: kTasksHistoryFilterKey,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        category,
      ],
    );
  }

  Widget _filterChip(
    String label,
    TaskListFilter filter,
    TasksReady state,
    AppColors colors, {
    Key? key,
  }) {
    final selected = state.filter == filter;
    return InkWell(
      key: key,
      onTap: () => widget.cubit.selectFilter(filter),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : colors.surfaceSecondary,
          border: Border.all(
            color: selected
                ? colors.primary.withValues(alpha: 0.45)
                : colors.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: selected ? colors.primary : colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    TasksReady state,
    TasksStrings l10n,
  ) {
    if (state.visibleTasks.isEmpty) {
      return Center(child: _buildEmptyCard(context, l10n));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: state.visibleTasks.length,
      itemBuilder: (context, index) {
        final task = state.visibleTasks[index];
        return _buildTaskCard(context, task, l10n);
      },
    );
  }

  Widget _buildEmptyCard(BuildContext context, TasksStrings l10n) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Card(
      color: _colors(context).surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: _colors(context).border),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 32,
              color: _colors(context).primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.tasksEmpty,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tasksEmptyHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _colors(context).textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixView(
    BuildContext context,
    TasksReady state,
    TasksStrings l10n,
    bool isDesktop, {
    bool shrinkWrap = false,
  }) {
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
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 260,
        padding: const EdgeInsets.only(bottom: 24),
        children: quadrants.map((q) {
          return _buildQuadrantSection(
            context,
            q.$1,
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
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.only(bottom: 24),
      children: quadrants.map((q) {
        return _buildQuadrantSection(
          context,
          q.$1,
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
    EisenhowerQuadrant quadrant,
    String shortLabel,
    String fullLabel,
    List<Task> tasks,
    TasksStrings l10n, {
    required bool constrainTaskList,
  }) {
    final theme = Theme.of(context);
    final colors = _colors(context);
    final (accent, quadrantIcon) = switch (quadrant) {
      EisenhowerQuadrant.urgentImportant => (colors.error, Icons.bolt_rounded),
      EisenhowerQuadrant.notUrgentImportant => (
        colors.primary,
        Icons.calendar_today_rounded,
      ),
      EisenhowerQuadrant.urgentNotImportant => (
        colors.warning,
        Icons.people_outline_rounded,
      ),
      EisenhowerQuadrant.notUrgentNotImportant => (
        colors.textMuted,
        Icons.cleaning_services_rounded,
      ),
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 240),
      child: Card(
        color: Color.alphaBlend(accent.withValues(alpha: 0.04), colors.surface),
        margin: EdgeInsets.only(bottom: constrainTaskList ? 0 : 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.25),
              colors.border,
            ),
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(quadrantIcon, size: 16, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shortLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          fullLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: colors.border),
              if (constrainTaskList)
                Expanded(child: _buildQuadrantTasks(context, tasks, l10n))
              else
                _buildQuadrantTasks(context, tasks, l10n, shrinkWrap: true),
            ],
          ),
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
          _buildMatrixTaskCard(context, tasks[index], l10n),
    );
  }

  Widget _buildMatrixTaskCard(
    BuildContext context,
    Task task,
    TasksStrings l10n,
  ) {
    final colors = _colors(context);
    return Container(
      key: ValueKey<String>('matrix-task-${task.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            key: ValueKey<String>(
              task.isCompleted
                  ? 'task-reopen-${task.id}'
                  : 'task-complete-${task.id}',
            ),
            visualDensity: VisualDensity.compact,
            tooltip: task.isCompleted ? l10n.taskReopen : l10n.taskComplete,
            onPressed: () => _changeCompletion(context, task, l10n),
            icon: Icon(
              task.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: task.isCompleted ? colors.primary : colors.textMuted,
              size: 20,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                if (task.scheduledTime != null ||
                    task.estimatedDurationMinutes != null)
                  Text(
                    [
                      if (task.scheduledTime != null)
                        MaterialLocalizations.of(context).formatTimeOfDay(
                          TimeOfDay.fromDateTime(task.scheduledTime!),
                        ),
                      if (task.estimatedDurationMinutes != null)
                        '${task.estimatedDurationMinutes} ${l10n.taskDurationUnit}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                  ),
              ],
            ),
          ),
          PopupMenuButton<EisenhowerQuadrant>(
            key: ValueKey<String>('task-move-${task.id}'),
            tooltip: l10n.tasksViewMatrix,
            icon: Icon(
              Icons.swap_horiz_rounded,
              color: colors.textMuted,
              size: 19,
            ),
            onSelected: (quadrant) => _moveTask(context, task, quadrant, l10n),
            itemBuilder: (_) => [
              for (final quadrant in EisenhowerQuadrant.values)
                PopupMenuItem(
                  value: quadrant,
                  child: Text(_quadrantLabel(quadrant, l10n)),
                ),
            ],
          ),
          IconButton(
            key: ValueKey<String>('task-delete-${task.id}'),
            tooltip: l10n.taskDelete,
            visualDensity: VisualDensity.compact,
            onPressed: () => _deleteTask(context, task, l10n),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: colors.textMuted,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Task task,
    TasksStrings l10n, {
    bool isMatrix = false,
  }) {
    final theme = Theme.of(context);
    final colors = _colors(context);
    final cardKey = isMatrix
        ? ValueKey<String>('matrix-task-${task.id}')
        : ValueKey<String>('task-${task.id}');

    return AppHoverSurface(
      radius: 18,
      child: Card(
        key: cardKey,
        color: isMatrix ? colors.surfaceSecondary : colors.surface,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMatrix ? 8 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                key: ValueKey<String>(
                  task.isCompleted
                      ? 'task-reopen-${task.id}'
                      : 'task-complete-${task.id}',
                ),
                icon: Icon(
                  task.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 23,
                ),
                color: task.isCompleted ? colors.primary : colors.textMuted,
                tooltip: task.isCompleted ? l10n.taskReopen : l10n.taskComplete,
                onPressed: () => _changeCompletion(context, task, l10n),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          task.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (task.scheduledTime != null)
                            MaterialLocalizations.of(context).formatTimeOfDay(
                              TimeOfDay.fromDateTime(task.scheduledTime!),
                            ),
                          if (task.estimatedDurationMinutes != null)
                            '${task.estimatedDurationMinutes} ${l10n.taskDurationUnit}',
                          _quadrantLabel(task.quadrant, l10n),
                          '+${task.completionXp} XP',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      if (task.completedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.taskCompletedAt(
                            _localizedTimestamp(context, task.completedAt!),
                          ),
                          key: ValueKey<String>('task-completed-at-${task.id}'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: ValueKey<String>('task-edit-${task.id}'),
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    tooltip: l10n.taskEdit,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
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
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    tooltip: l10n.taskDelete,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () => _deleteTask(context, task, l10n),
                  ),
                  if (isMatrix)
                    PopupMenuButton<EisenhowerQuadrant>(
                      key: ValueKey<String>('task-move-${task.id}'),
                      tooltip: l10n.tasksViewMatrix,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                      onSelected: (quadrant) =>
                          _moveTask(context, task, quadrant, l10n),
                      itemBuilder: (_) => [
                        for (final quadrant in EisenhowerQuadrant.values)
                          PopupMenuItem(
                            value: quadrant,
                            child: Text(_quadrantLabel(quadrant, l10n)),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTask(
    BuildContext context,
    Task task,
    TasksStrings l10n,
  ) async {
    final result = await widget.cubit.deleteTask(task.id);
    if (result.failureOrNull != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tasksFailure)));
    }
  }

  Future<void> _moveTask(
    BuildContext context,
    Task task,
    EisenhowerQuadrant quadrant,
    TasksStrings l10n,
  ) async {
    final result = await widget.cubit.moveTask(
      taskId: task.id,
      quadrant: quadrant,
    );
    if (result.failureOrNull != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tasksFailure)));
    }
  }

  String _quadrantLabel(EisenhowerQuadrant quadrant, TasksStrings l10n) =>
      switch (quadrant) {
        EisenhowerQuadrant.urgentImportant => l10n.quadrantDo,
        EisenhowerQuadrant.notUrgentImportant => l10n.quadrantSchedule,
        EisenhowerQuadrant.urgentNotImportant => l10n.quadrantDelegate,
        EisenhowerQuadrant.notUrgentNotImportant => l10n.quadrantEliminate,
      };

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

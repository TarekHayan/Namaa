library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/today_agenda.dart';
import '../domain/today_projection.dart';
import '../domain/today_section.dart';
import 'today_cubit.dart';
import 'today_state.dart';
import 'today_strings.dart';
import 'widgets/today_agenda_section.dart';
import 'widgets/today_habit_list.dart';
import 'widgets/today_overdue_section.dart';
import 'widgets/today_priority_section.dart';
import 'widgets/today_summary_section.dart';

const Key kTodayScreenKey = Key('today_screen');
const Key kTodayTasksNavigationKey = Key('today_tasks_navigation');
const Key kTodayHabitsNavigationKey = Key('today_habits_navigation');
const Key kTodayMindMapsNavigationKey = Key('today_mind_maps_navigation');
const Key kTodayPreferencesKey = Key('today_preferences');

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.cubit,
    required this.stringsResolver,
    required this.onTasks,
    required this.onHabits,
    required this.onMindMaps,
    required this.onPreferences,
    this.onNewTask,
    this.onNewHabit,
    this.onTaskMatrix,
    this.onTaskOverdue,
  });
  final TodayCubit cubit;
  final TodayStrings Function(BuildContext) stringsResolver;
  final VoidCallback onTasks;
  final VoidCallback onHabits;
  final VoidCallback onMindMaps;
  final VoidCallback onPreferences;
  final VoidCallback? onNewTask;
  final VoidCallback? onNewHabit;
  final VoidCallback? onTaskMatrix;
  final VoidCallback? onTaskOverdue;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.cubit.resumeForeground();
  }

  @override
  void didUpdateWidget(covariant TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cubit != widget.cubit) {
      oldWidget.cubit.pauseForeground();
      widget.cubit.resumeForeground();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.cubit.resumeForeground();
    } else {
      widget.cubit.pauseForeground();
    }
  }

  @override
  void dispose() {
    widget.cubit.pauseForeground();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: widget.cubit,
    child: BlocBuilder<TodayCubit, TodayState>(
      builder: (context, state) {
        final strings = widget.stringsResolver(context);
        return Scaffold(
          key: kTodayScreenKey,
          appBar: AppBar(
            title: Text(strings.title),
            actions: [
              IconButton(
                key: kTodayPreferencesKey,
                tooltip: strings.preferences,
                onPressed: widget.onPreferences,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => widget.cubit.refresh(),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          strings.formatDate(state.calendar.localDate),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        if (widget.onNewTask != null ||
                            widget.onNewHabit != null)
                          Wrap(
                            spacing: 8,
                            children: [
                              if (widget.onNewTask != null)
                                FilledButton.icon(
                                  key: const Key('today_new_task'),
                                  onPressed: widget.onNewTask,
                                  icon: const Icon(Icons.add_task),
                                  label: Text(strings.newTask),
                                ),
                              if (widget.onNewHabit != null)
                                FilledButton.icon(
                                  key: const Key('today_new_habit'),
                                  onPressed: widget.onNewHabit,
                                  icon: const Icon(Icons.add),
                                  label: Text(strings.newHabit),
                                ),
                            ],
                          ),
                        TodaySummarySection<TodayTaskSummary>(
                          title: strings.tasks,
                          section: state.tasks,
                          strings: strings,
                          onRetry: widget.cubit.retryTasks,
                          content: (summary) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (summary.totalCount > 0) ...[
                                Text(
                                  '${strings.formatCount(summary.completedCount)}/${strings.formatCount(summary.totalCount)} · ${strings.formatPercent(summary.percent!)}',
                                ),
                                Text(
                                  '${strings.open}: ${strings.formatCount(summary.openCount)} · ${strings.completed}: ${strings.formatCount(summary.completedCount)}',
                                ),
                              ],
                              TodayAgendaSection(
                                agenda: TodayAgenda.project(
                                  state.calendar.localDate,
                                  summary.items,
                                  ownerId: state.scope.taskOwnerId,
                                ),
                                strings: strings,
                                onOpenTasks: widget.onTasks,
                                actions: state.taskActions,
                                allowActions:
                                    state.tasks.status ==
                                    TodaySectionStatus.available,
                                onSetCompleted:
                                    state.tasks.status ==
                                        TodaySectionStatus.available
                                    ? widget.cubit.setTaskCompleted
                                    : null,
                              ),
                              TodayPrioritySection(
                                tasks: summary.doFirst,
                                strings: strings,
                                onOpenTasks: widget.onTasks,
                                onOpenMatrix:
                                    widget.onTaskMatrix ?? widget.onTasks,
                              ),
                              TodayOverdueSection(
                                count: summary.overdueCount,
                                strings: strings,
                                onOpenOverdue:
                                    widget.onTaskOverdue ?? widget.onTasks,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          key: kTodayTasksNavigationKey,
                          onPressed: widget.onTasks,
                          child: Text(strings.tasks),
                        ),
                        TodaySummarySection<TodayHabitSummary>(
                          title: strings.habits,
                          section: state.habits,
                          strings: strings,
                          onRetry: widget.cubit.retryHabits,
                          content: (summary) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (summary.totalCount == 0)
                                Text(strings.noHabits)
                              else ...[
                                Text(
                                  '${strings.formatCount(summary.completedCount)}/${strings.formatCount(summary.totalCount)} · ${strings.formatPercent(summary.percent!)}',
                                ),
                                TodayHabitList(
                                  habits: summary.items,
                                  strings: strings,
                                  actions: state.habitActions,
                                  onSetCompleted:
                                      state.habits.status ==
                                          TodaySectionStatus.available
                                      ? widget.cubit.setHabitCompleted
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                        TextButton(
                          key: kTodayHabitsNavigationKey,
                          onPressed: widget.onHabits,
                          child: Text(strings.habits),
                        ),
                        TodaySummarySection<TodayXpSummary>(
                          title: strings.xp,
                          section: state.xp,
                          strings: strings,
                          onRetry: widget.cubit.retryXp,
                          content: (summary) => Text(
                            strings.formatXp(summary.amount),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        TextButton.icon(
                          key: kTodayMindMapsNavigationKey,
                          onPressed: widget.onMindMaps,
                          icon: const Icon(Icons.hub_outlined),
                          label: Text(strings.mindMaps),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

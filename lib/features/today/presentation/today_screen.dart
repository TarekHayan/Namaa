library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/today_projection.dart';
import 'today_cubit.dart';
import 'today_state.dart';
import 'today_strings.dart';
import 'widgets/today_habit_list.dart';
import 'widgets/today_summary_section.dart';
import 'widgets/today_task_list.dart';

const Key kTodayScreenKey = Key('today_screen');
const Key kTodayTasksNavigationKey = Key('today_tasks_navigation');
const Key kTodayHabitsNavigationKey = Key('today_habits_navigation');
const Key kTodayMindMapsNavigationKey = Key('today_mind_maps_navigation');
const Key kTodayPreferencesKey = Key('today_preferences');

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.cubit,
    required this.stringsResolver,
    required this.onTasks,
    required this.onHabits,
    required this.onMindMaps,
    required this.onPreferences,
  });
  final TodayCubit cubit;
  final TodayStrings Function(BuildContext) stringsResolver;
  final VoidCallback onTasks;
  final VoidCallback onHabits;
  final VoidCallback onMindMaps;
  final VoidCallback onPreferences;

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: cubit,
    child: BlocBuilder<TodayCubit, TodayState>(
      builder: (context, state) {
        final strings = stringsResolver(context);
        return Scaffold(
          key: kTodayScreenKey,
          appBar: AppBar(
            title: Text(strings.title),
            actions: [
              IconButton(
                key: kTodayPreferencesKey,
                tooltip: strings.preferences,
                onPressed: onPreferences,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => cubit.refresh(),
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
                        TodaySummarySection<TodayTaskSummary>(
                          title: strings.tasks,
                          section: state.tasks,
                          strings: strings,
                          onRetry: cubit.retryTasks,
                          content: (summary) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (summary.totalCount == 0)
                                Text(strings.noTasks)
                              else ...[
                                Text(
                                  '${strings.formatCount(summary.completedCount)}/${strings.formatCount(summary.totalCount)} · ${strings.formatPercent(summary.percent!)}',
                                ),
                                Text(
                                  '${strings.open}: ${strings.formatCount(summary.openCount)} · ${strings.completed}: ${strings.formatCount(summary.completedCount)}',
                                ),
                                TodayTaskList(
                                  tasks: summary.items,
                                  strings: strings,
                                ),
                              ],
                              Text(
                                '${strings.overdue}: ${strings.formatCount(summary.overdueCount)}',
                              ),
                              if (summary.doFirst.isNotEmpty) ...[
                                Text(
                                  strings.doFirst,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                TodayTaskList(
                                  tasks: summary.doFirst,
                                  strings: strings,
                                ),
                              ],
                            ],
                          ),
                        ),
                        TextButton(
                          key: kTodayTasksNavigationKey,
                          onPressed: onTasks,
                          child: Text(strings.tasks),
                        ),
                        TodaySummarySection<TodayHabitSummary>(
                          title: strings.habits,
                          section: state.habits,
                          strings: strings,
                          onRetry: cubit.retryHabits,
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
                                ),
                              ],
                            ],
                          ),
                        ),
                        TextButton(
                          key: kTodayHabitsNavigationKey,
                          onPressed: onHabits,
                          child: Text(strings.habits),
                        ),
                        TodaySummarySection<TodayXpSummary>(
                          title: strings.xp,
                          section: state.xp,
                          strings: strings,
                          onRetry: cubit.retryXp,
                          content: (summary) => Text(
                            strings.formatXp(summary.amount),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        TextButton.icon(
                          key: kTodayMindMapsNavigationKey,
                          onPressed: onMindMaps,
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

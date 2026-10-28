library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'today_cubit.dart';
import 'today_dashboard_view.dart';
import 'today_state.dart';
import 'today_strings.dart';

export 'today_dashboard_view.dart'
    show
        kTodayScreenKey,
        kTodayTasksNavigationKey,
        kTodayHabitsNavigationKey,
        kTodayMindMapsNavigationKey,
        kTodayPreferencesKey;

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
      builder: (context, state) => TodayDashboardView(
        state: state,
        strings: widget.stringsResolver(context),
        onRefresh: widget.cubit.refresh,
        onTasks: widget.onTasks,
        onHabits: widget.onHabits,
        onMindMaps: widget.onMindMaps,
        onPreferences: widget.onPreferences,
        onNewTask: widget.onNewTask,
        onNewHabit: widget.onNewHabit,
        onTaskMatrix: widget.onTaskMatrix,
        onTaskOverdue: widget.onTaskOverdue,
        onRetryTasks: widget.cubit.retryTasks,
        onRetryHabits: widget.cubit.retryHabits,
        onRetryXp: widget.cubit.retryXp,
        onSetTaskCompleted: widget.cubit.setTaskCompleted,
        onSetHabitCompleted: widget.cubit.setHabitCompleted,
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/features/habits/application/habit_queries.dart';
import 'package:namma_project/features/habits/presentation/habit_editor.dart';
import 'package:namma_project/features/habits/presentation/habit_history_view.dart';
import 'package:namma_project/features/habits/presentation/habits_cubit.dart';
import 'package:namma_project/features/habits/presentation/habits_state.dart';
import 'package:namma_project/features/habits/presentation/habits_strings.dart';

export 'habit_editor.dart'
    show
        kHabitNameFieldKey,
        kHabitNameValidationKey,
        kHabitWeekdayValidationKey,
        kHabitSaveButtonKey;

const Key kHabitAddButtonKey = Key('habit_add_button');
const Key kHabitsEmptyKey = Key('habits_empty');
const Key kHabitsSignedOutKey = Key('habits_signed_out');
const Key kHabitsMobileLayoutKey = Key('habits_mobile_layout');
const Key kHabitsDesktopLayoutKey = Key('habits_desktop_layout');

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({
    super.key,
    required this.cubit,
    required this.accountId,
    required this.stringsResolver,
  });

  final HabitsCubit cubit;
  final String? accountId;
  final HabitsStringsResolver stringsResolver;

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.accountId != null) widget.cubit.load(widget.accountId!);
  }

  @override
  void didUpdateWidget(HabitsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accountId != null && widget.accountId != oldWidget.accountId) {
      widget.cubit.load(widget.accountId!);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.cubit.resume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.cubit.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.stringsResolver(context);
    if (widget.accountId == null) {
      return Scaffold(
        body: Center(
          child: Text(strings.signInRequired, key: kHabitsSignedOutKey),
        ),
      );
    }
    return BlocBuilder<HabitsCubit, HabitsState>(
      bloc: widget.cubit,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(strings.title)),
        floatingActionButton: FloatingActionButton.extended(
          key: kHabitAddButtonKey,
          tooltip: strings.create,
          icon: const Icon(Icons.add),
          label: Text(strings.create),
          onPressed: () => HabitEditor.show(
            context,
            cubit: widget.cubit,
            stringsResolver: widget.stringsResolver,
          ),
        ),
        body: switch (state) {
          HabitsInitial() ||
          HabitsLoading() => const Center(child: CircularProgressIndicator()),
          HabitsFailure() => Center(child: Text(strings.loadFailure)),
          HabitsReady(:final accountId) when accountId != widget.accountId =>
            const Center(child: CircularProgressIndicator()),
          HabitsReady(:final today, :final lastFailure) => LayoutBuilder(
            builder: (context, constraints) => Center(
              child: ConstrainedBox(
                key: constraints.maxWidth >= 700
                    ? kHabitsDesktopLayoutKey
                    : kHabitsMobileLayoutKey,
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    if (lastFailure != null)
                      MaterialBanner(
                        content: Text(strings.saveFailure),
                        actions: [
                          TextButton(
                            onPressed: widget.cubit.clearFailure,
                            child: Text(strings.cancel),
                          ),
                        ],
                      ),
                    Expanded(
                      child: today.isEmpty
                          ? Center(
                              child: Text(strings.empty, key: kHabitsEmptyKey),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                96,
                              ),
                              itemCount: today.length,
                              itemBuilder: (context, index) => _HabitCard(
                                value: today[index],
                                strings: strings,
                                onComplete: () => widget.cubit.completeToday(
                                  today[index].habit.id,
                                ),
                                onUndo: () => widget.cubit.undoToday(
                                  today[index].habit.id,
                                ),
                                onHistory: () => HabitHistoryView.show(
                                  context,
                                  history: today[index].history,
                                  strings: strings,
                                ),
                                onEdit: () => HabitEditor.show(
                                  context,
                                  cubit: widget.cubit,
                                  stringsResolver: widget.stringsResolver,
                                  habit: today[index].habit,
                                ),
                                onDelete: () => _confirmDelete(
                                  context,
                                  today[index].habit.id,
                                  strings,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String habitId,
    HabitsStrings strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('habit_delete_confirmation'),
        title: Text(strings.delete),
        content: Text(strings.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            key: const Key('habit_confirm_delete'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.cubit.deleteHabit(habitId, confirmed: true);
    }
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.value,
    required this.strings,
    required this.onComplete,
    required this.onUndo,
    required this.onHistory,
    required this.onEdit,
    required this.onDelete,
  });
  final HabitToday value;
  final HabitsStrings strings;
  final VoidCallback onComplete;
  final VoidCallback onUndo;
  final VoidCallback onHistory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final habit = value.habit;
    return Card(
      key: ValueKey('habit-${habit.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    habit.currentRevision.weekdays
                        .map(strings.weekday)
                        .join(' • '),
                  ),
                  Text(value.isDue ? strings.dueToday : strings.notDueToday),
                  Text('${strings.currentStreak}: ${value.currentStreak}'),
                  if (value.history.isTodayPending) Text(strings.pendingToday),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: ValueKey('habit-history-${habit.id}'),
                      onPressed: onHistory,
                      icon: const Icon(Icons.history),
                      label: Text(strings.history),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        key: ValueKey('habit-edit-${habit.id}'),
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(strings.edit),
                      ),
                      TextButton.icon(
                        key: ValueKey('habit-delete-${habit.id}'),
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(strings.delete),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (value.isCompleted)
              IconButton(
                key: ValueKey('habit-undo-${habit.id}'),
                tooltip: strings.undo,
                onPressed: onUndo,
                icon: const Icon(Icons.undo),
              )
            else if (value.isDue)
              IconButton(
                key: ValueKey('habit-complete-${habit.id}'),
                tooltip: strings.complete,
                onPressed: onComplete,
                icon: const Icon(Icons.check_circle_outline),
              ),
          ],
        ),
      ),
    );
  }
}

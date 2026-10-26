import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_hover_surface.dart';
import 'package:namma_project/app/widgets/app_status_view.dart';
import 'package:namma_project/core/application/navigation/owner_entry_intent.dart';
import 'package:namma_project/features/habits/application/habit_queries.dart';
import 'package:namma_project/features/habits/application/habit_sync_service.dart';
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
        kHabitSaveButtonKey,
        kHabitRepeatedTypeKey,
        kHabitDailyTargetKey,
        kHabitDailyTargetValidationKey;

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
    this.entryIntent,
  });

  final HabitsCubit cubit;
  final String? accountId;
  final HabitsStringsResolver stringsResolver;
  final OwnerEntryIntent? entryIntent;

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen>
    with WidgetsBindingObserver {
  bool _intentConsumed = false;
  bool _showAddForm = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.accountId != null) widget.cubit.load(widget.accountId!);
  }

  @override
  void didUpdateWidget(HabitsScreen oldWidget) {
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
      builder: (context, state) {
        if (!_intentConsumed &&
            widget.entryIntent == OwnerEntryIntent.newHabit &&
            state is HabitsReady &&
            state.accountId == widget.accountId) {
          _intentConsumed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.accountId == state.accountId) {
              HabitEditor.show(
                context,
                cubit: widget.cubit,
                stringsResolver: widget.stringsResolver,
              );
            }
          });
        }
        final colors = Theme.of(context).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light;
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(title: Text(strings.title)),
          body: switch (state) {
            HabitsInitial() || HabitsLoading() => const AppStatusView.loading(),
            HabitsFailure() => AppStatusView.error(title: strings.loadFailure),
            HabitsReady(:final accountId) when accountId != widget.accountId =>
              const Center(child: CircularProgressIndicator()),
            HabitsReady(
              :final today,
              :final lastFailure,
              :final syncSnapshot,
              :final conflicts,
            ) =>
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 700;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      key: wide
                          ? kHabitsDesktopLayoutKey
                          : kHabitsMobileLayoutKey,
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          wide ? 28 : 16,
                          wide ? 28 : 16,
                          wide ? 28 : 16,
                          32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HabitsHero(
                              strings: strings,
                              colors: colors,
                              onAdd: () =>
                                  setState(() => _showAddForm = !_showAddForm),
                            ),
                            const SizedBox(height: 20),
                            if (_showAddForm) ...[
                              HabitEditor(
                                cubit: widget.cubit,
                                stringsResolver: widget.stringsResolver,
                                inline: true,
                                onClose: () =>
                                    setState(() => _showAddForm = false),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (syncSnapshot.status ==
                                HabitSyncStatus.synchronizing)
                              ListTile(
                                leading: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                title: Text(strings.syncing),
                              ),
                            if (syncSnapshot.status == HabitSyncStatus.failed)
                              MaterialBanner(
                                content: Text(strings.syncFailed),
                                actions: [
                                  TextButton(
                                    onPressed: widget.cubit.retrySync,
                                    child: Text(strings.syncRetry),
                                  ),
                                ],
                              ),
                            if (conflicts.isNotEmpty)
                              SizedBox(
                                height: 140,
                                child: ListView.builder(
                                  itemCount: conflicts.length,
                                  itemBuilder: (context, index) {
                                    final conflict = conflicts[index];
                                    return Card(
                                      key: ValueKey(
                                        'habit-conflict-${conflict.id}',
                                      ),
                                      child: ListTile(
                                        title: Text(strings.conflict),
                                        subtitle: Text(
                                          '${strings.activeVersion}: ${conflict.activeLabel}\n'
                                          '${strings.retainedVersion}: ${conflict.retainedLabel}'
                                          '${conflict.unresolved ? '\n${strings.unresolvedConflict}' : ''}',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
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
                            if (today.isEmpty)
                              _HabitsEmpty(strings: strings, colors: colors)
                            else
                              LayoutBuilder(
                                builder: (context, gridConstraints) {
                                  final columns =
                                      gridConstraints.maxWidth >= 780 ? 2 : 1;
                                  final cardWidth = columns == 2
                                      ? (gridConstraints.maxWidth - 16) / 2
                                      : gridConstraints.maxWidth;
                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: [
                                      for (final item in today)
                                        SizedBox(
                                          width: cardWidth,
                                          child: _HabitCard(
                                            value: item,
                                            strings: strings,
                                            colors: colors,
                                            onComplete: () => widget.cubit
                                                .completeToday(item.habit.id),
                                            onUndo: () => widget.cubit
                                                .undoToday(item.habit.id),
                                            onIncrement: (step) =>
                                                widget.cubit.adjustToday(
                                                  item.habit.id,
                                                  step,
                                                ),
                                            onDecrement: () => widget.cubit
                                                .adjustToday(item.habit.id, -1),
                                            onHistory: () =>
                                                HabitHistoryView.show(
                                                  context,
                                                  history: item.history,
                                                  strings: strings,
                                                ),
                                            onEdit: () => HabitEditor.show(
                                              context,
                                              cubit: widget.cubit,
                                              stringsResolver:
                                                  widget.stringsResolver,
                                              habit: item.habit,
                                            ),
                                            onDelete: () => _confirmDelete(
                                              context,
                                              item.habit.id,
                                              strings,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          },
        );
      },
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
    required this.colors,
    required this.onComplete,
    required this.onUndo,
    required this.onIncrement,
    required this.onDecrement,
    required this.onHistory,
    required this.onEdit,
    required this.onDelete,
  });
  final HabitToday value;
  final HabitsStrings strings;
  final AppColors colors;
  final VoidCallback onComplete;
  final VoidCallback onUndo;
  final void Function(int step) onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onHistory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final habit = value.habit;
    final completed = value.isCompleted;
    final target = habit.dailyTarget;
    final count = value.day?.count ?? 0;
    final progress = (count / target).clamp(0.0, 1.0);
    return AppHoverSurface(
      radius: 32,
      child: Container(
        key: ValueKey('habit-${habit.id}'),
        decoration: BoxDecoration(
          color: completed ? colors.accentSoft : colors.surface,
          border: Border.all(
            color: completed
                ? colors.primary.withValues(alpha: 0.45)
                : colors.border,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      habit.name,
                      softWrap: true,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HabitIconAction(
                    key: ValueKey('habit-edit-${habit.id}'),
                    icon: Icons.edit_outlined,
                    tooltip: strings.edit,
                    colors: colors,
                    onPressed: onEdit,
                  ),
                  if (habit.hasRepetitions)
                    _HabitIconAction(
                      key: ValueKey('habit-history-${habit.id}'),
                      icon: Icons.history,
                      tooltip: strings.history,
                      colors: colors,
                      onPressed: onHistory,
                    ),
                  if (habit.hasRepetitions && count > 0)
                    _HabitIconAction(
                      key: ValueKey('habit-reset-${habit.id}'),
                      icon: Icons.restart_alt_rounded,
                      tooltip: strings.undo,
                      colors: colors,
                      onPressed: onUndo,
                    ),
                  _HabitIconAction(
                    key: ValueKey('habit-delete-${habit.id}'),
                    icon: Icons.delete_outline,
                    tooltip: strings.delete,
                    colors: colors,
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                habit.currentRevision.weekdays.map(strings.weekday).join(' • '),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      ' / $target',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: colors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  backgroundColor: colors.surfaceSecondary,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                value.isDue ? strings.dueToday : strings.notDueToday,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '${strings.currentStreak}: ${value.currentStreak}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
              if (value.history.isTodayPending)
                Text(
                  strings.pendingToday,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.warning),
                ),
              const SizedBox(height: 18),
              Divider(color: colors.border, height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (habit.hasRepetitions) ...[
                    _HabitIconAction(
                      key: ValueKey('habit-decrement-${habit.id}'),
                      icon: Icons.remove,
                      tooltip: '-1',
                      colors: colors,
                      onPressed: count > 0 ? onDecrement : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        key: ValueKey('habit-increment-${habit.id}'),
                        label: '+1',
                        icon: Icons.add,
                        onPressed: value.isDue && count < target
                            ? () => onIncrement(1)
                            : null,
                        expanded: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      key: ValueKey('habit-plus-five-${habit.id}'),
                      label: '+5',
                      variant: AppButtonVariant.outline,
                      onPressed: value.isDue && count < target
                          ? () => onIncrement(5)
                          : null,
                    ),
                  ] else if (completed)
                    Expanded(
                      child: Tooltip(
                        message: strings.undo,
                        child: AppButton(
                          key: ValueKey('habit-undo-${habit.id}'),
                          label: strings.undo,
                          icon: Icons.undo,
                          variant: AppButtonVariant.secondary,
                          onPressed: onUndo,
                          expanded: true,
                        ),
                      ),
                    )
                  else if (value.isDue)
                    Expanded(
                      child: Tooltip(
                        message: strings.complete,
                        child: AppButton(
                          key: ValueKey('habit-complete-${habit.id}'),
                          label: strings.complete,
                          icon: Icons.check_circle_outline,
                          onPressed: onComplete,
                          expanded: true,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        strings.notDueToday,
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ),
                  if (!habit.hasRepetitions) ...[
                    const SizedBox(width: 10),
                    _HabitIconAction(
                      key: ValueKey('habit-history-${habit.id}'),
                      icon: Icons.history,
                      tooltip: strings.history,
                      colors: colors,
                      onPressed: onHistory,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitsHero extends StatelessWidget {
  const _HabitsHero({
    required this.strings,
    required this.colors,
    required this.onAdd,
  });

  final HabitsStrings strings;
  final AppColors colors;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final title = isArabic ? 'العادات الشخصية' : 'Personal habits';
    final subtitle = isArabic
        ? 'متابعة العادات اليومية والتكرارات'
        : 'Track daily habits and repetitions';
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
      ],
    );
    final add = AppButton(
      key: kHabitAddButtonKey,
      label: strings.create,
      icon: Icons.add,
      onPressed: onAdd,
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(32),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 480
            ? Row(
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 16),
                  add,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [content, const SizedBox(height: 18), add],
              ),
      ),
    );
  }
}

class _HabitsEmpty extends StatelessWidget {
  const _HabitsEmpty({required this.strings, required this.colors});
  final HabitsStrings strings;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Container(
    key: kHabitsEmptyKey,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
    decoration: BoxDecoration(
      color: colors.surface,
      border: Border.all(color: colors.border),
      borderRadius: BorderRadius.circular(32),
    ),
    child: Column(
      children: [
        Icon(Icons.autorenew_rounded, size: 34, color: colors.primary),
        const SizedBox(height: 14),
        Text(
          strings.empty,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: colors.textPrimary),
        ),
      ],
    ),
  );
}

class _HabitIconAction extends StatelessWidget {
  const _HabitIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.colors,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final AppColors colors;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    color: colors.textSecondary,
    style: IconButton.styleFrom(
      backgroundColor: colors.surfaceSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

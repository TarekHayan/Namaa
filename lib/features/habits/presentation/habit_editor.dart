import 'package:flutter/material.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/features/habits/application/habit_commands.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/presentation/habits_cubit.dart';
import 'package:namma_project/features/habits/presentation/habits_strings.dart';

const Key kHabitNameFieldKey = Key('habit_name_field');
const Key kHabitNameValidationKey = Key('habit_name_validation');
const Key kHabitWeekdayValidationKey = Key('habit_weekday_validation');
const Key kHabitSaveButtonKey = Key('habit_save_button');
const Key kHabitReminderButtonKey = Key('habit_reminder_button');
const Key kHabitReminderClearKey = Key('habit_reminder_clear');
const Key kHabitRepeatedTypeKey = Key('habit_repeated_type');
const Key kHabitDailyTargetKey = Key('habit_daily_target');
const Key kHabitDailyTargetValidationKey = Key('habit_daily_target_validation');

class HabitEditor extends StatefulWidget {
  const HabitEditor({
    super.key,
    required this.cubit,
    required this.stringsResolver,
    this.habit,
    this.inline = false,
    this.onClose,
  });

  final HabitsCubit cubit;
  final HabitsStringsResolver stringsResolver;
  final Habit? habit;
  final bool inline;
  final VoidCallback? onClose;

  static Future<void> show(
    BuildContext context, {
    required HabitsCubit cubit,
    required HabitsStringsResolver stringsResolver,
    Habit? habit,
  }) => showDialog<void>(
    context: context,
    builder: (_) => HabitEditor(
      cubit: cubit,
      stringsResolver: stringsResolver,
      habit: habit,
    ),
  );

  @override
  State<HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends State<HabitEditor> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _dailyTarget = TextEditingController(text: '10');
  final Set<int> _weekdays = {};
  bool _showNameError = false;
  bool _showWeekdayError = false;
  bool _saving = false;
  bool _saveFailed = false;
  bool _repeated = false;
  bool _showTargetError = false;
  int? _reminderMinuteOfDay;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    if (habit != null) {
      _name.text = habit.name;
      _repeated = habit.hasRepetitions;
      _dailyTarget.text = habit.dailyTarget.toString();
      _weekdays.addAll(habit.currentRevision.weekdays);
      _reminderMinuteOfDay = habit.reminderMinuteOfDay;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dailyTarget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final noName = _name.text.trim().isEmpty;
    final noWeekdays = _weekdays.isEmpty;
    final target = _repeated ? _parseDailyTarget(_dailyTarget.text) : 1;
    final invalidTarget = target == null || target < 2 || target > 9999;
    if (noName || noWeekdays || (_repeated && invalidTarget)) {
      setState(() {
        _showNameError = noName;
        _showWeekdayError = noWeekdays;
        _showTargetError = _repeated && invalidTarget;
      });
      return;
    }
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    final habit = widget.habit;
    final result = habit == null
        ? await widget.cubit.createHabit(
            CreateHabitInput(
              name: _name.text,
              weekdays: Set<int>.of(_weekdays),
              reminderMinuteOfDay: _reminderMinuteOfDay,
              dailyTarget: target!,
            ),
          )
        : await widget.cubit.editHabit(
            EditHabitInput(
              habitId: habit.id,
              name: _name.text,
              weekdays: Set<int>.of(_weekdays),
              reminderMinuteOfDay: _reminderMinuteOfDay,
            ),
          );
    if (!mounted) return;
    if (result.failureOrNull == null) {
      if (widget.inline) {
        widget.onClose?.call();
      } else {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.stringsResolver(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.habit == null ? strings.create : strings.edit,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: _saving ? null : _close,
              child: Text(strings.cancel),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          isArabic ? 'نوع العادة' : 'Habit type',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(isArabic ? 'مرة واحدة في اليوم' : 'Once per day'),
              selected: !_repeated,
              onSelected: widget.habit == null
                  ? (_) => setState(() => _repeated = false)
                  : null,
            ),
            ChoiceChip(
              key: kHabitRepeatedTypeKey,
              label: Text(isArabic ? 'بعدد مرات يوميًا' : 'Daily repetitions'),
              selected: _repeated,
              onSelected: widget.habit == null
                  ? (_) => setState(() => _repeated = true)
                  : null,
            ),
          ],
        ),
        if (_repeated) ...[
          const SizedBox(height: 14),
          TextField(
            key: kHabitDailyTargetKey,
            controller: _dailyTarget,
            enabled: widget.habit == null,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isArabic
                  ? 'الهدف اليومي (عدد المرات)'
                  : 'Daily target (repetitions)',
            ),
            onChanged: (_) {
              if (_showTargetError) setState(() => _showTargetError = false);
            },
          ),
          if (_showTargetError)
            Text(
              isArabic
                  ? 'اكتب هدفًا من ٢ إلى ٩٩٩٩ مرة'
                  : 'Enter a target from 2 to 9999',
              key: kHabitDailyTargetValidationKey,
              style: TextStyle(color: colors.error),
            ),
        ],
        const SizedBox(height: 18),
        TextField(
          key: kHabitNameFieldKey,
          controller: _name,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: strings.nameLabel),
          onChanged: (_) {
            if (_showNameError) setState(() => _showNameError = false);
          },
          onSubmitted: (_) => _save(),
        ),
        if (_showNameError)
          Text(
            strings.nameRequired,
            key: kHabitNameValidationKey,
            style: TextStyle(color: colors.error),
          ),
        const SizedBox(height: 20),
        Text(
          isArabic ? 'أيام التكرار' : 'Repeat days',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var weekday = 1; weekday <= 7; weekday++)
              FilterChip(
                key: Key('habit-weekday-$weekday'),
                label: Text(strings.weekday(weekday)),
                selected: _weekdays.contains(weekday),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _weekdays.add(weekday);
                  } else {
                    _weekdays.remove(weekday);
                  }
                  _showWeekdayError = false;
                }),
              ),
          ],
        ),
        if (_showWeekdayError)
          Text(
            strings.weekdaysRequired,
            key: kHabitWeekdayValidationKey,
            style: TextStyle(color: colors.error),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: kHabitReminderButtonKey,
                onPressed: _saving ? null : _chooseReminder,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _reminderMinuteOfDay == null
                      ? strings.reminderTime
                      : '${strings.reminderTime}: ${TimeOfDay(hour: _reminderMinuteOfDay! ~/ 60, minute: _reminderMinuteOfDay! % 60).format(context)}',
                ),
              ),
            ),
            if (_reminderMinuteOfDay != null)
              IconButton(
                key: kHabitReminderClearKey,
                tooltip: strings.reminderClear,
                onPressed: _saving
                    ? null
                    : () => setState(() => _reminderMinuteOfDay = null),
                icon: const Icon(Icons.clear),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          strings.reminderInactive,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
        if (_saveFailed) ...[
          const SizedBox(height: 10),
          Text(strings.saveFailure, style: TextStyle(color: colors.error)),
        ],
        const SizedBox(height: 24),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: AppButton(
            key: kHabitSaveButtonKey,
            label: strings.save,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ),
      ],
    );
    if (widget.inline) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.primary.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(32),
        ),
        child: content,
      );
    }
    return AlertDialog(
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(child: content),
      ),
    );
  }

  void _close() {
    if (widget.inline) {
      widget.onClose?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _chooseReminder() async {
    final initial = _reminderMinuteOfDay == null
        ? TimeOfDay.now()
        : TimeOfDay(
            hour: _reminderMinuteOfDay! ~/ 60,
            minute: _reminderMinuteOfDay! % 60,
          );
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected != null && mounted) {
      setState(
        () => _reminderMinuteOfDay = selected.hour * 60 + selected.minute,
      );
    }
  }
}

int? _parseDailyTarget(String text) {
  final normalized = text.trim().replaceAllMapped(RegExp(r'[٠-٩۰-۹]'), (match) {
    final digit = match[0]!.codeUnitAt(0);
    final value = digit >= 0x06F0 ? digit - 0x06F0 : digit - 0x0660;
    return value.toString();
  });
  return int.tryParse(normalized);
}

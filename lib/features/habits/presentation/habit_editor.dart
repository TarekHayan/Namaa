import 'package:flutter/material.dart';
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

class HabitEditor extends StatefulWidget {
  const HabitEditor({
    super.key,
    required this.cubit,
    required this.stringsResolver,
    this.habit,
  });

  final HabitsCubit cubit;
  final HabitsStringsResolver stringsResolver;
  final Habit? habit;

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
  final Set<int> _weekdays = {};
  bool _showNameError = false;
  bool _showWeekdayError = false;
  bool _saving = false;
  bool _saveFailed = false;
  int? _reminderMinuteOfDay;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    if (habit != null) {
      _name.text = habit.name;
      _weekdays.addAll(habit.currentRevision.weekdays);
      _reminderMinuteOfDay = habit.reminderMinuteOfDay;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final noName = _name.text.trim().isEmpty;
    final noWeekdays = _weekdays.isEmpty;
    if (noName || noWeekdays) {
      setState(() {
        _showNameError = noName;
        _showWeekdayError = noWeekdays;
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
      Navigator.of(context).pop();
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
    return AlertDialog(
      title: Text(widget.habit == null ? strings.create : strings.edit),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: kHabitReminderButtonKey,
                      onPressed: _saving
                          ? null
                          : () async {
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
                                  () => _reminderMinuteOfDay =
                                      selected.hour * 60 + selected.minute,
                                );
                              }
                            },
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
              Text(strings.reminderInactive),
              if (_saveFailed)
                Text(
                  strings.saveFailure,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          key: kHabitSaveButtonKey,
          onPressed: _saving ? null : _save,
          child: Text(strings.save),
        ),
      ],
    );
  }
}

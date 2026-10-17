import 'package:flutter/widgets.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/habits/presentation/habits_strings.dart';

HabitsStrings resolveHabitsStrings(BuildContext context) =>
    _AppHabitsStrings(FoundationLocalizations.of(context));

final class _AppHabitsStrings implements HabitsStrings {
  const _AppHabitsStrings(this._l10n);
  final FoundationLocalizations _l10n;

  @override
  String get title => _l10n.habitsTitle;
  @override
  String get empty => _l10n.habitsEmpty;
  @override
  String get create => _l10n.habitsCreate;
  @override
  String get edit => _l10n.habitEdit;
  @override
  String get delete => _l10n.habitDelete;
  @override
  String get deleteConfirmation => _l10n.habitDeleteConfirmation;
  @override
  String get reminderTime => _l10n.habitReminderTime;
  @override
  String get reminderClear => _l10n.habitReminderClear;
  @override
  String get reminderInactive => _l10n.habitReminderInactive;
  @override
  String get nameLabel => _l10n.habitNameLabel;
  @override
  String get nameRequired => _l10n.habitNameRequired;
  @override
  String get weekdaysRequired => _l10n.habitWeekdaysRequired;
  @override
  String get save => _l10n.habitSave;
  @override
  String get cancel => _l10n.habitCancel;
  @override
  String get complete => _l10n.habitComplete;
  @override
  String get undo => _l10n.habitUndo;
  @override
  String get dueToday => _l10n.habitDueToday;
  @override
  String get notDueToday => _l10n.habitNotDueToday;
  @override
  String get loadFailure => _l10n.habitsLoadFailure;
  @override
  String get saveFailure => _l10n.habitsSaveFailure;
  @override
  String get signInRequired => _l10n.habitsSignInRequired;
  @override
  String get history => _l10n.habitHistory;
  @override
  String get currentStreak => _l10n.habitCurrentStreak;
  @override
  String get completedDates => _l10n.habitCompletedDates;
  @override
  String get noCompletedDates => _l10n.habitNoCompletedDates;
  @override
  String get pendingToday => _l10n.habitPendingToday;
  @override
  String get scheduleHistory => _l10n.habitScheduleHistory;
  @override
  String get effectiveFrom => _l10n.habitEffectiveFrom;
  @override
  String get completedOn => _l10n.habitCompletedOn;
  @override
  String get closeHistory => _l10n.habitCloseHistory;

  @override
  String weekday(int weekday) => switch (weekday) {
    DateTime.monday => _l10n.habitMonday,
    DateTime.tuesday => _l10n.habitTuesday,
    DateTime.wednesday => _l10n.habitWednesday,
    DateTime.thursday => _l10n.habitThursday,
    DateTime.friday => _l10n.habitFriday,
    DateTime.saturday => _l10n.habitSaturday,
    DateTime.sunday => _l10n.habitSunday,
    _ => throw ArgumentError.value(weekday, 'weekday'),
  };
}

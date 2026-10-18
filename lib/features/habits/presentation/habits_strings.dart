import 'package:flutter/widgets.dart';

abstract interface class HabitsStrings {
  String get title;
  String get empty;
  String get create;
  String get edit;
  String get delete;
  String get deleteConfirmation;
  String get reminderTime;
  String get reminderClear;
  String get reminderInactive;
  String get syncing;
  String get syncFailed;
  String get syncRetry;
  String get conflict;
  String get activeVersion;
  String get retainedVersion;
  String get unresolvedConflict;
  String get nameLabel;
  String get nameRequired;
  String get weekdaysRequired;
  String get save;
  String get cancel;
  String get complete;
  String get undo;
  String get dueToday;
  String get notDueToday;
  String get loadFailure;
  String get saveFailure;
  String get signInRequired;
  String get history;
  String get currentStreak;
  String get completedDates;
  String get noCompletedDates;
  String get pendingToday;
  String get scheduleHistory;
  String get effectiveFrom;
  String get completedOn;
  String get closeHistory;
  String weekday(int weekday);
}

typedef HabitsStringsResolver = HabitsStrings Function(BuildContext context);

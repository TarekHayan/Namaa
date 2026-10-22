library;

import '../domain/today_calendar.dart';

abstract interface class TodayStrings {
  String get title;
  String get tasks;
  String get habits;
  String get mindMaps;
  String get xp;
  String get open;
  String get completed;
  String get streak;
  String get doFirst;
  String get overdue;
  String get noTasks;
  String get noHabits;
  String get loading;
  String get unavailable;
  String get outdated;
  String get retry;
  String get preferences;
  String get language;
  String get appearance;
  String get english;
  String get arabic;
  String get system;
  String get light;
  String get dark;
  String get newTask;
  String get newHabit;
  String get completeTask;
  String get reopenTask;
  String get completeHabit;
  String get undoHabit;
  String get saving;
  String get saveFailed;
  String get uncertain;
  String get staleDay;
  String formatDate(TodayLocalDate date);
  String formatCount(int value);
  String formatPercent(int value);
  String formatXp(int value);
  String formatTime(int minuteOfDay);
}

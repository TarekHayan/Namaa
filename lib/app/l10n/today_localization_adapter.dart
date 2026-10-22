library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:namma_project/features/today/domain/today_calendar.dart';
import 'package:namma_project/features/today/presentation/today_strings.dart';

import 'generated/app_localizations.dart';

TodayStrings resolveTodayStrings(BuildContext context) => _AppTodayStrings(
  FoundationLocalizations.of(context),
  Localizations.localeOf(context),
);

final class _AppTodayStrings implements TodayStrings {
  const _AppTodayStrings(this._l10n, this._locale);
  final FoundationLocalizations _l10n;
  final Locale _locale;
  String get _code => _locale.languageCode;

  @override
  String get title => _l10n.todayTitle;
  @override
  String get tasks => _l10n.tasksTitle;
  @override
  String get habits => _l10n.habitsTitle;
  @override
  String get mindMaps => _l10n.mindMapsTitle;
  @override
  String get xp => _l10n.todayXp;
  @override
  String get open => _l10n.todayOpen;
  @override
  String get completed => _l10n.todayCompleted;
  @override
  String get streak => _l10n.todayStreak;
  @override
  String get doFirst => _l10n.todayDoFirst;
  @override
  String get overdue => _l10n.todayOverdue;
  @override
  String get noTasks => _l10n.todayNoTasks;
  @override
  String get noHabits => _l10n.todayNoHabits;
  @override
  String get loading => _l10n.todayLoading;
  @override
  String get unavailable => _l10n.todaySourceUnavailable;
  @override
  String get outdated => _l10n.todayOutdated;
  @override
  String get retry => _l10n.retry;
  @override
  String get preferences => _l10n.todayPreferences;
  @override
  String get language => _l10n.todayLanguage;
  @override
  String get appearance => _l10n.todayAppearance;
  @override
  String get english => _l10n.todayEnglish;
  @override
  String get arabic => _l10n.todayArabic;
  @override
  String get system => _l10n.todaySystem;
  @override
  String get light => _l10n.todayLight;
  @override
  String get dark => _l10n.todayDark;
  @override
  String get newTask => _l10n.todayNewTask;
  @override
  String get newHabit => _l10n.todayNewHabit;
  @override
  String get completeTask => _l10n.todayCompleteTask;
  @override
  String get reopenTask => _l10n.todayReopenTask;
  @override
  String get completeHabit => _l10n.todayCompleteHabit;
  @override
  String get undoHabit => _l10n.todayUndoHabit;
  @override
  String get saving => _l10n.todaySaving;
  @override
  String get saveFailed => _l10n.todaySaveFailed;
  @override
  String get uncertain => _l10n.todayUncertain;
  @override
  String get staleDay => _l10n.todayStaleDay;
  @override
  String formatDate(TodayLocalDate date) => DateFormat.yMMMMEEEEd(
    _code,
  ).format(DateTime(date.year, date.month, date.day));
  @override
  String formatCount(int value) =>
      NumberFormat.decimalPattern(_code).format(value);
  @override
  String formatPercent(int value) =>
      NumberFormat.percentPattern(_code).format(value / 100);
  @override
  String formatXp(int value) => '${formatCount(value)} $xp';
  @override
  String formatTime(int minuteOfDay) => DateFormat.jm(
    _code,
  ).format(DateTime(2026, 1, 1, minuteOfDay ~/ 60, minuteOfDay % 60));
}

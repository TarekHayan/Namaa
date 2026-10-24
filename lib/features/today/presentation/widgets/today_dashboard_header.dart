library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../../data/umm_al_qura_today_date.dart';
import '../today_state.dart';
import '../today_strings.dart';

/// The Dashboard header deliberately derives both dates from the same local
/// calendar sample owned by [TodayState].
class TodayDashboardHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const TodayDashboardHeader({
    super.key,
    required this.state,
    required this.strings,
    required this.colors,
    required this.onPreferences,
    this.onNewTask,
    this.onNewHabit,
  });

  final TodayState state;
  final TodayStrings strings;
  final AppColors colors;
  final VoidCallback onPreferences;
  final VoidCallback? onNewTask;
  final VoidCallback? onNewHabit;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 12);

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final hijri = UmmAlQuraTodayDate.fromLocalDate(state.calendar.localDate);

    return AppBar(
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/images/namaa_icon.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _greeting(copy),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  strings.formatDate(state.calendar.localDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  hijri == null
                      ? copy.dashboardHijriDateUnavailable
                      : '${copy.dashboardUmmAlQuraCalendar} · '
                            '${copy.dashboardHijriDate(
                              '${hijri.day}',
                              _monthName(copy, hijri.month),
                              '${hijri.year}',
                            )}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onNewTask != null || onNewHabit != null)
          PopupMenuButton<VoidCallback>(
            tooltip: '${strings.newTask} / ${strings.newHabit}',
            icon: const Icon(Icons.add_rounded),
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              if (onNewTask != null)
                PopupMenuItem(
                  key: const Key('today_new_task'),
                  value: onNewTask,
                  child: Text(strings.newTask),
                ),
              if (onNewHabit != null)
                PopupMenuItem(
                  key: const Key('today_new_habit'),
                  value: onNewHabit,
                  child: Text(strings.newHabit),
                ),
            ],
          ),
        IconButton(
          key: const Key('today_preferences'),
          tooltip: strings.preferences,
          onPressed: onPreferences,
          icon: const Icon(Icons.tune_rounded),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  String _greeting(FoundationLocalizations copy) {
    final hour = state.calendar.nowUtc
        .add(Duration(minutes: state.calendar.utcOffsetMinutes))
        .hour;
    return hour < 12
        ? copy.dashboardGreetingMorning
        : copy.dashboardGreetingLater;
  }

  String _monthName(FoundationLocalizations copy, int month) => switch (month) {
    1 => copy.dashboardHijriMuharram,
    2 => copy.dashboardHijriSafar,
    3 => copy.dashboardHijriRabiAlAwwal,
    4 => copy.dashboardHijriRabiAlThani,
    5 => copy.dashboardHijriJumadaAlAwwal,
    6 => copy.dashboardHijriJumadaAlThani,
    7 => copy.dashboardHijriRajab,
    8 => copy.dashboardHijriShaban,
    9 => copy.dashboardHijriRamadan,
    10 => copy.dashboardHijriShawwal,
    11 => copy.dashboardHijriDhuAlQidah,
    12 => copy.dashboardHijriDhuAlHijjah,
    _ => copy.dashboardHijriDateUnavailable,
  };
}

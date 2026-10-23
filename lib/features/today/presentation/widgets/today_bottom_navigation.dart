import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import 'today_prayer_card.dart';

const Key kTodayBottomNavigationKey = Key('today_bottom_navigation');
const Key kTodayBottomTasksKey = Key('today_bottom_tasks');
const Key kTodayBottomHabitsKey = Key('today_bottom_habits');
const Key kTodayBottomPrayerKey = Key('today_bottom_prayer');
const Key kTodayBottomMoreKey = Key('today_bottom_more');
const Key kTodayMoreMindMapsKey = Key('today_more_mind_maps');
const Key kTodayMorePreferencesKey = Key('today_more_preferences');

/// Compact navigation for phone and smaller tablet widths.
class TodayBottomNavigation extends StatelessWidget {
  const TodayBottomNavigation({
    super.key,
    required this.colors,
    required this.onTasks,
    required this.onHabits,
    required this.onMindMaps,
    required this.onPreferences,
  });

  final AppColors colors;
  final VoidCallback onTasks;
  final VoidCallback onHabits;
  final VoidCallback onMindMaps;
  final VoidCallback onPreferences;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: colors.navigationBackground,
        indicatorColor: colors.accentSoft,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      child: NavigationBar(
        key: kTodayBottomNavigationKey,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              onTasks();
            case 2:
              onHabits();
            case 3:
              _showPrayerPreview(context);
            case 4:
              _showMore(context);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny_rounded),
            label: copy.todayTitle,
          ),
          NavigationDestination(
            key: kTodayBottomTasksKey,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: copy.tasksTitle,
          ),
          NavigationDestination(
            key: kTodayBottomHabitsKey,
            icon: const Icon(Icons.autorenew_rounded),
            label: copy.habitsTitle,
          ),
          NavigationDestination(
            key: kTodayBottomPrayerKey,
            icon: const Icon(Icons.schedule_outlined),
            label: copy.dashboardPrayerShort,
          ),
          NavigationDestination(
            key: kTodayBottomMoreKey,
            icon: const Icon(Icons.grid_view_rounded),
            label: copy.dashboardMore,
          ),
        ],
      ),
    );
  }

  void _showPrayerPreview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
            ),
            child: SingleChildScrollView(
              child: TodayPrayerCard(colors: colors),
            ),
          ),
        ),
      ),
    );
  }

  void _showMore(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                copy.dashboardMore,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ListTile(
                key: kTodayMoreMindMapsKey,
                leading: const Icon(Icons.hub_outlined),
                title: Text(copy.mindMapsTitle),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onMindMaps();
                },
              ),
              ListTile(
                key: kTodayMorePreferencesKey,
                leading: const Icon(Icons.settings_outlined),
                title: Text(copy.todayPreferences),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onPreferences();
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
                child: Text(
                  copy.dashboardPreviewTitle,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.labelLarge?.copyWith(color: colors.textSecondary),
                ),
              ),
              _upcoming(copy.dashboardQuran, Icons.menu_book_rounded, copy),
              _upcoming(
                copy.dashboardAdhkarTitle,
                Icons.self_improvement_rounded,
                copy,
              ),
              _upcoming(copy.dashboardFocus, Icons.timer_outlined, copy),
              _upcoming(
                copy.dashboardFinance,
                Icons.account_balance_wallet_outlined,
                copy,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _upcoming(String title, IconData icon, FoundationLocalizations copy) =>
      ListTile(
        enabled: false,
        leading: Icon(icon, color: colors.textMuted),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Tooltip(
          message: copy.dashboardComingSoon,
          child: Icon(
            Icons.lock_clock_outlined,
            color: colors.textMuted,
            size: 18,
          ),
        ),
      );
}

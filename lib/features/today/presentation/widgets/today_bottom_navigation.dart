import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import 'today_coming_soon_page.dart';

const Key kTodayBottomNavigationKey = Key('today_bottom_navigation');
const Key kTodayBottomTasksKey = Key('today_bottom_tasks');
const Key kTodayBottomTrackKey = Key('today_bottom_track');
@Deprecated('Habits live under More in Dashboard 007.')
const Key kTodayBottomHabitsKey = kTodayBottomTrackKey;
const Key kTodayBottomFinanceKey = Key('today_bottom_finance');
const Key kTodayBottomMoreKey = Key('today_bottom_more');
const Key kTodayMoreHabitsKey = Key('today_more_habits');
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
              showTodayComingSoonPage(
                context,
                title: copy.dashboardTrack,
                icon: Icons.insights_outlined,
              );
            case 3:
              showTodayComingSoonPage(
                context,
                title: copy.dashboardFinance,
                icon: Icons.account_balance_wallet_outlined,
              );
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
            key: kTodayBottomTrackKey,
            icon: const Icon(Icons.insights_outlined),
            label: copy.dashboardTrack,
          ),
          NavigationDestination(
            key: kTodayBottomFinanceKey,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: copy.dashboardFinance,
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
                key: kTodayMoreHabitsKey,
                leading: const Icon(Icons.autorenew_rounded),
                title: Text(copy.habitsTitle),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onHabits();
                },
              ),
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

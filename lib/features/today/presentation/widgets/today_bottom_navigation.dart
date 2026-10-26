library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../dashboard_preview_data.dart';
import 'today_coming_soon_page.dart';

const Key kTodayBottomNavigationKey = Key('today_bottom_navigation');
const Key kTodayBottomTasksKey = Key('today_bottom_tasks');
const Key kTodayBottomTrackKey = Key('today_bottom_track');
const Key kTodayBottomPrayerKey =
    kTodayBottomTrackKey; // Alias for test compatibility
const Key kTodayBottomFinanceKey = Key('today_bottom_finance');
const Key kTodayBottomMoreKey = Key('today_bottom_more');
const Key kTodayBottomHabitsKey = Key('today_bottom_habits');
const Key kTodayMoreMindMapsKey = Key('today_more_mind_maps');
const Key kTodayMorePreferencesKey = Key('today_more_preferences');

/// Prototype-aligned bottom navigation bar presenting five primary destinations:
/// 1. Home, 2. Tasks, 3. Track, 4. Finance, 5. More.
/// Habits and Mind Maps are accessible inside the More sheet.
class TodayBottomNavigation extends StatelessWidget {
  const TodayBottomNavigation({
    super.key,
    required this.colors,
    required this.onTasks,
    required this.onHabits,
    required this.onMindMaps,
    required this.onPreferences,
    this.onHome,
    this.selectedIndex = 0,
    this.onPreview,
  });

  final AppColors colors;
  final VoidCallback onTasks;
  final VoidCallback onHabits;
  final VoidCallback onMindMaps;
  final VoidCallback onPreferences;
  final VoidCallback? onHome;
  final int selectedIndex;
  final void Function(BuildContext, String, DashboardPreviewFeature?)?
  onPreview;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);

    return SafeArea(
      top: false,
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 68,
          backgroundColor: colors.navigationBackground,
          indicatorColor: colors.primary.withValues(alpha: 0.16),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return colors.primary.withValues(alpha: 0.24);
            }
            if (states.contains(WidgetState.hovered)) {
              return colors.primary.withValues(alpha: 0.08);
            }
            return null;
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              size: 22,
              color: states.contains(WidgetState.selected)
                  ? colors.primary
                  : colors.textSecondary,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              color: isSelected ? colors.primary : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 11,
              letterSpacing: isSelected ? 0.2 : 0.0,
            );
          }),
        ),
        child: NavigationBar(
          key: kTodayBottomNavigationKey,
          selectedIndex: selectedIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                onHome?.call();
                break;
              case 1:
                onTasks();
                break;
              case 2:
                _showTrackPreview(context, copy);
                break;
              case 3:
                _showFinancePreview(context, copy);
                break;
              case 4:
                _showMore(context, copy);
                break;
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore_rounded),
              label: copy.dashboardHome,
              tooltip: copy.dashboardHome,
            ),
            NavigationDestination(
              key: kTodayBottomTasksKey,
              icon: const Icon(Icons.check_circle_outline_rounded),
              selectedIcon: const Icon(Icons.check_circle_rounded),
              label: copy.tasksTitle,
              tooltip: copy.tasksTitle,
            ),
            NavigationDestination(
              key: kTodayBottomTrackKey,
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights_rounded),
              label: copy.dashboardTrack,
              tooltip: copy.dashboardTrack,
            ),
            NavigationDestination(
              key: kTodayBottomFinanceKey,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
              label: copy.dashboardFinance,
              tooltip: copy.dashboardFinance,
            ),
            NavigationDestination(
              key: kTodayBottomMoreKey,
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view_rounded),
              label: copy.dashboardMore,
              tooltip: copy.dashboardMore,
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackPreview(BuildContext context, FoundationLocalizations copy) {
    if (onPreview != null) {
      onPreview!(
        context,
        copy.dashboardComingSoonTrackTitle,
        DashboardPreviewFeature.prayer,
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodayComingSoonPage(
          title: copy.dashboardComingSoonTrackTitle,
          feature: DashboardPreviewFeature.prayer,
          colors: colors,
        ),
      ),
    );
  }

  void _showFinancePreview(BuildContext context, FoundationLocalizations copy) {
    if (onPreview != null) {
      onPreview!(
        context,
        copy.dashboardComingSoonFinanceTitle,
        DashboardPreviewFeature.finance,
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodayComingSoonPage(
          title: copy.dashboardComingSoonFinanceTitle,
          feature: DashboardPreviewFeature.finance,
          colors: colors,
        ),
      ),
    );
  }

  void _showMore(BuildContext context, FoundationLocalizations copy) {
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
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),

              // Habits Owner Destination
              ListTile(
                key: kTodayBottomHabitsKey,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.autorenew_rounded, color: colors.primary),
                ),
                title: Text(
                  copy.habitsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onHabits();
                },
              ),

              // Mind Maps Owner Destination
              ListTile(
                key: kTodayMoreMindMapsKey,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.hub_outlined, color: colors.secondary),
                ),
                title: Text(
                  copy.mindMapsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onMindMaps();
                },
              ),

              // Preferences
              ListTile(
                key: kTodayMorePreferencesKey,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: colors.textPrimary,
                  ),
                ),
                title: Text(
                  copy.todayPreferences,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onPreferences();
                },
              ),

              const SizedBox(height: 8),
              Divider(color: colors.border),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
                child: Text(
                  copy.dashboardPreviewTitle,
                  style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _upcoming(copy.dashboardPrayer, Icons.schedule_rounded, copy),
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
              _upcoming(copy.dashboardCounters, Icons.repeat_rounded, copy),
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

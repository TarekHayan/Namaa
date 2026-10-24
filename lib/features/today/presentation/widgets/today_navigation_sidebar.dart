import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import 'today_coming_soon_page.dart';

const Key kTodaySidebarKey = Key('today_sidebar');
const Key kTodaySidebarTasksKey = Key('today_sidebar_tasks');
const Key kTodaySidebarTrackKey = Key('today_sidebar_track');
const Key kTodaySidebarFinanceKey = Key('today_sidebar_finance');
const Key kTodaySidebarMoreKey = Key('today_sidebar_more');
const Key kTodaySidebarHabitsKey = Key('today_sidebar_habits');
const Key kTodaySidebarMindMapsKey = Key('today_sidebar_mind_maps');
const Key kTodaySidebarPreferencesKey = Key('today_sidebar_preferences');

/// Navigation for the Today dashboard. Unfinished destinations are visible but
/// disabled, so a preview never pretends to open a working feature.
class TodayNavigationSidebar extends StatelessWidget {
  const TodayNavigationSidebar({
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
    return Material(
      key: kTodaySidebarKey,
      color: colors.navigationBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/namaa_icon.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.appTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          copy.dashboardSidebarTagline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                children: [
                  _item(
                    context,
                    icon: Icons.home_outlined,
                    label: copy.dashboardHome,
                    selected: true,
                  ),
                  const SizedBox(height: 4),
                  _item(
                    context,
                    key: kTodaySidebarTasksKey,
                    icon: Icons.check_circle_outline_rounded,
                    label: copy.tasksTitle,
                    onTap: onTasks,
                  ),
                  _item(
                    context,
                    key: kTodaySidebarTrackKey,
                    icon: Icons.insights_outlined,
                    label: copy.dashboardTrack,
                    onTap: () => _showComingSoon(
                      context,
                      copy.dashboardTrack,
                      Icons.insights_outlined,
                    ),
                  ),
                  _item(
                    context,
                    key: kTodaySidebarFinanceKey,
                    icon: Icons.account_balance_wallet_outlined,
                    label: copy.dashboardFinance,
                    onTap: () => _showComingSoon(
                      context,
                      copy.dashboardFinance,
                      Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      20,
                      12,
                      8,
                    ),
                    child: Text(
                      copy.dashboardMore,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _item(
                    context,
                    key: kTodaySidebarMoreKey,
                    icon: Icons.grid_view_rounded,
                    label: copy.dashboardMore,
                    onTap: () => _showMore(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _item(
                    context,
                    key: kTodaySidebarPreferencesKey,
                    icon: Icons.settings_outlined,
                    label: copy.todayPreferences,
                    onTap: onPreferences,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title, IconData icon) {
    showTodayComingSoonPage(context, title: title, icon: icon);
  }

  void _showMore(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              key: kTodaySidebarHabitsKey,
              leading: const Icon(Icons.autorenew_rounded),
              title: Text(copy.habitsTitle),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onHabits();
              },
            ),
            ListTile(
              key: kTodaySidebarMindMapsKey,
              leading: const Icon(Icons.hub_outlined),
              title: Text(copy.mindMapsTitle),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onMindMaps();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool selected = false,
    bool comingSoon = false,
  }) {
    final foreground = selected
        ? Colors.white
        : comingSoon
        ? colors.textMuted
        : colors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        key: key,
        minTileHeight: 48,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: selected ? colors.secondary : null,
        leading: Icon(icon, size: 21, color: foreground),
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: foreground,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: comingSoon
            ? Tooltip(
                message: FoundationLocalizations.of(
                  context,
                ).dashboardComingSoon,
                child: Icon(
                  Icons.lock_clock_outlined,
                  size: 17,
                  color: colors.textMuted,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

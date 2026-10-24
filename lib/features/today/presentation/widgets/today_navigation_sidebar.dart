import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';

const Key kTodaySidebarKey = Key('today_sidebar');
const Key kTodaySidebarTasksKey = Key('today_sidebar_tasks');
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
    this.xpAmount,
  });

  final AppColors colors;
  final VoidCallback onTasks;
  final VoidCallback onHabits;
  final VoidCallback onMindMaps;
  final VoidCallback onPreferences;
  final int? xpAmount;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final level = xpAmount == null ? null : (xpAmount! ~/ 200) + 1;

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
                    icon: Icons.dashboard_rounded,
                    label: copy.todayTitle,
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
                    key: kTodaySidebarHabitsKey,
                    icon: Icons.autorenew_rounded,
                    label: copy.habitsTitle,
                    onTap: onHabits,
                  ),
                  _item(
                    context,
                    key: kTodaySidebarMindMapsKey,
                    icon: Icons.hub_outlined,
                    label: copy.mindMapsTitle,
                    onTap: onMindMaps,
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      20,
                      12,
                      8,
                    ),
                    child: Text(
                      copy.dashboardPreviewTitle,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _item(
                    context,
                    icon: Icons.schedule_rounded,
                    label: copy.dashboardPrayer,
                    comingSoon: true,
                  ),
                  _item(
                    context,
                    icon: Icons.menu_book_rounded,
                    label: copy.dashboardQuran,
                    comingSoon: true,
                  ),
                  _item(
                    context,
                    icon: Icons.self_improvement_rounded,
                    label: copy.dashboardAdhkarTitle,
                    comingSoon: true,
                  ),
                  _item(
                    context,
                    icon: Icons.timer_outlined,
                    label: copy.dashboardFocus,
                    comingSoon: true,
                  ),
                  _item(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    label: copy.dashboardFinance,
                    comingSoon: true,
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
                  if (level != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        copy.dashboardLevelBadge(level, xpAmount!),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
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

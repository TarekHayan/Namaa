library;

import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_hover_surface.dart';

import '../dashboard_preview_data.dart';
import 'today_coming_soon_page.dart';

const Key kTodaySidebarKey = Key('today_sidebar');
const Key kTodaySidebarTasksKey = Key('today_sidebar_tasks');
const Key kTodaySidebarTrackKey = Key('today_sidebar_track');
const Key kTodaySidebarFinanceKey = Key('today_sidebar_finance');
const Key kTodaySidebarHabitsKey = Key('today_sidebar_habits');
const Key kTodaySidebarMindMapsKey = Key('today_sidebar_mind_maps');
const Key kTodaySidebarPrayerKey = Key('today_sidebar_prayer');
const Key kTodaySidebarQuranKey = Key('today_sidebar_quran');
const Key kTodaySidebarFocusKey = Key('today_sidebar_focus');
const Key kTodaySidebarAdhkarKey = Key('today_sidebar_adhkar');
const Key kTodaySidebarQiyamKey = Key('today_sidebar_qiyam');
const Key kTodaySidebarCountersKey = Key('today_sidebar_counters');
const Key kTodaySidebarPreferencesKey = Key('today_sidebar_preferences');
const double kTodaySidebarWidth = 252;
const double kTodaySidebarBreakpoint = 1100;

enum TodayNavigationSection { home, tasks, habits, mindMaps, preview }

/// Wide-screen navigation shows each destination directly. The five-tab More
/// hub remains a phone-only space saver.
class TodayNavigationSidebar extends StatelessWidget {
  const TodayNavigationSidebar({
    super.key,
    required this.colors,
    required this.onTasks,
    required this.onHabits,
    required this.onMindMaps,
    required this.onPreferences,
    this.onHome,
    this.section = TodayNavigationSection.home,
    this.onPreview,
    this.xpAmount,
  });

  final AppColors colors;
  final VoidCallback onTasks;
  final VoidCallback onHabits;
  final VoidCallback onMindMaps;
  final VoidCallback onPreferences;
  final VoidCallback? onHome;
  final TodayNavigationSection section;
  final void Function(BuildContext, String, DashboardPreviewFeature?)?
  onPreview;
  final int? xpAmount;

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
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
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
                  // 1. Home
                  _item(
                    context,
                    icon: Icons.explore_rounded,
                    label: copy.dashboardHome,
                    selected: section == TodayNavigationSection.home,
                    onTap: onHome,
                  ),
                  const SizedBox(height: 4),

                  // 2. Tasks
                  _item(
                    context,
                    key: kTodaySidebarTasksKey,
                    icon: Icons.check_circle_outline_rounded,
                    label: copy.tasksTitle,
                    onTap: onTasks,
                    selected: section == TodayNavigationSection.tasks,
                  ),

                  _item(
                    context,
                    key: kTodaySidebarHabitsKey,
                    icon: Icons.autorenew_rounded,
                    label: copy.habitsTitle,
                    onTap: onHabits,
                    selected: section == TodayNavigationSection.habits,
                  ),
                  _item(
                    context,
                    key: kTodaySidebarMindMapsKey,
                    icon: Icons.hub_outlined,
                    label: copy.mindMapsTitle,
                    onTap: onMindMaps,
                    selected: section == TodayNavigationSection.mindMaps,
                  ),

                  // 3. Track
                  _item(
                    context,
                    key: kTodaySidebarTrackKey,
                    icon: Icons.insights_rounded,
                    label: copy.dashboardTrack,
                    onTap: () => _openPreview(
                      context,
                      copy.dashboardComingSoonTrackTitle,
                    ),
                    comingSoon: true,
                  ),

                  // 4. Finance
                  _item(
                    context,
                    key: kTodaySidebarFinanceKey,
                    icon: Icons.account_balance_wallet_outlined,
                    label: copy.dashboardFinance,
                    onTap: () => _openPreview(
                      context,
                      copy.dashboardComingSoonFinanceTitle,
                      DashboardPreviewFeature.finance,
                    ),
                    comingSoon: true,
                  ),
                  _item(
                    context,
                    key: kTodaySidebarPrayerKey,
                    icon: Icons.schedule_rounded,
                    label: copy.dashboardComingSoonPrayerTitle,
                    onTap: () => _openPreview(
                      context,
                      copy.dashboardComingSoonPrayerTitle,
                      DashboardPreviewFeature.prayer,
                    ),
                    comingSoon: true,
                  ),
                  _item(
                    context,
                    key: kTodaySidebarQuranKey,
                    icon: Icons.menu_book_rounded,
                    label: copy.dashboardComingSoonQuranTitle,
                    onTap: () => _openPreview(
                      context,
                      copy.dashboardComingSoonQuranTitle,
                      DashboardPreviewFeature.quran,
                    ),
                    comingSoon: true,
                  ),
                  _item(
                    context,
                    key: kTodaySidebarFocusKey,
                    icon: Icons.timer_outlined,
                    label: copy.dashboardComingSoonFocusTitle,
                    onTap: () => _openPreview(
                      context,
                      copy.dashboardComingSoonFocusTitle,
                      DashboardPreviewFeature.focus,
                    ),
                    comingSoon: true,
                  ),
                  _item(
                    context,
                    key: kTodaySidebarAdhkarKey,
                    icon: Icons.wb_sunny_outlined,
                    label: copy.dashboardComingSoonAdhkarTitle,
                    onTap: () => _openPreview(
                      context,
                      copy.dashboardComingSoonAdhkarTitle,
                      DashboardPreviewFeature.adhkar,
                    ),
                    comingSoon: true,
                  ),
                  _item(
                    context,
                    key: kTodaySidebarQiyamKey,
                    icon: Icons.nightlight_round,
                    label: copy.dashboardComingSoonQiyamTitle,
                    onTap: () => _openPreview(
                      context,
                      copy.dashboardComingSoonQiyamTitle,
                      DashboardPreviewFeature.qiyam,
                    ),
                    comingSoon: true,
                  ),
                  _item(
                    context,
                    key: kTodaySidebarCountersKey,
                    icon: Icons.repeat_rounded,
                    label: copy.dashboardComingSoonCountersTitle,
                    onTap: () => _openPreview(
                      context,
                      copy.dashboardComingSoonCountersTitle,
                      DashboardPreviewFeature.counters,
                    ),
                    comingSoon: true,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            if (xpAmount != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Text(
                  '$xpAmount XP',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
              child: _item(
                context,
                key: kTodaySidebarPreferencesKey,
                icon: Icons.settings_outlined,
                label: copy.todayPreferences,
                onTap: onPreferences,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPreview(
    BuildContext context,
    String title, [
    DashboardPreviewFeature? feature,
  ]) {
    if (onPreview != null) {
      onPreview!(context, title, feature);
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            TodayComingSoonPage(title: title, feature: feature, colors: colors),
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
      child: AppHoverSurface(
        radius: 12,
        enabled: !selected && onTap != null,
        clickable: onTap != null,
        child: ListTile(
          key: key,
          minTileHeight: 48,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: selected ? colors.secondary : null,
          hoverColor: selected ? colors.secondary : colors.accentSoft,
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
      ),
    );
  }
}

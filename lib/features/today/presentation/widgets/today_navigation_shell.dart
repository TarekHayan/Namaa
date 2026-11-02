import 'package:flutter/material.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/features/prayer/presentation/prayer_track_hub.dart';

import '../dashboard_preview_data.dart';
import 'today_bottom_navigation.dart';
import 'today_coming_soon_page.dart';
import 'today_navigation_sidebar.dart';

/// Keeps the same navigation visible while moving between product sections.
/// The content area follows the prototype's 1024px maximum width separately.
class TodayNavigationShell extends StatelessWidget {
  const TodayNavigationShell({
    super.key,
    required this.colors,
    required this.section,
    required this.onTasks,
    required this.onHabits,
    required this.onMindMaps,
    this.onPrayer,
    required this.onPreferences,
    required this.child,
    this.onHome,
    this.xpAmount,
  });

  final AppColors colors;
  final TodayNavigationSection section;
  final VoidCallback onTasks;
  final VoidCallback onHabits;
  final VoidCallback onMindMaps;
  final VoidCallback? onPrayer;
  final VoidCallback onPreferences;
  final VoidCallback? onHome;
  final int? xpAmount;
  final Widget child;

  /// Opens a preview inside the surrounding navigation frame when available.
  static void openPreview(
    BuildContext context, {
    required String title,
    required AppColors colors,
    DashboardPreviewFeature? feature,
  }) {
    final actions = context
        .dependOnInheritedWidgetOfExactType<_TodayNavigationActions>();
    if (actions != null) {
      actions.openPreview(context, title, feature);
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            TodayComingSoonPage(title: title, feature: feature, colors: colors),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= kTodaySidebarBreakpoint;
      void goHome() {
        if (onHome != null) {
          onHome!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }

      void openPreview(
        BuildContext source,
        String title,
        DashboardPreviewFeature? feature,
      ) {
        Navigator.of(source).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => TodayNavigationShell(
              colors: colors,
              section: TodayNavigationSection.preview,
              onHome: goHome,
              onTasks: onTasks,
              onHabits: onHabits,
              onMindMaps: onMindMaps,
              onPrayer: onPrayer,
              onPreferences: onPreferences,
              xpAmount: xpAmount,
              child: TodayComingSoonPage(
                title: title,
                feature: feature,
                colors: colors,
              ),
            ),
          ),
        );
      }

      void openTrack() {
        if (onPrayer == null || section == TodayNavigationSection.track) return;
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (trackContext) => TodayNavigationShell(
              colors: colors,
              section: TodayNavigationSection.track,
              onHome: goHome,
              onTasks: onTasks,
              onHabits: onHabits,
              onMindMaps: onMindMaps,
              onPrayer: onPrayer,
              onPreferences: onPreferences,
              xpAmount: xpAmount,
              child: PrayerTrackHub(
                onPrayer: () {
                  Navigator.of(trackContext).pop();
                  onPrayer!();
                },
              ),
            ),
          ),
        );
      }

      if (wide) {
        return _TodayNavigationActions(
          openPreview: openPreview,
          child: Row(
            children: [
              SizedBox(
                width: kTodaySidebarWidth,
                child: TodayNavigationSidebar(
                  colors: colors,
                  section: section,
                  onHome: goHome,
                  onTasks: onTasks,
                  onHabits: onHabits,
                  onMindMaps: onMindMaps,
                  onPrayer: onPrayer,
                  onTrack: onPrayer == null ? null : openTrack,
                  onPreferences: onPreferences,
                  onPreview: openPreview,
                  xpAmount: xpAmount,
                ),
              ),
              Expanded(child: child),
            ],
          ),
        );
      }

      return _TodayNavigationActions(
        openPreview: openPreview,
        child: Scaffold(
          backgroundColor: colors.background,
          body: child,
          bottomNavigationBar: TodayBottomNavigation(
            colors: colors,
            selectedIndex: switch (section) {
              TodayNavigationSection.home => 0,
              TodayNavigationSection.tasks => 1,
              TodayNavigationSection.prayer ||
              TodayNavigationSection.track => 2,
              TodayNavigationSection.habits ||
              TodayNavigationSection.mindMaps ||
              TodayNavigationSection.preview => 4,
            },
            onHome: goHome,
            onTasks: onTasks,
            onHabits: onHabits,
            onMindMaps: onMindMaps,
            onPrayer: onPrayer,
            onTrack: onPrayer == null ? null : openTrack,
            onPreferences: onPreferences,
            onPreview: openPreview,
          ),
        ),
      );
    },
  );
}

class _TodayNavigationActions extends InheritedWidget {
  const _TodayNavigationActions({
    required this.openPreview,
    required super.child,
  });

  final void Function(BuildContext, String, DashboardPreviewFeature?)
  openPreview;

  @override
  bool updateShouldNotify(_TodayNavigationActions oldWidget) =>
      openPreview != oldWidget.openPreview;
}

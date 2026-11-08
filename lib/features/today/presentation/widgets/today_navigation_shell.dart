import 'package:flutter/material.dart';
import 'package:namma_project/app/theme/app_colors.dart';

import '../dashboard_preview_data.dart';
import 'prayer_track_hub.dart';
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

      // Sections behave as tabs, never as a stack. Track, Finance and the
      // coming-soon previews open as a single page over the current section;
      // a second one replaces the first, and leaving to any destination
      // closes it first. No back arrow is shown anywhere.
      final overlay =
          section == TodayNavigationSection.track ||
          section == TodayNavigationSection.finance ||
          section == TodayNavigationSection.preview;
      VoidCallback leave(VoidCallback action) => overlay
          ? () {
              Navigator.of(context).pop();
              action();
            }
          : action;
      final home = leave(goHome);
      final tasks = leave(onTasks);
      final habits = leave(onHabits);
      final mindMaps = leave(onMindMaps);
      final prayer = onPrayer == null ? null : leave(onPrayer!);

      void open(BuildContext source, Route<void> route) {
        final navigator = Navigator.of(source);
        if (overlay) {
          navigator.pushReplacement<void, void>(route);
        } else {
          navigator.push<void>(route);
        }
      }

      // Overlays receive the original destination callbacks; each overlay
      // wraps them with its own "close first" step when it builds.
      TodayNavigationShell overlayShell(
        TodayNavigationSection target,
        Widget child,
      ) => TodayNavigationShell(
        colors: colors,
        section: target,
        onHome: goHome,
        onTasks: onTasks,
        onHabits: onHabits,
        onMindMaps: onMindMaps,
        onPrayer: onPrayer,
        onPreferences: onPreferences,
        xpAmount: xpAmount,
        child: child,
      );

      void openPreview(
        BuildContext source,
        String title,
        DashboardPreviewFeature? feature,
      ) {
        final target = feature == DashboardPreviewFeature.finance
            ? TodayNavigationSection.finance
            : TodayNavigationSection.preview;
        // Re-tapping the open Finance tab does nothing.
        if (target == TodayNavigationSection.finance && section == target) {
          return;
        }
        open(
          source,
          MaterialPageRoute<void>(
            builder: (_) => overlayShell(
              target,
              TodayComingSoonPage(
                title: title,
                feature: feature,
                colors: colors,
                showBack: false,
              ),
            ),
          ),
        );
      }

      void openTrack() {
        if (onPrayer == null || section == TodayNavigationSection.track) return;
        open(
          context,
          MaterialPageRoute<void>(
            builder: (trackContext) => overlayShell(
              TodayNavigationSection.track,
              PrayerTrackHub(
                onPrayer: () {
                  Navigator.of(trackContext).pop();
                  onPrayer!();
                },
              ),
            ),
          ),
        );
      }

      final Widget frame;
      if (wide) {
        frame = Row(
          children: [
            SizedBox(
              width: kTodaySidebarWidth,
              child: TodayNavigationSidebar(
                colors: colors,
                section: section,
                onHome: home,
                onTasks: tasks,
                onHabits: habits,
                onMindMaps: mindMaps,
                onPrayer: prayer,
                onTrack: onPrayer == null ? null : openTrack,
                onPreferences: onPreferences,
                onPreview: openPreview,
                xpAmount: xpAmount,
              ),
            ),
            Expanded(child: child),
          ],
        );
      } else {
        frame = Scaffold(
          backgroundColor: colors.background,
          body: child,
          bottomNavigationBar: TodayBottomNavigation(
            colors: colors,
            selectedIndex: switch (section) {
              TodayNavigationSection.home => 0,
              TodayNavigationSection.tasks => 1,
              TodayNavigationSection.prayer ||
              TodayNavigationSection.track => 2,
              TodayNavigationSection.finance => 3,
              TodayNavigationSection.habits ||
              TodayNavigationSection.mindMaps ||
              TodayNavigationSection.preview => 4,
            },
            onHome: home,
            onTasks: tasks,
            onHabits: habits,
            onMindMaps: mindMaps,
            onPrayer: prayer,
            onTrack: onPrayer == null ? null : openTrack,
            onPreferences: onPreferences,
            onPreview: openPreview,
          ),
        );
      }

      return _TodayNavigationActions(
        openPreview: openPreview,
        // The device back button never walks through visited sections: from
        // any section it returns to Home, and from Home it leaves the app.
        child: section == TodayNavigationSection.home
            ? frame
            : PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) home();
                },
                child: frame,
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

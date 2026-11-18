import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_typography.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_card.dart';
import 'package:namma_project/app/widgets/app_icon_badge.dart';
import 'package:namma_project/app/widgets/app_notice.dart';
import 'package:namma_project/app/widgets/app_progress_ring.dart';
import 'package:namma_project/app/widgets/app_segmented_control.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import '../adhkar_state.dart';

/// The page title, the subtitle and the three tabs (Morning, Evening, My
/// Adhkar) of the approved design. The title, subtitle and tabs stay put
/// whichever tab is open; only the content below them changes.
final class AdhkarTitleBlock extends StatelessWidget {
  const AdhkarTitleBlock({
    super.key,
    required this.copy,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final AdhkarStrings copy;
  final AdhkarTab selectedTab;
  final ValueChanged<AdhkarTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      key: const Key('adhkar_header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          copy.title,
          style: AppTypography.fixed(
            28,
            FontWeight.w800,
            colors.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          copy.subtitle,
          style: AppTypography.fixed(
            14,
            FontWeight.w400,
            colors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        AppSegmentedControl(
          selectedIndex: selectedTab.index,
          onChanged: (index) => onTabChanged(AdhkarTab.values[index]),
          segments: [
            AppSegment(
              key: const Key('adhkar_switch_morning'),
              label: copy.tabLabel(true),
            ),
            AppSegment(
              key: const Key('adhkar_switch_evening'),
              label: copy.tabLabel(false),
            ),
            AppSegment(
              key: const Key('adhkar_switch_my_adhkar'),
              label: copy.myAdhkarTab,
            ),
          ],
        ),
      ],
    );
  }
}

/// The content of the Morning and Evening tabs: the progress card with its
/// ring (or the finished card), the time-window line, the setup notice, the
/// streak row, the main button, and the sync differences row.
final class AdhkarListPage extends StatelessWidget {
  const AdhkarListPage({
    super.key,
    required this.copy,
    required this.locale,
    required this.state,
    required this.morning,
    required this.onOpenReader,
    this.onOpenPrayerSetup,
    this.syncRow,
  });

  final AdhkarStrings copy;
  final String locale;
  final AdhkarState state;
  final bool morning;

  /// Opens the reader on the item at the given index of this list.
  final ValueChanged<int> onOpenReader;
  final VoidCallback? onOpenPrayerSetup;

  /// The compact "Sync differences" row, composed by the route; null (or one
  /// that renders nothing) when there is nothing to show.
  final Widget? syncRow;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final list = morning ? AdhkarList.morning : AdhkarList.evening;
    final items = state.catalog?.itemsOf(list) ?? const <DhikrItem>[];
    final clock = state.clock;
    final total = state.totalOf(list);
    final completed = state.completedOf(list);
    final finished = total > 0 && completed == total;
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();
    final firstUndone = items.indexWhere(
      (item) => state.countOf(item.itemId) < item.target,
    );
    final started = items.any((item) => state.countOf(item.itemId) > 0);
    final listLabel = copy.listLabel(morning);
    final countable = morning
        ? (clock?.morningCountable ?? false)
        : (clock?.eveningCountable ?? false);
    final scheduleState = clock?.scheduleState;

    final String mainLabel;
    final int mainIndex;
    if (finished) {
      mainLabel = copy.readAgain;
      mainIndex = 0;
    } else if (!started || firstUndone < 0) {
      mainLabel = copy.start;
      mainIndex = firstUndone < 0 ? 0 : firstUndone;
    } else {
      mainLabel = copy.continueFrom(items[firstUndone].position);
      mainIndex = firstUndone;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (finished)
          _FinishedCard(
            copy: copy,
            listLabel: listLabel,
            completed: completed,
            total: total,
          )
        else
          _ProgressCard(
            copy: copy,
            listLabel: listLabel,
            completed: completed,
            total: total,
            percent: percent,
          ),
        const SizedBox(height: 16),
        if (scheduleState == AdhkarScheduleState.available) ...[
          _TimeLine(
            copy: copy,
            locale: locale,
            startsAtUtc: countable
                ? (morning ? clock!.fajrUtc : clock!.maghribUtc)
                : clock!.nextBoundaryUtc,
            zoneId: clock.zoneId,
          ),
          const SizedBox(height: 16),
        ] else if (scheduleState != null) ...[
          _SetupNotice(
            copy: copy,
            locked: scheduleState == AdhkarScheduleState.unavailable,
            onOpenPrayerSetup: onOpenPrayerSetup,
          ),
          const SizedBox(height: 16),
        ],
        _StreakRow(copy: copy, streak: state.streak),
        const SizedBox(height: 16),
        const Spacer(),
        _MainButton(
          label: mainLabel,
          secondary: finished,
          onTap: items.isEmpty ? null : () => onOpenReader(mainIndex),
        ),
        // The row carries its own top gap, so nothing shows when it is empty.
        ?syncRow,
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              copy.quranAttribution,
              key: const Key('adhkar_attribution'),
              textAlign: TextAlign.center,
              style: AppTypography.fixed(
                12,
                FontWeight.w400,
                colors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
      ],
    );
  }
}

final class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.copy,
    required this.listLabel,
    required this.completed,
    required this.total,
    required this.percent,
  });

  final AdhkarStrings copy;
  final String listLabel;
  final int completed;
  final int total;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      key: const Key('adhkar_progress_card'),
      radius: 28,
      padding: const EdgeInsets.all(20),
      elevated: true,
      child: Row(
        children: [
          Semantics(
            label: copy.percent(percent),
            excludeSemantics: true,
            child: SizedBox(
              width: 96,
              height: 96,
              child: AppProgressRing(
                progress: total == 0 ? 0 : completed / total,
                strokeWidth: 8,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        copy.percent(percent),
                        key: const Key('adhkar_progress_percent'),
                        textScaler: TextScaler.noScaling,
                        style: AppTypography.fixed(
                          24,
                          FontWeight.w800,
                          colors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.progress(listLabel, completed, total),
                  style: AppTypography.fixed(
                    17,
                    FontWeight.w700,
                    colors.textPrimary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy.doneCount(completed),
                  style: AppTypography.fixed(
                    14,
                    FontWeight.w400,
                    colors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _FinishedCard extends StatelessWidget {
  const _FinishedCard({
    required this.copy,
    required this.listLabel,
    required this.completed,
    required this.total,
  });

  final AdhkarStrings copy;
  final String listLabel;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      key: const Key('adhkar_finished_card'),
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          AppIconBadge(
            icon: Icons.check_rounded,
            size: 72,
            iconSize: 36,
            borderColor: colors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            copy.completeTitle,
            textAlign: TextAlign.center,
            style: AppTypography.fixed(
              20,
              FontWeight.w800,
              colors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            copy.progress(listLabel, completed, total),
            textAlign: TextAlign.center,
            style: AppTypography.fixed(
              14,
              FontWeight.w400,
              colors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// The time-window line: when this list's time starts (or starts next).
final class _TimeLine extends StatelessWidget {
  const _TimeLine({
    required this.copy,
    required this.locale,
    required this.startsAtUtc,
    required this.zoneId,
  });

  final AdhkarStrings copy;
  final String locale;
  final DateTime? startsAtUtc;
  final String? zoneId;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final at = startsAtUtc;
    if (at == null || zoneId == null) return const SizedBox.shrink();
    return AppCard(
      key: const Key('adhkar_starts_at_notice'),
      radius: 20,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 22, color: colors.accentStrong),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              copy.startsAt(formatAdhkarTime(at, zoneId!, locale)),
              style: AppTypography.fixed(
                16,
                FontWeight.w600,
                colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats an instant in the location's zone (HH:mm). Composition initializes
/// the IANA database at startup; this helper loads it itself when rendered
/// without composition (widget tests), like the Prayer adapter does.
String formatAdhkarTime(DateTime instantUtc, String zoneId, String locale) {
  if (tz.timeZoneDatabase.locations.isEmpty) {
    timezone_data.initializeTimeZones();
  }
  try {
    final cityTime = tz.TZDateTime.from(instantUtc, tz.getLocation(zoneId));
    return DateFormat.Hm(locale).format(cityTime);
  } catch (_) {
    return DateFormat.Hm(locale).format(instantUtc.toUtc());
  }
}

/// The setup notice: no saved Prayer location (counting stays unrestricted),
/// or a saved one that cannot produce its times (counting is paused). Both
/// offer the existing Prayer location setup.
final class _SetupNotice extends StatelessWidget {
  const _SetupNotice({
    required this.copy,
    required this.locked,
    required this.onOpenPrayerSetup,
  });

  final AdhkarStrings copy;
  final bool locked;
  final VoidCallback? onOpenPrayerSetup;

  @override
  Widget build(BuildContext context) => AppBanner(
    key: const Key('adhkar_setup_notice'),
    message: locked ? copy.countingLocked : copy.setupPrompt,
    messageKey: locked ? const Key('adhkar_locked_notice') : null,
    icon: Icons.location_on_outlined,
    actionLabel: onOpenPrayerSetup == null ? null : copy.openPrayerSetup,
    onAction: onOpenPrayerSetup,
    actionKey: const Key('adhkar_setup_button'),
  );
}

final class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.copy, required this.streak});

  final AdhkarStrings copy;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      key: const Key('adhkar_streak_row'),
      radius: 22,
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const AppIconBadge(
            icon: Icons.local_fire_department_outlined,
            size: 44,
            iconSize: 24,
            tone: AppBadgeTone.warning,
            bordered: false,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              copy.streak(streak),
              style: AppTypography.fixed(
                16,
                FontWeight.w700,
                colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The main button: start, continue from an item, or (finished, secondary
/// style) read the list again.
final class _MainButton extends StatelessWidget {
  const _MainButton({
    required this.label,
    required this.secondary,
    required this.onTap,
  });

  final String label;
  final bool secondary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppButton(
    key: const Key('adhkar_main_button'),
    label: label,
    onPressed: onTap,
    look: AppButtonLook.refined,
    variant: secondary ? AppButtonVariant.secondary : AppButtonVariant.primary,
    size: AppButtonSize.large,
    trailingIcon: Icons.arrow_forward,
    expanded: true,
    fill: secondary ? AppColors.of(context).surface : null,
    tuning: const AppButtonTuning(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      fontWeight: FontWeight.w700,
      labelHeight: 1.4,
    ),
  );
}

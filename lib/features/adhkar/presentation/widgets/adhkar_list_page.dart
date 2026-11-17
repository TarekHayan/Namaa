import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import '../adhkar_state.dart';
import 'adhkar_style.dart';

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
    final palette = AdhkarPalette.of(context);
    return Column(
      key: const Key('adhkar_header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          copy.title,
          style: adhkarText(28, FontWeight.w800, palette.text, height: 1.4),
        ),
        const SizedBox(height: 4),
        Text(
          copy.subtitle,
          style: adhkarText(14, FontWeight.w400, palette.text2, height: 1.6),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: palette.card(radius: 20, color: palette.surface2),
          child: Row(
            children: [
              _Tab(
                key: const Key('adhkar_switch_morning'),
                label: copy.tabLabel(true),
                selected: selectedTab == AdhkarTab.morning,
                onTap: () => onTabChanged(AdhkarTab.morning),
              ),
              const SizedBox(width: 4),
              _Tab(
                key: const Key('adhkar_switch_evening'),
                label: copy.tabLabel(false),
                selected: selectedTab == AdhkarTab.evening,
                onTap: () => onTabChanged(AdhkarTab.evening),
              ),
              const SizedBox(width: 4),
              _Tab(
                key: const Key('adhkar_switch_my_adhkar'),
                label: copy.myAdhkarTab,
                selected: selectedTab == AdhkarTab.myAdhkar,
                onTap: () => onTabChanged(AdhkarTab.myAdhkar),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        excludeSemantics: true,
        label: label,
        onTap: onTap,
        child: Material(
          color: selected ? palette.surface : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? palette.primary : Colors.transparent,
            ),
          ),
          shadowColor: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: adhkarText(
                      15,
                      selected ? FontWeight.w700 : FontWeight.w600,
                      selected ? palette.accent : palette.text2,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
    final palette = AdhkarPalette.of(context);
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
              style: adhkarText(
                12,
                FontWeight.w400,
                palette.text2,
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
    final palette = AdhkarPalette.of(context);
    return Container(
      key: const Key('adhkar_progress_card'),
      padding: const EdgeInsets.all(20),
      decoration: palette.card(radius: 28, shadows: palette.glow),
      child: Row(
        children: [
          Semantics(
            label: copy.percent(percent),
            excludeSemantics: true,
            child: SizedBox(
              width: 96,
              height: 96,
              child: CustomPaint(
                painter: AdhkarRingPainter(
                  progress: total == 0 ? 0 : completed / total,
                  strokeWidth: 8,
                  fill: palette.primary,
                  track: palette.track,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        copy.percent(percent),
                        key: const Key('adhkar_progress_percent'),
                        textScaler: TextScaler.noScaling,
                        style: adhkarText(
                          24,
                          FontWeight.w800,
                          palette.text,
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
                  style: adhkarText(
                    17,
                    FontWeight.w700,
                    palette.text,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy.doneCount(completed),
                  style: adhkarText(
                    14,
                    FontWeight.w400,
                    palette.text2,
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
    final palette = AdhkarPalette.of(context);
    return Container(
      key: const Key('adhkar_finished_card'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: palette.card(radius: 28),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.soft,
              border: Border.all(color: palette.primary),
            ),
            child: Icon(Icons.check_rounded, size: 36, color: palette.accent),
          ),
          const SizedBox(height: 12),
          Text(
            copy.completeTitle,
            textAlign: TextAlign.center,
            style: adhkarText(20, FontWeight.w800, palette.text, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            copy.progress(listLabel, completed, total),
            textAlign: TextAlign.center,
            style: adhkarText(14, FontWeight.w400, palette.text2, height: 1.6),
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
    final palette = AdhkarPalette.of(context);
    final at = startsAtUtc;
    if (at == null || zoneId == null) return const SizedBox.shrink();
    return Container(
      key: const Key('adhkar_starts_at_notice'),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: palette.card(radius: 20),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 22, color: palette.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              copy.startsAt(formatAdhkarTime(at, zoneId!, locale)),
              style: adhkarText(16, FontWeight.w600, palette.text),
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
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Container(
      key: const Key('adhkar_setup_notice'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: palette.card(
        radius: 20,
        color: palette.warnSoft,
        borderColor: palette.warn,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 24,
                  color: palette.warn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  locked ? copy.countingLocked : copy.setupPrompt,
                  key: locked ? const Key('adhkar_locked_notice') : null,
                  style: adhkarText(
                    16,
                    FontWeight.w600,
                    palette.text,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          if (onOpenPrayerSetup != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AdhkarOutlinedAction(
                key: const Key('adhkar_setup_button'),
                label: copy.openPrayerSetup,
                borderColor: palette.warn,
                onTap: onOpenPrayerSetup!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A 48 px outlined action on a tinted banner (the setup button).
final class AdhkarOutlinedAction extends StatelessWidget {
  const AdhkarOutlinedAction({
    super.key,
    required this.label,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: adhkarText(16, FontWeight.w700, palette.text),
            ),
          ),
        ),
      ),
    );
  }
}

final class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.copy, required this.streak});

  final AdhkarStrings copy;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Container(
      key: const Key('adhkar_streak_row'),
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: palette.card(radius: 22),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.warnSoft,
            ),
            child: Icon(
              Icons.local_fire_department_outlined,
              size: 24,
              color: palette.warn,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              copy.streak(streak),
              style: adhkarText(16, FontWeight.w700, palette.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// The main button: «ابدأ», «متابعة من الذكر n», or (finished, secondary
/// style) «قراءة القائمة مرة أخرى».
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
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    final foreground = secondary ? palette.text : palette.onButton;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: secondary ? null : palette.buttonGlow,
      ),
      child: Material(
        color: secondary ? palette.surface : palette.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: secondary ? BorderSide(color: palette.border) : BorderSide.none,
        ),
        child: InkWell(
          key: const Key('adhkar_main_button'),
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: adhkarText(
                        16,
                        FontWeight.w700,
                        foreground,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.arrow_forward, size: 22, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The compact "Sync differences" row at the bottom of the Adhkar page.
final class AdhkarSyncRow extends StatelessWidget {
  const AdhkarSyncRow({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Material(
      color: palette.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        key: const Key('adhkar_sync_row'),
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.sync_alt_rounded, size: 20, color: palette.text),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: adhkarText(14, FontWeight.w600, palette.text),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: palette.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

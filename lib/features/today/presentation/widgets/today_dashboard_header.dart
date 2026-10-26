library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';

import '../../data/umm_al_qura_today_date.dart';
import '../dashboard_preview_data.dart';
import '../today_dashboard_view.dart';
import '../today_state.dart';
import '../today_strings.dart';

/// Transparent controls and a generic, time-of-day greeting. The user's name
/// can be added here when authentication provides a verified profile.
class TodayDashboardHeader extends StatelessWidget
    implements PreferredSizeWidget {
  static const double toolbarHeight = 64;
  static double dateRowHeightFor(double width, double textScale) =>
      width >= 1000 && textScale < 1.25
      ? 0
      : width < 420 || textScale >= 1.25
      ? 52
      : 36;

  const TodayDashboardHeader({
    super.key,
    required this.state,
    required this.strings,
    required this.colors,
    required this.onPreferences,
    this.dateRowHeight = 36,
    this.horizontalInset = 16,
    this.onNewTask,
    this.onNewHabit,
  });

  final TodayState state;
  final TodayStrings strings;
  final AppColors colors;
  final VoidCallback onPreferences;
  final double dateRowHeight;
  final double horizontalInset;
  final VoidCallback? onNewTask;
  final VoidCallback? onNewHabit;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight + dateRowHeight);

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final preview = DashboardPreviewData.standard;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = Localizations.localeOf(context).languageCode;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final isCompact = dateRowHeight > 0 || textScale >= 1.25;

    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      forceMaterialTransparency: true,
      automaticallyImplyLeading: false,
      titleSpacing: horizontalInset,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: colors.background.withValues(alpha: isDark ? 0.72 : 0.78),
              border: Border(
                bottom: BorderSide(color: colors.border.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),
      ),
      bottom: dateRowHeight == 0
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(dateRowHeight),
              child: SizedBox(
                height: dateRowHeight,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 6),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TodayDashboardDateLine(
                      state: state,
                      strings: strings,
                      colors: colors,
                    ),
                  ),
                ),
              ),
            ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _greeting(copy),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: dateRowHeight == 0 ? 20 : 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text('👋', style: TextStyle(fontSize: 17)),
            ],
          ),
          if (dateRowHeight == 0)
            TodayDashboardDateLine(
              state: state,
              strings: strings,
              colors: colors,
            ),
        ],
      ),
      actions: [
        // Streak Badge (Sample tagged)
        if (!isCompact)
          Semantics(
            label:
                '${copy.dashboardSampleValue}: ${copy.dashboardStreak} ${preview.streakDays.value}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x33451A03)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0x66F59E0B)
                      : const Color(0xFFFFEDD5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 17,
                    color: Color(0xFFF97316),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${preview.streakDays.value} · ${copy.dashboardSampleBadge}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!isCompact) const SizedBox(width: 4),

        // Level Badge (Shown on wider layouts with normal text)
        if (!isCompact) ...[
          Semantics(
            label:
                '${copy.dashboardSampleValue}: ${copy.dashboardLevel} ${preview.level.value}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 17,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${copy.dashboardLevel} ${preview.level.value} · ${copy.dashboardSampleBadge}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],

        // Language Switcher
        InkWell(
          key: const Key('today_language_toggle'),
          onTap: () => _toggleLanguage(context, currentLang),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language_rounded, size: 18, color: colors.primary),
                const SizedBox(width: 2),
                Text(
                  currentLang == 'ar' ? 'EN' : 'عربي',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),

        // Quick Add Button
        if (onNewTask != null || onNewHabit != null)
          PopupMenuButton<VoidCallback>(
            tooltip: '${strings.newTask} / ${strings.newHabit}',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  if (dateRowHeight == 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      copy.dashboardQuickAdd,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              if (onNewTask != null)
                PopupMenuItem(
                  key: const Key('today_new_task'),
                  value: onNewTask,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(strings.newTask),
                    ],
                  ),
                ),
              if (onNewHabit != null)
                PopupMenuItem(
                  key: const Key('today_new_habit'),
                  value: onNewHabit,
                  child: Row(
                    children: [
                      const Icon(Icons.autorenew_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(strings.newHabit),
                    ],
                  ),
                ),
            ],
          ),

        IconButton(
          key: kTodayPreferencesKey,
          tooltip: strings.preferences,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: onPreferences,
          icon: const Icon(Icons.tune_rounded, size: 24),
        ),
        SizedBox(width: horizontalInset),
      ],
    );
  }

  void _toggleLanguage(BuildContext context, String currentLang) {
    try {
      final cubit = context.read<LocaleCubit>();
      cubit.selectLanguage(currentLang == 'ar' ? 'en' : 'ar');
    } catch (_) {}
  }

  String _greeting(FoundationLocalizations copy) {
    final hour = state.calendar.nowUtc
        .add(Duration(minutes: state.calendar.utcOffsetMinutes))
        .hour;
    return hour < 12
        ? copy.dashboardGreetingMorning
        : copy.dashboardGreetingLater;
  }
}

/// Gregorian and Umm al-Qura dates share the compact translucent header.
class TodayDashboardDateLine extends StatelessWidget {
  const TodayDashboardDateLine({
    super.key,
    required this.state,
    required this.strings,
    required this.colors,
  });

  final TodayState state;
  final TodayStrings strings;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final hijri = UmmAlQuraTodayDate.fromLocalDate(state.calendar.localDate);
    final dateStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.textSecondary,
      fontSize: MediaQuery.sizeOf(context).width < 420 ? 10 : 12,
    );
    return Wrap(
      spacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(strings.formatDate(state.calendar.localDate), style: dateStyle),
        Text('•', style: dateStyle),
        Text(
          _hijriSubtitle(copy, hijri),
          style: dateStyle?.copyWith(
            color: hijri == null ? colors.textSecondary : colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _hijriSubtitle(
    FoundationLocalizations copy,
    UmmAlQuraTodayDate? hijri,
  ) {
    if (hijri == null) {
      return copy.dashboardHijriDateUnavailable;
    }
    final hijriStr = copy.dashboardHijriDate(
      '${hijri.day}',
      _monthName(copy, hijri.month),
      '${hijri.year}',
    );
    return '$hijriStr (${copy.dashboardUmmAlQuraCalendar})';
  }

  String _monthName(FoundationLocalizations copy, int month) => switch (month) {
    1 => copy.dashboardHijriMuharram,
    2 => copy.dashboardHijriSafar,
    3 => copy.dashboardHijriRabiAlAwwal,
    4 => copy.dashboardHijriRabiAlThani,
    5 => copy.dashboardHijriJumadaAlAwwal,
    6 => copy.dashboardHijriJumadaAlThani,
    7 => copy.dashboardHijriRajab,
    8 => copy.dashboardHijriShaban,
    9 => copy.dashboardHijriRamadan,
    10 => copy.dashboardHijriShawwal,
    11 => copy.dashboardHijriDhuAlQidah,
    12 => copy.dashboardHijriDhuAlHijjah,
    _ => copy.dashboardHijriDateUnavailable,
  };
}

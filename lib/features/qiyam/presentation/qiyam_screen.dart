import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_layout.dart';
import 'package:namma_project/app/widgets/app_notice.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_conflict_evidence.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';

import 'qiyam_conflicts_view.dart';
import 'qiyam_cubit.dart';
import 'qiyam_state.dart';
import 'widgets/qiyam_header.dart';
import 'widgets/qiyam_history_section.dart';
import 'widgets/qiyam_night_details.dart';
import 'widgets/qiyam_supplications_card.dart';
import 'widgets/qiyam_tracker_card.dart';

/// Wraps the Qiyam page in the app's navigation shell. The route composes it;
/// a bare screen (a test, a preview) shows no shell.
typedef QiyamShellBuilder = Widget Function(BuildContext context, Widget page);

/// The width of the content area from which the history sits in a side
/// column (contracts/adhkar-qiyam-ui.md).
const double kQiyamSideColumnBreakpoint = 1024;

/// The width of the history side column.
const double kQiyamSideColumnWidth = 360;

/// The Qiyam screen (contracts/adhkar-qiyam-ui.md, approved design
/// 2026-11-18): the heading with the last-third and streak chips, the tonight
/// tracker with the answered switch and the autosaved details, the
/// supplications, a compact "Sync differences" row when conflicts exist, and
/// the paged history; the read-only sync page is a second layer inside the
/// same route. An unavailable saved schedule keeps the screen visible but
/// pauses recording. Everything autosaves, so leaving needs no confirmation:
/// device back closes the night details (a sheet or dialog) first, then the
/// sync page, then goes Home (the shell handles that last step).
final class QiyamScreen extends StatefulWidget {
  const QiyamScreen({
    super.key,
    this.conflicts,
    this.shellBuilder,
    this.onOpenPrayerSetup,
  });

  /// The owner's retained night conflicts, composed by the route; null shows
  /// no "Sync differences" row.
  final Stream<List<QiyamConflictEvidence>>? conflicts;

  /// Puts the page inside the app shell; null shows the page alone.
  final QiyamShellBuilder? shellBuilder;

  /// Opens the existing Prayer location setup; null hides the setup button.
  final VoidCallback? onOpenPrayerSetup;

  @override
  State<QiyamScreen> createState() => _QiyamScreenState();
}

final class _QiyamScreenState extends State<QiyamScreen>
    with WidgetsBindingObserver {
  bool _syncOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The night may have turned while the app was away.
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<QiyamCubit>().resume());
    }
  }

  /// Closes the sync page. A sheet or dialog above the screen is a route of
  /// its own, so it is left to the navigator (the first back closes it); with
  /// nothing open here nothing is handled and the shell returns Home.
  Future<bool> _onBack() async {
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    if (_syncOpen) {
      setState(() => _syncOpen = false);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<QiyamCubit>();
    final state = cubit.state;
    final conflicts = widget.conflicts;
    final Widget page;
    if (_syncOpen && conflicts != null) {
      page = QiyamConflictsPage(
        conflicts: conflicts,
        currentNight: state.night?.nightDate,
        onBack: () => setState(() => _syncOpen = false),
      );
    } else {
      page = _QiyamPage(
        cubit: cubit,
        state: state,
        onOpenPrayerSetup: widget.onOpenPrayerSetup,
        syncRow: conflicts == null
            ? null
            : QiyamConflictsRow(
                conflicts: conflicts,
                onOpen: () => setState(() => _syncOpen = true),
              ),
      );
    }
    final shelled = widget.shellBuilder?.call(context, page) ?? page;
    // Outside a Router (a bare MaterialApp) there is no dispatcher to listen
    // to.
    if (Router.maybeOf(context) == null) return shelled;
    return BackButtonListener(onBackButtonPressed: _onBack, child: shelled);
  }
}

/// The page: one column on a phone, and the history in a side column on a
/// wide content area.
final class _QiyamPage extends StatelessWidget {
  const _QiyamPage({
    required this.cubit,
    required this.state,
    required this.onOpenPrayerSetup,
    required this.syncRow,
  });

  final QiyamCubit cubit;
  final QiyamState state;
  final VoidCallback? onOpenPrayerSetup;
  final Widget? syncRow;

  @override
  Widget build(BuildContext context) {
    final localizations = FoundationLocalizations.of(context);
    final copy = QiyamStrings(localizations);
    final locale = localizations.localeName;
    final colors = AppColors.of(context);
    final night = state.night;
    final paused =
        night != null && night.scheduleState == QiyamScheduleState.unavailable;
    final changed = state.actionStatus == QiyamActionStatus.nightChanged;

    final history = QiyamHistorySection(
      copy: copy,
      locale: locale,
      entries: state.history,
      loading: state.historyLoading,
      failed: state.historyFailed,
      complete: state.historyComplete,
      onLoadMore: cubit.loadMoreHistory,
      onOpenNight: (entry) =>
          unawaited(showQiyamNightDetails(context, entry: entry)),
    );

    final Widget tracker = night == null
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        : QiyamTrackerCard(
            copy: copy,
            night: night,
            form: state.form,
            status: state.actionStatus,
            failureMessageKey: state.failureMessageKey,
            celebration: state.celebration,
            onYes: cubit.answerYes,
            onNo: cubit.answerNo,
            onRakahs: cubit.selectRakahs,
            onWitr: cubit.toggleWitr,
            onTimes: cubit.updateTimes,
            onNote: cubit.updateNote,
          );

    final mainColumn = <Widget>[
      QiyamHeader(
        copy: copy,
        night: night,
        locale: locale,
        streak: state.streak,
        streakFailed: state.streakFailed,
        onOpenPrayerSetup: onOpenPrayerSetup,
      ),
      if (paused)
        AppBanner(
          key: const Key('qiyam_locked_notice'),
          message: copy.recordingLocked,
          icon: Icons.schedule_rounded,
        ),
      if (changed)
        AppBanner(
          key: const Key('qiyam_night_changed'),
          tone: AppBannerTone.accent,
          message: copy.nightChanged,
          icon: Icons.dark_mode_outlined,
        ),
      tracker,
      QiyamSupplicationsCard(copy: copy, supplications: state.supplications),
      ?syncRow,
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= kQiyamSideColumnBreakpoint;
            final roomy = constraints.maxWidth >= AppLayout.wideBreakpoint;
            final padding = roomy
                ? const EdgeInsets.all(40)
                : const EdgeInsets.fromLTRB(20, 24, 20, 24);
            final main = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _spaced(mainColumn, 16),
            );
            return SingleChildScrollView(
              padding: padding,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1160 : 720),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: main),
                            const SizedBox(width: 32),
                            SizedBox(
                              width: kQiyamSideColumnWidth,
                              child: history,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [main, const SizedBox(height: 16), history],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> children, double gap) => [
    for (var i = 0; i < children.length; i++) ...[
      if (i > 0) SizedBox(height: gap),
      children[i],
    ],
  ];
}

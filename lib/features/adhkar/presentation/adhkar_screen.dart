import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

import 'adhkar_conflicts_view.dart';
import 'adhkar_cubit.dart';
import 'adhkar_state.dart';
import 'my_adhkar_cubit.dart';
import 'widgets/adhkar_list_page.dart';
import 'widgets/adhkar_reader.dart';
import 'widgets/adhkar_reader_parts.dart';
import 'widgets/adhkar_style.dart';
import 'widgets/my_adhkar_tab.dart';

/// Wraps the Adhkar page (not the reader) in the app's navigation shell. The
/// route composes it; a bare screen (a test, a preview) shows no shell.
typedef AdhkarShellBuilder = Widget Function(BuildContext context, Widget page);

/// The Adhkar screen (contracts/adhkar-qiyam-ui.md, approved design
/// 2026-11-17): the title and three tabs, the Morning/Evening page (progress
/// card, time line, streak, main button), «أذكاري», and two layers inside the
/// same route: the full-screen reader (no shell) and the read-only sync
/// differences page. Device back closes the topmost layer first and then
/// leaves for Home (the shell handles that last step).
final class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({
    super.key,
    this.conflicts,
    this.shellBuilder,
    this.onOpenPrayerSetup,
  });

  /// The owner's conflict evidence, composed by the route; null shows no
  /// "Sync differences" row.
  final AdhkarConflictsSource? conflicts;

  /// Puts the page inside the app shell; null shows the page alone.
  final AdhkarShellBuilder? shellBuilder;

  /// Opens the existing Prayer location setup; null hides the setup buttons.
  final VoidCallback? onOpenPrayerSetup;

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

final class _AdhkarScreenState extends State<AdhkarScreen> {
  bool _syncOpen = false;
  AdhkarList? _readerList;
  int _readerStart = 0;

  void _openReader(AdhkarList list, int index) => setState(() {
    _readerList = list;
    _readerStart = index;
  });

  void _closeReader() => setState(() => _readerList = null);

  void _selectTab(AdhkarTab tab) {
    final cubit = context.read<AdhkarCubit>();
    if (cubit.state.selectedTab == AdhkarTab.myAdhkar &&
        tab != AdhkarTab.myAdhkar) {
      // Leaving My Adhkar closes an open group, so coming back shows the
      // group list.
      final mine = _maybeMyAdhkar();
      if (mine != null) unawaited(mine.closeGroup());
    }
    cubit.selectTab(tab);
  }

  MyAdhkarCubit? _maybeMyAdhkar() {
    try {
      return context.read<MyAdhkarCubit>();
    } on Object {
      return null;
    }
  }

  /// Closes the topmost layer: the reader, then the sync page. A dialog or
  /// sheet above the screen is a route of its own, so it is left to the
  /// navigator (the first back closes it); with no layer open nothing is
  /// handled here and the shell returns Home.
  Future<bool> _onBack() async {
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    if (_readerList != null) {
      _closeReader();
      return true;
    }
    if (_syncOpen) {
      setState(() => _syncOpen = false);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AdhkarCubit>();
    final state = cubit.state;
    final copy = AdhkarStrings(FoundationLocalizations.of(context));
    final locale = FoundationLocalizations.of(context).localeName;
    final palette = AdhkarPalette.of(context);
    final reader = _readerList;

    final Widget page;
    if (state.catalog == null) {
      page = Scaffold(
        backgroundColor: palette.bg,
        body: state.loading
            ? const Center(child: CircularProgressIndicator())
            : AdhkarErrorView(
                key: const Key('adhkar_content_error'),
                copy: copy,
                onRetry: () => unawaited(cubit.load()),
              ),
      );
    } else if (_syncOpen && widget.conflicts != null) {
      page = AdhkarConflictsPage(
        source: widget.conflicts!,
        onBack: () => setState(() => _syncOpen = false),
      );
    } else {
      page = _AdhkarPage(
        copy: copy,
        locale: locale,
        state: state,
        onTabChanged: _selectTab,
        onOpenReader: _openReader,
        onOpenPrayerSetup: widget.onOpenPrayerSetup,
        syncRow: widget.conflicts == null
            ? null
            : AdhkarConflictsRow(
                source: widget.conflicts!,
                onOpen: () => setState(() => _syncOpen = true),
              ),
      );
    }
    final shelled = widget.shellBuilder?.call(context, page) ?? page;

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        // The page stays mounted under the reader so an open group, a
        // scroll position and the tab come back as they were.
        Offstage(
          offstage: reader != null,
          child: ExcludeFocus(
            excluding: reader != null,
            child: TickerMode(enabled: reader == null, child: shelled),
          ),
        ),
        if (reader != null)
          Positioned.fill(
            child: AdhkarReader(
              key: ValueKey('adhkar_reader_${reader.name}_$_readerStart'),
              list: reader,
              initialIndex: _readerStart,
              onClose: _closeReader,
              onOpenPrayerSetup: widget.onOpenPrayerSetup,
            ),
          ),
      ],
    );
    // Outside a Router (a bare MaterialApp) there is no dispatcher to
    // listen to.
    if (Router.maybeOf(context) == null) return stack;
    return BackButtonListener(onBackButtonPressed: _onBack, child: stack);
  }
}

/// The page itself: the title block and tabs, then the content of the tab
/// (the main page for Morning and Evening, the collection for «أذكاري»).
final class _AdhkarPage extends StatelessWidget {
  const _AdhkarPage({
    required this.copy,
    required this.locale,
    required this.state,
    required this.onTabChanged,
    required this.onOpenReader,
    required this.onOpenPrayerSetup,
    required this.syncRow,
  });

  final AdhkarStrings copy;
  final String locale;
  final AdhkarState state;
  final ValueChanged<AdhkarTab> onTabChanged;
  final void Function(AdhkarList list, int index) onOpenReader;
  final VoidCallback? onOpenPrayerSetup;
  final Widget? syncRow;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    final tab = state.selectedTab;
    final isMine = tab == AdhkarTab.myAdhkar;
    final morning = tab == AdhkarTab.morning;
    final wide = MediaQuery.sizeOf(context).width >= kAdhkarWideBreakpoint;
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final base = wide ? 32.0 : 20.0;
            final side = math.max(
              base,
              (constraints.maxWidth - kAdhkarColumnMaxWidth) / 2,
            );
            final bottom = wide ? 32.0 : 24.0;
            final head = SliverPadding(
              padding: EdgeInsets.fromLTRB(side, wide ? 32 : 24, side, 0),
              sliver: SliverToBoxAdapter(
                child: AdhkarTitleBlock(
                  copy: copy,
                  selectedTab: tab,
                  onTabChanged: onTabChanged,
                ),
              ),
            );
            if (isMine) {
              return CustomScrollView(
                slivers: [
                  head,
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side, 16, side, bottom),
                    sliver: const SliverToBoxAdapter(child: MyAdhkarTab()),
                  ),
                ],
              );
            }
            final list = morning ? AdhkarList.morning : AdhkarList.evening;
            return CustomScrollView(
              slivers: [
                head,
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 16, side, bottom),
                  sliver: SliverFillRemaining(
                    hasScrollBody: false,
                    child: AdhkarListPage(
                      copy: copy,
                      locale: locale,
                      state: state,
                      morning: morning,
                      onOpenReader: (index) => onOpenReader(list, index),
                      onOpenPrayerSetup: onOpenPrayerSetup,
                      syncRow: syncRow,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

import '../adhkar_cubit.dart';
import '../adhkar_state.dart';
import 'adhkar_list_page.dart';
import 'adhkar_reader_parts.dart';
import 'adhkar_style.dart';

/// How long the done bar holds before the page slides to the next item.
const Duration kAdhkarDoneHold = Duration(milliseconds: 600);

/// The slide to the next item.
const Duration kAdhkarSlide = Duration(milliseconds: 250);

/// The reader (contracts/adhkar-qiyam-ui.md, "Reader"): one item per page,
/// the count button with its ring, the done bar and the auto slide, swipe
/// both ways, the list sheet and jump, the reset dialog, the locked banners,
/// the completion state and the error state. It runs the existing
/// [AdhkarCubit] commands; it stores nothing and awards nothing itself.
final class AdhkarReader extends StatefulWidget {
  const AdhkarReader({
    super.key,
    required this.list,
    required this.initialIndex,
    required this.onClose,
    this.onOpenPrayerSetup,
  });

  final AdhkarList list;
  final int initialIndex;

  /// Closes the reader and returns to the Adhkar page on the same tab.
  final VoidCallback onClose;
  final VoidCallback? onOpenPrayerSetup;

  @override
  State<AdhkarReader> createState() => _AdhkarReaderState();
}

final class _AdhkarReaderState extends State<AdhkarReader> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  final FocusNode _focus = FocusNode(debugLabel: 'adhkar_reader');
  late int _index = widget.initialIndex;
  Timer? _holdTimer;
  String? _holdingItemId;
  bool _complete = false;
  bool _celebrated = false;

  AdhkarCubit get _cubit => context.read<AdhkarCubit>();

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pages.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<DhikrItem> _items(AdhkarState state) =>
      state.catalog?.itemsOf(widget.list) ?? const <DhikrItem>[];

  bool _countable(AdhkarState state) {
    if (state.countingLocked) return false;
    final clock = state.clock;
    return widget.list == AdhkarList.morning
        ? (clock?.morningCountable ?? false)
        : (clock?.eveningCountable ?? false);
  }

  Future<void> _count(DhikrItem item) async {
    final cubit = _cubit;
    final state = cubit.state;
    if (!_countable(state) ||
        state.countOf(item.itemId) >= item.target ||
        _holdingItemId != null) {
      return;
    }
    unawaited(HapticFeedback.lightImpact());
    await cubit.increment(item.itemId, state.clock?.day ?? '');
    if (!mounted) return;
    if (cubit.state.countOf(item.itemId) >= item.target) {
      _beginHold(item);
    }
  }

  void _beginHold(DhikrItem item) {
    setState(() => _holdingItemId = item.itemId);
    _holdTimer?.cancel();
    _holdTimer = Timer(kAdhkarDoneHold, () {
      if (!mounted) return;
      final items = _items(_cubit.state);
      final at = items.indexWhere(
        (candidate) => candidate.itemId == item.itemId,
      );
      setState(() => _holdingItemId = null);
      // Only the page the person is still on advances; a swipe away during
      // the hold leaves them where they went.
      if (at < 0 || at != _index) return;
      if (at < items.length - 1) {
        unawaited(
          _pages.animateToPage(
            at + 1,
            duration: kAdhkarSlide,
            curve: Curves.easeOutCubic,
          ),
        );
        return;
      }
      final state = _cubit.state;
      final allDone = items.every(
        (candidate) => state.countOf(candidate.itemId) >= candidate.target,
      );
      if (allDone) {
        setState(() {
          _complete = true;
          _celebrated = state.celebration != null;
        });
      }
    });
  }

  void _step(int delta, int length) {
    final target = (_index + delta).clamp(0, length - 1);
    if (target == _index) return;
    unawaited(
      _pages.animateToPage(
        target,
        duration: kAdhkarSlide,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  KeyEventResult _onKey(KeyEvent event, List<DhikrItem> items, bool rtl) {
    if (event is KeyUpEvent || _complete || items.isEmpty) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      unawaited(_count(items[_index.clamp(0, items.length - 1)]));
      return KeyEventResult.handled;
    }
    // The arrow keys follow the screen: in Arabic the left arrow goes to the
    // next item, in English the right arrow does.
    if (key == LogicalKeyboardKey.arrowLeft) {
      _step(rtl ? 1 : -1, items.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _step(rtl ? -1 : 1, items.length);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _confirmReset(DhikrItem item) async {
    final copy = AdhkarStrings(FoundationLocalizations.of(context));
    final cubit = _cubit;
    final day = cubit.state.clock?.day ?? '';
    final confirmed = await showAdhkarResetDialog(context, copy);
    if (confirmed == true && mounted) {
      await cubit.reset(item.itemId, day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = AdhkarStrings(FoundationLocalizations.of(context));
    final palette = AdhkarPalette.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final wide = MediaQuery.sizeOf(context).width >= kAdhkarWideBreakpoint;
    return BlocBuilder<AdhkarCubit, AdhkarState>(
      builder: (context, state) {
        final items = _items(state);
        final morning = widget.list == AdhkarList.morning;
        final total = items.length;
        final doneItems = items
            .where((item) => state.countOf(item.itemId) >= item.target)
            .length;
        final unavailable = state.catalog == null || items.isEmpty;
        final Widget body;
        if (unavailable) {
          body = AdhkarErrorView(
            key: const Key('adhkar_reader_error'),
            copy: copy,
            onRetry: () => unawaited(_cubit.load()),
          );
        } else if (_complete) {
          body = _CompleteView(
            copy: copy,
            showPoints: _celebrated,
            onClose: widget.onClose,
          );
        } else {
          body = _ReaderBody(
            copy: copy,
            state: state,
            items: items,
            list: widget.list,
            wide: wide,
            pages: _pages,
            index: _index.clamp(0, total - 1),
            holdingItemId: _holdingItemId,
            countable: _countable(state),
            onOpenPrayerSetup: widget.onOpenPrayerSetup,
            onPageChanged: (value) => setState(() => _index = value),
            onCount: _count,
            onReset: _confirmReset,
            onStep: (delta) => _step(delta, total),
          );
        }
        final showList = !unavailable && !_complete;
        return Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: (_, event) => _onKey(event, items, rtl),
          child: Material(
            key: const Key('adhkar_reader'),
            color: palette.bg,
            child: SafeArea(
              child: Column(
                children: [
                  _ReaderHeader(
                    title: copy.listLabel(morning),
                    listLabel: copy.listButton,
                    closeLabel: copy.close,
                    onList: showList
                        ? () => showAdhkarListSheet(
                            context: context,
                            cubit: _cubit,
                            list: widget.list,
                            currentIndex: _index,
                            onJump: (value) {
                              if (_pages.hasClients) _pages.jumpToPage(value);
                            },
                          )
                        : null,
                    onClose: widget.onClose,
                  ),
                  _TopProgress(
                    progress: total == 0
                        ? 0
                        : (_complete ? total : doneItems) / total,
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({
    required this.title,
    required this.listLabel,
    required this.closeLabel,
    required this.onList,
    required this.onClose,
  });

  final String title;
  final String listLabel;
  final String closeLabel;
  final VoidCallback? onList;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            AdhkarSquareButton(
              key: const Key('adhkar_reader_list'),
              icon: Icons.format_list_bulleted_rounded,
              label: listLabel,
              onTap: onList,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: adhkarText(
                  18,
                  FontWeight.w700,
                  palette.text,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AdhkarSquareButton(
              key: const Key('adhkar_reader_close'),
              icon: Icons.close_rounded,
              label: closeLabel,
              onTap: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

/// The thin progress bar for the whole list under the header.
final class _TopProgress extends StatelessWidget {
  const _TopProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Container(
      key: const Key('adhkar_reader_progress'),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 4,
      decoration: BoxDecoration(
        color: palette.border,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: palette.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// The reader proper: the pages, and under them the done bar or lock
/// banner, the repetition and position row, and the control bar. On wide
/// windows the column is at most 720 px with round previous/next buttons on
/// each side and the keyboard hints under the controls.
final class _ReaderBody extends StatelessWidget {
  const _ReaderBody({
    required this.copy,
    required this.state,
    required this.items,
    required this.list,
    required this.wide,
    required this.pages,
    required this.index,
    required this.holdingItemId,
    required this.countable,
    required this.onOpenPrayerSetup,
    required this.onPageChanged,
    required this.onCount,
    required this.onReset,
    required this.onStep,
  });

  final AdhkarStrings copy;
  final AdhkarState state;
  final List<DhikrItem> items;
  final AdhkarList list;
  final bool wide;
  final PageController pages;
  final int index;
  final String? holdingItemId;
  final bool countable;
  final VoidCallback? onOpenPrayerSetup;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<DhikrItem> onCount;
  final ValueChanged<DhikrItem> onReset;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    final item = items[index];
    final count = state.countOf(item.itemId);
    final holding = holdingItemId == item.itemId;
    final reachedTarget = count >= item.target;
    final locale = FoundationLocalizations.of(context).localeName;
    final clock = state.clock;

    Widget? banner;
    if (holding) {
      banner = AdhkarDoneBar(copy: copy);
    } else if (state.countingLocked) {
      banner = AdhkarLockBanner(
        key: const Key('adhkar_reader_lock_setup'),
        message: copy.countingLocked,
        icon: Icons.location_on_outlined,
        actionLabel: onOpenPrayerSetup == null ? null : copy.openPrayerSetup,
        onAction: onOpenPrayerSetup,
      );
    } else if (!countable) {
      final at = clock?.nextBoundaryUtc;
      final zone = clock?.zoneId;
      banner = AdhkarLockBanner(
        key: const Key('adhkar_reader_lock_time'),
        message: at != null && zone != null
            ? copy.startsAt(formatAdhkarTime(at, zone, locale))
            : copy.countingLocked,
        icon: Icons.schedule_rounded,
      );
    }

    final column = LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  key: const Key('adhkar_reader_pages'),
                  controller: pages,
                  itemCount: items.length,
                  onPageChanged: onPageChanged,
                  physics: const PageScrollPhysics().applyTo(
                    const ClampingScrollPhysics(),
                  ),
                  itemBuilder: (context, i) => AdhkarItemPage(
                    key: Key('adhkar_reader_page_${items[i].itemId}'),
                    item: items[i],
                    copy: copy,
                    wide: wide,
                    dimmed: holdingItemId == items[i].itemId,
                  ),
                ),
                if (holding)
                  PositionedDirectional(
                    top: 16,
                    bottom: 16,
                    end: 4,
                    width: 10,
                    child: Container(
                      key: const Key('adhkar_reader_next_sliver'),
                      decoration: BoxDecoration(
                        color: palette.soft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.primary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // The controls take at most 60% of the height and scroll beyond it
          // (a long banner at a large text scale), so the page always shows.
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.6),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (banner != null) ...[banner, const SizedBox(height: 12)],
                    _InfoRow(
                      repeatLabel: copy.repeat(item.target),
                      positionLabel: copy.position(item.position, items.length),
                    ),
                    AdhkarControlBar(
                      key: const Key('adhkar_reader_controls'),
                      copy: copy,
                      count: count,
                      target: item.target,
                      done: reachedTarget,
                      locked: !countable,
                      itemKey: item.itemId,
                      onCount: () => onCount(item),
                      onReset: () => onReset(item),
                    ),
                    if (wide) AdhkarKeyboardHints(copy: copy),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!wide) return column;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          AdhkarRoundNav(
            key: const Key('adhkar_reader_prev'),
            icon: Icons.chevron_left,
            label: copy.previousItem,
            onTap: index > 0 ? () => onStep(-1) : null,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Align(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: kAdhkarColumnMaxWidth,
                ),
                child: column,
              ),
            ),
          ),
          const SizedBox(width: 24),
          AdhkarRoundNav(
            key: const Key('adhkar_reader_next'),
            icon: Icons.chevron_right,
            label: copy.nextItem,
            onTap: index < items.length - 1 ? () => onStep(1) : null,
          ),
        ],
      ),
    );
  }
}

/// The repetition chip and the position, kept with the counter so they stay
/// visible while a long text scrolls.
final class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.repeatLabel, required this.positionLabel});

  final String repeatLabel;
  final String positionLabel;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 6,
        children: [
          Container(
            key: const Key('adhkar_reader_repeat'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: palette.soft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              repeatLabel,
              style: adhkarText(15, FontWeight.w700, palette.accent),
            ),
          ),
          // The position reads "n | N" left to right in both languages.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              positionLabel,
              key: const Key('adhkar_reader_position'),
              style: adhkarText(
                15,
                FontWeight.w600,
                palette.text2,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );
  }
}

/// The completion state: the ornament with its check, «اكتملت الأذكار!», the
/// points chip (only when this completion awarded them), and the way back.
final class _CompleteView extends StatelessWidget {
  const _CompleteView({
    required this.copy,
    required this.showPoints,
    required this.onClose,
  });

  final AdhkarStrings copy;
  final bool showPoints;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Column(
      key: const Key('adhkar_reader_complete'),
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 48),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(200, 200),
                              painter: AdhkarOrnamentPainter(
                                stroke: palette.primary,
                                fill: palette.soft,
                              ),
                            ),
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.button,
                                boxShadow: palette.buttonGlow,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 44,
                                color: palette.onButton,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        copy.completeTitle,
                        textAlign: TextAlign.center,
                        style: adhkarText(
                          28,
                          FontWeight.w800,
                          palette.text,
                          height: 1.4,
                        ),
                      ),
                      if (showPoints) ...[
                        const SizedBox(height: 20),
                        Container(
                          key: const Key('adhkar_reader_points'),
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: palette.soft,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: palette.border),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            copy.points,
                            style: adhkarText(
                              16,
                              FontWeight.w700,
                              palette.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AdhkarFilledAction(
              key: const Key('adhkar_reader_back'),
              label: copy.backToAdhkar,
              onTap: onClose,
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_typography.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_card.dart';
import 'package:namma_project/app/widgets/app_confirmation.dart';
import 'package:namma_project/app/widgets/app_icon_badge.dart';
import 'package:namma_project/app/widgets/app_ink_surface.dart';
import 'package:namma_project/app/widgets/app_key_cap.dart';
import 'package:namma_project/app/widgets/app_pill.dart';
import 'package:namma_project/app/widgets/app_progress_ring.dart';
import 'package:namma_project/app/widgets/app_sheets.dart';
import 'package:namma_project/app/widgets/app_surface_icon_button.dart';
import 'package:namma_project/app/widgets/app_text_scale_clamp.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

import '../adhkar_cubit.dart';
import '../adhkar_state.dart';
import 'adhkar_style.dart';

/// One page of the reader: the optional preface, the text (the Quran font
/// for a Quran item, Amiri otherwise; the verse-end markers are in the text
/// itself), the reference line, and the collapsible virtue when the item has
/// one. The area scrolls vertically while the counter stays fixed.
final class AdhkarItemPage extends StatefulWidget {
  const AdhkarItemPage({
    super.key,
    required this.item,
    required this.copy,
    required this.wide,
    required this.dimmed,
  });

  final DhikrItem item;
  final AdhkarStrings copy;
  final bool wide;

  /// True while the done bar holds: the text dims and shifts a little toward
  /// the next page.
  final bool dimmed;

  @override
  State<AdhkarItemPage> createState() => _AdhkarItemPageState();
}

final class _AdhkarItemPageState extends State<AdhkarItemPage> {
  bool _virtueOpen = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final item = widget.item;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final font = item.kind == DhikrKind.quran
        ? kQuranFontFamily
        : kDhikrFontFamily;
    final gap = widget.wide ? 22.0 : 16.0;
    final virtue = item.virtueAr;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0, constraints.maxHeight - 32),
          ),
          child: Center(
            child: AnimatedOpacity(
              opacity: widget.dimmed ? 0.5 : 1,
              duration: const Duration(milliseconds: 150),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: Matrix4.translationValues(
                  widget.dimmed ? (rtl ? 14 : -14) : 0,
                  0,
                  0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.prefaceAr != null) ...[
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          item.prefaceAr!,
                          key: Key('adhkar_preface_${item.itemId}'),
                          textAlign: TextAlign.center,
                          style: AppTypography.fixed(
                            19,
                            FontWeight.w700,
                            colors.accentStrong,
                            height: 1.8,
                          ).copyWith(fontFamily: kDhikrFontFamily),
                        ),
                      ),
                      SizedBox(height: gap),
                    ],
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        item.textAr,
                        key: Key('adhkar_text_${item.itemId}'),
                        textAlign: TextAlign.center,
                        style: AppTypography.fixed(
                          widget.wide ? 34 : 28,
                          FontWeight.w400,
                          colors.textPrimary,
                          height: 2.15,
                        ).copyWith(fontFamily: font),
                      ),
                    ),
                    SizedBox(height: gap),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        item.referenceAr,
                        key: Key('adhkar_reference_${item.itemId}'),
                        textAlign: TextAlign.center,
                        style: AppTypography.fixed(
                          17,
                          FontWeight.w600,
                          colors.accentStrong,
                        ),
                      ),
                    ),
                    if (virtue != null) ...[
                      SizedBox(height: gap),
                      _VirtuePill(
                        key: Key('adhkar_virtue_toggle_${item.itemId}'),
                        label: widget.copy.virtue,
                        open: _virtueOpen,
                        onTap: () => setState(() => _virtueOpen = !_virtueOpen),
                      ),
                      if (_virtueOpen) ...[
                        const SizedBox(height: 10),
                        AppCard(
                          key: Key('adhkar_virtue_text_${item.itemId}'),
                          tone: AppCardTone.secondary,
                          radius: 20,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                virtue,
                                style: AppTypography.fixed(
                                  19,
                                  FontWeight.w400,
                                  colors.textSecondary,
                                  height: 1.9,
                                ).copyWith(fontFamily: kDhikrFontFamily),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _VirtuePill extends StatelessWidget {
  const _VirtuePill({
    super.key,
    required this.label,
    required this.open,
    required this.onTap,
  });

  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      expanded: open,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: AppInkSurface(
        borderColor: colors.border,
        stadium: true,
        minHeight: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: AppTypography.fixed(
                  15,
                  FontWeight.w600,
                  colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The «تمّ الذكر · التالي» bar shown during the hold.
final class AdhkarDoneBar extends StatelessWidget {
  const AdhkarDoneBar({super.key, required this.copy});

  final AdhkarStrings copy;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppTextScaleClamp(
      max: 1.3,
      child: AppCard(
        key: const Key('adhkar_reader_done_bar'),
        tone: AppCardTone.accent,
        radius: 16,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            Icon(Icons.check_rounded, size: 20, color: colors.accentStrong),
            Text(
              copy.done,
              style: AppTypography.fixed(
                15,
                FontWeight.w600,
                colors.textPrimary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.next,
                  style: AppTypography.fixed(
                    15,
                    FontWeight.w600,
                    colors.accentStrong,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 18, color: colors.accentStrong),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The control bar: an empty 52 px slot reserved for a later audio button,
/// the large round count button with its progress ring, and the reset button.
final class AdhkarControlBar extends StatelessWidget {
  const AdhkarControlBar({
    super.key,
    required this.copy,
    required this.count,
    required this.target,
    required this.done,
    required this.locked,
    required this.itemKey,
    required this.onCount,
    required this.onReset,
  });

  final AdhkarStrings copy;
  final int count;
  final int target;
  final bool done;
  final bool locked;
  final String itemKey;
  final VoidCallback onCount;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final k = math.min(scale, 1.4);
    final ring = (104 * k).round().toDouble();
    final gap = scale >= 1.5 ? 12.0 : 22.0;
    final resetOff = locked;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Reserved for a future audio button; intentionally empty.
          const SizedBox(width: 52, height: 52),
          SizedBox(width: gap),
          AdhkarCountButton(
            key: Key('adhkar_reader_count_$itemKey'),
            ring: ring,
            k: k,
            count: count,
            target: target,
            done: done,
            locked: locked,
            semanticLabel: copy.countSemantic(count, target),
            onTap: (done || locked) ? null : onCount,
          ),
          SizedBox(width: gap),
          AppSurfaceIconButton(
            key: const Key('adhkar_reader_reset'),
            icon: Icons.restart_alt,
            label: copy.resetCount,
            onTap: resetOff ? null : onReset,
            size: 52,
            circle: true,
            disabledOpacity: 0.45,
          ),
        ],
      ),
    );
  }
}

/// The round count button: the ring (count over target), the page background
/// ring cover, and the disc holding the count, a check when done, or a lock
/// when counting is paused. The semantic label is "Count, 2 of 3".
final class AdhkarCountButton extends StatefulWidget {
  const AdhkarCountButton({
    super.key,
    required this.ring,
    required this.k,
    required this.count,
    required this.target,
    required this.done,
    required this.locked,
    required this.semanticLabel,
    required this.onTap,
  });

  final double ring;
  final double k;
  final int count;
  final int target;
  final bool done;
  final bool locked;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  State<AdhkarCountButton> createState() => _AdhkarCountButtonState();
}

final class _AdhkarCountButtonState extends State<AdhkarCountButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ring = widget.ring;
    final cover = ring - 12;
    final disc = ring - 28;
    final locked = widget.locked;
    final progress = widget.done || widget.target == 0
        ? (widget.done ? 1.0 : 0.0)
        : widget.count / widget.target;
    final Widget face;
    if (widget.done) {
      face = Icon(
        Icons.check_rounded,
        size: 40 * widget.k,
        color: colors.onAccentStrong,
      );
    } else if (locked) {
      face = Icon(
        Icons.lock_outline,
        size: 40 * widget.k,
        color: colors.textSecondary,
      );
    } else {
      face = Text(
        '${widget.count}',
        textScaler: TextScaler.noScaling,
        style: AppTypography.fixed(
          36 * widget.k,
          FontWeight.w800,
          colors.onAccentStrong,
          height: 1,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      );
    }
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      liveRegion: true,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: SizedBox(
        width: ring,
        height: ring,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AppProgressRing(
              size: ring,
              strokeWidth: 6,
              progress: locked ? 0 : progress,
            ),
            Container(
              width: cover,
              height: cover,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.background,
              ),
            ),
            AnimatedScale(
              scale: _pressed ? 0.94 : 1,
              duration: const Duration(milliseconds: 90),
              child: Container(
                width: disc,
                height: disc,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: locked ? colors.surfaceSecondary : colors.accentStrong,
                  border: locked ? Border.all(color: colors.border) : null,
                  boxShadow: locked ? null : colors.buttonShadow,
                ),
                child: face,
              ),
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: const Key('adhkar_reader_count'),
                  customBorder: const CircleBorder(),
                  onTap: widget.onTap,
                  onHighlightChanged: (value) {
                    if (_pressed != value) setState(() => _pressed = value);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The keyboard hints shown on wide windows.
final class AdhkarKeyboardHints extends StatelessWidget {
  const AdhkarKeyboardHints({super.key, required this.copy});

  final AdhkarStrings copy;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        key: const Key('adhkar_reader_keyboard_hints'),
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 28,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppKeyCap(label: 'Space'),
              const SizedBox(width: 8),
              const AppKeyCap(label: 'Enter'),
              const SizedBox(width: 8),
              Text(
                copy.keyCount,
                style: AppTypography.fixed(
                  14,
                  FontWeight.w400,
                  colors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppKeyCap(label: '←'),
              const SizedBox(width: 8),
              const AppKeyCap(label: '→'),
              const SizedBox(width: 8),
              Text(
                copy.keyMove,
                style: AppTypography.fixed(
                  14,
                  FontWeight.w400,
                  colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The content-unavailable state with its retry button (the reader and the
/// Adhkar page share it).
final class AdhkarErrorView extends StatelessWidget {
  const AdhkarErrorView({super.key, required this.copy, required this.onRetry});

  final AdhkarStrings copy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIconBadge(
              icon: Icons.error_outline,
              size: 96,
              iconSize: 44,
              tone: AppBadgeTone.error,
            ),
            const SizedBox(height: 20),
            Text(
              copy.contentUnavailable,
              textAlign: TextAlign.center,
              style: AppTypography.fixed(
                20,
                FontWeight.w700,
                colors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              key: const Key('adhkar_retry'),
              label: copy.retry,
              onPressed: onRetry,
              look: AppButtonLook.refined,
              variant: AppButtonVariant.secondary,
              fill: colors.surface,
              tuning: const AppButtonTuning(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 6),
                labelHeight: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The completion ornament: a thin circle and two overlaid squares forming
/// an eight-point star, in the design's 120-unit box.
final class AdhkarOrnamentPainter extends CustomPainter {
  const AdhkarOrnamentPainter({required this.stroke, required this.fill});

  final Color stroke;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120;
    canvas.save();
    canvas.scale(scale);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = stroke.withValues(alpha: 0.35);
    canvas.drawCircle(const Offset(60, 60), 58, line);
    final square = RRect.fromRectAndRadius(
      const Rect.fromLTWH(24, 24, 72, 72),
      const Radius.circular(6),
    );
    final squareFill = Paint()..color = fill;
    final squareLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = stroke.withValues(alpha: 0.8);
    canvas.drawRRect(square, squareFill);
    canvas.drawRRect(square, squareLine);
    canvas.translate(60, 60);
    canvas.rotate(math.pi / 4);
    canvas.translate(-60, -60);
    canvas.drawRRect(square, squareFill);
    canvas.drawRRect(square, squareLine);
    canvas.restore();
  }

  @override
  bool shouldRepaint(AdhkarOrnamentPainter old) =>
      old.stroke != stroke || old.fill != fill;
}

/// Opens the reset confirmation dialog; true when the person confirms.
Future<bool?> showAdhkarResetDialog(BuildContext context, AdhkarStrings copy) =>
    showAppConfirmDialog(
      context: context,
      title: copy.resetTitle,
      body: copy.resetBody,
      cancelLabel: copy.myAdhkarCancel,
      confirmLabel: copy.resetConfirm,
      panelKey: const Key('adhkar_reset_dialog'),
      cancelKey: const Key('adhkar_reset_cancel'),
      confirmKey: const Key('adhkar_reset_confirm'),
    );

/// Opens the list sheet: every item with its first words, its count and a
/// done mark; the current row is highlighted and scrolled into view, and
/// tapping a row closes the sheet and jumps straight to that item.
Future<void> showAdhkarListSheet({
  required BuildContext context,
  required AdhkarCubit cubit,
  required AdhkarList list,
  required int currentIndex,
  required ValueChanged<int> onJump,
}) {
  final copy = AdhkarStrings(FoundationLocalizations.of(context));
  return showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => _ListSheet(
      copy: copy,
      cubit: cubit,
      list: list,
      currentIndex: currentIndex,
      onJump: (index) {
        Navigator.of(sheetContext).pop();
        onJump(index);
      },
    ),
  );
}

final class _ListSheet extends StatefulWidget {
  const _ListSheet({
    required this.copy,
    required this.cubit,
    required this.list,
    required this.currentIndex,
    required this.onJump,
  });

  final AdhkarStrings copy;
  final AdhkarCubit cubit;
  final AdhkarList list;
  final int currentIndex;
  final ValueChanged<int> onJump;

  @override
  State<_ListSheet> createState() => _ListSheetState();
}

final class _ListSheetState extends State<_ListSheet> {
  static const double _rowExtent = 66;

  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: math.max(0, (widget.currentIndex - 1) * _rowExtent),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final copy = widget.copy;
    final list = widget.list;
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return BlocBuilder<AdhkarCubit, AdhkarState>(
      bloc: widget.cubit,
      builder: (context, state) {
        final items = state.catalog?.itemsOf(list) ?? const <DhikrItem>[];
        final done = items
            .where((item) => state.countOf(item.itemId) >= item.target)
            .length;
        return AppSheetPanel(
          key: const Key('adhkar_reader_sheet'),
          height: height,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 4),
                child: AppSheetHandle(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        copy.listLabel(list == AdhkarList.morning),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.fixed(
                          20,
                          FontWeight.w700,
                          colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppPill(
                      label: copy.counter(done, items.length),
                      labelKey: const Key('adhkar_reader_sheet_count'),
                      maxLines: 1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: items.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _SheetRow(
                      key: Key('adhkar_reader_sheet_row_${items[i].itemId}'),
                      copy: copy,
                      item: items[i],
                      count: state.countOf(items[i].itemId),
                      current: i == widget.currentIndex,
                      onTap: () => widget.onJump(i),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _SheetRow extends StatelessWidget {
  const _SheetRow({
    super.key,
    required this.copy,
    required this.item,
    required this.count,
    required this.current,
    required this.onTap,
  });

  final AdhkarStrings copy;
  final DhikrItem item;
  final int count;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final done = count >= item.target;
    final font = item.kind == DhikrKind.quran
        ? kQuranFontFamily
        : kDhikrFontFamily;
    return AppInkSurface(
      color: current ? colors.accentSoft : Colors.transparent,
      borderColor: current ? colors.primary : Colors.transparent,
      radius: 18,
      minHeight: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${item.position}',
              style: AppTypography.fixed(
                15,
                FontWeight.w700,
                colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  item.textAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.fixed(
                    19,
                    FontWeight.w400,
                    colors.textPrimary,
                    height: 1.7,
                  ).copyWith(fontFamily: font),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$count / ${item.target}',
            style: AppTypography.fixed(
              15,
              FontWeight.w600,
              colors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          if (done)
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accentStrong,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 16,
                color: colors.onAccentStrong,
              ),
            )
          else
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.border, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}

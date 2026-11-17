import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

import '../adhkar_cubit.dart';
import '../adhkar_state.dart';
import 'adhkar_list_page.dart';
import 'adhkar_style.dart';

/// Caps the text scale inside banners and chips, as the design does (banners
/// wrap instead of clipping at 200%).
final class _ClampScale extends StatelessWidget {
  const _ClampScale({required this.max, required this.child});

  final double max;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: max),
    ),
    child: child,
  );
}

/// A 48 px rounded-square icon button (the list and close buttons).
final class AdhkarSquareButton extends StatelessWidget {
  const AdhkarSquareButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: palette.surface2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: palette.border),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, size: 22, color: palette.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 56 px round previous/next buttons beside the wide column.
final class AdhkarRoundNav extends StatelessWidget {
  const AdhkarRoundNav({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: palette.glow,
          ),
          child: Material(
            color: palette.surface,
            shape: CircleBorder(side: BorderSide(color: palette.border)),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(icon, size: 24, color: palette.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width filled primary button (the completion state's way back).
final class AdhkarFilledAction extends StatelessWidget {
  const AdhkarFilledAction({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: palette.buttonGlow,
      ),
      child: Material(
        color: palette.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: adhkarText(16, FontWeight.w700, palette.onButton),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    final palette = AdhkarPalette.of(context);
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
                          style: adhkarText(
                            19,
                            FontWeight.w700,
                            palette.accent,
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
                        style: adhkarText(
                          widget.wide ? 34 : 28,
                          FontWeight.w400,
                          palette.text,
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
                        style: adhkarText(17, FontWeight.w600, palette.accent),
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
                        Container(
                          key: Key('adhkar_virtue_text_${item.itemId}'),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: palette.card(
                            radius: 20,
                            color: palette.surface2,
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              virtue,
                              style: adhkarText(
                                19,
                                FontWeight.w400,
                                palette.text2,
                                height: 1.9,
                              ).copyWith(fontFamily: kDhikrFontFamily),
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
    final palette = AdhkarPalette.of(context);
    return Semantics(
      button: true,
      expanded: open,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: palette.surface,
        shape: StadiumBorder(side: BorderSide(color: palette.border)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: adhkarText(15, FontWeight.w600, palette.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: palette.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    final palette = AdhkarPalette.of(context);
    return _ClampScale(
      max: 1.3,
      child: Container(
        key: const Key('adhkar_reader_done_bar'),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: palette.soft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.primary),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            Icon(Icons.check_rounded, size: 20, color: palette.accent),
            Text(
              copy.done,
              style: adhkarText(15, FontWeight.w600, palette.text),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.next,
                  style: adhkarText(15, FontWeight.w600, palette.accent),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 18, color: palette.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A banner giving the reason counting is locked: the time window, or the
/// missing Prayer times (with the setup action).
final class AdhkarLockBanner extends StatelessWidget {
  const AdhkarLockBanner({
    super.key,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return _ClampScale(
      max: 1.3,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: palette.card(
          radius: 18,
          color: palette.warnSoft,
          borderColor: palette.warn,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 24, color: palette.warn),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: adhkarText(15, FontWeight.w600, palette.text),
                  ),
                ),
              ],
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AdhkarOutlinedAction(
                  key: const Key('adhkar_reader_setup_button'),
                  label: actionLabel!,
                  borderColor: palette.warn,
                  onTap: onAction!,
                ),
              ),
            ],
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
    final palette = AdhkarPalette.of(context);
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
          Opacity(
            opacity: resetOff ? 0.45 : 1,
            child: Semantics(
              button: true,
              enabled: !resetOff,
              label: copy.resetCount,
              excludeSemantics: true,
              onTap: resetOff ? null : onReset,
              child: Material(
                color: palette.surface2,
                shape: CircleBorder(side: BorderSide(color: palette.border)),
                child: InkWell(
                  key: const Key('adhkar_reader_reset'),
                  onTap: resetOff ? null : onReset,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(
                      Icons.restart_alt,
                      size: 22,
                      color: palette.text,
                    ),
                  ),
                ),
              ),
            ),
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
    final palette = AdhkarPalette.of(context);
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
        color: palette.onButton,
      );
    } else if (locked) {
      face = Icon(
        Icons.lock_outline,
        size: 40 * widget.k,
        color: palette.text2,
      );
    } else {
      face = Text(
        '${widget.count}',
        textScaler: TextScaler.noScaling,
        style: adhkarText(
          36 * widget.k,
          FontWeight.w800,
          palette.onButton,
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
            CustomPaint(
              size: Size(ring, ring),
              painter: AdhkarRingPainter(
                progress: locked ? 0 : progress,
                strokeWidth: 6,
                fill: palette.primary,
                track: palette.track,
              ),
            ),
            Container(
              width: cover,
              height: cover,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.bg,
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
                  color: locked ? palette.surface2 : palette.button,
                  border: locked ? Border.all(color: palette.border) : null,
                  boxShadow: locked ? null : palette.buttonGlow,
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
    final palette = AdhkarPalette.of(context);
    Widget kbd(String label) => Container(
      constraints: const BoxConstraints(minWidth: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: palette.border),
          top: BorderSide(color: palette.border),
          right: BorderSide(color: palette.border),
          bottom: BorderSide(color: palette.border, width: 2),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: adhkarText(13, FontWeight.w600, palette.text, height: 1.3),
        ),
      ),
    );
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
              kbd('Space'),
              const SizedBox(width: 8),
              kbd('Enter'),
              const SizedBox(width: 8),
              Text(
                copy.keyCount,
                style: adhkarText(14, FontWeight.w400, palette.text2),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              kbd('←'),
              const SizedBox(width: 8),
              kbd('→'),
              const SizedBox(width: 8),
              Text(
                copy.keyMove,
                style: adhkarText(14, FontWeight.w400, palette.text2),
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
    final palette = AdhkarPalette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.errorSoft,
                border: Border.all(color: palette.border),
              ),
              child: Icon(Icons.error_outline, size: 44, color: palette.error),
            ),
            const SizedBox(height: 20),
            Text(
              copy.contentUnavailable,
              textAlign: TextAlign.center,
              style: adhkarText(20, FontWeight.w700, palette.text),
            ),
            const SizedBox(height: 20),
            Material(
              color: palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: palette.border),
              ),
              child: InkWell(
                key: const Key('adhkar_retry'),
                onTap: onRetry,
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 6,
                    ),
                    child: Text(
                      copy.retry,
                      textAlign: TextAlign.center,
                      style: adhkarText(16, FontWeight.w600, palette.text),
                    ),
                  ),
                ),
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
    showDialog<bool>(
      context: context,
      barrierColor: AdhkarPalette.of(context).scrim,
      builder: (dialogContext) {
        final palette = AdhkarPalette.of(dialogContext);
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              key: const Key('adhkar_reset_dialog'),
              padding: const EdgeInsets.all(24),
              decoration: palette.card(radius: 28, shadows: palette.glow),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      copy.resetTitle,
                      style: adhkarText(
                        20,
                        FontWeight.w700,
                        palette.text,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      copy.resetBody,
                      style: adhkarText(
                        16,
                        FontWeight.w400,
                        palette.text2,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cancel = _DialogButton(
                          key: const Key('adhkar_reset_cancel'),
                          label: copy.myAdhkarCancel,
                          background: palette.surface2,
                          foreground: palette.text,
                          border: palette.border,
                          onTap: () => Navigator.of(dialogContext).pop(false),
                        );
                        final confirm = _DialogButton(
                          key: const Key('adhkar_reset_confirm'),
                          label: copy.resetConfirm,
                          background: palette.error,
                          foreground: palette.onError,
                          onTap: () => Navigator.of(dialogContext).pop(true),
                        );
                        // Side by side when both fit; stacked when narrow.
                        if (constraints.maxWidth >= 250) {
                          return Row(
                            children: [
                              Expanded(child: cancel),
                              const SizedBox(width: 10),
                              Expanded(child: confirm),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            confirm,
                            const SizedBox(height: 10),
                            cancel,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

final class _DialogButton extends StatelessWidget {
  const _DialogButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: border == null ? BorderSide.none : BorderSide(color: border!),
    ),
    child: InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: adhkarText(16, FontWeight.w700, foreground),
            ),
          ),
        ),
      ),
    ),
  );
}

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
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AdhkarPalette.of(context).scrim,
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
    final palette = AdhkarPalette.of(context);
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
        return Container(
          key: const Key('adhkar_reader_sheet'),
          height: height,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: palette.border),
            boxShadow: palette.glow,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
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
                        style: adhkarText(20, FontWeight.w700, palette.text),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.soft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        copy.counter(done, items.length),
                        key: const Key('adhkar_reader_sheet_count'),
                        maxLines: 1,
                        style: adhkarText(15, FontWeight.w700, palette.accent),
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
    final palette = AdhkarPalette.of(context);
    final done = count >= item.target;
    final font = item.kind == DhikrKind.quran
        ? kQuranFontFamily
        : kDhikrFontFamily;
    return Material(
      color: current ? palette.soft : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: current ? palette.primary : Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.position}',
                    style: adhkarText(15, FontWeight.w700, palette.text2),
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
                        style: adhkarText(
                          19,
                          FontWeight.w400,
                          palette.text,
                          height: 1.7,
                        ).copyWith(fontFamily: font),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$count / ${item.target}',
                  style: adhkarText(15, FontWeight.w600, palette.text2),
                ),
                const SizedBox(width: 10),
                if (done)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.button,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: palette.onButton,
                    ),
                  )
                else
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.border, width: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

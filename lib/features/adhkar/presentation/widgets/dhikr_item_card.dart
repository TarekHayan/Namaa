import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';

import '../adhkar_state.dart';

/// The Arabic display font for dhikr text (registered in pubspec.yaml).
const String kDhikrFontFamily = 'Amiri';

/// The Quran font for verse text — KFGQPC Uthmanic Hafs, bundled unmodified
/// through the Quran Foundation (T081) so the Uthmani script and the QPC
/// Hafs encoding render correctly (FR-019).
const String kQuranFontFamily = 'KFGQPC HAFS';

/// One dhikr card (the prototype's third group): the number badge, the
/// "virtue and source" toggle, the reset button with its tooltip, the
/// Arabic text — dhikr in Amiri, a Quran item's verses in the Quran font —
/// with no English translation line in any language (owner decision D3),
/// the count/target line, and the large count button ("Tap to count (n)"
/// or "Completed"), disabled when the item is complete or the list is not
/// countable. The semantic label is "Count, x of y".
///
/// A Quran item shows its optional preface as a small separate line, then
/// the verses, then "surah: from–to".
final class DhikrItemCard extends StatefulWidget {
  const DhikrItemCard({
    super.key,
    required this.copy,
    required this.locale,
    required this.itemId,
    required this.position,
    required this.target,
    required this.isQuran,
    required this.textAr,
    required this.virtueAr,
    required this.referenceAr,
    required this.surah,
    required this.ayahFrom,
    required this.ayahTo,
    required this.prefaceAr,
    required this.count,
    required this.status,
    required this.countable,
    required this.onCount,
    required this.onReset,
  });

  final AdhkarStrings copy;
  final String locale;
  final String itemId;
  final int position;
  final int target;
  final bool isQuran;
  final String textAr;
  final String? virtueAr;
  final String referenceAr;
  final String? surah;
  final int? ayahFrom;
  final int? ayahTo;
  final String? prefaceAr;
  final int count;
  final AdhkarActionStatus? status;
  final bool countable;
  final VoidCallback onCount;
  final VoidCallback onReset;

  @override
  State<DhikrItemCard> createState() => _DhikrItemCardState();
}

final class _DhikrItemCardState extends State<DhikrItemCard> {
  bool _expanded = false;

  bool get _completed => widget.count >= widget.target;
  bool get _enabled => !_completed && widget.countable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bodyFont = widget.isQuran ? kQuranFontFamily : kDhikrFontFamily;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: colors.primary.withValues(alpha: 0.12),
                  child: Text(
                    '${widget.position}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: colors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextButton(
                    key: Key('adhkar_virtue_toggle_${widget.itemId}'),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      widget.copy.virtueAndSource,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  key: Key('adhkar_reset_${widget.itemId}'),
                  tooltip: widget.copy.resetTooltip,
                  onPressed: widget.onReset,
                  icon: const Icon(Icons.restart_alt_outlined),
                ),
              ],
            ),
            if (widget.isQuran && widget.prefaceAr != null) ...[
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  widget.prefaceAr!,
                  key: Key('adhkar_preface_${widget.itemId}'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: kDhikrFontFamily,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                widget.textAr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: bodyFont,
                  height: 1.9,
                ),
              ),
            ),
            if (widget.isQuran && widget.surah != null) ...[
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  '${widget.surah}: '
                  '${widget.ayahFrom}–${widget.ayahTo}',
                  key: Key('adhkar_surah_${widget.itemId}'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: kDhikrFontFamily,
                  ),
                ),
              ),
            ],
            if (_expanded)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  if (widget.virtueAr != null)
                    Text(
                      '${widget.copy.virtueLabel} ${widget.virtueAr}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.copy.sourceLabel} ${widget.referenceAr}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.copy.target(widget.count, widget.target),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                if (widget.status == AdhkarActionStatus.pending)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (widget.status == AdhkarActionStatus.failed)
                  Icon(Icons.error_outline, size: 16, color: colors.error),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              label: widget.copy.countSemantic(widget.count, widget.target),
              button: true,
              excludeSemantics: true,
              child: FilledButton(
                key: Key('adhkar_count_${widget.itemId}'),
                onPressed: _enabled
                    ? () {
                        widget.onCount();
                        HapticFeedback.selectionClick();
                      }
                    : null,
                child: Text(
                  _completed
                      ? widget.copy.completed
                      : widget.copy.tapToCount(widget.count + 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

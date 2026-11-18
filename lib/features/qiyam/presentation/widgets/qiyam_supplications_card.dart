import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_layout.dart';
import 'package:namma_project/app/theme/app_typography.dart';
import 'package:namma_project/app/widgets/app_card.dart';
import 'package:namma_project/app/widgets/app_ink_surface.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_supplication.dart';

/// The supplications card (approved design, 2026-11-18): the Witr
/// supplication and the Qunut of the reviewed catalog, each in Amiri with its
/// source, selectable, collapsed to four lines with a "Show all" / "Show
/// less" toggle so tonight's question and its recording stay first. The texts
/// come from the catalog, never from code; the names above them are copy.
final class QiyamSupplicationsCard extends StatefulWidget {
  const QiyamSupplicationsCard({
    super.key,
    required this.copy,
    required this.supplications,
  });

  final QiyamStrings copy;
  final List<QiyamSupplication> supplications;

  @override
  State<QiyamSupplicationsCard> createState() => _QiyamSupplicationsCardState();
}

final class _QiyamSupplicationsCardState extends State<QiyamSupplicationsCard> {
  final Set<String> _open = <String>{};

  @override
  Widget build(BuildContext context) {
    if (widget.supplications.isEmpty) return const SizedBox.shrink();
    final colors = AppColors.of(context);
    final copy = widget.copy;
    final textSize = AppLayout.isWide(context) ? 24.0 : 22.0;
    return AppCard(
      key: const Key('qiyam_supplications_card'),
      radius: 16,
      padding: const EdgeInsets.all(20),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                header: true,
                child: Text(
                  copy.supplicationsTitle,
                  style: AppTypography.fixed(
                    20,
                    FontWeight.w600,
                    colors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            for (final supplication in widget.supplications)
              _Supplication(
                copy: copy,
                supplication: supplication,
                textSize: textSize,
                open: _open.contains(supplication.id),
                onToggle: () => setState(() {
                  if (!_open.remove(supplication.id)) {
                    _open.add(supplication.id);
                  }
                }),
              ),
          ],
        ),
      ),
    );
  }
}

final class _Supplication extends StatelessWidget {
  const _Supplication({
    required this.copy,
    required this.supplication,
    required this.textSize,
    required this.open,
    required this.onToggle,
  });

  final QiyamStrings copy;
  final QiyamSupplication supplication;
  final double textSize;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final name = copy.supplicationName(supplication.id);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (name != null) ...[
            Text(
              name,
              style: AppTypography.fixed(
                16,
                FontWeight.w700,
                colors.accentStrong,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              supplication.textAr,
              key: Key('qiyam_supplication_${supplication.id}'),
              maxLines: open ? null : 4,
              overflow: open ? TextOverflow.visible : TextOverflow.ellipsis,
              style: AppTypography.fixed(
                textSize,
                FontWeight.w400,
                colors.textPrimary,
                height: 2.05,
              ).copyWith(fontFamily: 'Amiri'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            supplication.sourceAr,
            key: Key('qiyam_supplication_source_${supplication.id}'),
            style: AppTypography.fixed(
              14,
              FontWeight.w400,
              colors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              button: true,
              expanded: open,
              excludeSemantics: true,
              label: open ? copy.showLess : copy.showAll,
              onTap: onToggle,
              child: AppInkSurface(
                key: Key('qiyam_supplication_toggle_${supplication.id}'),
                color: Colors.transparent,
                radius: 12,
                minHeight: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onTap: onToggle,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        open ? copy.showLess : copy.showAll,
                        style: AppTypography.fixed(
                          14,
                          FontWeight.w700,
                          colors.accentStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: colors.accentStrong,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

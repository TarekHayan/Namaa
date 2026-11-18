import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/qiyam_strings_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_typography.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_card.dart';
import 'package:namma_project/app/widgets/app_segmented_control.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_night.dart';
import 'package:namma_project/features/qiyam/presentation/qiyam_state.dart';

import 'qiyam_details_form.dart';

/// The tonight tracker (approved design, 2026-11-18).
///
/// Unanswered: the question, the best-time note, and the two answers — a tap
/// saves at once, there is no Save button. Answered: the two answers become a
/// two-option switch that stays available all night (no confirmation); "Not
/// yet" is calm — no blame and no red — and "Yes" opens the optional details
/// form. The first "Yes" of a night shows the +30 points moment, which stays
/// until the page is left. Both answers are disabled while recording is
/// paused (a saved schedule is unavailable).
final class QiyamTrackerCard extends StatelessWidget {
  const QiyamTrackerCard({
    super.key,
    required this.copy,
    required this.night,
    required this.form,
    required this.status,
    required this.failureMessageKey,
    required this.celebration,
    required this.onYes,
    required this.onNo,
    required this.onRakahs,
    required this.onWitr,
    required this.onTimes,
    required this.onNote,
  });

  final QiyamStrings copy;
  final QiyamNightState? night;
  final QiyamForm? form;
  final QiyamActionStatus? status;
  final String? failureMessageKey;

  /// True once tonight's first "Yes" earned the points.
  final bool celebration;
  final VoidCallback onYes;
  final VoidCallback onNo;
  final ValueChanged<int> onRakahs;
  final VoidCallback onWitr;
  final void Function(String? startTime, String? endTime) onTimes;
  final ValueChanged<String> onNote;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final locked = night?.editable != true;
    final form = this.form;
    final Widget body;
    if (form == null) {
      body = _Unanswered(copy: copy, locked: locked, onYes: onYes, onNo: onNo);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (celebration && form.performed) ...[
            _PointsMoment(copy: copy),
            const SizedBox(height: 16),
          ],
          AppSegmentedControl(
            key: const Key('qiyam_answer_switch'),
            selectedIndex: form.performed ? 0 : 1,
            onChanged: (index) {
              if (locked) return;
              if (index == 0 && !form.performed) onYes();
              if (index == 1 && form.performed) onNo();
            },
            segments: [
              AppSegment(key: const Key('qiyam_seg_yes'), label: copy.segYes),
              AppSegment(key: const Key('qiyam_seg_no'), label: copy.no),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  copy.detailsNotKept,
                  key: const Key('qiyam_no_kept_note'),
                  style: AppTypography.fixed(
                    14,
                    FontWeight.w400,
                    colors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          if (!form.performed) ...[
            const SizedBox(height: 16),
            _CalmNo(copy: copy),
          ] else ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: colors.border),
            const SizedBox(height: 16),
            QiyamDetailsForm(
              key: ValueKey('qiyam_details_${night?.nightDate}'),
              copy: copy,
              night: night,
              form: form,
              status: status,
              failureMessageKey: failureMessageKey,
              onRakahs: onRakahs,
              onWitr: onWitr,
              onTimes: onTimes,
              onNote: onNote,
            ),
          ],
        ],
      );
    }
    return AppCard(
      key: const Key('qiyam_tracker_card'),
      radius: 16,
      padding: const EdgeInsets.all(20),
      child: body,
    );
  }
}

final class _Unanswered extends StatelessWidget {
  const _Unanswered({
    required this.copy,
    required this.locked,
    required this.onYes,
    required this.onNo,
  });

  final QiyamStrings copy;
  final bool locked;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          copy.didYouPray,
          style: AppTypography.fixed(
            20,
            FontWeight.w600,
            colors.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          copy.bestTime,
          style: AppTypography.fixed(
            14,
            FontWeight.w400,
            colors.textSecondary,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          key: const Key('qiyam_yes'),
          label: copy.yesXp,
          onPressed: locked ? null : onYes,
          look: AppButtonLook.refined,
          size: AppButtonSize.small,
          expanded: true,
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: locked ? 0.6 : 1,
          child: AppButton(
            key: const Key('qiyam_no'),
            label: copy.no,
            onPressed: locked ? null : onNo,
            look: AppButtonLook.refined,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            expanded: true,
          ),
        ),
      ],
    );
  }
}

/// The one-time "Qiyam complete! +30 points" moment.
final class _PointsMoment extends StatelessWidget {
  const _PointsMoment({required this.copy});

  final QiyamStrings copy;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      liveRegion: true,
      child: AppCard(
        key: const Key('qiyam_celebration'),
        tone: AppCardTone.accent,
        radius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accentStrong,
                boxShadow: colors.buttonShadow,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 22,
                color: colors.onAccentStrong,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                copy.xpEarned,
                style: AppTypography.fixed(
                  20,
                  FontWeight.w700,
                  colors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The calm "Not yet" state: a moon, and the reminder that tonight's answer
/// can still change.
final class _CalmNo extends StatelessWidget {
  const _CalmNo({required this.copy});

  final QiyamStrings copy;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      key: const Key('qiyam_calm_no'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surfaceSecondary,
            border: Border.all(color: colors.border),
          ),
          child: Icon(
            Icons.dark_mode_outlined,
            size: 22,
            color: colors.accentStrong,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            copy.noCalm,
            style: AppTypography.fixed(
              16,
              FontWeight.w400,
              colors.textPrimary,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

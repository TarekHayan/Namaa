import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_sheets.dart';

/// Two actions side by side, stacked when the width is below [minInlineWidth].
/// Stacked, [primary] comes first; side by side it is first too unless
/// [primaryFirstInline] is false (a dialog that puts Cancel first).
class AppButtonPair extends StatelessWidget {
  const AppButtonPair({
    super.key,
    required this.primary,
    required this.secondary,
    this.minInlineWidth = 250,
    this.primaryFirstInline = true,
  });

  final Widget primary;
  final Widget secondary;
  final double minInlineWidth;
  final bool primaryFirstInline;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= minInlineWidth) {
        return Row(
          children: [
            Expanded(child: primaryFirstInline ? primary : secondary),
            const SizedBox(width: 10),
            Expanded(child: primaryFirstInline ? secondary : primary),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [primary, const SizedBox(height: 10), secondary],
      );
    },
  );
}

/// Opens a confirmation dialog with a destructive confirm button and a
/// cancel button; resolves to true when the person confirms. Callers pass the
/// translated texts; the keys go on the panel and the two buttons.
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String cancelLabel,
  required String confirmLabel,
  Key? panelKey,
  Key? cancelKey,
  Key? confirmKey,
}) => showAppDialog<bool>(
  context: context,
  builder: (dialogContext) {
    final colors = AppColors.of(dialogContext);
    return AppCard(
      key: panelKey,
      radius: 28,
      padding: const EdgeInsets.all(24),
      elevated: true,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTypography.fixed(
                20,
                FontWeight.w700,
                colors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: AppTypography.fixed(
                16,
                FontWeight.w400,
                colors.textSecondary,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 20),
            AppButtonPair(
              primaryFirstInline: false,
              primary: AppButton(
                key: confirmKey,
                label: confirmLabel,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                look: AppButtonLook.refined,
                variant: AppButtonVariant.danger,
                tuning: const AppButtonTuning(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  fontWeight: FontWeight.w700,
                  labelHeight: 1.5,
                ),
              ),
              secondary: AppButton(
                key: cancelKey,
                label: cancelLabel,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                look: AppButtonLook.refined,
                variant: AppButtonVariant.secondary,
                tuning: const AppButtonTuning(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  fontWeight: FontWeight.w700,
                  labelHeight: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
);

/// An in-place delete confirmation: a tinted card with a title, an optional
/// subtitle (user text, so its direction follows the text), a body and the
/// destructive and cancel buttons. Both buttons are disabled while [busy].
/// Callers pass the translated texts; the keys go on the two buttons.
class AppInlineConfirmation extends StatelessWidget {
  const AppInlineConfirmation({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    this.busy = false,
    this.confirmKey,
    this.cancelKey,
  });

  final String title;
  final String? subtitle;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool busy;
  final Key? confirmKey;
  final Key? cancelKey;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      tone: AppCardTone.error,
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTypography.fixed(17, FontWeight.w700, colors.textPrimary),
          ),
          if (subtitle != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                subtitle!,
                textDirection: AppTypography.directionFor(
                  subtitle!,
                  Directionality.of(context),
                ),
                style: AppTypography.fixed(
                  14,
                  FontWeight.w600,
                  colors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            body,
            style: AppTypography.fixed(
              14,
              FontWeight.w400,
              colors.textPrimary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 14),
          AppButtonPair(
            primary: AppButton(
              key: confirmKey,
              label: confirmLabel,
              onPressed: busy ? null : onConfirm,
              look: AppButtonLook.refined,
              variant: AppButtonVariant.danger,
              size: AppButtonSize.small,
              tuning: const AppButtonTuning(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              ),
            ),
            secondary: AppButton(
              key: cancelKey,
              label: cancelLabel,
              onPressed: busy ? null : onCancel,
              look: AppButtonLook.refined,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              fill: colors.surface,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_card.dart';

/// How serious an inline note is.
enum AppNoticeTone {
  /// A limit or a caution: warning icon, main text.
  warning,

  /// A rejected input: error text and icon, semi-bold.
  error,
}

/// A line of inline text with a leading icon, for limits and field errors.
/// Callers pass the translated text.
class AppInlineNote extends StatelessWidget {
  const AppInlineNote({
    super.key,
    required this.text,
    this.tone = AppNoticeTone.warning,
  });

  final String text;
  final AppNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final error = tone == AppNoticeTone.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(
            Icons.error_outline,
            size: 18,
            color: error ? colors.errorText : colors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.fixed(
              14,
              error ? FontWeight.w600 : FontWeight.w400,
              error ? colors.errorText : colors.textPrimary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// A tinted notice block: an icon, a message and an optional action button.
/// [compact] is the dense form used over a reader's controls (smaller text and
/// corners). Callers pass the translated message and action label.
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    required this.icon,
    this.compact = false,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.messageKey,
  });

  final String message;
  final IconData icon;
  final bool compact;

  /// The action button; shown only when both [actionLabel] and [onAction]
  /// are set.
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final Key? messageKey;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasAction = actionLabel != null && onAction != null;
    return AppCard(
      tone: AppCardTone.warning,
      radius: compact ? 18 : 20,
      constraints: compact ? const BoxConstraints(minHeight: 52) : null,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 12 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: compact ? 0 : 2),
                child: Icon(icon, size: 24, color: colors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  key: messageKey,
                  style: AppTypography.fixed(
                    compact ? 15 : 16,
                    FontWeight.w600,
                    colors.textPrimary,
                    height: compact ? 1.5 : 1.6,
                  ),
                ),
              ),
            ],
          ),
          if (hasAction) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                key: actionKey,
                label: actionLabel!,
                onPressed: onAction,
                look: AppButtonLook.refined,
                variant: AppButtonVariant.outline,
                size: AppButtonSize.small,
                color: colors.warning,
                tuning: const AppButtonTuning(labelHeight: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

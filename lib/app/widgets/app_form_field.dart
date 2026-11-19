import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_notice.dart';

/// A form field with its label above it.
class AppLabeledField extends StatelessWidget {
  const AppLabeledField({super.key, required this.label, required this.field});

  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: AppTypography.fixed(
          14,
          FontWeight.w700,
          AppColors.of(context).textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      field,
    ],
  );
}

/// The shared input look for a text field with a character counter: a filled
/// field with 16 px corners, a hairline border that becomes a 1.5 px primary
/// border while focused and a 1.5 px error border when invalid, the error
/// (with its icon) under the start side and the counter, always left to
/// right, under the end side. Callers pass the translated texts and counter.
InputDecoration appCountedFieldDecoration(
  AppColors colors, {
  required String counterText,
  required Key counterKey,
  required bool counterError,
  String? errorText,
  String? helperText,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecoration(
    filled: true,
    fillColor: colors.surfaceSecondary,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(colors.border, 1),
    enabledBorder: border(colors.border, 1),
    focusedBorder: border(colors.primary, 1.5),
    errorBorder: border(colors.error, 1.5),
    focusedErrorBorder: border(colors.error, 1.5),
    error: errorText == null
        ? null
        : AppInlineNote(text: errorText, tone: AppNoticeTone.error),
    helper: helperText == null
        ? null
        : Text(
            helperText,
            style: AppTypography.fixed(
              14,
              FontWeight.w400,
              colors.textSecondary,
              height: 1.6,
            ),
          ),
    helperMaxLines: 3,
    counter: Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        counterText,
        key: counterKey,
        style: AppTypography.fixed(
          14,
          FontWeight.w400,
          counterError ? colors.errorText : colors.textSecondary,
        ),
      ),
    ),
  );
}

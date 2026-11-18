import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A 24-hour time input: a filled field for typing `HH:mm` (always left to
/// right) with a clock button that opens the platform time picker. It holds no
/// validation: the owner of the [controller] decides whether the text is valid,
/// passes [invalid] to draw the error border and shows the message itself.
/// Callers pass the translated [pickTooltip].
class AppTimeField extends StatelessWidget {
  const AppTimeField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.pickTooltip,
    this.invalid = false,
    this.enabled = true,
    this.fieldKey,
    this.pickerKey,
  });

  final TextEditingController controller;

  /// Called with the new text after typing and after a picker choice.
  final ValueChanged<String> onChanged;
  final String pickTooltip;
  final bool invalid;
  final bool enabled;

  /// The key of the text field.
  final Key? fieldKey;

  /// The key of the clock button.
  final Key? pickerKey;

  static final RegExp _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  static TimeOfDay? _parse(String text) {
    if (!_time.hasMatch(text)) return null;
    return TimeOfDay(
      hour: int.parse(text.substring(0, 2)),
      minute: int.parse(text.substring(3, 5)),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parse(controller.text) ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final text =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
    final outline = invalid ? colors.error : colors.border;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextField(
        key: fieldKey,
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        keyboardType: TextInputType.datetime,
        textDirection: TextDirection.ltr,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
          LengthLimitingTextInputFormatter(5),
        ],
        style: AppTypography.fixed(
          16,
          FontWeight.w400,
          colors.textPrimary,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.surfaceSecondary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: border(outline, invalid ? 1.5 : 1),
          enabledBorder: border(outline, invalid ? 1.5 : 1),
          disabledBorder: border(colors.border, 1),
          focusedBorder: border(invalid ? colors.error : colors.primary, 1.5),
          suffixIcon: IconButton(
            key: pickerKey,
            tooltip: pickTooltip,
            onPressed: enabled ? () => _pick(context) : null,
            icon: Icon(
              Icons.schedule_rounded,
              size: 20,
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_menu_design.dart';

/// One consistent form selector for tasks, maps, and future sections.
/// It preserves Flutter's keyboard, screen-reader, and form behavior.
class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.initialValue,
    required this.items,
    required this.onChanged,
    this.decoration,
    this.isExpanded = true,
  });

  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final input = decoration ?? const InputDecoration();
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.border),
    );

    final field = DropdownButtonFormField<T>(
      initialValue: initialValue,
      items: items,
      onChanged: onChanged,
      isExpanded: isExpanded,
      dropdownColor: colors.surface,
      borderRadius: AppMenuDesign.radius,
      menuMaxHeight: AppMenuDesign.maxHeight,
      elevation: 12,
      itemHeight: 52,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 22,
        color: colors.textSecondary,
      ),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: input.copyWith(
        filled: input.filled ?? true,
        fillColor: input.fillColor ?? colors.surfaceSecondary,
        isDense: input.isDense ?? true,
        contentPadding:
            input.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: input.border ?? enabledBorder,
        enabledBorder: input.enabledBorder ?? enabledBorder,
        focusedBorder:
            input.focusedBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.primary, width: 1.4),
            ),
      ),
    );
    // Floating labels sit on the top edge of the field. Keep that edge away
    // from the previous control wherever this shared selector is used.
    if (input.labelText?.isNotEmpty != true) return field;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: field,
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_notice.dart';

/// A span of the day from [start] to [end] on a 24-hour clock. [end] may be
/// earlier than [start], which means the span crosses midnight (Isha 19:12 to
/// Fajr 04:51, for example). Callers use it to build the validator they pass
/// to [AppTimeField], and to order two times inside the span with [offsetOf].
final class AppTimeWindow {
  const AppTimeWindow({required this.start, required this.end});

  final TimeOfDay start;
  final TimeOfDay end;

  static int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  /// The minutes from [start] forward to [time] around the clock (0..1439),
  /// so a time after midnight orders after one before it.
  int offsetOf(TimeOfDay time) => (_minutes(time) - _minutes(start)) % 1440;

  /// The length of the window in minutes.
  int get length => offsetOf(end);

  /// Whether [time] is inside the window, both ends included.
  bool contains(TimeOfDay time) => offsetOf(time) <= length;

  /// The time [minutes] after [time], on the 24-hour clock.
  static TimeOfDay shifted(TimeOfDay time, int minutes) {
    final total = (_minutes(time) + minutes) % 1440;
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }
}

/// A 24-hour time field the user cannot type into. The whole field is the tap
/// target (a tap, Enter or Space on the focused field): it opens the platform
/// clock dial, the same Material time picker the Tasks editor uses but dial
/// only, with no switch to keyboard entry. It shows the chosen time in the
/// locale's format (always left to right) and a clock icon.
///
/// The field holds no rules. A pick goes to [validator] first: a message means
/// the time is refused, so [onPicked] is not called and the message shows under
/// the field until the next valid pick or until [value] changes; null accepts
/// it. A cancelled dial changes nothing. Callers pass the translated
/// [semanticLabel] (the field's name), [pickHint] (what a tap does) and
/// [placeholder] (an empty field), and the error messages the [validator]
/// returns.
class AppTimeField extends StatefulWidget {
  const AppTimeField({
    super.key,
    required this.value,
    required this.onPicked,
    required this.semanticLabel,
    required this.pickHint,
    this.placeholder = '--:--',
    this.initialTime,
    this.validator,
    this.enabled = true,
    this.fieldKey,
    this.errorKey,
  });

  /// The accepted time, or null while the field is empty.
  final TimeOfDay? value;

  /// Called with a pick the [validator] accepted.
  final ValueChanged<TimeOfDay> onPicked;

  /// The field's name for screen readers (usually the visible label).
  final String semanticLabel;

  /// What a tap does, read after the name ("Pick a time").
  final String pickHint;

  /// Shown while [value] is null.
  final String placeholder;

  /// Where the dial opens when [value] is null; the current time otherwise.
  final TimeOfDay? initialTime;

  /// Returns the error message for a refused pick, or null to accept it.
  final String? Function(TimeOfDay picked)? validator;

  final bool enabled;

  /// The key of the tap target (the field itself, without its error line).
  final Key? fieldKey;

  /// The key of the error line under the field.
  final Key? errorKey;

  /// [time] in the locale's 24-hour format, as the field shows it. Callers use
  /// it to put times into their own messages.
  static String format(BuildContext context, TimeOfDay time) =>
      MaterialLocalizations.of(
        context,
      ).formatTimeOfDay(time, alwaysUse24HourFormat: true);

  @override
  State<AppTimeField> createState() => _AppTimeFieldState();
}

class _AppTimeFieldState extends State<AppTimeField> {
  final FocusNode _focus = FocusNode(debugLabel: 'AppTimeField');
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(AppTimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new accepted value (or a disabled field) answers the old refusal.
    if (oldWidget.value != widget.value || !widget.enabled) _error = null;
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_focusChanged)
      ..dispose();
    super.dispose();
  }

  void _focusChanged() => setState(() {});

  Future<void> _pick() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: widget.value ?? widget.initialTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.dialOnly,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final message = widget.validator?.call(picked);
    if (message != null) {
      setState(() => _error = message);
      return;
    }
    setState(() => _error = null);
    widget.onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final invalid = _error != null;
    final value = widget.value;
    final shown = value == null
        ? widget.placeholder
        : AppTimeField.format(context, value);
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
    final outline = invalid ? colors.error : colors.border;
    final field = Semantics(
      container: true,
      button: true,
      enabled: widget.enabled,
      focusable: widget.enabled,
      focused: _focus.hasFocus,
      label: widget.semanticLabel,
      value: shown,
      hint: widget.enabled ? widget.pickHint : null,
      onTap: widget.enabled ? _pick : null,
      excludeSemantics: true,
      child: InkWell(
        key: widget.fieldKey,
        focusNode: _focus,
        borderRadius: BorderRadius.circular(16),
        onTap: widget.enabled ? _pick : null,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: InputDecorator(
            isFocused: _focus.hasFocus,
            decoration: InputDecoration(
              enabled: widget.enabled,
              filled: true,
              fillColor: colors.surfaceSecondary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: border(outline, invalid ? 1.5 : 1),
              enabledBorder: border(outline, invalid ? 1.5 : 1),
              disabledBorder: border(colors.border, 1),
              focusedBorder: border(
                invalid ? colors.error : colors.primary,
                1.5,
              ),
              suffixIcon: Icon(
                Icons.schedule_rounded,
                size: 20,
                color: colors.textSecondary,
              ),
            ),
            child: Text(
              shown,
              style: AppTypography.fixed(
                16,
                FontWeight.w400,
                value == null ? colors.textSecondary : colors.textPrimary,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ),
      ),
    );
    if (_error == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: AppInlineNote(
            key: widget.errorKey,
            text: _error!,
            tone: AppNoticeTone.error,
          ),
        ),
      ],
    );
  }
}

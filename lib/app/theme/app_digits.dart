import 'package:intl/intl.dart' show DateFormat;

/// Namaa shows Latin digits (0123456789) in every language (owner decision,
/// 2026-11-18). Without this, Arabic dates and times from `intl` (prayer
/// times, Adhkar and Qiyam times, the time picker, conflict stamps) use
/// Arabic-Indic digits while counts and percentages use Latin ones, so one
/// screen mixed both.
///
/// It sets `intl`'s default for new `DateFormat`s, so it runs once at
/// startup (from the composition root) before any screen formats a time.
void useLatinDigits() {
  for (final locale in const ['ar', 'ar_EG']) {
    DateFormat.useNativeDigitsByDefaultFor(locale, false);
  }
}

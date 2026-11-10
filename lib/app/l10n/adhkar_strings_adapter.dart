import 'generated/app_localizations.dart';

/// Adhkar screen copy helpers over the generated localizations (the same
/// pattern as the Prayer adapter). The adhkar and supplication texts
/// themselves come from the reviewed catalog, never from these resources.
final class AdhkarStrings {
  const AdhkarStrings(this.copy);

  final FoundationLocalizations copy;

  String get title => copy.adhkarTitle;
  String get subtitle => copy.adhkarSubtitle;
  String tabLabel(bool morning) =>
      morning ? copy.adhkarTabMorning : copy.adhkarTabEvening;
  String progress(String list, int count, int total) =>
      copy.adhkarProgress(list, count, total);
  String percent(int percent) => copy.adhkarPercent(percent);
  String completedSummary(int completed) =>
      copy.adhkarCompletedSummary(completed);
  String startsAt(String time) => copy.adhkarStartsAt(time);
  String get setupPrompt => copy.adhkarSetupPrompt;
  String get virtueAndSource => copy.adhkarVirtueAndSource;
  String get virtueLabel => copy.adhkarVirtueLabel;
  String get sourceLabel => copy.adhkarSourceLabel;
  String get resetTooltip => copy.adhkarResetTooltip;
  String target(int count, int target) => copy.adhkarTarget(count, target);
  String tapToCount(int nextCount) => copy.adhkarTapToCountN(nextCount);
  String get completed => copy.adhkarCompleted;
  String countSemantic(int count, int target) =>
      copy.adhkarCountSemantic(count, target);
  String streak(int days) => copy.adhkarStreak(days);
  String get setComplete => copy.adhkarSetComplete;
  String get contentUnavailable => copy.adhkarContentUnavailable;
  String get countingLocked => copy.adhkarCountingLocked;
  String get openPrayerSetup => copy.adhkarOpenPrayerSetup;
}

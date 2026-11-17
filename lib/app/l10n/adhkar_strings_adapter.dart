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
  String get quranAttribution => copy.quranAttribution;

  // -- My Adhkar (Story 5) ---------------------------------------------------

  String get myAdhkarTab => copy.myAdhkarTab;
  String get myAdhkarHeading => copy.myAdhkarHeading;
  String get myAdhkarNote => copy.myAdhkarNote;
  String get myAdhkarLoadFailed => copy.myAdhkarLoadFailed;
  String get myAdhkarCreateGroup => copy.myAdhkarCreateGroup;
  String get myAdhkarCreateGroupDisabled => copy.myAdhkarCreateGroupDisabled;
  String groupEntries(int count) => copy.myAdhkarGroupEntries(count);
  String get myAdhkarRename => copy.myAdhkarRename;
  String get myAdhkarDelete => copy.myAdhkarDelete;
  String get myAdhkarGroupSheetTitleCreate =>
      copy.myAdhkarGroupSheetTitleCreate;
  String get myAdhkarGroupSheetTitleRename =>
      copy.myAdhkarGroupSheetTitleRename;
  String get myAdhkarGroupNameLabel => copy.myAdhkarGroupNameLabel;
  String counter(int used, int limit) => copy.myAdhkarCounter(used, limit);
  String get myAdhkarGroupNameInvalid => copy.myAdhkarGroupNameInvalid;
  String get myAdhkarGroupDeleteTitle => copy.myAdhkarGroupDeleteTitle;
  String groupDeleteBody(int count) => copy.myAdhkarGroupDeleteBody(count);
  String get myAdhkarCancel => copy.myAdhkarCancel;
  String get myAdhkarSave => copy.myAdhkarSave;
  String get myAdhkarEmptyTitle => copy.myAdhkarEmptyTitle;
  String get myAdhkarEmptyBody => copy.myAdhkarEmptyBody;
  String get myAdhkarAdd => copy.myAdhkarAdd;
  String get myAdhkarAddDisabled => copy.myAdhkarAddDisabled;
  String get myAdhkarGroupEmpty => copy.myAdhkarGroupEmpty;
  String get myAdhkarBackToGroups => copy.myAdhkarBackToGroups;
  String otherGroups(String names) => copy.myAdhkarOtherGroups(names);
  String get myAdhkarEdit => copy.myAdhkarEdit;
  String get myAdhkarCopy => copy.myAdhkarCopy;
  String get myAdhkarCopied => copy.myAdhkarCopied;
  String get myAdhkarEntrySheetTitleAdd => copy.myAdhkarEntrySheetTitleAdd;
  String get myAdhkarEntrySheetTitleEdit => copy.myAdhkarEntrySheetTitleEdit;
  String get myAdhkarTextLabel => copy.myAdhkarTextLabel;
  String get myAdhkarTextHint => copy.myAdhkarTextHint;
  String get myAdhkarSourceLabel => copy.myAdhkarSourceLabel;
  String get myAdhkarSourceHint => copy.myAdhkarSourceHint;
  String get myAdhkarGroupsLabel => copy.myAdhkarGroupsLabel;
  String get myAdhkarTextInvalid => copy.myAdhkarTextInvalid;
  String get myAdhkarSourceInvalid => copy.myAdhkarSourceInvalid;
  String get myAdhkarGroupSetInvalid => copy.myAdhkarGroupSetInvalid;
  String get myAdhkarGroupDeleted => copy.myAdhkarGroupDeleted;
  String get myAdhkarItemDeleted => copy.myAdhkarItemDeleted;
  String get myAdhkarGroupUnknown => copy.myAdhkarGroupUnknown;
  String get myAdhkarItemUnknown => copy.myAdhkarItemUnknown;
  String get myAdhkarSaveFailed => copy.myAdhkarSaveFailed;
  String get myAdhkarEntryDeleteTitle => copy.myAdhkarEntryDeleteTitle;
  String get myAdhkarEntryDeleteBody => copy.myAdhkarEntryDeleteBody;

  /// The list separator for the "also in" line: the Arabic comma in Arabic.
  String get listSeparator => copy.localeName.startsWith('ar') ? '، ' : ', ';
}

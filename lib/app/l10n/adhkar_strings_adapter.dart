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

  /// The list's own name ("Morning adhkar"), used in the progress card and as
  /// the reader's title; the tab labels are shorter in English.
  String listLabel(bool morning) =>
      morning ? copy.adhkarListMorning : copy.adhkarListEvening;
  String progress(String list, int count, int total) =>
      copy.adhkarProgress(list, count, total);
  String percent(int percent) => copy.adhkarPercent(percent);
  String doneCount(int count) => copy.adhkarDoneCount(count);
  String startsAt(String time) => copy.adhkarStartsAt(time);
  String get setupPrompt => copy.adhkarSetupPrompt;
  String countSemantic(int count, int target) =>
      copy.adhkarCountSemantic(count, target);
  String streak(int days) => copy.adhkarStreak(days);
  String get contentUnavailable => copy.adhkarContentUnavailable;
  String get countingLocked => copy.adhkarCountingLocked;
  String get openPrayerSetup => copy.adhkarOpenPrayerSetup;
  String get quranAttribution => copy.quranAttribution;
  String get start => copy.adhkarStart;
  String continueFrom(int position) => copy.adhkarContinueFrom(position);
  String get readAgain => copy.adhkarReadAgain;
  String get completeTitle => copy.adhkarCompleteTitle;
  String get points => copy.adhkarPoints;
  String get backToAdhkar => copy.adhkarBackToAdhkar;
  String get retry => copy.adhkarRetry;
  String get syncRow => copy.adhkarConflicts;

  // -- The reader ------------------------------------------------------------

  String get listButton => copy.adhkarListButton;
  String get close => copy.adhkarClose;
  String get resetCount => copy.adhkarResetCount;
  String get virtue => copy.adhkarVirtue;
  String get done => copy.adhkarDone;
  String get next => copy.adhkarNext;
  String repeat(int count) => copy.adhkarRepeat(count);
  String position(int position, int total) =>
      copy.adhkarPosition(position, total);
  String get resetTitle => copy.adhkarResetTitle;
  String get resetBody => copy.adhkarResetBody;
  String get resetConfirm => copy.adhkarResetConfirm;
  String get keyCount => copy.adhkarKeyCount;
  String get keyMove => copy.adhkarKeyMove;
  String get previousItem => copy.adhkarPreviousItem;
  String get nextItem => copy.adhkarNextItem;

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
  String get menuLabel => copy.myAdhkarMenuLabel;
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

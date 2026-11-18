import 'generated/app_localizations.dart';

/// Qiyam screen copy helpers over the generated localizations (the same
/// pattern as the Adhkar adapter). The supplication texts themselves come
/// from the reviewed catalog, never from these resources.
final class QiyamStrings {
  const QiyamStrings(this.copy);

  final FoundationLocalizations copy;

  String get title => copy.qiyamTitle;
  String get subtitle => copy.qiyamSubtitle;
  String lastThird(String time) => copy.qiyamLastThird(time);
  String get lastThirdUnavailable => copy.qiyamLastThirdUnavailable;
  String get openPrayerSetup => copy.qiyamOpenPrayerSetup;
  String get didYouPray => copy.qiyamDidYouPray;
  String get bestTime => copy.qiyamBestTime;
  String get yesXp => copy.qiyamYesXp;
  String get no => copy.qiyamNo;
  String get rakahsLabel => copy.qiyamRakahsLabel;
  String rakahsCount(int count) => copy.qiyamRakahsCount(count);
  String get startTime => copy.qiyamStartTime;
  String get endTime => copy.qiyamEndTime;
  String get witr => copy.qiyamWitr;
  String get notesLabel => copy.qiyamNotesLabel;
  String get notesPlaceholder => copy.qiyamNotesPlaceholder;
  String noteCounter(int count) => copy.qiyamNoteCounter(count);
  String get supplicationsTitle => copy.qiyamSupplicationsTitle;
  String get saving => copy.qiyamSaving;
  String get saved => copy.qiyamSaved;
  String get saveFailed => copy.qiyamSaveFailed;
  String get nightChanged => copy.qiyamNightChanged;
  String get recordingLocked => copy.qiyamRecordingLocked;
  String get readOnly => copy.qiyamReadOnly;
  String get xpEarned => copy.qiyamXpEarned;
  String streak(int nights) => copy.qiyamStreak(nights);
  String get streakFailed => copy.qiyamStreakFailed;
  String get historyTitle => copy.qiyamHistoryTitle;
  String historyPrayedWithWitr(int count) =>
      copy.qiyamHistoryPrayedWithWitr(count);
  String historyPrayed(int count) => copy.qiyamHistoryPrayed(count);
  String get historyNotPerformed => copy.qiyamHistoryNotPerformed;
  String get historyNotRecorded => copy.qiyamHistoryNotRecorded;
  String get historyLoadMore => copy.qiyamHistoryLoadMore;
  String get historyFailed => copy.qiyamHistoryFailed;
  String get retry => copy.retry;
  String get detailsNotKept => copy.qiyamNightNotPerformedDetails;
  String get noteTooLong => copy.qiyamNightNoteTooLong;
  String get invalidTime => copy.qiyamNightInvalidTime;
  String get invalidRakahs => copy.qiyamNightInvalidRakahs;
  String get segYes => copy.qiyamSegYes;
  String get noCalm => copy.qiyamNoCalm;
  String get detailsTitle => copy.qiyamDetailsTitle;
  String get showAll => copy.qiyamShowAll;
  String get showLess => copy.qiyamShowLess;
  String get pickTime => copy.qiyamPickTime;
  String get nightDetailsTitle => copy.qiyamNightDetailsTitle;
  String get detailStatus => copy.qiyamDetailStatus;
  String get detailWitr => copy.qiyamDetailWitr;
  String get detailPrayed => copy.qiyamDetailPrayed;
  String get detailNo => copy.qiyamDetailNo;
  String get close => copy.qiyamClose;
  String get noNote => copy.qiyamNoNote;
  String get conflictBack => copy.qiyamConflictBack;
  String get conflictTonight => copy.qiyamConflictTonight;
  String conflictNight(String date) => copy.qiyamConflictNight(date);
  String get conflictActive => copy.qiyamConflictActive;
  String get conflictRetained => copy.qiyamConflictRetained;
  String get conflictReadOnly => copy.qiyamConflictReadOnly;
  String get conflicts => copy.qiyamConflicts;
  String conflictAnswerYes(int count, {required bool witr}) => witr
      ? copy.qiyamConflictAnswerYesWitr(count)
      : copy.qiyamConflictAnswerYes(count);
  String today(String time) => copy.adhkarSyncToday(time);
  String yesterday(String time) => copy.adhkarSyncYesterday(time);

  /// The name shown above a supplication, by its catalog id; null for an id
  /// with no name (the card then shows only the text).
  String? supplicationName(String id) => switch (id) {
    's1' => copy.qiyamSupplicationWitr,
    's2' => copy.qiyamSupplicationQunut,
    _ => null,
  };
}

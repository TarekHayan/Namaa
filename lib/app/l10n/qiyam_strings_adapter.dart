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

  /// The localized copy for a command failure's message key; unknown keys
  /// fall back to the generic save-failed copy.
  String failure(String messageKey) => switch (messageKey) {
    'qiyam.night.invalid_rakahs' => copy.qiyamNightInvalidRakahs,
    'qiyam.night.invalid_time' => copy.qiyamNightInvalidTime,
    'qiyam.night.note_too_long' => copy.qiyamNightNoteTooLong,
    'qiyam.night.not_performed_details' => copy.qiyamNightNotPerformedDetails,
    _ => copy.qiyamSaveFailed,
  };
}

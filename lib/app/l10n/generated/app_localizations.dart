import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of FoundationLocalizations
/// returned by `FoundationLocalizations.of(context)`.
///
/// Applications need to include `FoundationLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: FoundationLocalizations.localizationsDelegates,
///   supportedLocales: FoundationLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the FoundationLocalizations.supportedLocales
/// property.
abstract class FoundationLocalizations {
  FoundationLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static FoundationLocalizations of(BuildContext context) {
    return Localizations.of<FoundationLocalizations>(
      context,
      FoundationLocalizations,
    )!;
  }

  static const LocalizationsDelegate<FoundationLocalizations> delegate =
      _FoundationLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Namaa'**
  String get appTitle;

  /// No description provided for @todayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTitle;

  /// No description provided for @todayXp.
  ///
  /// In en, this message translates to:
  /// **'XP earned today'**
  String get todayXp;

  /// No description provided for @todayOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get todayOpen;

  /// No description provided for @todayCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get todayCompleted;

  /// No description provided for @todayStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get todayStreak;

  /// No description provided for @todayDoFirst.
  ///
  /// In en, this message translates to:
  /// **'Start with what matters'**
  String get todayDoFirst;

  /// No description provided for @todayOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get todayOverdue;

  /// No description provided for @todayNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks scheduled today'**
  String get todayNoTasks;

  /// No description provided for @todayNoHabits.
  ///
  /// In en, this message translates to:
  /// **'No habits due today'**
  String get todayNoHabits;

  /// No description provided for @todayShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get todayShowMore;

  /// No description provided for @todayLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading this section…'**
  String get todayLoading;

  /// No description provided for @todaySourceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This section is unavailable right now.'**
  String get todaySourceUnavailable;

  /// No description provided for @todayOutdated.
  ///
  /// In en, this message translates to:
  /// **'Showing older information. Try again to update it.'**
  String get todayOutdated;

  /// No description provided for @todayPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get todayPreferences;

  /// No description provided for @todayLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get todayLanguage;

  /// No description provided for @todayAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get todayAppearance;

  /// No description provided for @todayEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get todayEnglish;

  /// No description provided for @todayArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get todayArabic;

  /// No description provided for @todaySystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get todaySystem;

  /// No description provided for @todayLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get todayLight;

  /// No description provided for @todayDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get todayDark;

  /// No description provided for @foundationReady.
  ///
  /// In en, this message translates to:
  /// **'Namaa is ready'**
  String get foundationReady;

  /// No description provided for @foundationBootstrapRecoverable.
  ///
  /// In en, this message translates to:
  /// **'Namaa could not finish starting. Please try again.'**
  String get foundationBootstrapRecoverable;

  /// No description provided for @foundationBootstrapBlocking.
  ///
  /// In en, this message translates to:
  /// **'Namaa could not start safely.'**
  String get foundationBootstrapBlocking;

  /// No description provided for @foundationLocaleRecoverable.
  ///
  /// In en, this message translates to:
  /// **'Your language preference could not be saved.'**
  String get foundationLocaleRecoverable;

  /// No description provided for @foundationThemeRecoverable.
  ///
  /// In en, this message translates to:
  /// **'Your appearance preference could not be saved.'**
  String get foundationThemeRecoverable;

  /// No description provided for @foundationRouteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This route is unavailable.'**
  String get foundationRouteUnavailable;

  /// No description provided for @foundationPlatformRecoverable.
  ///
  /// In en, this message translates to:
  /// **'This platform capability could not be verified.'**
  String get foundationPlatformRecoverable;

  /// No description provided for @foundationGenericFailure.
  ///
  /// In en, this message translates to:
  /// **'Namaa needs attention before it can continue.'**
  String get foundationGenericFailure;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tasksSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your tasks.'**
  String get tasksSignInRequired;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @tasksFilterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tasksFilterToday;

  /// No description provided for @tasksFilterUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get tasksFilterUrgent;

  /// No description provided for @tasksFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tasksFilterAll;

  /// No description provided for @tasksFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tasksFilterCompleted;

  /// No description provided for @tasksFilterHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tasksFilterHistory;

  /// No description provided for @tasksFilterOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get tasksFilterOverdue;

  /// No description provided for @tasksViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get tasksViewList;

  /// No description provided for @tasksViewMatrix.
  ///
  /// In en, this message translates to:
  /// **'Matrix'**
  String get tasksViewMatrix;

  /// No description provided for @tasksCategoryFilter.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get tasksCategoryFilter;

  /// No description provided for @tasksAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get tasksAllCategories;

  /// No description provided for @taskCategoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get taskCategoryWork;

  /// No description provided for @taskCategoryStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get taskCategoryStudy;

  /// No description provided for @taskCategoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get taskCategoryPersonal;

  /// No description provided for @taskCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get taskCategoryHealth;

  /// No description provided for @taskCategorySpiritual.
  ///
  /// In en, this message translates to:
  /// **'Spiritual'**
  String get taskCategorySpiritual;

  /// No description provided for @taskCategoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get taskCategoryFinance;

  /// No description provided for @taskCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get taskCategoryOther;

  /// No description provided for @quadrantUrgentImportant.
  ///
  /// In en, this message translates to:
  /// **'Urgent & Important'**
  String get quadrantUrgentImportant;

  /// No description provided for @quadrantNotUrgentImportant.
  ///
  /// In en, this message translates to:
  /// **'Important, Not Urgent'**
  String get quadrantNotUrgentImportant;

  /// No description provided for @quadrantUrgentNotImportant.
  ///
  /// In en, this message translates to:
  /// **'Urgent, Not Important'**
  String get quadrantUrgentNotImportant;

  /// No description provided for @quadrantNotUrgentNotImportant.
  ///
  /// In en, this message translates to:
  /// **'Not Urgent & Not Important'**
  String get quadrantNotUrgentNotImportant;

  /// No description provided for @quadrantDo.
  ///
  /// In en, this message translates to:
  /// **'Do First'**
  String get quadrantDo;

  /// No description provided for @quadrantSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get quadrantSchedule;

  /// No description provided for @quadrantDelegate.
  ///
  /// In en, this message translates to:
  /// **'Delegate'**
  String get quadrantDelegate;

  /// No description provided for @quadrantEliminate.
  ///
  /// In en, this message translates to:
  /// **'Eliminate'**
  String get quadrantEliminate;

  /// No description provided for @taskCreate.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get taskCreate;

  /// No description provided for @taskEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get taskEdit;

  /// No description provided for @taskDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get taskDelete;

  /// No description provided for @taskComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get taskComplete;

  /// No description provided for @taskReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get taskReopen;

  /// No description provided for @taskChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get taskChecklistTitle;

  /// No description provided for @taskChecklistNewHint.
  ///
  /// In en, this message translates to:
  /// **'Add a step'**
  String get taskChecklistNewHint;

  /// No description provided for @taskChecklistAdd.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get taskChecklistAdd;

  /// No description provided for @taskChecklistSave.
  ///
  /// In en, this message translates to:
  /// **'Save step'**
  String get taskChecklistSave;

  /// No description provided for @taskChecklistRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove step'**
  String get taskChecklistRemove;

  /// No description provided for @taskChecklistTextRequired.
  ///
  /// In en, this message translates to:
  /// **'Step text is required'**
  String get taskChecklistTextRequired;

  /// No description provided for @taskCompletedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed {timestamp}'**
  String taskCompletedAt(String timestamp);

  /// No description provided for @taskSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get taskSave;

  /// No description provided for @taskCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get taskCancel;

  /// No description provided for @taskTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitleLabel;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get taskTitleHint;

  /// No description provided for @taskDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get taskDescriptionLabel;

  /// No description provided for @taskDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Notes or details'**
  String get taskDescriptionHint;

  /// No description provided for @taskDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated Duration (minutes)'**
  String get taskDurationLabel;

  /// No description provided for @taskDurationHint.
  ///
  /// In en, this message translates to:
  /// **'30'**
  String get taskDurationHint;

  /// No description provided for @taskScheduledDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Date'**
  String get taskScheduledDateLabel;

  /// No description provided for @taskScheduledTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get taskScheduledTimeLabel;

  /// No description provided for @taskDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get taskDeadlineLabel;

  /// No description provided for @taskDateTodayDefault.
  ///
  /// In en, this message translates to:
  /// **'Today (default)'**
  String get taskDateTodayDefault;

  /// No description provided for @taskNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get taskNotSet;

  /// No description provided for @taskClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get taskClear;

  /// No description provided for @taskCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get taskCategoryLabel;

  /// No description provided for @taskQuadrantLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskQuadrantLabel;

  /// No description provided for @taskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get taskTitleRequired;

  /// No description provided for @taskDurationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Duration must be positive'**
  String get taskDurationInvalid;

  /// No description provided for @taskDurationUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get taskDurationUnit;

  /// No description provided for @tasksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get tasksEmpty;

  /// No description provided for @tasksLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading tasks...'**
  String get tasksLoading;

  /// No description provided for @tasksFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tasks'**
  String get tasksFailure;

  /// No description provided for @tasksConflictNotice.
  ///
  /// In en, this message translates to:
  /// **'Sync conflict detected. Local changes are preserved beside remote changes.'**
  String get tasksConflictNotice;

  /// No description provided for @tasksActiveLocal.
  ///
  /// In en, this message translates to:
  /// **'Local version'**
  String get tasksActiveLocal;

  /// No description provided for @tasksRetainedRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote version'**
  String get tasksRetainedRemote;

  /// No description provided for @habitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habitsTitle;

  /// No description provided for @habitsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get habitsEmpty;

  /// No description provided for @habitsCreate.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get habitsCreate;

  /// No description provided for @habitEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit habit'**
  String get habitEdit;

  /// No description provided for @habitDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete habit'**
  String get habitDelete;

  /// No description provided for @habitDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete this habit? Its history will be kept for recovery, but it will disappear from your habits.'**
  String get habitDeleteConfirmation;

  /// No description provided for @habitReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get habitReminderTime;

  /// No description provided for @habitReminderClear.
  ///
  /// In en, this message translates to:
  /// **'Clear time'**
  String get habitReminderClear;

  /// No description provided for @habitReminderInactive.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not active yet. A chosen time is saved for later.'**
  String get habitReminderInactive;

  /// No description provided for @habitsSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing habits…'**
  String get habitsSyncing;

  /// No description provided for @habitsSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Habits could not finish syncing. Your saved changes remain on this device.'**
  String get habitsSyncFailed;

  /// No description provided for @habitsSyncRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry sync'**
  String get habitsSyncRetry;

  /// No description provided for @habitsConflict.
  ///
  /// In en, this message translates to:
  /// **'A habit change needs review'**
  String get habitsConflict;

  /// No description provided for @habitsActiveVersion.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get habitsActiveVersion;

  /// No description provided for @habitsRetainedVersion.
  ///
  /// In en, this message translates to:
  /// **'Retained version'**
  String get habitsRetainedVersion;

  /// No description provided for @habitsUnresolvedConflict.
  ///
  /// In en, this message translates to:
  /// **'The versions have the same time and need review.'**
  String get habitsUnresolvedConflict;

  /// No description provided for @habitNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get habitNameLabel;

  /// No description provided for @habitNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a habit name'**
  String get habitNameRequired;

  /// No description provided for @habitWeekdaysRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one day'**
  String get habitWeekdaysRequired;

  /// No description provided for @habitSave.
  ///
  /// In en, this message translates to:
  /// **'Save habit'**
  String get habitSave;

  /// No description provided for @habitCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get habitCancel;

  /// No description provided for @habitComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete today'**
  String get habitComplete;

  /// No description provided for @habitUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo today'**
  String get habitUndo;

  /// No description provided for @habitDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get habitDueToday;

  /// No description provided for @habitNotDueToday.
  ///
  /// In en, this message translates to:
  /// **'Not due today'**
  String get habitNotDueToday;

  /// No description provided for @habitsLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not load habits. Try again.'**
  String get habitsLoadFailure;

  /// No description provided for @habitsSaveFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not save your change. Please try again.'**
  String get habitsSaveFailure;

  /// No description provided for @habitsSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your habits.'**
  String get habitsSignInRequired;

  /// No description provided for @habitHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get habitHistory;

  /// No description provided for @habitCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak (days)'**
  String get habitCurrentStreak;

  /// No description provided for @habitCompletedDates.
  ///
  /// In en, this message translates to:
  /// **'Completed dates'**
  String get habitCompletedDates;

  /// No description provided for @habitNoCompletedDates.
  ///
  /// In en, this message translates to:
  /// **'No completed dates yet'**
  String get habitNoCompletedDates;

  /// No description provided for @habitPendingToday.
  ///
  /// In en, this message translates to:
  /// **'Today is still in progress'**
  String get habitPendingToday;

  /// No description provided for @habitScheduleHistory.
  ///
  /// In en, this message translates to:
  /// **'Schedule history'**
  String get habitScheduleHistory;

  /// No description provided for @habitEffectiveFrom.
  ///
  /// In en, this message translates to:
  /// **'Effective from'**
  String get habitEffectiveFrom;

  /// No description provided for @habitCompletedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed on'**
  String get habitCompletedOn;

  /// No description provided for @habitCloseHistory.
  ///
  /// In en, this message translates to:
  /// **'Close history'**
  String get habitCloseHistory;

  /// No description provided for @habitMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get habitMonday;

  /// No description provided for @habitTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get habitTuesday;

  /// No description provided for @habitWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get habitWednesday;

  /// No description provided for @habitThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get habitThursday;

  /// No description provided for @habitFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get habitFriday;

  /// No description provided for @habitSaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get habitSaturday;

  /// No description provided for @habitSunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get habitSunday;

  /// No description provided for @mindMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mind Maps'**
  String get mindMapsTitle;

  /// No description provided for @mindMapsCreate.
  ///
  /// In en, this message translates to:
  /// **'New map'**
  String get mindMapsCreate;

  /// No description provided for @mindMapsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search maps'**
  String get mindMapsSearch;

  /// No description provided for @mindMapsEmptyLibrary.
  ///
  /// In en, this message translates to:
  /// **'No maps yet. Create your first map.'**
  String get mindMapsEmptyLibrary;

  /// No description provided for @mindMapsEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No maps match your search.'**
  String get mindMapsEmptySearch;

  /// No description provided for @mindMapTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Map title'**
  String get mindMapTitleLabel;

  /// No description provided for @mindMapDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get mindMapDescriptionLabel;

  /// No description provided for @mindMapEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get mindMapEditTitle;

  /// No description provided for @mindMapEditDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit description'**
  String get mindMapEditDescription;

  /// No description provided for @mindMapDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get mindMapDuplicate;

  /// No description provided for @mindMapDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get mindMapDelete;

  /// No description provided for @mindMapDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete this map? It will disappear from your library. Linked tasks will remain.'**
  String get mindMapDeleteConfirmation;

  /// No description provided for @mindMapSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mindMapSave;

  /// No description provided for @mindMapCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mindMapCancel;

  /// No description provided for @mindMapTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a map title'**
  String get mindMapTitleRequired;

  /// No description provided for @mindMapsLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not load maps. Try again.'**
  String get mindMapsLoadFailure;

  /// No description provided for @mindMapsSaveFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not save your map change. Please try again.'**
  String get mindMapsSaveFailure;

  /// No description provided for @mindMapsAccountFailure.
  ///
  /// In en, this message translates to:
  /// **'This account cannot change that map.'**
  String get mindMapsAccountFailure;

  /// No description provided for @mindMapsNotFound.
  ///
  /// In en, this message translates to:
  /// **'This map is no longer available.'**
  String get mindMapsNotFound;

  /// No description provided for @mindMapsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get mindMapsRetry;

  /// No description provided for @mindMapSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing mind maps…'**
  String get mindMapSyncing;

  /// No description provided for @mindMapSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Mind maps could not sync. Local changes are saved.'**
  String get mindMapSyncFailed;

  /// No description provided for @mindMapSyncRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry sync'**
  String get mindMapSyncRetry;

  /// No description provided for @mindMapConflicts.
  ///
  /// In en, this message translates to:
  /// **'Review other versions'**
  String get mindMapConflicts;

  /// No description provided for @mindMapConflictActive.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get mindMapConflictActive;

  /// No description provided for @mindMapConflictRetained.
  ///
  /// In en, this message translates to:
  /// **'Other version'**
  String get mindMapConflictRetained;

  /// No description provided for @mindMapConflictUnresolved.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get mindMapConflictUnresolved;

  /// No description provided for @mindMapNodeCount.
  ///
  /// In en, this message translates to:
  /// **'Nodes'**
  String get mindMapNodeCount;

  /// No description provided for @mindMapCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get mindMapCompletedCount;

  /// No description provided for @mindMapCentralNode.
  ///
  /// In en, this message translates to:
  /// **'Central idea'**
  String get mindMapCentralNode;

  /// No description provided for @mindMapsSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your mind maps.'**
  String get mindMapsSignInRequired;

  /// No description provided for @mindMapsBack.
  ///
  /// In en, this message translates to:
  /// **'Back to maps'**
  String get mindMapsBack;

  /// No description provided for @mindMapEditMap.
  ///
  /// In en, this message translates to:
  /// **'Edit map'**
  String get mindMapEditMap;

  /// No description provided for @mindMapAddNode.
  ///
  /// In en, this message translates to:
  /// **'Add node'**
  String get mindMapAddNode;

  /// No description provided for @mindMapEditNode.
  ///
  /// In en, this message translates to:
  /// **'Edit node'**
  String get mindMapEditNode;

  /// No description provided for @mindMapNodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Node title'**
  String get mindMapNodeTitle;

  /// No description provided for @mindMapNodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Node description'**
  String get mindMapNodeDescription;

  /// No description provided for @mindMapNodeKind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get mindMapNodeKind;

  /// No description provided for @mindMapNodePriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get mindMapNodePriority;

  /// No description provided for @mindMapNodeStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get mindMapNodeStatus;

  /// No description provided for @mindMapKindCentral.
  ///
  /// In en, this message translates to:
  /// **'Central idea'**
  String get mindMapKindCentral;

  /// No description provided for @mindMapKindMainIdea.
  ///
  /// In en, this message translates to:
  /// **'Main idea'**
  String get mindMapKindMainIdea;

  /// No description provided for @mindMapKindBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get mindMapKindBranch;

  /// No description provided for @mindMapKindTask.
  ///
  /// In en, this message translates to:
  /// **'Task idea'**
  String get mindMapKindTask;

  /// No description provided for @mindMapKindNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get mindMapKindNote;

  /// No description provided for @mindMapStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get mindMapStatusNotStarted;

  /// No description provided for @mindMapStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get mindMapStatusInProgress;

  /// No description provided for @mindMapStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get mindMapStatusCompleted;

  /// No description provided for @mindMapPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get mindMapPriorityLow;

  /// No description provided for @mindMapPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mindMapPriorityMedium;

  /// No description provided for @mindMapPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get mindMapPriorityHigh;

  /// No description provided for @mindMapNodeTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a node title'**
  String get mindMapNodeTitleRequired;

  /// No description provided for @mindMapDeleteNode.
  ///
  /// In en, this message translates to:
  /// **'Delete node'**
  String get mindMapDeleteNode;

  /// No description provided for @mindMapDeleteNodeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete this node? Its children will remain as independent nodes.'**
  String get mindMapDeleteNodeConfirmation;

  /// No description provided for @mindMapParent.
  ///
  /// In en, this message translates to:
  /// **'Parent branch'**
  String get mindMapParent;

  /// No description provided for @mindMapDetach.
  ///
  /// In en, this message translates to:
  /// **'Detach from parent'**
  String get mindMapDetach;

  /// No description provided for @mindMapSideLink.
  ///
  /// In en, this message translates to:
  /// **'Visual link'**
  String get mindMapSideLink;

  /// No description provided for @mindMapConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get mindMapConnect;

  /// No description provided for @mindMapDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get mindMapDisconnect;

  /// No description provided for @mindMapMoveNode.
  ///
  /// In en, this message translates to:
  /// **'Move node'**
  String get mindMapMoveNode;

  /// No description provided for @mindMapUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get mindMapUndo;

  /// No description provided for @mindMapRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get mindMapRedo;

  /// No description provided for @mindMapGraphError.
  ///
  /// In en, this message translates to:
  /// **'Could not save this graph change. Check the connection and try again.'**
  String get mindMapGraphError;

  /// No description provided for @mindMapNoParent.
  ///
  /// In en, this message translates to:
  /// **'Independent'**
  String get mindMapNoParent;

  /// No description provided for @mindMapProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get mindMapProgress;

  /// No description provided for @mindMapChooseTask.
  ///
  /// In en, this message translates to:
  /// **'Choose a task'**
  String get mindMapChooseTask;

  /// No description provided for @mindMapLinkTask.
  ///
  /// In en, this message translates to:
  /// **'Link task'**
  String get mindMapLinkTask;

  /// No description provided for @mindMapChangeTask.
  ///
  /// In en, this message translates to:
  /// **'Change linked task'**
  String get mindMapChangeTask;

  /// No description provided for @mindMapUnlinkTask.
  ///
  /// In en, this message translates to:
  /// **'Unlink task'**
  String get mindMapUnlinkTask;

  /// No description provided for @mindMapLinkedTask.
  ///
  /// In en, this message translates to:
  /// **'Linked task'**
  String get mindMapLinkedTask;

  /// No description provided for @mindMapTaskUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Linked task unavailable'**
  String get mindMapTaskUnavailable;

  /// No description provided for @mindMapCompleteTask.
  ///
  /// In en, this message translates to:
  /// **'Complete task'**
  String get mindMapCompleteTask;

  /// No description provided for @mindMapReopenTask.
  ///
  /// In en, this message translates to:
  /// **'Reopen task'**
  String get mindMapReopenTask;

  /// No description provided for @mindMapLoadingTasks.
  ///
  /// In en, this message translates to:
  /// **'Loading tasks…'**
  String get mindMapLoadingTasks;

  /// No description provided for @mindMapRetryTasks.
  ///
  /// In en, this message translates to:
  /// **'Retry loading tasks'**
  String get mindMapRetryTasks;

  /// No description provided for @mindMapNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No accessible tasks found'**
  String get mindMapNoTasks;

  /// No description provided for @mindMapTaskLinkFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not load or link this task. Try again.'**
  String get mindMapTaskLinkFailure;

  /// No description provided for @mindMapSettings.
  ///
  /// In en, this message translates to:
  /// **'Map settings'**
  String get mindMapSettings;

  /// No description provided for @mindMapLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get mindMapLayout;

  /// No description provided for @mindMapApplyLayout.
  ///
  /// In en, this message translates to:
  /// **'Apply layout'**
  String get mindMapApplyLayout;

  /// No description provided for @mindMapLayoutRadial.
  ///
  /// In en, this message translates to:
  /// **'Radial'**
  String get mindMapLayoutRadial;

  /// No description provided for @mindMapLayoutTree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get mindMapLayoutTree;

  /// No description provided for @mindMapLayoutHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get mindMapLayoutHorizontal;

  /// No description provided for @mindMapLayoutVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get mindMapLayoutVertical;

  /// No description provided for @mindMapLayoutFreeform.
  ///
  /// In en, this message translates to:
  /// **'Freeform'**
  String get mindMapLayoutFreeform;

  /// No description provided for @mindMapBackground.
  ///
  /// In en, this message translates to:
  /// **'Canvas background'**
  String get mindMapBackground;

  /// No description provided for @mindMapDefaultNode.
  ///
  /// In en, this message translates to:
  /// **'New node default'**
  String get mindMapDefaultNode;

  /// No description provided for @mindMapConnectionStyle.
  ///
  /// In en, this message translates to:
  /// **'New connection default'**
  String get mindMapConnectionStyle;

  /// No description provided for @mindMapSpacing.
  ///
  /// In en, this message translates to:
  /// **'Spacing'**
  String get mindMapSpacing;

  /// No description provided for @mindMapNodeColor.
  ///
  /// In en, this message translates to:
  /// **'Node color'**
  String get mindMapNodeColor;

  /// No description provided for @mindMapConnectionColor.
  ///
  /// In en, this message translates to:
  /// **'Connection color'**
  String get mindMapConnectionColor;

  /// No description provided for @mindMapConnectionWidth.
  ///
  /// In en, this message translates to:
  /// **'Connection width'**
  String get mindMapConnectionWidth;

  /// No description provided for @mindMapNodeIcon.
  ///
  /// In en, this message translates to:
  /// **'Node icon'**
  String get mindMapNodeIcon;

  /// No description provided for @mindMapNodeShape.
  ///
  /// In en, this message translates to:
  /// **'Node shape'**
  String get mindMapNodeShape;

  /// No description provided for @mindMapNodeSize.
  ///
  /// In en, this message translates to:
  /// **'Node size'**
  String get mindMapNodeSize;

  /// No description provided for @mindMapTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get mindMapTextSize;

  /// No description provided for @mindMapShapeRectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get mindMapShapeRectangle;

  /// No description provided for @mindMapShapeRounded.
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get mindMapShapeRounded;

  /// No description provided for @mindMapShapeCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get mindMapShapeCircle;

  /// No description provided for @mindMapShapePill.
  ///
  /// In en, this message translates to:
  /// **'Pill'**
  String get mindMapShapePill;

  /// No description provided for @mindMapShapeGlass.
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get mindMapShapeGlass;

  /// No description provided for @mindMapSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get mindMapSizeSmall;

  /// No description provided for @mindMapSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mindMapSizeMedium;

  /// No description provided for @mindMapSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get mindMapSizeLarge;

  /// No description provided for @mindMapIconIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get mindMapIconIdea;

  /// No description provided for @mindMapIconTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get mindMapIconTask;

  /// No description provided for @mindMapIconNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get mindMapIconNote;

  /// No description provided for @mindMapIconStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get mindMapIconStar;

  /// No description provided for @mindMapIconFlag.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get mindMapIconFlag;

  /// No description provided for @mindMapColorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get mindMapColorWhite;

  /// No description provided for @mindMapColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get mindMapColorBlue;

  /// No description provided for @mindMapColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get mindMapColorGreen;

  /// No description provided for @mindMapColorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get mindMapColorAmber;

  /// No description provided for @mindMapColorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get mindMapColorPurple;

  /// No description provided for @mindMapColorDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get mindMapColorDark;

  /// No description provided for @mindMapColorCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current color'**
  String get mindMapColorCurrent;

  /// No description provided for @mindMapFit.
  ///
  /// In en, this message translates to:
  /// **'Fit map'**
  String get mindMapFit;

  /// No description provided for @mindMapCenter.
  ///
  /// In en, this message translates to:
  /// **'Center map'**
  String get mindMapCenter;

  /// No description provided for @mindMapZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get mindMapZoomIn;

  /// No description provided for @mindMapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get mindMapZoomOut;

  /// No description provided for @mindMapPanLeft.
  ///
  /// In en, this message translates to:
  /// **'Pan left'**
  String get mindMapPanLeft;

  /// No description provided for @mindMapPanRight.
  ///
  /// In en, this message translates to:
  /// **'Pan right'**
  String get mindMapPanRight;

  /// No description provided for @mindMapPanUp.
  ///
  /// In en, this message translates to:
  /// **'Pan up'**
  String get mindMapPanUp;

  /// No description provided for @mindMapPanDown.
  ///
  /// In en, this message translates to:
  /// **'Pan down'**
  String get mindMapPanDown;

  /// No description provided for @mindMapDragNode.
  ///
  /// In en, this message translates to:
  /// **'Drag node to move'**
  String get mindMapDragNode;

  /// No description provided for @mindMapKeyboardHelp.
  ///
  /// In en, this message translates to:
  /// **'Keyboard: arrow keys pan, plus and minus zoom, F fits, C centers'**
  String get mindMapKeyboardHelp;

  /// No description provided for @todayNewTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get todayNewTask;

  /// No description provided for @todayNewHabit.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get todayNewHabit;

  /// No description provided for @todayCompleteTask.
  ///
  /// In en, this message translates to:
  /// **'Complete task'**
  String get todayCompleteTask;

  /// No description provided for @todayReopenTask.
  ///
  /// In en, this message translates to:
  /// **'Reopen task'**
  String get todayReopenTask;

  /// No description provided for @todayCompleteHabit.
  ///
  /// In en, this message translates to:
  /// **'Complete habit'**
  String get todayCompleteHabit;

  /// No description provided for @todayUndoHabit.
  ///
  /// In en, this message translates to:
  /// **'Undo habit'**
  String get todayUndoHabit;

  /// No description provided for @todaySaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get todaySaving;

  /// No description provided for @todaySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Check the item and try again.'**
  String get todaySaveFailed;

  /// No description provided for @todayUncertain.
  ///
  /// In en, this message translates to:
  /// **'Save result is uncertain. Check the current item before trying again.'**
  String get todayUncertain;

  /// No description provided for @todayStaleDay.
  ///
  /// In en, this message translates to:
  /// **'The day changed. Review today\'s items before acting.'**
  String get todayStaleDay;

  /// No description provided for @todayAgenda.
  ///
  /// In en, this message translates to:
  /// **'Today\'s agenda'**
  String get todayAgenda;

  /// No description provided for @todayTimed.
  ///
  /// In en, this message translates to:
  /// **'Timed'**
  String get todayTimed;

  /// No description provided for @todayUntimed.
  ///
  /// In en, this message translates to:
  /// **'Untimed'**
  String get todayUntimed;

  /// No description provided for @todayMinuteUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get todayMinuteUnit;

  /// No description provided for @todayNoPriorityTasks.
  ///
  /// In en, this message translates to:
  /// **'No urgent and important tasks due today or overdue.'**
  String get todayNoPriorityTasks;

  /// No description provided for @todayOpenMatrix.
  ///
  /// In en, this message translates to:
  /// **'Open task matrix'**
  String get todayOpenMatrix;

  /// No description provided for @todayOpenOverdue.
  ///
  /// In en, this message translates to:
  /// **'Open overdue tasks'**
  String get todayOpenOverdue;

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'A calmer start to today'**
  String get dashboardGreetingMorning;

  /// No description provided for @dashboardGreetingLater.
  ///
  /// In en, this message translates to:
  /// **'Make space for what matters'**
  String get dashboardGreetingLater;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One place for your priorities and daily rhythm.'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Your day at a glance'**
  String get dashboardOverview;

  /// No description provided for @dashboardTasksProgress.
  ///
  /// In en, this message translates to:
  /// **'Tasks completed'**
  String get dashboardTasksProgress;

  /// No description provided for @dashboardHabitsProgress.
  ///
  /// In en, this message translates to:
  /// **'Habits completed'**
  String get dashboardHabitsProgress;

  /// No description provided for @dashboardXpEarned.
  ///
  /// In en, this message translates to:
  /// **'XP earned today'**
  String get dashboardXpEarned;

  /// No description provided for @dashboardExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore your space'**
  String get dashboardExplore;

  /// No description provided for @dashboardMindMapsHint.
  ///
  /// In en, this message translates to:
  /// **'Turn ideas into clear paths'**
  String get dashboardMindMapsHint;

  /// No description provided for @dashboardPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming into focus'**
  String get dashboardPreviewTitle;

  /// No description provided for @dashboardPreviewDescription.
  ///
  /// In en, this message translates to:
  /// **'A glimpse of the spaces we are building next.'**
  String get dashboardPreviewDescription;

  /// No description provided for @dashboardSampleBadge.
  ///
  /// In en, this message translates to:
  /// **'SAMPLE DATA'**
  String get dashboardSampleBadge;

  /// No description provided for @dashboardSidebarTagline.
  ///
  /// In en, this message translates to:
  /// **'Space for a balanced day'**
  String get dashboardSidebarTagline;

  /// No description provided for @dashboardComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get dashboardComingSoon;

  /// No description provided for @dashboardPrayerShort.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get dashboardPrayerShort;

  /// No description provided for @dashboardMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get dashboardMore;

  /// No description provided for @dashboardPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get dashboardPrayer;

  /// No description provided for @dashboardPrayerDetail.
  ///
  /// In en, this message translates to:
  /// **'Next: Asr · 3:25 PM'**
  String get dashboardPrayerDetail;

  /// No description provided for @dashboardQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran reading'**
  String get dashboardQuran;

  /// No description provided for @dashboardQuranDetail.
  ///
  /// In en, this message translates to:
  /// **'7 of 20 pages this week'**
  String get dashboardQuranDetail;

  /// No description provided for @dashboardFinance.
  ///
  /// In en, this message translates to:
  /// **'Personal finances'**
  String get dashboardFinance;

  /// No description provided for @dashboardFinanceDetail.
  ///
  /// In en, this message translates to:
  /// **'Monthly goal · 4,250 / 8,000'**
  String get dashboardFinanceDetail;

  /// No description provided for @dashboardFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus time'**
  String get dashboardFocus;

  /// No description provided for @dashboardFocusDetail.
  ///
  /// In en, this message translates to:
  /// **'Two sessions planned · 50 min'**
  String get dashboardFocusDetail;

  /// No description provided for @dashboardEncryptedBadge.
  ///
  /// In en, this message translates to:
  /// **'Locally saved & encrypted'**
  String get dashboardEncryptedBadge;

  /// No description provided for @dashboardProductiveDay.
  ///
  /// In en, this message translates to:
  /// **'Balanced & productive day'**
  String get dashboardProductiveDay;

  /// No description provided for @dashboardLevelBadge.
  ///
  /// In en, this message translates to:
  /// **'Lv.{level} • {xp} XP'**
  String dashboardLevelBadge(int level, int xp);

  /// No description provided for @dashboardSampleNotice.
  ///
  /// In en, this message translates to:
  /// **'Preview of upcoming feature. Values are demo samples.'**
  String get dashboardSampleNotice;

  /// No description provided for @dashboardPrayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Prayers'**
  String get dashboardPrayerTitle;

  /// No description provided for @dashboardPrayerCity.
  ///
  /// In en, this message translates to:
  /// **'Riyadh'**
  String get dashboardPrayerCity;

  /// No description provided for @dashboardPrayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get dashboardPrayerFajr;

  /// No description provided for @dashboardPrayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dashboardPrayerDhuhr;

  /// No description provided for @dashboardPrayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get dashboardPrayerAsr;

  /// No description provided for @dashboardPrayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get dashboardPrayerMaghrib;

  /// No description provided for @dashboardPrayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get dashboardPrayerIsha;

  /// No description provided for @dashboardPrayerNext.
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get dashboardPrayerNext;

  /// No description provided for @dashboardPrayerRemaining.
  ///
  /// In en, this message translates to:
  /// **'3h 24m remaining'**
  String get dashboardPrayerRemaining;

  /// No description provided for @dashboardPrayerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dashboardPrayerDone;

  /// No description provided for @dashboardPrayerUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get dashboardPrayerUpcoming;

  /// No description provided for @dashboardQuranSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Quran & Memorization'**
  String get dashboardQuranSectionTitle;

  /// No description provided for @dashboardQuranWirdTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Reading • Surah Al-Kahf'**
  String get dashboardQuranWirdTitle;

  /// No description provided for @dashboardQuranProgressInfo.
  ///
  /// In en, this message translates to:
  /// **'Juz 15 • Page 302 of 304 • 75% done'**
  String get dashboardQuranProgressInfo;

  /// No description provided for @dashboardQuranRemainingPages.
  ///
  /// In en, this message translates to:
  /// **'2 pages remaining to finish reading'**
  String get dashboardQuranRemainingPages;

  /// No description provided for @dashboardQuranAyahQuote.
  ///
  /// In en, this message translates to:
  /// **'«And as for the wall, it belonged to two orphan boys in the city, and there was beneath it a treasure for them...»'**
  String get dashboardQuranAyahQuote;

  /// No description provided for @dashboardQuranAyahRef.
  ///
  /// In en, this message translates to:
  /// **'Surah Al-Kahf • Ayah 82'**
  String get dashboardQuranAyahRef;

  /// No description provided for @dashboardQuranContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get dashboardQuranContinueReading;

  /// No description provided for @dashboardQuranMemorizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Memorization Review • Surah Al-Mulk'**
  String get dashboardQuranMemorizationTitle;

  /// No description provided for @dashboardQuranMemorizationDetail.
  ///
  /// In en, this message translates to:
  /// **'Verses 1-5 mastered ✓ • Verses 6-10 pending'**
  String get dashboardQuranMemorizationDetail;

  /// No description provided for @dashboardQuranStartRecite.
  ///
  /// In en, this message translates to:
  /// **'Start recitation'**
  String get dashboardQuranStartRecite;

  /// No description provided for @dashboardFinanceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Finance Snapshot'**
  String get dashboardFinanceSectionTitle;

  /// No description provided for @dashboardFinanceMonth.
  ///
  /// In en, this message translates to:
  /// **'Current month example'**
  String get dashboardFinanceMonth;

  /// No description provided for @dashboardFinanceTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get dashboardFinanceTotalBalance;

  /// No description provided for @dashboardFinanceAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available to Spend'**
  String get dashboardFinanceAvailable;

  /// No description provided for @dashboardFinanceSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get dashboardFinanceSavings;

  /// No description provided for @dashboardFinanceCurrency.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get dashboardFinanceCurrency;

  /// No description provided for @dashboardFinanceFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'7-Day Cash Flow'**
  String get dashboardFinanceFlowTitle;

  /// No description provided for @dashboardFinanceIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboardFinanceIncome;

  /// No description provided for @dashboardFinanceExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get dashboardFinanceExpense;

  /// No description provided for @dashboardFinanceBudgetConsumption.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget Usage'**
  String get dashboardFinanceBudgetConsumption;

  /// No description provided for @dashboardFinanceBudgetConsumed.
  ///
  /// In en, this message translates to:
  /// **'52% consumed'**
  String get dashboardFinanceBudgetConsumed;

  /// No description provided for @dashboardFinanceSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get dashboardFinanceSpent;

  /// No description provided for @dashboardFinanceRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get dashboardFinanceRemaining;

  /// No description provided for @dashboardFinanceDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'16 days left'**
  String get dashboardFinanceDaysLeft;

  /// No description provided for @dashboardFinanceAddIncome.
  ///
  /// In en, this message translates to:
  /// **'+ Income'**
  String get dashboardFinanceAddIncome;

  /// No description provided for @dashboardFinanceAddExpense.
  ///
  /// In en, this message translates to:
  /// **'- Expense'**
  String get dashboardFinanceAddExpense;

  /// No description provided for @dashboardFinanceAddSaving.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get dashboardFinanceAddSaving;

  /// No description provided for @dashboardFocusSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus & Spiritual Routine'**
  String get dashboardFocusSectionTitle;

  /// No description provided for @dashboardFocusPomodoroTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested Focus Session'**
  String get dashboardFocusPomodoroTitle;

  /// No description provided for @dashboardFocusPomodoroDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: 25 minutes'**
  String get dashboardFocusPomodoroDuration;

  /// No description provided for @dashboardFocusStart.
  ///
  /// In en, this message translates to:
  /// **'Start session'**
  String get dashboardFocusStart;

  /// No description provided for @dashboardFocusCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'50 min completed today'**
  String get dashboardFocusCompletedToday;

  /// No description provided for @dashboardAdhkarTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Adhkar & Sunan'**
  String get dashboardAdhkarTitle;

  /// No description provided for @dashboardAdhkarMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning Adhkar'**
  String get dashboardAdhkarMorning;

  /// No description provided for @dashboardAdhkarEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening Adhkar'**
  String get dashboardAdhkarEvening;

  /// No description provided for @dashboardAdhkarQiyam.
  ///
  /// In en, this message translates to:
  /// **'Qiyam & Witr'**
  String get dashboardAdhkarQiyam;

  /// No description provided for @dashboardReflectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Reflection'**
  String get dashboardReflectionTitle;

  /// No description provided for @dashboardReflectionQuote.
  ///
  /// In en, this message translates to:
  /// **'«The most beloved deeds to Allah are those done regularly, even if small.»'**
  String get dashboardReflectionQuote;

  /// No description provided for @dashboardReflectionAction.
  ///
  /// In en, this message translates to:
  /// **'Write reflection'**
  String get dashboardReflectionAction;
}

class _FoundationLocalizationsDelegate
    extends LocalizationsDelegate<FoundationLocalizations> {
  const _FoundationLocalizationsDelegate();

  @override
  Future<FoundationLocalizations> load(Locale locale) {
    return SynchronousFuture<FoundationLocalizations>(
      lookupFoundationLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_FoundationLocalizationsDelegate old) => false;
}

FoundationLocalizations lookupFoundationLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return FoundationLocalizationsAr();
    case 'en':
      return FoundationLocalizationsEn();
  }

  throw FlutterError(
    'FoundationLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

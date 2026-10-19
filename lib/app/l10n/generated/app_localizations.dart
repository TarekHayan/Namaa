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

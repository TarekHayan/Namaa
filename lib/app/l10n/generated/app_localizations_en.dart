// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class FoundationLocalizationsEn extends FoundationLocalizations {
  FoundationLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Namaa';

  @override
  String get foundationReady => 'Namaa is ready';

  @override
  String get foundationBootstrapRecoverable =>
      'Namaa could not finish starting. Please try again.';

  @override
  String get foundationBootstrapBlocking => 'Namaa could not start safely.';

  @override
  String get foundationLocaleRecoverable =>
      'Your language preference could not be saved.';

  @override
  String get foundationThemeRecoverable =>
      'Your appearance preference could not be saved.';

  @override
  String get foundationRouteUnavailable => 'This route is unavailable.';

  @override
  String get foundationPlatformRecoverable =>
      'This platform capability could not be verified.';

  @override
  String get foundationGenericFailure =>
      'Namaa needs attention before it can continue.';

  @override
  String get retry => 'Retry';

  @override
  String get tasksSignInRequired => 'Sign in to access your tasks.';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get tasksFilterToday => 'Today';

  @override
  String get tasksFilterUrgent => 'Urgent';

  @override
  String get tasksFilterAll => 'All';

  @override
  String get tasksFilterCompleted => 'Completed';

  @override
  String get tasksFilterHistory => 'History';

  @override
  String get tasksFilterOverdue => 'Overdue';

  @override
  String get tasksViewList => 'List';

  @override
  String get tasksViewMatrix => 'Matrix';

  @override
  String get tasksCategoryFilter => 'Category';

  @override
  String get tasksAllCategories => 'All Categories';

  @override
  String get taskCategoryWork => 'Work';

  @override
  String get taskCategoryStudy => 'Study';

  @override
  String get taskCategoryPersonal => 'Personal';

  @override
  String get taskCategoryHealth => 'Health';

  @override
  String get taskCategorySpiritual => 'Spiritual';

  @override
  String get taskCategoryFinance => 'Finance';

  @override
  String get taskCategoryOther => 'Other';

  @override
  String get quadrantUrgentImportant => 'Urgent & Important';

  @override
  String get quadrantNotUrgentImportant => 'Important, Not Urgent';

  @override
  String get quadrantUrgentNotImportant => 'Urgent, Not Important';

  @override
  String get quadrantNotUrgentNotImportant => 'Not Urgent & Not Important';

  @override
  String get quadrantDo => 'Do First';

  @override
  String get quadrantSchedule => 'Schedule';

  @override
  String get quadrantDelegate => 'Delegate';

  @override
  String get quadrantEliminate => 'Eliminate';

  @override
  String get taskCreate => 'New Task';

  @override
  String get taskEdit => 'Edit Task';

  @override
  String get taskDelete => 'Delete';

  @override
  String get taskComplete => 'Complete';

  @override
  String get taskReopen => 'Reopen';

  @override
  String get taskChecklistTitle => 'Checklist';

  @override
  String get taskChecklistNewHint => 'Add a step';

  @override
  String get taskChecklistAdd => 'Add step';

  @override
  String get taskChecklistSave => 'Save step';

  @override
  String get taskChecklistRemove => 'Remove step';

  @override
  String get taskChecklistTextRequired => 'Step text is required';

  @override
  String taskCompletedAt(String timestamp) {
    return 'Completed $timestamp';
  }

  @override
  String get taskSave => 'Save';

  @override
  String get taskCancel => 'Cancel';

  @override
  String get taskTitleLabel => 'Title';

  @override
  String get taskTitleHint => 'Task title';

  @override
  String get taskDescriptionLabel => 'Description';

  @override
  String get taskDescriptionHint => 'Notes or details';

  @override
  String get taskDurationLabel => 'Estimated Duration (minutes)';

  @override
  String get taskDurationHint => '30';

  @override
  String get taskScheduledDateLabel => 'Scheduled Date';

  @override
  String get taskScheduledTimeLabel => 'Time';

  @override
  String get taskDeadlineLabel => 'Deadline';

  @override
  String get taskDateTodayDefault => 'Today (default)';

  @override
  String get taskNotSet => 'Not set';

  @override
  String get taskClear => 'Clear';

  @override
  String get taskCategoryLabel => 'Category';

  @override
  String get taskQuadrantLabel => 'Priority';

  @override
  String get taskTitleRequired => 'Title is required';

  @override
  String get taskDurationInvalid => 'Duration must be positive';

  @override
  String get taskDurationUnit => 'min';

  @override
  String get tasksEmpty => 'No tasks yet';

  @override
  String get tasksLoading => 'Loading tasks...';

  @override
  String get tasksFailure => 'Failed to load tasks';

  @override
  String get tasksConflictNotice =>
      'Sync conflict detected. Local changes are preserved beside remote changes.';

  @override
  String get tasksActiveLocal => 'Local version';

  @override
  String get tasksRetainedRemote => 'Remote version';

  @override
  String get habitsTitle => 'Habits';

  @override
  String get habitsEmpty => 'No habits yet';

  @override
  String get habitsCreate => 'New habit';

  @override
  String get habitEdit => 'Edit habit';

  @override
  String get habitDelete => 'Delete habit';

  @override
  String get habitDeleteConfirmation =>
      'Delete this habit? Its history will be kept for recovery, but it will disappear from your habits.';

  @override
  String get habitReminderTime => 'Reminder time';

  @override
  String get habitReminderClear => 'Clear time';

  @override
  String get habitReminderInactive =>
      'Notifications are not active yet. A chosen time is saved for later.';

  @override
  String get habitNameLabel => 'Name';

  @override
  String get habitNameRequired => 'Enter a habit name';

  @override
  String get habitWeekdaysRequired => 'Choose at least one day';

  @override
  String get habitSave => 'Save habit';

  @override
  String get habitCancel => 'Cancel';

  @override
  String get habitComplete => 'Complete today';

  @override
  String get habitUndo => 'Undo today';

  @override
  String get habitDueToday => 'Due today';

  @override
  String get habitNotDueToday => 'Not due today';

  @override
  String get habitsLoadFailure => 'Could not load habits. Try again.';

  @override
  String get habitsSaveFailure =>
      'Could not save your change. Please try again.';

  @override
  String get habitsSignInRequired => 'Sign in to access your habits.';

  @override
  String get habitHistory => 'History';

  @override
  String get habitCurrentStreak => 'Current streak (days)';

  @override
  String get habitCompletedDates => 'Completed dates';

  @override
  String get habitNoCompletedDates => 'No completed dates yet';

  @override
  String get habitPendingToday => 'Today is still in progress';

  @override
  String get habitScheduleHistory => 'Schedule history';

  @override
  String get habitEffectiveFrom => 'Effective from';

  @override
  String get habitCompletedOn => 'Completed on';

  @override
  String get habitCloseHistory => 'Close history';

  @override
  String get habitMonday => 'Monday';

  @override
  String get habitTuesday => 'Tuesday';

  @override
  String get habitWednesday => 'Wednesday';

  @override
  String get habitThursday => 'Thursday';

  @override
  String get habitFriday => 'Friday';

  @override
  String get habitSaturday => 'Saturday';

  @override
  String get habitSunday => 'Sunday';
}

import 'package:flutter/widgets.dart';

/// Feature-owned localization contract. The app layer adapts generated ARB
/// resources to this surface so Tasks presentation never depends outward on
/// application composition.
abstract interface class TasksStrings {
  String get retry;
  String get tasksSignInRequired;
  String get tasksTitle;
  String get tasksFilterToday;
  String get tasksFilterUrgent;
  String get tasksFilterAll;
  String get tasksFilterCompleted;
  String get tasksViewList;
  String get tasksViewMatrix;
  String get tasksCategoryFilter;
  String get tasksAllCategories;
  String get taskCategoryWork;
  String get taskCategoryStudy;
  String get taskCategoryPersonal;
  String get taskCategoryHealth;
  String get taskCategorySpiritual;
  String get taskCategoryFinance;
  String get taskCategoryOther;
  String get quadrantUrgentImportant;
  String get quadrantNotUrgentImportant;
  String get quadrantUrgentNotImportant;
  String get quadrantNotUrgentNotImportant;
  String get quadrantDo;
  String get quadrantSchedule;
  String get quadrantDelegate;
  String get quadrantEliminate;
  String get taskCreate;
  String get taskEdit;
  String get taskDelete;
  String get taskComplete;
  String get taskReopen;
  String taskCompletedAt(String timestamp);
  String get taskSave;
  String get taskCancel;
  String get taskTitleLabel;
  String get taskTitleHint;
  String get taskDescriptionLabel;
  String get taskDescriptionHint;
  String get taskDurationLabel;
  String get taskDurationHint;
  String get taskScheduledDateLabel;
  String get taskScheduledTimeLabel;
  String get taskDeadlineLabel;
  String get taskDateTodayDefault;
  String get taskNotSet;
  String get taskClear;
  String get taskCategoryLabel;
  String get taskQuadrantLabel;
  String get taskTitleRequired;
  String get taskDurationInvalid;
  String get taskDurationUnit;
  String get tasksEmpty;
  String get tasksFailure;
  String get tasksConflictNotice;
  String get tasksActiveLocal;
  String get tasksRetainedRemote;
}

typedef TasksStringsResolver = TasksStrings Function(BuildContext context);

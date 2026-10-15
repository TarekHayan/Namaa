import 'package:flutter/widgets.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/tasks/presentation/tasks_strings.dart';

TasksStrings resolveTasksStrings(BuildContext context) =>
    _AppTasksStrings(FoundationLocalizations.of(context));

final class _AppTasksStrings implements TasksStrings {
  const _AppTasksStrings(this._l10n);

  final FoundationLocalizations _l10n;

  @override
  String get retry => _l10n.retry;
  @override
  String get tasksSignInRequired => _l10n.tasksSignInRequired;
  @override
  String get tasksTitle => _l10n.tasksTitle;
  @override
  String get tasksFilterToday => _l10n.tasksFilterToday;
  @override
  String get tasksFilterUrgent => _l10n.tasksFilterUrgent;
  @override
  String get tasksFilterAll => _l10n.tasksFilterAll;
  @override
  String get tasksFilterCompleted => _l10n.tasksFilterCompleted;
  @override
  String get tasksFilterHistory => _l10n.tasksFilterHistory;
  @override
  String get tasksFilterOverdue => _l10n.tasksFilterOverdue;
  @override
  String get tasksViewList => _l10n.tasksViewList;
  @override
  String get tasksViewMatrix => _l10n.tasksViewMatrix;
  @override
  String get tasksCategoryFilter => _l10n.tasksCategoryFilter;
  @override
  String get tasksAllCategories => _l10n.tasksAllCategories;
  @override
  String get taskCategoryWork => _l10n.taskCategoryWork;
  @override
  String get taskCategoryStudy => _l10n.taskCategoryStudy;
  @override
  String get taskCategoryPersonal => _l10n.taskCategoryPersonal;
  @override
  String get taskCategoryHealth => _l10n.taskCategoryHealth;
  @override
  String get taskCategorySpiritual => _l10n.taskCategorySpiritual;
  @override
  String get taskCategoryFinance => _l10n.taskCategoryFinance;
  @override
  String get taskCategoryOther => _l10n.taskCategoryOther;
  @override
  String get quadrantUrgentImportant => _l10n.quadrantUrgentImportant;
  @override
  String get quadrantNotUrgentImportant => _l10n.quadrantNotUrgentImportant;
  @override
  String get quadrantUrgentNotImportant => _l10n.quadrantUrgentNotImportant;
  @override
  String get quadrantNotUrgentNotImportant =>
      _l10n.quadrantNotUrgentNotImportant;
  @override
  String get quadrantDo => _l10n.quadrantDo;
  @override
  String get quadrantSchedule => _l10n.quadrantSchedule;
  @override
  String get quadrantDelegate => _l10n.quadrantDelegate;
  @override
  String get quadrantEliminate => _l10n.quadrantEliminate;
  @override
  String get taskCreate => _l10n.taskCreate;
  @override
  String get taskEdit => _l10n.taskEdit;
  @override
  String get taskDelete => _l10n.taskDelete;
  @override
  String get taskComplete => _l10n.taskComplete;
  @override
  String get taskReopen => _l10n.taskReopen;
  @override
  String get taskChecklistTitle => _l10n.taskChecklistTitle;
  @override
  String get taskChecklistNewHint => _l10n.taskChecklistNewHint;
  @override
  String get taskChecklistAdd => _l10n.taskChecklistAdd;
  @override
  String get taskChecklistSave => _l10n.taskChecklistSave;
  @override
  String get taskChecklistRemove => _l10n.taskChecklistRemove;
  @override
  String get taskChecklistTextRequired => _l10n.taskChecklistTextRequired;
  @override
  String taskCompletedAt(String timestamp) => _l10n.taskCompletedAt(timestamp);
  @override
  String get taskSave => _l10n.taskSave;
  @override
  String get taskCancel => _l10n.taskCancel;
  @override
  String get taskTitleLabel => _l10n.taskTitleLabel;
  @override
  String get taskTitleHint => _l10n.taskTitleHint;
  @override
  String get taskDescriptionLabel => _l10n.taskDescriptionLabel;
  @override
  String get taskDescriptionHint => _l10n.taskDescriptionHint;
  @override
  String get taskDurationLabel => _l10n.taskDurationLabel;
  @override
  String get taskDurationHint => _l10n.taskDurationHint;
  @override
  String get taskScheduledDateLabel => _l10n.taskScheduledDateLabel;
  @override
  String get taskScheduledTimeLabel => _l10n.taskScheduledTimeLabel;
  @override
  String get taskDeadlineLabel => _l10n.taskDeadlineLabel;
  @override
  String get taskDateTodayDefault => _l10n.taskDateTodayDefault;
  @override
  String get taskNotSet => _l10n.taskNotSet;
  @override
  String get taskClear => _l10n.taskClear;
  @override
  String get taskCategoryLabel => _l10n.taskCategoryLabel;
  @override
  String get taskQuadrantLabel => _l10n.taskQuadrantLabel;
  @override
  String get taskTitleRequired => _l10n.taskTitleRequired;
  @override
  String get taskDurationInvalid => _l10n.taskDurationInvalid;
  @override
  String get taskDurationUnit => _l10n.taskDurationUnit;
  @override
  String get tasksEmpty => _l10n.tasksEmpty;
  @override
  String get tasksFailure => _l10n.tasksFailure;
  @override
  String get tasksConflictNotice => _l10n.tasksConflictNotice;
  @override
  String get tasksActiveLocal => _l10n.tasksActiveLocal;
  @override
  String get tasksRetainedRemote => _l10n.tasksRetainedRemote;
}

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
  String get habitsSyncing => 'Syncing habits…';

  @override
  String get habitsSyncFailed =>
      'Habits could not finish syncing. Your saved changes remain on this device.';

  @override
  String get habitsSyncRetry => 'Retry sync';

  @override
  String get habitsConflict => 'A habit change needs review';

  @override
  String get habitsActiveVersion => 'Current version';

  @override
  String get habitsRetainedVersion => 'Retained version';

  @override
  String get habitsUnresolvedConflict =>
      'The versions have the same time and need review.';

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

  @override
  String get mindMapsTitle => 'Mind Maps';

  @override
  String get mindMapsCreate => 'New map';

  @override
  String get mindMapsSearch => 'Search maps';

  @override
  String get mindMapsEmptyLibrary => 'No maps yet. Create your first map.';

  @override
  String get mindMapsEmptySearch => 'No maps match your search.';

  @override
  String get mindMapTitleLabel => 'Map title';

  @override
  String get mindMapDescriptionLabel => 'Description';

  @override
  String get mindMapEditTitle => 'Rename';

  @override
  String get mindMapEditDescription => 'Edit description';

  @override
  String get mindMapDuplicate => 'Duplicate';

  @override
  String get mindMapDelete => 'Delete';

  @override
  String get mindMapDeleteConfirmation =>
      'Delete this map? It will disappear from your library. Linked tasks will remain.';

  @override
  String get mindMapSave => 'Save';

  @override
  String get mindMapCancel => 'Cancel';

  @override
  String get mindMapTitleRequired => 'Enter a map title';

  @override
  String get mindMapsLoadFailure => 'Could not load maps. Try again.';

  @override
  String get mindMapsSaveFailure =>
      'Could not save your map change. Please try again.';

  @override
  String get mindMapsAccountFailure => 'This account cannot change that map.';

  @override
  String get mindMapsNotFound => 'This map is no longer available.';

  @override
  String get mindMapsRetry => 'Retry';

  @override
  String get mindMapNodeCount => 'Nodes';

  @override
  String get mindMapCompletedCount => 'Completed';

  @override
  String get mindMapCentralNode => 'Central idea';

  @override
  String get mindMapsSignInRequired => 'Sign in to access your mind maps.';

  @override
  String get mindMapsBack => 'Back to maps';

  @override
  String get mindMapEditMap => 'Edit map';

  @override
  String get mindMapAddNode => 'Add node';

  @override
  String get mindMapEditNode => 'Edit node';

  @override
  String get mindMapNodeTitle => 'Node title';

  @override
  String get mindMapNodeDescription => 'Node description';

  @override
  String get mindMapNodeKind => 'Type';

  @override
  String get mindMapNodePriority => 'Priority';

  @override
  String get mindMapNodeStatus => 'Status';

  @override
  String get mindMapKindCentral => 'Central idea';

  @override
  String get mindMapKindMainIdea => 'Main idea';

  @override
  String get mindMapKindBranch => 'Branch';

  @override
  String get mindMapKindTask => 'Task idea';

  @override
  String get mindMapKindNote => 'Note';

  @override
  String get mindMapStatusNotStarted => 'Not started';

  @override
  String get mindMapStatusInProgress => 'In progress';

  @override
  String get mindMapStatusCompleted => 'Completed';

  @override
  String get mindMapPriorityLow => 'Low';

  @override
  String get mindMapPriorityMedium => 'Medium';

  @override
  String get mindMapPriorityHigh => 'High';

  @override
  String get mindMapNodeTitleRequired => 'Enter a node title';

  @override
  String get mindMapDeleteNode => 'Delete node';

  @override
  String get mindMapDeleteNodeConfirmation =>
      'Delete this node? Its children will remain as independent nodes.';

  @override
  String get mindMapParent => 'Parent branch';

  @override
  String get mindMapDetach => 'Detach from parent';

  @override
  String get mindMapSideLink => 'Visual link';

  @override
  String get mindMapConnect => 'Connect';

  @override
  String get mindMapDisconnect => 'Disconnect';

  @override
  String get mindMapMoveNode => 'Move node';

  @override
  String get mindMapUndo => 'Undo';

  @override
  String get mindMapRedo => 'Redo';

  @override
  String get mindMapGraphError =>
      'Could not save this graph change. Check the connection and try again.';

  @override
  String get mindMapNoParent => 'Independent';

  @override
  String get mindMapProgress => 'Progress';

  @override
  String get mindMapChooseTask => 'Choose a task';

  @override
  String get mindMapLinkTask => 'Link task';

  @override
  String get mindMapChangeTask => 'Change linked task';

  @override
  String get mindMapUnlinkTask => 'Unlink task';

  @override
  String get mindMapLinkedTask => 'Linked task';

  @override
  String get mindMapTaskUnavailable => 'Linked task unavailable';

  @override
  String get mindMapCompleteTask => 'Complete task';

  @override
  String get mindMapReopenTask => 'Reopen task';

  @override
  String get mindMapLoadingTasks => 'Loading tasks…';

  @override
  String get mindMapRetryTasks => 'Retry loading tasks';

  @override
  String get mindMapNoTasks => 'No accessible tasks found';

  @override
  String get mindMapTaskLinkFailure =>
      'Could not load or link this task. Try again.';

  @override
  String get mindMapSettings => 'Map settings';

  @override
  String get mindMapLayout => 'Layout';

  @override
  String get mindMapApplyLayout => 'Apply layout';

  @override
  String get mindMapLayoutRadial => 'Radial';

  @override
  String get mindMapLayoutTree => 'Tree';

  @override
  String get mindMapLayoutHorizontal => 'Horizontal';

  @override
  String get mindMapLayoutVertical => 'Vertical';

  @override
  String get mindMapLayoutFreeform => 'Freeform';

  @override
  String get mindMapBackground => 'Canvas background';

  @override
  String get mindMapDefaultNode => 'New node default';

  @override
  String get mindMapConnectionStyle => 'New connection default';

  @override
  String get mindMapSpacing => 'Spacing';

  @override
  String get mindMapNodeColor => 'Node color';

  @override
  String get mindMapConnectionColor => 'Connection color';

  @override
  String get mindMapConnectionWidth => 'Connection width';

  @override
  String get mindMapNodeIcon => 'Node icon';

  @override
  String get mindMapNodeShape => 'Node shape';

  @override
  String get mindMapNodeSize => 'Node size';

  @override
  String get mindMapTextSize => 'Text size';

  @override
  String get mindMapShapeRectangle => 'Rectangle';

  @override
  String get mindMapShapeRounded => 'Rounded';

  @override
  String get mindMapShapeCircle => 'Circle';

  @override
  String get mindMapShapePill => 'Pill';

  @override
  String get mindMapShapeGlass => 'Glass';

  @override
  String get mindMapSizeSmall => 'Small';

  @override
  String get mindMapSizeMedium => 'Medium';

  @override
  String get mindMapSizeLarge => 'Large';

  @override
  String get mindMapIconIdea => 'Idea';

  @override
  String get mindMapIconTask => 'Task';

  @override
  String get mindMapIconNote => 'Note';

  @override
  String get mindMapIconStar => 'Star';

  @override
  String get mindMapIconFlag => 'Flag';

  @override
  String get mindMapColorWhite => 'White';

  @override
  String get mindMapColorBlue => 'Blue';

  @override
  String get mindMapColorGreen => 'Green';

  @override
  String get mindMapColorAmber => 'Amber';

  @override
  String get mindMapColorPurple => 'Purple';

  @override
  String get mindMapColorDark => 'Dark';

  @override
  String get mindMapColorCurrent => 'Current color';

  @override
  String get mindMapFit => 'Fit map';

  @override
  String get mindMapCenter => 'Center map';

  @override
  String get mindMapZoomIn => 'Zoom in';

  @override
  String get mindMapZoomOut => 'Zoom out';

  @override
  String get mindMapPanLeft => 'Pan left';

  @override
  String get mindMapPanRight => 'Pan right';

  @override
  String get mindMapPanUp => 'Pan up';

  @override
  String get mindMapPanDown => 'Pan down';

  @override
  String get mindMapDragNode => 'Drag node to move';

  @override
  String get mindMapKeyboardHelp =>
      'Keyboard: arrow keys pan, plus and minus zoom, F fits, C centers';
}

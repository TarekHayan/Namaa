import 'dart:async';

import 'package:flutter/material.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/domain/checklist_item.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/tasks/presentation/tasks_cubit.dart';
import 'package:namma_project/features/tasks/presentation/tasks_state.dart';
import 'package:namma_project/features/tasks/presentation/tasks_strings.dart';

const Key kTaskTitleFieldKey = Key('task_title_field');
const Key kTaskDescriptionFieldKey = Key('task_description_field');
const Key kTaskDurationFieldKey = Key('task_duration_field');
const Key kTaskScheduledDateButtonKey = Key('task_scheduled_date_button');
const Key kTaskScheduledTimeButtonKey = Key('task_scheduled_time_button');
const Key kTaskDeadlineButtonKey = Key('task_deadline_button');
const Key kTaskSaveButtonKey = Key('task_save_button');
const Key kTaskTitleValidationKey = Key('task_title_validation');
const Key kTaskChecklistNewFieldKey = Key('task_checklist_new_field');
const Key kTaskChecklistAddButtonKey = Key('task_checklist_add_button');

class TaskEditor extends StatefulWidget {
  const TaskEditor({
    super.key,
    required this.cubit,
    required this.stringsResolver,
    required this.accountId,
    this.session,
    this.initialTask,
  });

  final TasksCubit cubit;
  final TasksStringsResolver stringsResolver;
  final String accountId;
  final CloudSessionPort? session;
  final Task? initialTask;

  static Future<void> show(
    BuildContext context, {
    required TasksCubit cubit,
    required TasksStringsResolver stringsResolver,
    required String accountId,
    CloudSessionPort? session,
    Task? initialTask,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: TaskEditor(
            cubit: cubit,
            stringsResolver: stringsResolver,
            accountId: accountId,
            session: session,
            initialTask: initialTask,
          ),
        ),
      ),
    );
  }

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;

  Task? _currentTask;
  List<ChecklistItem> _checklistItems = const [];
  late final TextEditingController _newStepController;
  String? _newStepError;
  final Map<String, TextEditingController> _stepControllers = {};
  final Map<String, String?> _stepErrors = {};
  final Set<String> _dirtyStepIds = {};

  DateTime? _scheduledDate;
  DateTime? _scheduledTime;
  DateTime? _targetDeadline;
  bool _deadlineChanged = false;
  late TaskCategory _category;
  late EisenhowerQuadrant _quadrant;

  String? _titleError;
  String? _submissionError;
  bool _isSaving = false;
  StreamSubscription<CloudSessionSnapshot>? _sessionSubscription;
  StreamSubscription<TasksState>? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    _sessionSubscription = widget.session?.observeSession().listen((snapshot) {
      if (snapshot.status != CloudSessionStatus.signedIn ||
          snapshot.accountId != widget.accountId) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
    final task = widget.initialTask;
    _currentTask = task;
    if (task != null) {
      _tasksSubscription = widget.cubit.stream.listen((state) {
        if (!mounted || state is! TasksReady) return;
        for (final latest in state.allTasks) {
          if (latest.id == task.id &&
              latest.accountId == widget.accountId &&
              !latest.isDeleted &&
              !latest.updatedAt.isBefore(_currentTask!.updatedAt) &&
              !identical(latest, _currentTask)) {
            setState(() => _updateChecklistFromTask(latest));
            break;
          }
        }
      });
    }
    _newStepController = TextEditingController();
    if (task != null) {
      _checklistItems = List<ChecklistItem>.from(task.checklistItems)
        ..sort((a, b) => a.order.compareTo(b.order));
      for (final item in _checklistItems) {
        _stepControllers[item.id] = TextEditingController(text: item.text);
      }
    }
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _durationController = TextEditingController(
      text: task == null
          ? '30'
          : task.estimatedDurationMinutes?.toString() ?? '',
    );
    _scheduledDate = task?.scheduledDate;
    _scheduledTime = task?.scheduledTime;
    _targetDeadline = task?.targetDeadline;
    _category = task?.category ?? TaskCategory.work;
    _quadrant = task?.quadrant ?? EisenhowerQuadrant.urgentImportant;
  }

  @override
  void dispose() {
    unawaited(_sessionSubscription?.cancel());
    unawaited(_tasksSubscription?.cancel());
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _newStepController.dispose();
    for (final controller in _stepControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickScheduledDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      setState(() {
        _scheduledDate = selected;
        final time = _scheduledTime;
        if (time != null) {
          _scheduledTime = DateTime(
            selected.year,
            selected.month,
            selected.day,
            time.hour,
            time.minute,
          );
        }
      });
    }
  }

  Future<void> _pickScheduledTime() async {
    final initial = _scheduledTime == null
        ? TimeOfDay.now()
        : TimeOfDay.fromDateTime(_scheduledTime!);
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected == null || !mounted) {
      return;
    }
    final date =
        _scheduledDate ?? widget.initialTask?.scheduledDate ?? DateTime.now();
    setState(() {
      _scheduledTime = DateTime(
        date.year,
        date.month,
        date.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initialDeadline = _targetDeadline?.toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDeadline ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: initialDeadline == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(initialDeadline),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      _targetDeadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _deadlineChanged = true;
    });
  }

  Future<void> _save() async {
    final session = widget.session;
    if (session != null) {
      final resolved = await session.obtainSyncContext();
      if (!mounted) return;
      if (resolved.valueOrNull?.accountId != widget.accountId) {
        Navigator.of(context).pop();
        return;
      }
    }
    final l10n = widget.stringsResolver(context);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = l10n.taskTitleRequired;
      });
      return;
    }

    final durationText = _durationController.text.trim();
    int? duration;
    if (durationText.isNotEmpty) {
      duration = int.tryParse(durationText);
      if (duration == null || duration <= 0) {
        setState(() {
          _submissionError = l10n.taskDurationInvalid;
        });
        return;
      }
    }

    setState(() {
      _titleError = null;
      _submissionError = null;
      _isSaving = true;
    });

    final task = _currentTask ?? widget.initialTask;
    final deadlineOffset = _targetDeadline == null
        ? null
        : _deadlineChanged
        ? _targetDeadline!.timeZoneOffset.inMinutes
        : task?.targetDeadlineUtcOffsetMinutes;

    if (task == null) {
      final result = await widget.cubit.createTask(
        CreateTaskInput(
          title: title,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          scheduledDate: _scheduledDate,
          scheduledTime: _scheduledTime,
          targetDeadline: _targetDeadline,
          targetDeadlineUtcOffsetMinutes: deadlineOffset,
          category: _category,
          quadrant: _quadrant,
          estimatedDurationMinutes: duration ?? 30,
        ),
      );
      if (!mounted) return;
      if (result.failureOrNull == null) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isSaving = false;
          _submissionError = l10n.tasksFailure;
        });
      }
    } else {
      final descText = _descriptionController.text.trim();
      final result = await widget.cubit.editTask(
        EditTaskInput(
          taskId: task.id,
          title: title,
          description: descText.isEmpty ? null : descText,
          clearDescription: descText.isEmpty && task.description != null,
          scheduledDate: _scheduledDate,
          scheduledTime: _scheduledTime,
          clearScheduledTime:
              _scheduledTime == null && task.scheduledTime != null,
          targetDeadline: _targetDeadline,
          targetDeadlineUtcOffsetMinutes: deadlineOffset,
          clearTargetDeadline:
              _targetDeadline == null && task.targetDeadline != null,
          category: _category,
          quadrant: _quadrant,
          estimatedDurationMinutes: duration,
          clearEstimatedDuration:
              duration == null && task.estimatedDurationMinutes != null,
        ),
      );
      if (!mounted) return;
      if (result.failureOrNull == null) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isSaving = false;
          _submissionError = l10n.tasksFailure;
        });
      }
    }
  }

  void _updateChecklistFromTask(Task updatedTask) {
    if (_currentTask != null &&
        updatedTask.updatedAt.isBefore(_currentTask!.updatedAt)) {
      return;
    }
    _currentTask = updatedTask;
    _checklistItems = List<ChecklistItem>.from(updatedTask.checklistItems)
      ..sort((a, b) => a.order.compareTo(b.order));
    final currentIds = _checklistItems.map((item) => item.id).toSet();
    _stepControllers.removeWhere((id, controller) {
      if (!currentIds.contains(id)) {
        controller.dispose();
        _dirtyStepIds.remove(id);
        return true;
      }
      return false;
    });
    _stepErrors.removeWhere((id, _) => !currentIds.contains(id));
    for (final item in _checklistItems) {
      if (!_stepControllers.containsKey(item.id)) {
        _stepControllers[item.id] = TextEditingController(text: item.text);
      } else {
        if (_stepControllers[item.id]!.text != item.text &&
            !_dirtyStepIds.contains(item.id)) {
          _stepControllers[item.id]!.text = item.text;
        }
      }
    }
  }

  Future<void> _addChecklistItem() async {
    final text = _newStepController.text.trim();
    final l10n = widget.stringsResolver(context);
    if (text.isEmpty) {
      setState(() {
        _newStepError = l10n.taskChecklistTextRequired;
      });
      return;
    }
    final task = _currentTask ?? widget.initialTask!;
    final result = await widget.cubit.addChecklistItem(
      taskId: task.id,
      text: text,
    );
    if (!mounted) return;
    if (result.failureOrNull == null && result.valueOrNull != null) {
      _newStepController.clear();
      setState(() {
        _newStepError = null;
        _updateChecklistFromTask(result.valueOrNull!);
      });
    } else {
      setState(() {
        _submissionError = l10n.tasksFailure;
      });
    }
  }

  Future<void> _toggleChecklistItem(ChecklistItem item) async {
    final task = _currentTask ?? widget.initialTask!;
    final result = await widget.cubit.setChecklistItemCompleted(
      taskId: task.id,
      itemId: item.id,
      completed: !item.completed,
    );
    if (!mounted) return;
    if (result.failureOrNull == null && result.valueOrNull != null) {
      setState(() {
        _updateChecklistFromTask(result.valueOrNull!);
      });
    } else {
      final l10n = widget.stringsResolver(context);
      setState(() {
        _submissionError = l10n.tasksFailure;
      });
    }
  }

  Future<void> _saveChecklistItem(ChecklistItem item) async {
    final text = _stepControllers[item.id]?.text.trim() ?? '';
    final l10n = widget.stringsResolver(context);
    if (text.isEmpty) {
      setState(() {
        _stepErrors[item.id] = l10n.taskChecklistTextRequired;
      });
      return;
    }
    final task = _currentTask ?? widget.initialTask!;
    final result = await widget.cubit.editChecklistItem(
      taskId: task.id,
      itemId: item.id,
      text: text,
    );
    if (!mounted) return;
    if (result.failureOrNull == null && result.valueOrNull != null) {
      setState(() {
        _stepErrors.remove(item.id);
        if (_stepControllers[item.id]?.text.trim() == text) {
          _dirtyStepIds.remove(item.id);
        }
        _updateChecklistFromTask(result.valueOrNull!);
      });
    } else {
      setState(() {
        _submissionError = l10n.tasksFailure;
      });
    }
  }

  Future<void> _removeChecklistItem(ChecklistItem item) async {
    final task = _currentTask ?? widget.initialTask!;
    final result = await widget.cubit.removeChecklistItem(
      taskId: task.id,
      itemId: item.id,
    );
    if (!mounted) return;
    if (result.failureOrNull == null && result.valueOrNull != null) {
      setState(() {
        _updateChecklistFromTask(result.valueOrNull!);
      });
    } else {
      final l10n = widget.stringsResolver(context);
      setState(() {
        _submissionError = l10n.tasksFailure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.stringsResolver(context);
    final theme = Theme.of(context);
    final isEditing = widget.initialTask != null;
    final material = MaterialLocalizations.of(context);
    final scheduledDateText = _scheduledDate == null
        ? l10n.taskDateTodayDefault
        : material.formatMediumDate(_scheduledDate!);
    final scheduledTimeText = _scheduledTime == null
        ? l10n.taskNotSet
        : material.formatTimeOfDay(TimeOfDay.fromDateTime(_scheduledTime!));
    final deadline = _targetDeadline?.toLocal();
    final deadlineText = deadline == null
        ? l10n.taskNotSet
        : '${material.formatMediumDate(deadline)} · '
              '${material.formatTimeOfDay(TimeOfDay.fromDateTime(deadline))}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEditing ? l10n.taskEdit : l10n.taskCreate,
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: kTaskTitleFieldKey,
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.taskTitleLabel,
                    hintText: l10n.taskTitleHint,
                  ),
                  onChanged: (_) {
                    if (_titleError != null) {
                      setState(() => _titleError = null);
                    }
                  },
                ),
                if (_titleError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _titleError!,
                    key: kTaskTitleValidationKey,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  key: kTaskDescriptionFieldKey,
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.taskDescriptionLabel,
                    hintText: l10n.taskDescriptionHint,
                  ),
                  maxLines: 2,
                ),
                if (isEditing) ...[
                  const SizedBox(height: 16),
                  _buildChecklistSection(context, theme, l10n),
                ],
                const SizedBox(height: 16),
                TextField(
                  key: kTaskDurationFieldKey,
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.taskDurationLabel,
                    hintText: l10n.taskDurationHint,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: kTaskScheduledDateButtonKey,
                      onPressed: _pickScheduledDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        '${l10n.taskScheduledDateLabel}: $scheduledDateText',
                      ),
                    ),
                    OutlinedButton.icon(
                      key: kTaskScheduledTimeButtonKey,
                      onPressed: _pickScheduledTime,
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(
                        '${l10n.taskScheduledTimeLabel}: $scheduledTimeText',
                      ),
                    ),
                    if (_scheduledTime != null)
                      IconButton(
                        tooltip: l10n.taskClear,
                        onPressed: () => setState(() => _scheduledTime = null),
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: kTaskDeadlineButtonKey,
                        onPressed: _pickDeadline,
                        icon: const Icon(Icons.event_available_outlined),
                        label: Text('${l10n.taskDeadlineLabel}: $deadlineText'),
                      ),
                    ),
                    if (_targetDeadline != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: l10n.taskClear,
                        onPressed: () => setState(() {
                          _targetDeadline = null;
                          _deadlineChanged = true;
                        }),
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskCategory>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: l10n.taskCategoryLabel,
                  ),
                  items: TaskCategory.values.map((category) {
                    return DropdownMenuItem<TaskCategory>(
                      value: category,
                      child: Text(_localizedCategory(category, l10n)),
                    );
                  }).toList(),
                  onChanged: (cat) {
                    if (cat != null) setState(() => _category = cat);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EisenhowerQuadrant>(
                  initialValue: _quadrant,
                  decoration: InputDecoration(
                    labelText: l10n.taskQuadrantLabel,
                  ),
                  items: EisenhowerQuadrant.values.map((quadrant) {
                    return DropdownMenuItem<EisenhowerQuadrant>(
                      value: quadrant,
                      child: Text(_localizedQuadrant(quadrant, l10n)),
                    );
                  }).toList(),
                  onChanged: (quad) {
                    if (quad != null) setState(() => _quadrant = quad);
                  },
                ),
                if (_submissionError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _submissionError!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.taskCancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: kTaskSaveButtonKey,
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.taskSave),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistSection(
    BuildContext context,
    ThemeData theme,
    TasksStrings l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.taskChecklistTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in _checklistItems) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              key: ValueKey<String>('task-checklist-row-${item.id}'),
              children: [
                Semantics(
                  label: item.text,
                  child: Checkbox(
                    key: ValueKey<String>('task-checklist-toggle-${item.id}'),
                    value: item.completed,
                    onChanged: (_) => _toggleChecklistItem(item),
                  ),
                ),
                Expanded(
                  child: TextField(
                    key: ValueKey<String>('task-checklist-text-${item.id}'),
                    controller: _stepControllers.putIfAbsent(
                      item.id,
                      () => TextEditingController(text: item.text),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      errorText: _stepErrors[item.id],
                    ),
                    onChanged: (_) {
                      _dirtyStepIds.add(item.id);
                      if (_stepErrors[item.id] != null) {
                        setState(() => _stepErrors.remove(item.id));
                      }
                    },
                  ),
                ),
                IconButton(
                  key: ValueKey<String>('task-checklist-save-${item.id}'),
                  icon: const Icon(Icons.check, size: 20),
                  tooltip: l10n.taskChecklistSave,
                  onPressed: () => _saveChecklistItem(item),
                ),
                IconButton(
                  key: ValueKey<String>('task-checklist-remove-${item.id}'),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: l10n.taskChecklistRemove,
                  onPressed: () => _removeChecklistItem(item),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: kTaskChecklistNewFieldKey,
                controller: _newStepController,
                decoration: InputDecoration(
                  hintText: l10n.taskChecklistNewHint,
                  errorText: _newStepError,
                  isDense: true,
                ),
                onChanged: (_) {
                  if (_newStepError != null) {
                    setState(() => _newStepError = null);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: kTaskChecklistAddButtonKey,
              icon: const Icon(Icons.add),
              tooltip: l10n.taskChecklistAdd,
              onPressed: _addChecklistItem,
            ),
          ],
        ),
      ],
    );
  }

  static String _localizedCategory(TaskCategory category, TasksStrings l10n) =>
      switch (category) {
        TaskCategory.work => l10n.taskCategoryWork,
        TaskCategory.study => l10n.taskCategoryStudy,
        TaskCategory.personal => l10n.taskCategoryPersonal,
        TaskCategory.health => l10n.taskCategoryHealth,
        TaskCategory.spiritual => l10n.taskCategorySpiritual,
        TaskCategory.finance => l10n.taskCategoryFinance,
        TaskCategory.other => l10n.taskCategoryOther,
      };

  static String _localizedQuadrant(
    EisenhowerQuadrant quadrant,
    TasksStrings l10n,
  ) => switch (quadrant) {
    EisenhowerQuadrant.urgentImportant => l10n.quadrantUrgentImportant,
    EisenhowerQuadrant.notUrgentImportant => l10n.quadrantNotUrgentImportant,
    EisenhowerQuadrant.urgentNotImportant => l10n.quadrantUrgentNotImportant,
    EisenhowerQuadrant.notUrgentNotImportant =>
      l10n.quadrantNotUrgentNotImportant,
  };
}

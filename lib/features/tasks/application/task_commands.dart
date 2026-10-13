import 'dart:math';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/domain/checklist_item.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

typedef InstantProvider = DateTime Function();
typedef IdProvider = String Function();

final class CreateTaskInput {
  const CreateTaskInput({
    required this.title,
    this.description,
    this.scheduledDate,
    this.scheduledTime,
    this.targetDeadline,
    this.targetDeadlineUtcOffsetMinutes,
    this.category = TaskCategory.work,
    this.quadrant = EisenhowerQuadrant.urgentImportant,
    this.estimatedDurationMinutes = 30,
    this.checklistItems = const <ChecklistItem>[],
    this.completionXp = 20,
  });

  final String title;
  final String? description;
  final DateTime? scheduledDate;
  final DateTime? scheduledTime;
  final DateTime? targetDeadline;
  final int? targetDeadlineUtcOffsetMinutes;
  final TaskCategory category;
  final EisenhowerQuadrant quadrant;
  final int? estimatedDurationMinutes;
  final List<ChecklistItem> checklistItems;
  final int completionXp;
}

final class EditTaskInput {
  const EditTaskInput({
    required this.taskId,
    this.title,
    this.description,
    this.clearDescription = false,
    this.scheduledDate,
    this.scheduledTime,
    this.clearScheduledTime = false,
    this.targetDeadline,
    this.targetDeadlineUtcOffsetMinutes,
    this.clearTargetDeadline = false,
    this.category,
    this.quadrant,
    this.estimatedDurationMinutes,
    this.clearEstimatedDuration = false,
  });

  final String taskId;
  final String? title;
  final String? description;
  final bool clearDescription;
  final DateTime? scheduledDate;
  final DateTime? scheduledTime;
  final bool clearScheduledTime;
  final DateTime? targetDeadline;
  final int? targetDeadlineUtcOffsetMinutes;
  final bool clearTargetDeadline;
  final TaskCategory? category;
  final EisenhowerQuadrant? quadrant;
  final int? estimatedDurationMinutes;
  final bool clearEstimatedDuration;
}

/// Account-scoped local-first create/edit/move/delete use cases.
final class TaskCommands {
  TaskCommands({
    required TaskRepository repository,
    required CloudSessionPort session,
    InstantProvider? nowUtc,
    InstantProvider? localDate,
    IdProvider? nextTaskId,
    IdProvider? nextOperationId,
    IdProvider? nextChecklistItemId,
  }) : _repository = repository,
       _session = session,
       _nowUtc = nowUtc ?? _systemUtcNow,
       _localDate = localDate ?? _systemLocalDate,
       _nextTaskId = nextTaskId ?? _newUuidV4,
       _nextOperationId = nextOperationId ?? _newUuidV4,
       _nextChecklistItemId = nextChecklistItemId ?? _newUuidV4;

  final TaskRepository _repository;
  final CloudSessionPort _session;
  final InstantProvider _nowUtc;
  final InstantProvider _localDate;
  final IdProvider _nextTaskId;
  final IdProvider _nextOperationId;
  final IdProvider _nextChecklistItemId;

  Future<AppResult<Task>> createTask(
    CreateTaskInput input, {
    String? expectedAccountId,
  }) async {
    final titleFailure = _validateTitle(input.title);
    if (titleFailure != null) {
      return AppResult<Task>.failure(titleFailure);
    }
    final contextResult = await _session.obtainSyncContext();
    final context = contextResult.valueOrNull;
    if (context == null) {
      return AppResult<Task>.failure(
        contextResult.failureOrNull ?? _signInFailure(_nowUtc()),
      );
    }
    if (expectedAccountId != null && context.accountId != expectedAccountId) {
      return AppResult<Task>.failure(_signInFailure(_nowUtc()));
    }
    final now = _nowUtc();
    try {
      final task = Task.create(
        id: _nextTaskId(),
        accountId: context.accountId,
        title: input.title,
        description: input.description,
        scheduledDate: input.scheduledDate ?? _localDate(),
        scheduledTime: input.scheduledTime,
        targetDeadline: input.targetDeadline,
        targetDeadlineUtcOffsetMinutes: input.targetDeadlineUtcOffsetMinutes,
        category: input.category,
        quadrant: input.quadrant,
        estimatedDurationMinutes: input.estimatedDurationMinutes,
        checklistItems: input.checklistItems,
        completionXp: input.completionXp,
        createdAt: now,
      );
      return _commit(task, ChangeKind.create, now);
    } on ArgumentError catch (error) {
      return AppResult<Task>.failure(_validationFailure(now, error));
    }
  }

  Future<AppResult<Task>> editTask(
    EditTaskInput input, {
    String? expectedAccountId,
  }) async {
    final title = input.title;
    if (title != null) {
      final titleFailure = _validateTitle(title);
      if (titleFailure != null) {
        return AppResult<Task>.failure(titleFailure);
      }
    }
    return _changeExisting(input.taskId, (task, now) {
      return task.copyWith(
        title: input.title,
        description: input.clearDescription
            ? null
            : input.description ?? task.description,
        scheduledDate: input.scheduledDate,
        scheduledTime: input.clearScheduledTime
            ? null
            : input.scheduledTime ?? task.scheduledTime,
        targetDeadline: input.clearTargetDeadline
            ? null
            : input.targetDeadline ?? task.targetDeadline,
        targetDeadlineUtcOffsetMinutes: input.clearTargetDeadline
            ? null
            : input.targetDeadlineUtcOffsetMinutes ??
                  task.targetDeadlineUtcOffsetMinutes,
        category: input.category,
        quadrant: input.quadrant,
        estimatedDurationMinutes: input.clearEstimatedDuration
            ? null
            : input.estimatedDurationMinutes ?? task.estimatedDurationMinutes,
        updatedAt: now,
      );
    }, expectedAccountId: expectedAccountId);
  }

  Future<AppResult<Task>> moveTask({
    required String taskId,
    required EisenhowerQuadrant quadrant,
    String? expectedAccountId,
  }) => _changeExisting(
    taskId,
    (task, now) => task.copyWith(quadrant: quadrant, updatedAt: now),
    expectedAccountId: expectedAccountId,
  );

  Future<AppResult<Task>> addChecklistItem({
    required String taskId,
    required String text,
    String? expectedAccountId,
  }) {
    final validation = _validateChecklistText(text);
    if (validation != null) {
      return Future<AppResult<Task>>.value(AppResult<Task>.failure(validation));
    }
    return _changeExisting(
      taskId,
      (task, now) => task.addChecklistItem(
        id: _nextChecklistItemId(),
        text: text,
        updatedAt: now,
      ),
      expectedAccountId: expectedAccountId,
    );
  }

  Future<AppResult<Task>> editChecklistItem({
    required String taskId,
    required String itemId,
    required String text,
    String? expectedAccountId,
  }) {
    final validation = _validateChecklistText(text);
    if (validation != null) {
      return Future<AppResult<Task>>.value(AppResult<Task>.failure(validation));
    }
    return _changeExisting(taskId, (task, now) {
      _requireChecklistItem(task, itemId);
      return task.editChecklistItem(itemId: itemId, text: text, updatedAt: now);
    }, expectedAccountId: expectedAccountId);
  }

  Future<AppResult<Task>> setChecklistItemCompleted({
    required String taskId,
    required String itemId,
    required bool completed,
    String? expectedAccountId,
  }) => _changeExisting(taskId, (task, now) {
    _requireChecklistItem(task, itemId);
    return task.setChecklistItemCompleted(
      itemId: itemId,
      completed: completed,
      updatedAt: now,
    );
  }, expectedAccountId: expectedAccountId);

  Future<AppResult<Task>> removeChecklistItem({
    required String taskId,
    required String itemId,
    String? expectedAccountId,
  }) => _changeExisting(taskId, (task, now) {
    _requireChecklistItem(task, itemId);
    return task.removeChecklistItem(itemId: itemId, updatedAt: now);
  }, expectedAccountId: expectedAccountId);

  Future<AppResult<void>> deleteTask(
    String taskId, {
    String? expectedAccountId,
  }) async {
    final changed = await _changeExisting(
      taskId,
      (task, now) => task.markDeleted(now),
      kind: ChangeKind.delete,
      expectedAccountId: expectedAccountId,
    );
    final failure = changed.failureOrNull;
    return failure == null
        ? AppResult<void>.success(null)
        : AppResult<void>.failure(failure);
  }

  Future<AppResult<Task>> _changeExisting(
    String taskId,
    Task Function(Task task, DateTime now) change, {
    ChangeKind kind = ChangeKind.update,
    String? expectedAccountId,
  }) async {
    final contextResult = await _session.obtainSyncContext();
    final context = contextResult.valueOrNull;
    if (context == null) {
      return AppResult<Task>.failure(
        contextResult.failureOrNull ?? _signInFailure(_nowUtc()),
      );
    }
    if (expectedAccountId != null && context.accountId != expectedAccountId) {
      return AppResult<Task>.failure(_signInFailure(_nowUtc()));
    }
    // The aggregate must be read and written under the same repository lock.
    // Otherwise simultaneous checklist edits can each overwrite the other's
    // copy of the parent Task (and its owned checklist payload).
    return _repository.runInTransaction(() async {
      final read = await _repository.readTask(
        accountId: context.accountId,
        taskId: taskId,
      );
      final readFailure = read.failureOrNull;
      if (readFailure != null) {
        return AppResult<Task>.failure(readFailure);
      }
      final task = read.valueOrNull;
      if (task == null ||
          task.accountId != context.accountId ||
          task.isDeleted) {
        return AppResult<Task>.failure(_notFoundFailure(_nowUtc()));
      }
      final requestedNow = _nowUtc();
      final now = requestedNow.isAfter(task.updatedAt)
          ? requestedNow
          : task.updatedAt.add(const Duration(microseconds: 1));
      try {
        return await _commit(change(task, now), kind, now);
      } on _ChecklistItemNotFound {
        return AppResult<Task>.failure(_checklistNotFoundFailure(now));
      } on ArgumentError catch (error) {
        return AppResult<Task>.failure(_validationFailure(now, error));
      }
    });
  }

  Future<AppResult<Task>> _commit(
    Task task,
    ChangeKind kind,
    DateTime queuedAt,
  ) async {
    final currentSession = await _session.obtainSyncContext();
    if (currentSession.valueOrNull?.accountId != task.accountId) {
      return AppResult<Task>.failure(_signInFailure(_nowUtc()));
    }
    final result = await _repository.commitTask(
      TaskWriteRequest(
        task: task,
        operationId: _nextOperationId(),
        kind: kind,
        queuedAt: queuedAt,
      ),
    );
    final failure = result.failureOrNull;
    return failure == null
        ? AppResult<Task>.success(task)
        : AppResult<Task>.failure(failure);
  }

  AppFailure? _validateTitle(String title) => title.trim().isEmpty
      ? taskCommandFailure(
          category: AppFailureCategory.validation,
          messageKey: 'tasks.validation.title_required',
          occurredAt: _nowUtc(),
        )
      : null;

  AppFailure? _validateChecklistText(String text) => text.trim().isEmpty
      ? taskCommandFailure(
          category: AppFailureCategory.validation,
          messageKey: 'tasks.validation.checklist_text_required',
          occurredAt: _nowUtc(),
        )
      : null;

  static void _requireChecklistItem(Task task, String itemId) {
    final normalizedId = itemId.trim();
    if (normalizedId.isEmpty ||
        !task.checklistItems.any((item) => item.id == normalizedId)) {
      throw const _ChecklistItemNotFound();
    }
  }

  static AppFailure _validationFailure(DateTime now, ArgumentError error) =>
      taskCommandFailure(
        category: AppFailureCategory.validation,
        messageKey: 'tasks.validation.invalid_value',
        occurredAt: now,
        technicalCause: error.name,
      );

  static AppFailure _notFoundFailure(DateTime now) => taskCommandFailure(
    category: AppFailureCategory.notFound,
    messageKey: 'tasks.error.not_found',
    occurredAt: now,
  );

  static AppFailure _checklistNotFoundFailure(DateTime now) =>
      taskCommandFailure(
        category: AppFailureCategory.notFound,
        messageKey: 'tasks.error.checklist_not_found',
        occurredAt: now,
      );

  static AppFailure _signInFailure(DateTime now) => taskCommandFailure(
    messageKey: 'tasks.auth.sign_in_required',
    occurredAt: now,
  );

  static DateTime _systemUtcNow() => DateTime.now().toUtc();

  static DateTime _systemLocalDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _newUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String byte(int index) => bytes[index].toRadixString(16).padLeft(2, '0');
    return '${byte(0)}${byte(1)}${byte(2)}${byte(3)}-'
        '${byte(4)}${byte(5)}-'
        '${byte(6)}${byte(7)}-'
        '${byte(8)}${byte(9)}-'
        '${byte(10)}${byte(11)}${byte(12)}${byte(13)}${byte(14)}${byte(15)}';
  }
}

final class _ChecklistItemNotFound implements Exception {
  const _ChecklistItemNotFound();
}

/// Builds a non-recoverable, localized application failure without exposing
/// infrastructure detail. Public for deterministic session fakes and adapters.
AppFailure taskCommandFailure({
  required String messageKey,
  required DateTime occurredAt,
  AppFailureCategory category = AppFailureCategory.authorization,
  String? technicalCause,
}) => AppFailure.blocking(
  category: category,
  messageKey: messageKey,
  occurredAt: occurredAt,
  technicalCause: technicalCause,
);

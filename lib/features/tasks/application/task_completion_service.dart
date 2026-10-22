import 'dart:math';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_commands.dart';
import 'package:namma_project/features/tasks/application/task_completion_unit_of_work.dart';
import 'package:namma_project/features/tasks/application/task_repository.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

typedef CompletionInstantProvider = DateTime Function();
typedef CompletionLocalDateProvider = DateTime Function();
typedef CompletionOperationIdProvider = String Function();

/// Account-scoped explicit completion and reopening use cases.
final class TaskCompletionService {
  TaskCompletionService({
    required TaskRepository repository,
    required TaskCompletionUnitOfWork unitOfWork,
    required CloudSessionPort session,
    CompletionInstantProvider? nowUtc,
    CompletionLocalDateProvider? currentLocalDate,
    CompletionOperationIdProvider? nextOperationId,
  }) : _repository = repository,
       _unitOfWork = unitOfWork,
       _session = session,
       _nowUtc = nowUtc ?? _systemUtcNow,
       _currentLocalDate = currentLocalDate ?? _systemLocalDate,
       _nextOperationId = nextOperationId ?? _newUuidV4;

  final TaskRepository _repository;
  final TaskCompletionUnitOfWork _unitOfWork;
  final CloudSessionPort _session;
  final CompletionInstantProvider _nowUtc;
  final CompletionLocalDateProvider _currentLocalDate;
  final CompletionOperationIdProvider _nextOperationId;

  Future<AppResult<Task>> completeTask(
    String taskId, {
    String? expectedAccountId,
    DateTime? expectedLocalDate,
  }) => _changeCompletion(
    taskId: taskId,
    expectedAccountId: expectedAccountId,
    expectedLocalDate: expectedLocalDate,
    complete: true,
  );

  Future<AppResult<Task>> reopenTask(
    String taskId, {
    String? expectedAccountId,
    DateTime? expectedLocalDate,
  }) => _changeCompletion(
    taskId: taskId,
    expectedAccountId: expectedAccountId,
    expectedLocalDate: expectedLocalDate,
    complete: false,
  );

  Future<AppResult<Task>> _changeCompletion({
    required String taskId,
    required bool complete,
    String? expectedAccountId,
    DateTime? expectedLocalDate,
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
    if (!_sameDay(expectedLocalDate, _currentLocalDate())) {
      return AppResult<Task>.failure(_staleDayFailure(_nowUtc()));
    }
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
      if (!_sameDay(expectedLocalDate, _currentLocalDate()) ||
          !_sameDay(expectedLocalDate, task.scheduledDate)) {
        return AppResult<Task>.failure(_staleDayFailure(_nowUtc()));
      }

      final currentSession = await _session.obtainSyncContext();
      if (currentSession.valueOrNull?.accountId != context.accountId) {
        return AppResult<Task>.failure(_signInFailure(_nowUtc()));
      }
      if (!_sameDay(expectedLocalDate, _currentLocalDate())) {
        return AppResult<Task>.failure(_staleDayFailure(_nowUtc()));
      }
      if ((complete && task.isCompleted) || (!complete && !task.isCompleted)) {
        return AppResult<Task>.success(task);
      }

      final requestedNow = _nowUtc();
      final now = requestedNow.isAfter(task.updatedAt)
          ? requestedNow
          : task.updatedAt.add(const Duration(microseconds: 1));
      try {
        final changed = complete ? task.complete(now) : task.reopen(now);
        final result = await _unitOfWork.commit(
          TaskCompletionCommit(
            task: changed,
            firstAward: complete
                ? TaskCompletionAward(
                    accountId: task.accountId,
                    source: kTaskDoneAwardSource,
                    sourceId: task.id,
                    amount: task.completionXp,
                    awardedAt: now,
                  )
                : null,
            operationId: _nextOperationId(),
            queuedAt: now,
          ),
        );
        final failure = result.failureOrNull;
        return failure == null
            ? AppResult<Task>.success(changed)
            : AppResult<Task>.failure(failure);
      } on ArgumentError catch (error) {
        return AppResult<Task>.failure(
          taskCommandFailure(
            category: AppFailureCategory.validation,
            messageKey: 'tasks.validation.invalid_value',
            occurredAt: now,
            technicalCause: error.name,
          ),
        );
      }
    });
  }

  static bool _sameDay(DateTime? expected, DateTime actual) =>
      expected == null ||
      (expected.year == actual.year &&
          expected.month == actual.month &&
          expected.day == actual.day);

  static AppFailure _staleDayFailure(DateTime now) => taskCommandFailure(
    category: AppFailureCategory.validation,
    messageKey: 'tasks.validation.stale_day',
    occurredAt: now,
  );

  static AppFailure _notFoundFailure(DateTime now) => taskCommandFailure(
    category: AppFailureCategory.notFound,
    messageKey: 'tasks.error.not_found',
    occurredAt: now,
  );

  static AppFailure _signInFailure(DateTime now) => taskCommandFailure(
    messageKey: 'tasks.auth.sign_in_required',
    occurredAt: now,
  );

  static DateTime _systemUtcNow() => DateTime.now().toUtc();
  static DateTime _systemLocalDate() => DateTime.now();

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

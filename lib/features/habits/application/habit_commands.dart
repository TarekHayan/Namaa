import 'dart:math';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/application/habit_repository.dart';
import 'package:namma_project/features/habits/domain/habit.dart';
import 'package:namma_project/features/habits/domain/habit_day.dart';

typedef HabitCalendar = ({String localDate, int utcOffsetMinutes}) Function();
typedef HabitInstant = DateTime Function();
typedef HabitId = String Function();

final class CreateHabitInput {
  const CreateHabitInput({
    required this.name,
    required this.weekdays,
    this.reminderMinuteOfDay,
    this.dailyTarget = 1,
  });
  final String name;
  final Set<int> weekdays;
  final int? reminderMinuteOfDay;
  final int dailyTarget;
}

final class EditHabitInput {
  const EditHabitInput({
    required this.habitId,
    required this.name,
    required this.weekdays,
    required this.reminderMinuteOfDay,
  });
  final String habitId;
  final String name;
  final Set<int> weekdays;
  final int? reminderMinuteOfDay;
}

/// Local-first commands. The session supplies the owner for every read/write.
final class HabitCommands {
  HabitCommands({
    required HabitRepository repository,
    required CloudSessionPort session,
    HabitInstant? nowUtc,
    HabitCalendar? localCalendar,
    HabitId? nextHabitId,
    HabitId? nextRevisionId,
    HabitId? nextOperationId,
  }) : _repository = repository,
       _session = session,
       _nowUtc = nowUtc ?? _systemUtc,
       _localCalendar = localCalendar ?? _systemCalendar,
       _nextHabitId = nextHabitId ?? _newUuid,
       _nextRevisionId = nextRevisionId ?? _newUuid,
       _nextOperationId = nextOperationId ?? _newUuid;

  final HabitRepository _repository;
  final CloudSessionPort _session;
  final HabitInstant _nowUtc;
  final HabitCalendar _localCalendar;
  final HabitId _nextHabitId;
  final HabitId _nextRevisionId;
  final HabitId _nextOperationId;

  Future<AppResult<Habit>> createHabit(
    CreateHabitInput input, {
    String? expectedAccountId,
  }) async {
    if (input.name.trim().isEmpty) {
      return AppResult.failure(
        _error(AppFailureCategory.validation, 'habits.validation.name'),
      );
    }
    if (input.weekdays.isEmpty ||
        input.weekdays.any((day) => day < 1 || day > 7)) {
      return AppResult.failure(
        _error(AppFailureCategory.validation, 'habits.validation.weekdays'),
      );
    }
    if (input.reminderMinuteOfDay != null &&
        (input.reminderMinuteOfDay! < 0 || input.reminderMinuteOfDay! > 1439)) {
      return AppResult.failure(
        _error(AppFailureCategory.validation, 'habits.validation.reminder'),
      );
    }
    if (input.dailyTarget < 1 || input.dailyTarget > 9999) {
      return AppResult.failure(
        _error(AppFailureCategory.validation, 'habits.validation.daily_target'),
      );
    }
    final account = await _account(expectedAccountId);
    if (account.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final now = _nowUtc();
    final calendar = _localCalendar();
    try {
      final habit = Habit.create(
        id: _nextHabitId(),
        accountId: account.valueOrNull!,
        name: input.name,
        weekdays: input.weekdays,
        revisionId: _nextRevisionId(),
        createdAt: now,
        effectiveLocalDate: calendar.localDate,
        utcOffsetMinutes: calendar.utcOffsetMinutes,
        reminderMinuteOfDay: input.reminderMinuteOfDay,
        dailyTarget: input.dailyTarget,
      );
      final checked = await _account(expectedAccountId);
      if (checked.valueOrNull != habit.accountId) {
        return AppResult.failure(
          _error(AppFailureCategory.authorization, 'habits.error.account'),
        );
      }
      final commit = await _repository.commitHabit(
        HabitWriteRequest(
          habit: habit,
          operationId: _nextOperationId(),
          kind: ChangeKind.create,
          queuedAt: now,
        ),
      );
      final failure = commit.failureOrNull;
      return failure == null
          ? AppResult.success(habit)
          : AppResult.failure(failure);
    } on ArgumentError {
      return AppResult.failure(
        _error(AppFailureCategory.validation, 'habits.validation.invalid'),
      );
    }
  }

  Future<AppResult<Habit>> editHabit(
    EditHabitInput input, {
    String? expectedAccountId,
  }) async {
    final validation = _validateFields(
      input.name,
      input.weekdays,
      input.reminderMinuteOfDay,
    );
    if (validation != null) return AppResult.failure(validation);
    final account = await _account(expectedAccountId);
    if (account.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final owner = account.valueOrNull!;
    return _repository.runInTransaction(() async {
      final existing = await _repository.readHabit(
        accountId: owner,
        habitId: input.habitId,
      );
      if (existing.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      final current = existing.valueOrNull;
      if (current == null || current.isDeleted) {
        return AppResult.failure(
          _error(AppFailureCategory.notFound, 'habits.error.not_found'),
        );
      }
      try {
        final requested = _nowUtc();
        final calendar = _localCalendar();
        final updated = current.edit(
          name: input.name,
          weekdays: input.weekdays,
          reminderMinuteOfDay: input.reminderMinuteOfDay,
          revisionId: _nextRevisionId(),
          editedAt: requested,
          effectiveLocalDate: calendar.localDate,
          utcOffsetMinutes: calendar.utcOffsetMinutes,
        );
        final checked = await _account(expectedAccountId);
        if (checked.valueOrNull != owner) {
          return AppResult.failure(
            _error(AppFailureCategory.authorization, 'habits.error.account'),
          );
        }
        final commit = await _repository.commitHabit(
          HabitWriteRequest(
            habit: updated,
            operationId: _nextOperationId(),
            kind: ChangeKind.update,
            queuedAt: updated.updatedAt,
          ),
        );
        final failure = commit.failureOrNull;
        return failure == null
            ? AppResult.success(updated)
            : AppResult.failure(failure);
      } on ArgumentError {
        return AppResult.failure(
          _error(AppFailureCategory.validation, 'habits.validation.invalid'),
        );
      }
    });
  }

  Future<AppResult<Habit>> deleteHabit(
    String habitId, {
    required bool confirmed,
    String? expectedAccountId,
  }) async {
    if (!confirmed) {
      return AppResult.failure(
        _error(
          AppFailureCategory.validation,
          'habits.validation.confirm_delete',
        ),
      );
    }
    final account = await _account(expectedAccountId);
    if (account.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final owner = account.valueOrNull!;
    return _repository.runInTransaction(() async {
      final existing = await _repository.readHabit(
        accountId: owner,
        habitId: habitId,
      );
      if (existing.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      final current = existing.valueOrNull;
      if (current == null || current.isDeleted) {
        return AppResult.failure(
          _error(AppFailureCategory.notFound, 'habits.error.not_found'),
        );
      }
      final deleted = current.delete(_nowUtc());
      final checked = await _account(expectedAccountId);
      if (checked.valueOrNull != owner) {
        return AppResult.failure(
          _error(AppFailureCategory.authorization, 'habits.error.account'),
        );
      }
      final commit = await _repository.commitHabit(
        HabitWriteRequest(
          habit: deleted,
          operationId: _nextOperationId(),
          kind: ChangeKind.delete,
          queuedAt: deleted.updatedAt,
        ),
      );
      final failure = commit.failureOrNull;
      return failure == null
          ? AppResult.success(deleted)
          : AppResult.failure(failure);
    });
  }

  AppFailure? _validateFields(
    String name,
    Set<int> weekdays,
    int? reminderMinuteOfDay,
  ) {
    if (name.trim().isEmpty) {
      return _error(AppFailureCategory.validation, 'habits.validation.name');
    }
    if (weekdays.isEmpty || weekdays.any((day) => day < 1 || day > 7)) {
      return _error(
        AppFailureCategory.validation,
        'habits.validation.weekdays',
      );
    }
    if (reminderMinuteOfDay != null &&
        (reminderMinuteOfDay < 0 || reminderMinuteOfDay > 1439)) {
      return _error(
        AppFailureCategory.validation,
        'habits.validation.reminder',
      );
    }
    return null;
  }

  Future<AppResult<HabitDay>> completeHabitToday(
    String habitId, {
    String? expectedAccountId,
    String? expectedLocalDate,
  }) async {
    final account = await _account(expectedAccountId);
    if (account.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final owner = account.valueOrNull!;
    final calendar = _localCalendar();
    if (expectedLocalDate != null && expectedLocalDate != calendar.localDate) {
      return AppResult.failure(_staleDay());
    }
    return _repository.runInTransaction(() async {
      final habitResult = await _repository.readHabit(
        accountId: owner,
        habitId: habitId,
      );
      if (habitResult.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      final habit = habitResult.valueOrNull;
      if (habit == null || habit.isDeleted) {
        return AppResult.failure(
          _error(AppFailureCategory.notFound, 'habits.error.not_found'),
        );
      }
      final previous = await _repository.readDay(
        accountId: owner,
        habitId: habitId,
        localDate: calendar.localDate,
      );
      if (previous.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      final checked = await _account(expectedAccountId);
      if (checked.valueOrNull != owner) {
        return AppResult.failure(
          _error(AppFailureCategory.authorization, 'habits.error.account'),
        );
      }
      if (_localCalendar().localDate != calendar.localDate) {
        return AppResult.failure(_staleDay());
      }
      if (previous.valueOrNull case final day? when day.isCompleted) {
        return AppResult.success(day);
      }
      if (!habit.isDueOn(calendar.localDate)) {
        return AppResult.failure(
          _error(AppFailureCategory.validation, 'habits.validation.not_due'),
        );
      }
      final requested = _nowUtc();
      final prior = previous.valueOrNull;
      final now = prior != null && !requested.isAfter(prior.updatedAt)
          ? prior.updatedAt.add(const Duration(microseconds: 1))
          : requested;
      final day = HabitDay.completed(
        accountId: owner,
        habitId: habitId,
        localDate: calendar.localDate,
        completedAt: now,
        earnedAgainstRevisionId: habit
            .revisionOn(calendar.localDate)!
            .revisionId,
        recordedUtcOffsetMinutes: calendar.utcOffsetMinutes,
        count: habit.dailyTarget,
      );
      final commit = await _repository.commitDay(
        HabitDayWriteRequest(
          day: day,
          operationId: _nextOperationId(),
          kind: previous.valueOrNull == null
              ? ChangeKind.create
              : ChangeKind.update,
          queuedAt: now,
        ),
      );
      final failure = commit.failureOrNull;
      return failure == null
          ? AppResult.success(day)
          : AppResult.failure(failure);
    });
  }

  /// Changes only today's count. Reaching the target earns today's completion.
  Future<AppResult<HabitDay>> adjustHabitToday(
    String habitId, {
    required int delta,
    String? expectedAccountId,
    String? expectedLocalDate,
  }) async {
    if (delta == 0 || delta < -9999 || delta > 9999) {
      return AppResult.failure(
        _error(AppFailureCategory.validation, 'habits.validation.daily_target'),
      );
    }
    final account = await _account(expectedAccountId);
    if (account.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final owner = account.valueOrNull!;
    final calendar = _localCalendar();
    if (expectedLocalDate != null && expectedLocalDate != calendar.localDate) {
      return AppResult.failure(_staleDay());
    }
    return _repository.runInTransaction(() async {
      final habitResult = await _repository.readHabit(
        accountId: owner,
        habitId: habitId,
      );
      if (habitResult.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      final habit = habitResult.valueOrNull;
      if (habit == null || habit.isDeleted) {
        return AppResult.failure(
          _error(AppFailureCategory.notFound, 'habits.error.not_found'),
        );
      }
      final previous = await _repository.readDay(
        accountId: owner,
        habitId: habitId,
        localDate: calendar.localDate,
      );
      if (previous.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      final prior = previous.valueOrNull;
      if (delta > 0 && !habit.isDueOn(calendar.localDate)) {
        return AppResult.failure(
          _error(AppFailureCategory.validation, 'habits.validation.not_due'),
        );
      }
      final target = habit.dailyTarget;
      final currentCount = prior?.count ?? 0;
      final nextCount = (currentCount + delta).clamp(0, target);
      if (nextCount == currentCount && prior != null) {
        return AppResult.success(prior);
      }
      if (nextCount == 0 && prior == null) {
        return AppResult.failure(
          _error(
            AppFailureCategory.validation,
            'habits.validation.not_completed',
          ),
        );
      }
      final checked = await _account(expectedAccountId);
      if (checked.valueOrNull != owner) {
        return AppResult.failure(
          _error(AppFailureCategory.authorization, 'habits.error.account'),
        );
      }
      if (_localCalendar().localDate != calendar.localDate) {
        return AppResult.failure(_staleDay());
      }
      final requested = _nowUtc();
      final now = prior != null && !requested.isAfter(prior.updatedAt)
          ? prior.updatedAt.add(const Duration(microseconds: 1))
          : requested;
      final base =
          prior ??
          HabitDay.restore(
            accountId: owner,
            habitId: habitId,
            localDate: calendar.localDate,
            completedAt: null,
            count: 0,
            earnedWhileDue: false,
            earnedAgainstRevisionId: null,
            recordedUtcOffsetMinutes: calendar.utcOffsetMinutes,
            updatedAt: now,
          );
      final day = base.changeCount(
        count: nextCount,
        target: target,
        at: now,
        utcOffsetMinutes: calendar.utcOffsetMinutes,
        revisionId: habit.revisionOn(calendar.localDate)!.revisionId,
      );
      final commit = await _repository.commitDay(
        HabitDayWriteRequest(
          day: day,
          operationId: _nextOperationId(),
          kind: prior == null ? ChangeKind.create : ChangeKind.update,
          queuedAt: now,
        ),
      );
      final failure = commit.failureOrNull;
      return failure == null
          ? AppResult.success(day)
          : AppResult.failure(failure);
    });
  }

  Future<AppResult<HabitDay>> undoHabitToday(
    String habitId, {
    String? expectedAccountId,
    String? expectedLocalDate,
  }) async {
    final account = await _account(expectedAccountId);
    if (account.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final owner = account.valueOrNull!;
    final calendar = _localCalendar();
    if (expectedLocalDate != null && expectedLocalDate != calendar.localDate) {
      return AppResult.failure(_staleDay());
    }
    return _repository.runInTransaction(() async {
      final habitResult = await _repository.readHabit(
        accountId: owner,
        habitId: habitId,
      );
      if (habitResult.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      if (habitResult.valueOrNull == null ||
          habitResult.valueOrNull!.isDeleted) {
        return AppResult.failure(
          _error(AppFailureCategory.notFound, 'habits.error.not_found'),
        );
      }
      final previous = await _repository.readDay(
        accountId: owner,
        habitId: habitId,
        localDate: calendar.localDate,
      );
      if (previous.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      final current = previous.valueOrNull;
      if (current == null || current.count == 0) {
        return AppResult.failure(
          _error(
            AppFailureCategory.validation,
            'habits.validation.not_completed',
          ),
        );
      }
      final requested = _nowUtc();
      final now = requested.isAfter(current.updatedAt)
          ? requested
          : current.updatedAt.add(const Duration(microseconds: 1));
      final day = current.undo(now, calendar.utcOffsetMinutes);
      final checked = await _account(expectedAccountId);
      if (checked.valueOrNull != owner) {
        return AppResult.failure(
          _error(AppFailureCategory.authorization, 'habits.error.account'),
        );
      }
      if (_localCalendar().localDate != calendar.localDate) {
        return AppResult.failure(_staleDay());
      }
      final commit = await _repository.commitDay(
        HabitDayWriteRequest(
          day: day,
          operationId: _nextOperationId(),
          kind: ChangeKind.update,
          queuedAt: now,
        ),
      );
      final failure = commit.failureOrNull;
      return failure == null
          ? AppResult.success(day)
          : AppResult.failure(failure);
    });
  }

  AppFailure _staleDay() =>
      _error(AppFailureCategory.validation, 'habits.validation.stale_day');

  Future<AppResult<String>> _account(String? expectedAccountId) async {
    final context = await _session.obtainSyncContext();
    final accountId = context.valueOrNull?.accountId;
    if (accountId == null ||
        accountId.isEmpty ||
        (expectedAccountId != null && accountId != expectedAccountId)) {
      return AppResult.failure(
        _error(AppFailureCategory.authorization, 'habits.error.account'),
      );
    }
    return AppResult.success(accountId);
  }

  AppFailure _error(AppFailureCategory category, String key) =>
      AppFailure.recoverable(
        category: category,
        messageKey: key,
        occurredAt: _nowUtc(),
      );

  static DateTime _systemUtc() => DateTime.now().toUtc();
  static ({String localDate, int utcOffsetMinutes}) _systemCalendar() {
    final now = DateTime.now();
    return (
      localDate: habitLocalDate(now),
      utcOffsetMinutes: now.timeZoneOffset.inMinutes,
    );
  }

  static String _newUuid() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

import 'dart:math';

import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/adhkar_clock.dart';
import '../domain/my_dhikr.dart';
import 'adhkar_clock_port.dart';
import 'adhkar_times_port.dart';
import 'my_adhkar_identity_port.dart';
import 'my_adhkar_repository.dart';

/// The outcomes of the My Adhkar commands (contracts/
/// adhkar-qiyam-application.md, "My Adhkar ports and commands").
sealed class MyAdhkarCommandOutcome {
  const MyAdhkarCommandOutcome();
}

/// The draft was added; [itemId] is the fresh UUIDv4 identity.
final class MyAdhkarAdded extends MyAdhkarCommandOutcome {
  const MyAdhkarAdded({required this.itemId});

  final String itemId;
}

/// The item was edited (the clamp, when it applied, is already committed).
final class MyAdhkarEdited extends MyAdhkarCommandOutcome {
  const MyAdhkarEdited();
}

/// The item was tombstoned; deleting an already deleted item is the same
/// no-op-confirmed outcome.
final class MyAdhkarDeleted extends MyAdhkarCommandOutcome {
  const MyAdhkarDeleted();
}

/// The count moved to [newCount]; completion is derived as
/// `newCount >= target` (FR-004) and never drives an award.
final class MyAdhkarCounted extends MyAdhkarCommandOutcome {
  const MyAdhkarCounted({required this.newCount});

  final int newCount;
}

/// The item already sits at its target: nothing to write.
final class MyAdhkarAtTarget extends MyAdhkarCommandOutcome {
  const MyAdhkarAtTarget();
}

/// The reset wrote 0 for the item.
final class MyAdhkarReset extends MyAdhkarCommandOutcome {
  const MyAdhkarReset();
}

/// The account already holds 100 live items (FR-023).
final class MyAdhkarLimitReached extends MyAdhkarCommandOutcome {
  const MyAdhkarLimitReached();
}

/// The item is deleted: edits and counts are rejected and deletion is never
/// undone (FR-025, FR-027).
final class MyAdhkarItemDeleted extends MyAdhkarCommandOutcome {
  const MyAdhkarItemDeleted();
}

/// The captured Adhkar day is no longer the current one; the UI refreshes.
final class MyAdhkarDayChanged extends MyAdhkarCommandOutcome {
  const MyAdhkarDayChanged();
}

/// The Prayer schedule is unavailable: the items stay visible but counting
/// is locked (owner decision, 2026-11-10) — never a calendar-day fallback.
final class MyAdhkarCountingLocked extends MyAdhkarCommandOutcome {
  const MyAdhkarCountingLocked();
}

/// The command boundary the Cubit drives (guards included).
abstract interface class MyAdhkarCommandRunner {
  Future<AppResult<MyAdhkarCommandOutcome>> add({required MyDhikrDraft draft});

  Future<AppResult<MyAdhkarCommandOutcome>> edit({
    required String capturedDay,
    required String itemId,
    required MyDhikrDraft draft,
  });

  Future<AppResult<MyAdhkarCommandOutcome>> delete({required String itemId});

  Future<AppResult<MyAdhkarCommandOutcome>> increment({
    required String capturedDay,
    required String itemId,
  });

  Future<AppResult<MyAdhkarCommandOutcome>> reset({
    required String capturedDay,
    required String itemId,
  });
}

/// The My Adhkar commands. Every command samples `now` exactly once and
/// stamps the commit with it. None of them touches the XP ledger, the set
/// award or the streak (FR-026): My Adhkar shares only the Adhkar day and
/// the counter rules.
final class MyAdhkarCommands implements MyAdhkarCommandRunner {
  MyAdhkarCommands({
    required String ownerId,
    required AdhkarTimesPort times,
    required AdhkarClockPort clock,
    required MyAdhkarRepository repository,
    required MyAdhkarIdentityPort identity,
  }) : _ownerId = ownerId,
       _times = times,
       _clock = clock,
       _repository = repository,
       _identity = identity {
    if (ownerId.trim().isEmpty) throw ArgumentError('Owner is required');
  }

  final String _ownerId;
  final AdhkarTimesPort _times;
  final AdhkarClockPort _clock;
  final MyAdhkarRepository _repository;
  final MyAdhkarIdentityPort _identity;

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> add({
    required MyDhikrDraft draft,
  }) async {
    final now = _clock.nowUtc();
    final validationFailure = _draftFailure(draft, now);
    if (validationFailure != null) {
      return AppResult.failure(validationFailure);
    }
    final added = await _repository.runInTransaction(() async {
      final liveCount = await _repository.liveItemCount(accountId: _ownerId);
      if (liveCount.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      if (!canAddMyDhikr(liveCount.valueOrNull!)) {
        return const AppResult<MyAdhkarCommandOutcome>.success(
          MyAdhkarLimitReached(),
        );
      }
      final itemId = _identity.newItemId();
      final insert = await _repository.insertItem(
        MyDhikrItem(
          accountId: _ownerId,
          itemId: itemId,
          text: draft.trimmedText,
          target: draft.target,
          note: draft.trimmedNote,
          createdAt: now,
          updatedAt: now,
          lastAcknowledgedUpdatedAt: null,
          deletedAt: null,
        ),
        operationId: _nextOperationId(),
        queueForSync: true,
      );
      if (insert.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      return AppResult<MyAdhkarCommandOutcome>.success(
        MyAdhkarAdded(itemId: itemId),
      );
    });
    return added;
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> edit({
    required String capturedDay,
    required String itemId,
    required MyDhikrDraft draft,
  }) async {
    final now = _clock.nowUtc();
    final validationFailure = _draftFailure(draft, now);
    if (validationFailure != null) {
      return AppResult.failure(validationFailure);
    }
    final priorRead = await _repository.readFresh(
      accountId: _ownerId,
      itemId: itemId,
    );
    if (priorRead.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final prior = priorRead.valueOrNull;
    if (prior == null) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.validation,
          messageKey: 'my_adhkar.item.unknown',
          occurredAt: now,
        ),
      );
    }
    if (prior.isDeleted) {
      return const AppResult.success(MyAdhkarItemDeleted());
    }
    // The clamp day: when the schedule is available the edit must still
    // target the current day; when it is unavailable counting is locked and
    // there is no "today" to clamp (the screen shows min(count, target)).
    final clockState = await _times.resolve(_ownerId, now);
    if (clockState.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final resolved = clockState.valueOrNull!;
    final String? clampDay;
    if (resolved.scheduleState == AdhkarScheduleState.unavailable) {
      clampDay = null;
    } else {
      if (capturedDay != resolved.day) {
        return const AppResult.success(MyAdhkarDayChanged());
      }
      clampDay = resolved.day;
    }
    final version = !now.isAfter(prior.updatedAt)
        ? prior.updatedAt.add(const Duration(microseconds: 1))
        : now;
    return _repository.runInTransaction(() async {
      final update = await _repository.updateItem(
        prior.copyWith(
          text: draft.trimmedText,
          target: draft.target,
          note: draft.trimmedNote,
          updatedAt: version,
        ),
        operationId: _nextOperationId(),
        queueForSync: true,
      );
      if (update.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      // FR-025 in the SAME transaction as the edit: lowering the target
      // below today's count sets today's count to the new target.
      if (clampDay != null && draft.target < prior.target) {
        final countRead = await _repository.readCountFresh(
          accountId: _ownerId,
          itemId: itemId,
          adhkarDay: clampDay,
        );
        if (countRead.failureOrNull case final failure?) {
          return AppResult<MyAdhkarCommandOutcome>.failure(failure);
        }
        final priorCount = countRead.valueOrNull;
        final currentCount = priorCount?.count ?? 0;
        if (currentCount > draft.target) {
          final commit = await _repository.commitCount(
            _countRequest(
              itemId: itemId,
              day: clampDay,
              newCount: draft.target,
              now: version,
              prior: priorCount,
            ),
          );
          if (commit.failureOrNull case final failure?) {
            return AppResult<MyAdhkarCommandOutcome>.failure(failure);
          }
        }
      }
      return const AppResult<MyAdhkarCommandOutcome>.success(MyAdhkarEdited());
    });
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> delete({
    required String itemId,
  }) async {
    final now = _clock.nowUtc();
    final priorRead = await _repository.readFresh(
      accountId: _ownerId,
      itemId: itemId,
    );
    if (priorRead.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final prior = priorRead.valueOrNull;
    if (prior == null) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.validation,
          messageKey: 'my_adhkar.item.unknown',
          occurredAt: now,
        ),
      );
    }
    final deleted = await _repository.runInTransaction(() async {
      final result = await _repository.markDeleted(
        accountId: _ownerId,
        itemId: itemId,
        deletedAt: now,
        updatedAt: now,
        operationId: _nextOperationId(),
        queueForSync: true,
      );
      if (result.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      return const AppResult<MyAdhkarCommandOutcome>.success(MyAdhkarDeleted());
    });
    return deleted;
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> increment({
    required String capturedDay,
    required String itemId,
  }) async {
    final now = _clock.nowUtc();
    final guarded = await _countGuard(
      capturedDay: capturedDay,
      itemId: itemId,
      now: now,
    );
    final guard = guarded.valueOrNull;
    if (guard == null) {
      return AppResult.failure(guarded.failureOrNull!);
    }
    if (guard is _LockedGuard) {
      return const AppResult.success(MyAdhkarCountingLocked());
    }
    if (guard is _DayChangedGuard) {
      return const AppResult.success(MyAdhkarDayChanged());
    }
    if (guard is _DeletedGuard) {
      return const AppResult.success(MyAdhkarItemDeleted());
    }
    if (guard is! _OpenGuard) {
      throw StateError('Unhandled My Adhkar guard: ${guard.runtimeType}');
    }
    final countRead = await _repository.readCountFresh(
      accountId: _ownerId,
      itemId: itemId,
      adhkarDay: guard.day,
    );
    final countFailure = countRead.failureOrNull;
    if (countFailure != null) {
      return AppResult.failure(countFailure);
    }
    final prior = countRead.valueOrNull;
    final currentCount = prior?.count ?? 0;
    if (currentCount >= guard.target) {
      return const AppResult.success(MyAdhkarAtTarget());
    }
    final committed = await _repository.commitCount(
      _countRequest(
        itemId: itemId,
        day: guard.day,
        newCount: currentCount + 1,
        now: now,
        prior: prior,
      ),
    );
    if (committed.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    return AppResult.success(
      MyAdhkarCounted(newCount: committed.valueOrNull!.newCount),
    );
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> reset({
    required String capturedDay,
    required String itemId,
  }) async {
    final now = _clock.nowUtc();
    final guarded = await _countGuard(
      capturedDay: capturedDay,
      itemId: itemId,
      now: now,
    );
    final guard = guarded.valueOrNull;
    if (guard == null) {
      return AppResult.failure(guarded.failureOrNull!);
    }
    if (guard is _LockedGuard) {
      return const AppResult.success(MyAdhkarCountingLocked());
    }
    if (guard is _DayChangedGuard) {
      return const AppResult.success(MyAdhkarDayChanged());
    }
    if (guard is _DeletedGuard) {
      return const AppResult.success(MyAdhkarItemDeleted());
    }
    if (guard is! _OpenGuard) {
      throw StateError('Unhandled My Adhkar guard: ${guard.runtimeType}');
    }
    final countRead = await _repository.readCountFresh(
      accountId: _ownerId,
      itemId: itemId,
      adhkarDay: guard.day,
    );
    final countFailure = countRead.failureOrNull;
    if (countFailure != null) {
      return AppResult.failure(countFailure);
    }
    // A reset always writes the 0 row (a missing row means 0; the persisted
    // 0 keeps a stale count from coming back on retry, data-model.md).
    final committed = await _repository.commitCount(
      _countRequest(
        itemId: itemId,
        day: guard.day,
        newCount: 0,
        now: now,
        prior: countRead.valueOrNull,
      ),
    );
    final commitFailure = committed.failureOrNull;
    if (commitFailure != null) {
      return AppResult.failure(commitFailure);
    }
    return const AppResult.success(MyAdhkarReset());
  }

  /// The shared counting guard: the times resolution, the locked state, the
  /// day guard and the item's tombstone. No period check and no award —
  /// My Adhkar is countable the whole Adhkar day (FR-024).
  Future<AppResult<_Guard>> _countGuard({
    required String capturedDay,
    required String itemId,
    required DateTime now,
  }) async {
    final clockState = await _times.resolve(_ownerId, now);
    if (clockState.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final state = clockState.valueOrNull!;
    if (state.scheduleState == AdhkarScheduleState.unavailable) {
      return const AppResult.success(_LockedGuard());
    }
    if (capturedDay != state.day) {
      return const AppResult.success(_DayChangedGuard());
    }
    final itemRead = await _repository.readFresh(
      accountId: _ownerId,
      itemId: itemId,
    );
    final itemFailure = itemRead.failureOrNull;
    if (itemFailure != null) {
      return AppResult.failure(itemFailure);
    }
    final item = itemRead.valueOrNull;
    if (item == null) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.validation,
          messageKey: 'my_adhkar.item.unknown',
          occurredAt: now,
        ),
      );
    }
    if (item.isDeleted) {
      return const AppResult.success(_DeletedGuard());
    }
    return AppResult.success(_OpenGuard(day: state.day!, target: item.target));
  }

  MyAdhkarCountCommitRequest _countRequest({
    required String itemId,
    required String day,
    required int newCount,
    required DateTime now,
    required MyAdhkarCountRecord? prior,
  }) {
    final version = prior != null && !now.isAfter(prior.updatedAt)
        ? prior.updatedAt.add(const Duration(microseconds: 1))
        : now;
    return MyAdhkarCountCommitRequest(
      accountId: _ownerId,
      itemId: itemId,
      adhkarDay: day,
      recordId: _identity.countRecordId(itemId, day),
      newCount: newCount,
      createdAt: prior?.createdAt ?? now,
      updatedAt: version,
      operationId: _nextOperationId(),
      expectedCurrentVersion: prior?.updatedAt,
      acknowledgedBase: prior?.lastAcknowledgedUpdatedAt,
      queueForSync: true,
      hadPrior: prior != null,
    );
  }

  /// The first draft violation as its typed failure, or null when valid.
  AppFailure? _draftFailure(MyDhikrDraft draft, DateTime now) {
    final violations = draft.violations();
    if (violations.isEmpty) return null;
    return AppFailure.recoverable(
      category: AppFailureCategory.validation,
      messageKey: switch (violations.first) {
        MyDhikrDraftViolation.text => 'my_adhkar.draft.invalid_text',
        MyDhikrDraftViolation.target => 'my_adhkar.draft.invalid_target',
        MyDhikrDraftViolation.note => 'my_adhkar.draft.note_too_long',
      },
      occurredAt: now,
    );
  }
}

String _nextOperationId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String byte(int index) => bytes[index].toRadixString(16).padLeft(2, '0');
  return 'my-adhkar-${byte(0)}${byte(1)}${byte(2)}${byte(3)}-'
      '${byte(4)}${byte(5)}-${byte(6)}${byte(7)}-'
      '${byte(8)}${byte(9)}-'
      '${byte(10)}${byte(11)}${byte(12)}${byte(13)}${byte(14)}${byte(15)}';
}

sealed class _Guard {
  const _Guard();
}

final class _LockedGuard extends _Guard {
  const _LockedGuard();
}

final class _DayChangedGuard extends _Guard {
  const _DayChangedGuard();
}

final class _DeletedGuard extends _Guard {
  const _DeletedGuard();
}

final class _OpenGuard extends _Guard {
  const _OpenGuard({required this.day, required this.target});
  final String day;
  final int target;
}

import 'dart:math';

import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/adhkar_clock.dart';
import 'adhkar_catalog_port.dart';
import 'adhkar_clock_port.dart';
import 'adhkar_identity_port.dart';
import 'adhkar_repository.dart';
import 'adhkar_times_port.dart';

/// The outcomes of the Adhkar count commands (contracts/
/// adhkar-qiyam-application.md).
sealed class AdhkarCommandOutcome {
  const AdhkarCommandOutcome();
}

/// The count moved to [newCount]; [setCompleted] is true when this commit
/// completed the list's approved set (the award decision itself lives in the
/// transaction).
final class AdhkarIncremented extends AdhkarCommandOutcome {
  const AdhkarIncremented({required this.newCount, required this.setCompleted});

  final int newCount;
  final bool setCompleted;
}

/// The reset wrote 0 for the item.
final class AdhkarReset extends AdhkarCommandOutcome {
  const AdhkarReset();
}

/// The item already sits at its target: nothing to write.
final class AdhkarAtTarget extends AdhkarCommandOutcome {
  const AdhkarAtTarget();
}

/// The captured Adhkar day is no longer the current one; the UI refreshes.
final class AdhkarDayChanged extends AdhkarCommandOutcome {
  const AdhkarDayChanged();
}

/// The item's list is not countable now; [startsAtUtc] is when its period
/// opens (the "its time starts at ..." notice).
final class AdhkarOutsidePeriod extends AdhkarCommandOutcome {
  const AdhkarOutsidePeriod({required this.startsAtUtc});

  final DateTime startsAtUtc;
}

/// The Prayer schedule is unavailable: the lists stay visible but counting
/// is locked (owner decision, 2026-11-10) — never a calendar-day fallback.
final class AdhkarCountingLocked extends AdhkarCommandOutcome {
  const AdhkarCountingLocked();
}

/// The command boundary the Cubit drives (guards included).
abstract interface class AdhkarCommandRunner {
  Future<AppResult<AdhkarCommandOutcome>> increment({
    required String capturedDay,
    required String itemId,
  });

  Future<AppResult<AdhkarCommandOutcome>> reset({
    required String capturedDay,
    required String itemId,
  });
}

/// The Adhkar count commands. Every command samples `now` exactly once and
/// stamps the commit with it, which keeps the record inside the server's
/// `[day - 1 day, day + 2 days)` award window for the current Adhkar day.
final class AdhkarCommands implements AdhkarCommandRunner {
  AdhkarCommands({
    required String ownerId,
    required AdhkarTimesPort times,
    required AdhkarCatalogPort catalog,
    required AdhkarRepository repository,
    required AdhkarCountCommitPort commits,
    required AdhkarClockPort clock,
    required AdhkarIdentityPort identity,
  }) : _ownerId = ownerId,
       _times = times,
       _catalog = catalog,
       _repository = repository,
       _commits = commits,
       _clock = clock,
       _identity = identity {
    if (ownerId.trim().isEmpty) throw ArgumentError('Owner is required');
  }

  final String _ownerId;
  final AdhkarTimesPort _times;
  final AdhkarCatalogPort _catalog;
  final AdhkarRepository _repository;
  final AdhkarCountCommitPort _commits;
  final AdhkarClockPort _clock;
  final AdhkarIdentityPort _identity;

  @override
  @override
  Future<AppResult<AdhkarCommandOutcome>> increment({
    required String capturedDay,
    required String itemId,
  }) async {
    final now = _clock.nowUtc();
    final guarded = await _guard(
      capturedDay: capturedDay,
      itemId: itemId,
      now: now,
      enforcePeriod: true,
    );
    final guard = guarded.valueOrNull;
    if (guard == null) {
      return AppResult.failure(guarded.failureOrNull!);
    }
    if (guard is _LockedGuard) {
      return const AppResult.success(AdhkarCountingLocked());
    }
    if (guard is _DayChangedGuard) {
      return const AppResult.success(AdhkarDayChanged());
    }
    if (guard is _OutsidePeriodGuard) {
      return AppResult.success(
        AdhkarOutsidePeriod(startsAtUtc: guard.startsAtUtc),
      );
    }
    if (guard is! _OpenGuard) {
      throw StateError('Unhandled Adhkar guard: ${guard.runtimeType}');
    }
    final item = guard.item;
    final prior = (await _repository.readFresh(
      accountId: _ownerId,
      adhkarDay: guard.day,
      itemId: itemId,
    )).valueOrNull;
    final currentCount = prior?.count ?? 0;
    if (currentCount >= item.target) {
      return const AppResult.success(AdhkarAtTarget());
    }
    final newCount = currentCount + 1;
    final committed = await _commit(
      guard: guard,
      itemId: itemId,
      newCount: newCount,
      now: now,
      prior: prior,
    );
    if (committed.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final outcome = committed.valueOrNull!;
    return AppResult.success(
      AdhkarIncremented(
        newCount: outcome.newCount,
        setCompleted: outcome.setCompleted,
      ),
    );
  }

  @override
  @override
  Future<AppResult<AdhkarCommandOutcome>> reset({
    required String capturedDay,
    required String itemId,
  }) async {
    final now = _clock.nowUtc();
    final guarded = await _guard(
      capturedDay: capturedDay,
      itemId: itemId,
      now: now,
      enforcePeriod: false,
    );
    final guard = guarded.valueOrNull;
    if (guard == null) {
      return AppResult.failure(guarded.failureOrNull!);
    }
    if (guard is _LockedGuard) {
      return const AppResult.success(AdhkarCountingLocked());
    }
    if (guard is _DayChangedGuard) {
      return const AppResult.success(AdhkarDayChanged());
    }
    // A reset is allowed outside the period (an accidental count can always
    // be fixed), so the period guard does not apply here.
    if (guard is! _OpenGuard) {
      throw StateError('Unhandled Adhkar guard: ${guard.runtimeType}');
    }
    final prior = (await _repository.readFresh(
      accountId: _ownerId,
      adhkarDay: guard.day,
      itemId: itemId,
    )).valueOrNull;
    final committed = await _commit(
      guard: guard,
      itemId: itemId,
      newCount: 0,
      now: now,
      prior: prior,
    );
    if (committed.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    return const AppResult.success(AdhkarReset());
  }

  Future<AppResult<_Guard>> _guard({
    required String capturedDay,
    required String itemId,
    required DateTime now,
    required bool enforcePeriod,
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
    final snapshot = await _catalog.snapshot(_ownerId);
    if (snapshot.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final item = snapshot.valueOrNull!.item(itemId);
    if (item == null) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.validation,
          messageKey: 'adhkar.item.unknown',
          occurredAt: now,
        ),
      );
    }
    final countable = item.list == 'morning'
        ? state.morningCountable
        : state.eveningCountable;
    if (enforcePeriod && !countable) {
      return AppResult.success(
        _OutsidePeriodGuard(
          startsAtUtc: item.list == 'morning'
              ? state.fajrUtc!
              : state.maghribUtc!,
        ),
      );
    }
    return AppResult.success(
      _OpenGuard(day: state.day!, item: item, snapshot: snapshot.valueOrNull!),
    );
  }

  Future<AppResult<AdhkarCommitOutcome>> _commit({
    required _OpenGuard guard,
    required String itemId,
    required int newCount,
    required DateTime now,
    required AdhkarCountRecord? prior,
  }) {
    final listItems = guard.snapshot
        .itemsOf(guard.item.list)
        .map((item) => AdhkarListItem(itemId: item.itemId, target: item.target))
        .toList(growable: false);
    final version = prior != null && !now.isAfter(prior.updatedAt)
        ? prior.updatedAt.add(const Duration(microseconds: 1))
        : now;
    return _commits.commit(
      AdhkarCommitRequest(
        accountId: _ownerId,
        adhkarDay: guard.day,
        itemId: itemId,
        recordId: _identity.itemRecordId(guard.day, itemId),
        catalogVersion: guard.snapshot.version,
        list: guard.item.list,
        newCount: newCount,
        updatedAt: version,
        operationId: _nextOperationId(),
        expectedCurrentVersion: prior?.updatedAt,
        acknowledgedBase: prior?.lastAcknowledgedUpdatedAt,
        queueForSync: true,
        listItems: listItems,
        setAwardSourceId: _identity.setAwardSourceId(
          guard.day,
          guard.item.list,
        ),
      ),
    );
  }
}

String _nextOperationId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String byte(int index) => bytes[index].toRadixString(16).padLeft(2, '0');
  return 'adhkar-${byte(0)}${byte(1)}${byte(2)}${byte(3)}-'
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

final class _OutsidePeriodGuard extends _Guard {
  const _OutsidePeriodGuard({required this.startsAtUtc});
  final DateTime startsAtUtc;
}

final class _OpenGuard extends _Guard {
  const _OpenGuard({
    required this.day,
    required this.item,
    required this.snapshot,
  });
  final String day;
  final AdhkarCatalogItemSnapshot item;
  final AdhkarCatalogSnapshot snapshot;
}

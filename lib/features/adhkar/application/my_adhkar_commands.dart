import 'dart:math';

import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/my_dhikr.dart';
import 'adhkar_clock_port.dart';
import 'my_adhkar_identity_port.dart';
import 'my_adhkar_repository.dart';

/// The outcomes of the My Adhkar commands (contracts/
/// adhkar-qiyam-application.md, "My Adhkar ports and commands", reshaped
/// 2026-11-16).
sealed class MyAdhkarCommandOutcome {
  const MyAdhkarCommandOutcome();
}

/// The group was created; [groupId] is the fresh UUIDv4 identity.
final class MyAdhkarGroupCreated extends MyAdhkarCommandOutcome {
  const MyAdhkarGroupCreated({required this.groupId});

  final String groupId;
}

/// The group was renamed.
final class MyAdhkarGroupRenamed extends MyAdhkarCommandOutcome {
  const MyAdhkarGroupRenamed();
}

/// The group was deleted, cascading [cascadedEntries] entries whose only
/// live group it was. The same outcome reports a submission that references
/// a deleted group (`groupDeleted` in the contract) and the no-op delete of
/// an already deleted group ([cascadedEntries] 0).
final class MyAdhkarGroupDeleted extends MyAdhkarCommandOutcome {
  const MyAdhkarGroupDeleted({required this.cascadedEntries});

  final int cascadedEntries;
}

/// The group limit of 100 live groups is reached (FR-028).
final class MyAdhkarGroupLimitReached extends MyAdhkarCommandOutcome {
  const MyAdhkarGroupLimitReached();
}

/// The entry was added; [itemId] is the fresh UUIDv4 identity.
final class MyAdhkarAdded extends MyAdhkarCommandOutcome {
  const MyAdhkarAdded({required this.itemId});

  final String itemId;
}

/// The entry was edited, including its group set.
final class MyAdhkarEdited extends MyAdhkarCommandOutcome {
  const MyAdhkarEdited();
}

/// The entry was deleted (or the already deleted entry was — the same no-op
/// confirmed outcome).
final class MyAdhkarDeleted extends MyAdhkarCommandOutcome {
  const MyAdhkarDeleted();
}

/// The entry limit of 1000 live entries is reached (FR-023).
final class MyAdhkarLimitReached extends MyAdhkarCommandOutcome {
  const MyAdhkarLimitReached();
}

/// The entry is deleted: edits are rejected and deletion is never undone
/// (FR-025, FR-027).
final class MyAdhkarItemDeleted extends MyAdhkarCommandOutcome {
  const MyAdhkarItemDeleted();
}

/// The command boundary the Cubit drives (guards included). There is no day
/// guard, no locked state and no Adhkar times dependency: My Adhkar works
/// the same when the Prayer schedule is unavailable (FR-024, spec scenario
/// 9).
abstract interface class MyAdhkarCommandRunner {
  Future<AppResult<MyAdhkarCommandOutcome>> createGroup({required String name});

  Future<AppResult<MyAdhkarCommandOutcome>> renameGroup({
    required String groupId,
    required String name,
  });

  Future<AppResult<MyAdhkarCommandOutcome>> deleteGroup({
    required String groupId,
  });

  /// How many entries the delete would tombstone (the confirmation count).
  /// An unknown group fails; a deleted group previews 0 (the delete is a
  /// no-op).
  Future<AppResult<int>> previewDeleteGroup({required String groupId});

  Future<AppResult<MyAdhkarCommandOutcome>> add({required MyDhikrDraft draft});

  Future<AppResult<MyAdhkarCommandOutcome>> edit({
    required String itemId,
    required MyDhikrDraft draft,
  });

  Future<AppResult<MyAdhkarCommandOutcome>> delete({required String itemId});
}

/// The My Adhkar commands. Every command samples `now` once and stamps the
/// commit with it. The edit reads, checks and writes in ONE transaction
/// (the repository update is guarded on `deleted_at IS NULL` and the prior
/// `updated_at`), the delete uses a monotonic `updated_at`
/// (`max(now, prior + 1 microsecond)`), and none of them touches the XP
/// ledger, the set award or the streak (FR-026).
final class MyAdhkarCommands implements MyAdhkarCommandRunner {
  MyAdhkarCommands({
    required String ownerId,
    required AdhkarClockPort clock,
    required MyAdhkarRepository repository,
    required MyAdhkarIdentityPort identity,
  }) : _ownerId = ownerId,
       _clock = clock,
       _repository = repository,
       _identity = identity {
    if (ownerId.trim().isEmpty) throw ArgumentError('Owner is required');
  }

  final String _ownerId;
  final AdhkarClockPort _clock;
  final MyAdhkarRepository _repository;
  final MyAdhkarIdentityPort _identity;

  // -- Groups ---------------------------------------------------------------

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> createGroup({
    required String name,
  }) async {
    final now = _clock.nowUtc();
    final validationFailure = _groupNameFailure(name, now);
    if (validationFailure != null) {
      return AppResult.failure(validationFailure);
    }
    return _repository.runInTransaction(() async {
      final liveCount = await _repository.liveGroupCount(accountId: _ownerId);
      if (liveCount.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      if (!canCreateMyAdhkarGroup(liveCount.valueOrNull!)) {
        return const AppResult<MyAdhkarCommandOutcome>.success(
          MyAdhkarGroupLimitReached(),
        );
      }
      final groupId = _identity.newGroupId();
      final insert = await _repository.insertGroup(
        MyAdhkarGroup(
          accountId: _ownerId,
          groupId: groupId,
          name: name.trim(),
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
        MyAdhkarGroupCreated(groupId: groupId),
      );
    });
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> renameGroup({
    required String groupId,
    required String name,
  }) async {
    final now = _clock.nowUtc();
    final validationFailure = _groupNameFailure(name, now);
    if (validationFailure != null) {
      return AppResult.failure(validationFailure);
    }
    return _repository.runInTransaction(() async {
      final read = await _repository.readGroupFresh(
        accountId: _ownerId,
        groupId: groupId,
      );
      if (read.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      final prior = read.valueOrNull;
      if (prior == null) {
        return AppResult<MyAdhkarCommandOutcome>.failure(_unknownGroup(now));
      }
      if (prior.isDeleted) {
        return const AppResult<MyAdhkarCommandOutcome>.success(
          MyAdhkarGroupDeleted(cascadedEntries: 0),
        );
      }
      final version = _nextVersion(now, prior.updatedAt);
      final rename = await _repository.renameGroup(
        prior.copyWith(name: name.trim(), updatedAt: version),
        priorUpdatedAt: prior.updatedAt,
        operationId: _nextOperationId(),
        queueForSync: true,
      );
      if (rename.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      return const AppResult<MyAdhkarCommandOutcome>.success(
        MyAdhkarGroupRenamed(),
      );
    });
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> deleteGroup({
    required String groupId,
  }) async {
    final now = _clock.nowUtc();
    return _repository.runInTransaction(() async {
      final read = await _repository.readGroupFresh(
        accountId: _ownerId,
        groupId: groupId,
      );
      if (read.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      final prior = read.valueOrNull;
      if (prior == null) {
        return AppResult<MyAdhkarCommandOutcome>.failure(_unknownGroup(now));
      }
      // The cascade tombstones the group, removes its memberships and
      // tombstones every entry left with no live group — all inside this
      // transaction — and appends exactly ONE outbox entry (the group).
      final cascade = await _repository.deleteGroupCascade(
        accountId: _ownerId,
        groupId: groupId,
        deletedAt: now,
        operationId: _nextOperationId(),
        queueForSync: true,
      );
      if (cascade.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      return AppResult<MyAdhkarCommandOutcome>.success(
        MyAdhkarGroupDeleted(cascadedEntries: cascade.valueOrNull!),
      );
    });
  }

  @override
  Future<AppResult<int>> previewDeleteGroup({required String groupId}) async {
    final now = _clock.nowUtc();
    final read = await _repository.readGroupFresh(
      accountId: _ownerId,
      groupId: groupId,
    );
    if (read.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final prior = read.valueOrNull;
    if (prior == null) {
      return AppResult.failure(_unknownGroup(now));
    }
    if (prior.isDeleted) {
      return const AppResult.success(0);
    }
    return _repository.liveEntriesOnlyInGroup(
      accountId: _ownerId,
      groupId: groupId,
    );
  }

  // -- Entries ---------------------------------------------------------------

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> add({
    required MyDhikrDraft draft,
  }) async {
    final now = _clock.nowUtc();
    final validationFailure = _draftFailure(draft, now);
    if (validationFailure != null) {
      return AppResult.failure(validationFailure);
    }
    return _repository.runInTransaction(() async {
      final groups = await _checkGroups(draft.groupIds, now);
      if (groups case final AppResult<MyAdhkarCommandOutcome> rejection?) {
        return rejection;
      }
      final liveCount = await _repository.liveEntryCount(accountId: _ownerId);
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
          source: draft.trimmedSource,
          groupIds: draft.groupIds,
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
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> edit({
    required String itemId,
    required MyDhikrDraft draft,
  }) async {
    final now = _clock.nowUtc();
    final validationFailure = _draftFailure(draft, now);
    if (validationFailure != null) {
      return AppResult.failure(validationFailure);
    }
    // Read, deleted check and write all happen inside this ONE transaction;
    // the repository update is additionally guarded on `deleted_at IS NULL`
    // and the prior `updated_at`, so it never resurrects a deleted entry or
    // overwrites a concurrent change.
    return _repository.runInTransaction(() async {
      final read = await _repository.readFresh(
        accountId: _ownerId,
        itemId: itemId,
      );
      if (read.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      final prior = read.valueOrNull;
      if (prior == null) {
        return AppResult<MyAdhkarCommandOutcome>.failure(_unknownItem(now));
      }
      if (prior.isDeleted) {
        return const AppResult<MyAdhkarCommandOutcome>.success(
          MyAdhkarItemDeleted(),
        );
      }
      final groups = await _checkGroups(draft.groupIds, now);
      if (groups case final AppResult<MyAdhkarCommandOutcome> rejection?) {
        return rejection;
      }
      final version = _nextVersion(now, prior.updatedAt);
      final update = await _repository.updateItem(
        prior.copyWith(
          text: draft.trimmedText,
          source: draft.trimmedSource,
          groupIds: draft.groupIds,
          updatedAt: version,
        ),
        priorUpdatedAt: prior.updatedAt,
        operationId: _nextOperationId(),
        queueForSync: true,
      );
      if (update.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      return const AppResult<MyAdhkarCommandOutcome>.success(MyAdhkarEdited());
    });
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> delete({
    required String itemId,
  }) async {
    final now = _clock.nowUtc();
    return _repository.runInTransaction(() async {
      final read = await _repository.readFresh(
        accountId: _ownerId,
        itemId: itemId,
      );
      if (read.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      final prior = read.valueOrNull;
      if (prior == null) {
        return AppResult<MyAdhkarCommandOutcome>.failure(_unknownItem(now));
      }
      // Deleting an already deleted entry is the no-op confirmed outcome;
      // the tombstone is set once and never moved.
      if (prior.isDeleted) {
        return const AppResult<MyAdhkarCommandOutcome>.success(
          MyAdhkarDeleted(),
        );
      }
      final tombstone = await _repository.markItemDeleted(
        accountId: _ownerId,
        itemId: itemId,
        deletedAt: now,
        operationId: _nextOperationId(),
        queueForSync: true,
      );
      if (tombstone.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      return const AppResult<MyAdhkarCommandOutcome>.success(MyAdhkarDeleted());
    });
  }

  // -- Shared helpers --------------------------------------------------------

  /// Every chosen group must exist and be live. An unknown group is a typed
  /// failure; a deleted group is the `groupDeleted` outcome (contract).
  Future<AppResult<MyAdhkarCommandOutcome>?> _checkGroups(
    List<String> groupIds,
    DateTime now,
  ) async {
    for (final groupId in groupIds) {
      final read = await _repository.readGroupFresh(
        accountId: _ownerId,
        groupId: groupId,
      );
      if (read.failureOrNull case final failure?) {
        return AppResult<MyAdhkarCommandOutcome>.failure(failure);
      }
      final group = read.valueOrNull;
      if (group == null) {
        return AppResult<MyAdhkarCommandOutcome>.failure(_unknownGroup(now));
      }
      if (group.isDeleted) {
        return const AppResult<MyAdhkarCommandOutcome>.success(
          MyAdhkarGroupDeleted(cascadedEntries: 0),
        );
      }
    }
    return null;
  }

  AppFailure? _draftFailure(MyDhikrDraft draft, DateTime now) {
    final violations = draft.violations();
    if (violations.isEmpty) return null;
    return AppFailure.recoverable(
      category: AppFailureCategory.validation,
      messageKey: switch (violations.first) {
        MyDhikrDraftViolation.text => 'my_adhkar.draft.invalid_text',
        MyDhikrDraftViolation.source => 'my_adhkar.draft.invalid_source',
        MyDhikrDraftViolation.groupSet => 'my_adhkar.draft.empty_group_set',
      },
      occurredAt: now,
    );
  }

  AppFailure? _groupNameFailure(String name, DateTime now) {
    final violations = MyAdhkarGroupDraft(name: name).violations();
    if (violations.isEmpty) return null;
    return AppFailure.recoverable(
      category: AppFailureCategory.validation,
      messageKey: 'my_adhkar.group.invalid_name',
      occurredAt: now,
    );
  }

  AppFailure _unknownGroup(DateTime now) => AppFailure.recoverable(
    category: AppFailureCategory.validation,
    messageKey: 'my_adhkar.group.unknown',
    occurredAt: now,
  );

  AppFailure _unknownItem(DateTime now) => AppFailure.recoverable(
    category: AppFailureCategory.validation,
    messageKey: 'my_adhkar.item.unknown',
    occurredAt: now,
  );

  DateTime _nextVersion(DateTime now, DateTime priorUpdatedAt) =>
      !now.isAfter(priorUpdatedAt)
      ? priorUpdatedAt.add(const Duration(microseconds: 1))
      : now;
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

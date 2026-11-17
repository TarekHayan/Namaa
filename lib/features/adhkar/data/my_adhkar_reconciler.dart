import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

import 'drift_my_adhkar_repository.dart';
import 'supabase_my_adhkar_reader.dart';

final class MyAdhkarReconciliationSummary {
  const MyAdhkarReconciliationSummary({
    required this.importedGroups,
    required this.importedItems,
    required this.importedConflicts,
  });

  final int importedGroups;
  final int importedItems;
  final int importedConflicts;
}

/// Applies a complete owner snapshot atomically (the Adhkar reconciler's
/// contract, reshaped for My Adhkar). Groups apply before entries, so an
/// entry's group set can be checked against the local groups. Rows with
/// pending local work survive untouched: their own RPC receipt resolves a
/// stale base on the server. A tombstone is applied, and never cleared. A
/// server group-delete cascade arrives as the group's tombstone plus the
/// entries' own versions (deleted, or with a smaller group set).
final class MyAdhkarReconciler {
  const MyAdhkarReconciler({
    required DriftMyAdhkarRepository repository,
    required LocalStorePort localStore,
  }) : _repository = repository,
       _localStore = localStore;

  final DriftMyAdhkarRepository _repository;
  final LocalStorePort _localStore;

  Future<AppResult<MyAdhkarReconciliationSummary>> reconcile({
    required String accountId,
    required MyAdhkarRemoteSnapshot remote,
    bool Function()? isCurrentScope,
  }) async {
    bool current() => isCurrentScope?.call() ?? true;
    if (!current()) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    if (remote.groups.any((row) => row.accountId != accountId) ||
        remote.items.any((row) => row.accountId != accountId)) {
      return AppResult.failure(_failure(AppFailureCategory.authorization));
    }
    return _repository.runInTransaction(() async {
      final pendingResult = await _localStore.readPendingChanges(accountId);
      if (!current()) {
        return AppResult.failure(_failure(AppFailureCategory.authorization));
      }
      if (pendingResult.failureOrNull case final failure?) {
        return AppResult.failure(failure);
      }
      final pendingGroups = <String>{};
      final pendingItems = <String>{};
      for (final row in pendingResult.valueOrNull!) {
        if (row.entityType == kMyAdhkarGroupEntityType) {
          pendingGroups.add(row.entityId);
        } else if (row.entityType == kMyAdhkarItemEntityType) {
          pendingItems.add(row.entityId);
        }
      }
      var importedGroups = 0;
      var importedItems = 0;
      var importedConflicts = 0;
      for (final conflict in remote.conflicts) {
        if (!current()) {
          return AppResult.failure(_failure(AppFailureCategory.authorization));
        }
        final applied = await _repository.applyRemoteConflict(
          conflict,
          accountId: accountId,
        );
        if (applied.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        importedConflicts++;
      }
      for (final group in remote.groups) {
        if (!current()) {
          return AppResult.failure(_failure(AppFailureCategory.authorization));
        }
        if (pendingGroups.contains(group.groupId)) continue;
        final applied = await _repository.applyRemoteGroup(
          group,
          accountId: accountId,
        );
        if (applied.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        if (applied.valueOrNull!) importedGroups++;
      }
      for (final item in remote.items) {
        if (!current()) {
          return AppResult.failure(_failure(AppFailureCategory.authorization));
        }
        if (pendingItems.contains(item.itemId)) continue;
        final applied = await _repository.applyRemoteItem(
          item,
          accountId: accountId,
        );
        if (applied.failureOrNull case final failure?) {
          return AppResult.failure(failure);
        }
        if (applied.valueOrNull!) importedItems++;
      }
      if (!current()) {
        return AppResult.failure(_failure(AppFailureCategory.authorization));
      }
      return AppResult.success(
        MyAdhkarReconciliationSummary(
          importedGroups: importedGroups,
          importedItems: importedItems,
          importedConflicts: importedConflicts,
        ),
      );
    });
  }

  AppFailure _failure(AppFailureCategory category) => AppFailure.recoverable(
    category: category,
    messageKey: 'my_adhkar.sync.failed',
    occurredAt: DateTime.now().toUtc(),
  );
}

import 'dart:convert';

import 'package:namma_project/core/data/cloud/supabase/supabase_sync_adapter.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_remote_reader.dart';
import 'package:namma_project/features/tasks/data/supabase_task_sync_adapter.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';
import 'package:namma_project/features/xp/domain/task_completion_award.dart';

/// Completes every authenticated Task and award page before publishing a
/// snapshot.
final class SupabaseTaskReader
    implements TaskRemoteReaderPort, TaskAwardRemoteReaderPort {
  SupabaseTaskReader({
    required SupabaseTaskGateway gateway,
    required TaskPayloadCodec codec,
    this.pageSize = kDefaultTaskRemotePageSize,
  }) : _gateway = gateway,
       _codec = codec;

  final SupabaseTaskGateway _gateway;
  final TaskPayloadCodec _codec;
  final int pageSize;

  @override
  Future<AppResult<List<Task>>> readAllTasks(String accountId) async {
    try {
      final tasks = <Task>[];
      final visitedCursors = <String>{};
      String? cursor;
      do {
        final page = await _gateway.fetchTaskPage(
          pageSize: pageSize,
          cursor: cursor,
        );
        for (final row in page.rows) {
          final owner = row['owner'];
          if (owner != accountId) {
            throw StateError('Remote Task owner did not match active account');
          }
          tasks.add(_decodeRow(row, accountId));
        }
        final next = page.nextCursor;
        if (next != null && !visitedCursors.add(next)) {
          throw StateError('Remote Task pagination cursor repeated');
        }
        cursor = next;
      } while (cursor != null);
      return AppResult<List<Task>>.success(List<Task>.unmodifiable(tasks));
    } catch (error) {
      return AppResult<List<Task>>.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.cloud,
          messageKey: kCloudSyncRecoverableMessageKey,
          occurredAt: DateTime.now().toUtc(),
          technicalCause: error.runtimeType.toString(),
        ),
      );
    }
  }

  @override
  Future<AppResult<List<TaskCompletionAward>>> readAllTaskAwards(
    String accountId,
  ) async {
    try {
      final awardsByKey = <String, TaskCompletionAward>{};
      final visitedCursors = <String>{};
      String? cursor;
      do {
        final page = await _gateway.fetchTaskAwardPage(
          pageSize: pageSize,
          cursor: cursor,
        );
        for (final row in page.rows) {
          final award = _decodeAwardRow(row, accountId);
          final existing = awardsByKey[award.uniqueKey];
          if (existing != null && existing != award) {
            throw StateError(
              'Remote Task award key contained conflicting immutable values',
            );
          }
          awardsByKey.putIfAbsent(award.uniqueKey, () => award);
        }
        final next = page.nextCursor;
        if (next != null && !visitedCursors.add(next)) {
          throw StateError('Remote Task award pagination cursor repeated');
        }
        cursor = next;
      } while (cursor != null);
      return AppResult<List<TaskCompletionAward>>.success(
        List<TaskCompletionAward>.unmodifiable(awardsByKey.values),
      );
    } catch (error) {
      return AppResult<List<TaskCompletionAward>>.failure(_cloudFailure(error));
    }
  }

  Task _decodeRow(Map<String, dynamic> row, String accountId) {
    final rawPayload = row['payload'];
    if (rawPayload is! Map) {
      throw const FormatException('Remote Task payload must be an object');
    }
    final payload = Map<String, dynamic>.from(rawPayload);
    payload['id'] = row['id'];
    payload['accountId'] = accountId;
    payload['updatedAt'] = row['updated_at'];
    payload['deletedAt'] = row['deleted_at'];
    return _codec.decode(jsonEncode(payload));
  }

  TaskCompletionAward _decodeAwardRow(
    Map<String, dynamic> row,
    String accountId,
  ) {
    if (row['owner'] != accountId) {
      throw StateError('Remote Task award owner did not match active account');
    }
    final source = row['source'];
    final sourceId = row['source_id'];
    final amount = row['amount'];
    final awardedAtValue = row['awarded_at'];
    if (source is! String || sourceId is! String || amount is! int) {
      throw const FormatException('Remote Task award fields are invalid');
    }
    if (awardedAtValue is! String) {
      throw const FormatException('Remote Task award timestamp is missing');
    }
    final awardedAt = DateTime.tryParse(awardedAtValue);
    if (awardedAt == null) {
      throw const FormatException('Remote Task award timestamp is invalid');
    }
    return TaskCompletionAward(
      accountId: accountId,
      source: source,
      sourceId: sourceId,
      amount: amount,
      awardedAt: awardedAt.toUtc(),
    );
  }

  static AppFailure _cloudFailure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.cloud,
    messageKey: kCloudSyncRecoverableMessageKey,
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}

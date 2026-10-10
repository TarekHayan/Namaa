import 'dart:convert';

import 'package:namma_project/core/data/cloud/supabase/supabase_sync_adapter.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/tasks/application/task_remote_reader.dart';
import 'package:namma_project/features/tasks/data/supabase_task_sync_adapter.dart';
import 'package:namma_project/features/tasks/data/task_payload_codec.dart';
import 'package:namma_project/features/tasks/domain/task.dart';

/// Completes every authenticated Task page before publishing a snapshot.
final class SupabaseTaskReader implements TaskRemoteReaderPort {
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
}

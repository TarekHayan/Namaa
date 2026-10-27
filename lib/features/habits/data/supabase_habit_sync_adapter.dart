import 'dart:convert';

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/data/sync/entity_dispatch_router.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/habits/data/habit_payload_codec.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const int kHabitRemotePageSize = 100;

final class HabitRemotePage {
  const HabitRemotePage({required this.rows, this.nextCursor});
  final List<Map<String, dynamic>> rows;
  final String? nextCursor;
}

abstract interface class SupabaseHabitGateway {
  String? get currentAccountId;
  Future<Map<String, dynamic>> applyChange({
    required String expectedAccountId,
    required String entityType,
    required String habitId,
    String? localDate,
    required Map<String, dynamic> payload,
    required String operationId,
    required String kind,
    required DateTime updatedAt,
  });
  Future<HabitRemotePage> fetchHabitPage({
    required String expectedAccountId,
    required int pageSize,
    String? cursor,
  });
  Future<HabitRemotePage> fetchDayPage({
    required String expectedAccountId,
    required int pageSize,
    String? cursor,
  });
}

final class SupabaseHabitGatewayImpl implements SupabaseHabitGateway {
  SupabaseHabitGatewayImpl(this._client);
  final SupabaseClient _client;

  @override
  String? get currentAccountId => _client.auth.currentUser?.id;

  void _checkAccount(String expected) {
    if (_client.auth.currentUser?.id != expected) {
      throw StateError('Authenticated account changed during Habit sync');
    }
  }

  @override
  Future<Map<String, dynamic>> applyChange({
    required String expectedAccountId,
    required String entityType,
    required String habitId,
    String? localDate,
    required Map<String, dynamic> payload,
    required String operationId,
    required String kind,
    required DateTime updatedAt,
  }) async {
    _checkAccount(expectedAccountId);
    final isDay = entityType == kHabitDayEntityType;
    final result = await _client.rpc<dynamic>(
      isDay ? 'apply_habit_day_change' : 'apply_habit_change',
      params: isDay
          ? <String, Object?>{
              'p_habit_id': habitId,
              'p_local_date': localDate,
              'p_payload': payload,
              'p_operation_id': operationId,
              'p_updated_at': updatedAt.toUtc().toIso8601String(),
              'p_kind': kind,
            }
          : <String, Object?>{
              'p_id': habitId,
              'p_payload': payload,
              'p_operation_id': operationId,
              'p_updated_at': updatedAt.toUtc().toIso8601String(),
              'p_kind': kind,
            },
    );
    _checkAccount(expectedAccountId);
    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first as Map);
    }
    if (result is Map) return Map<String, dynamic>.from(result);
    throw StateError('Habit mutation returned no receipt');
  }

  @override
  Future<HabitRemotePage> fetchHabitPage({
    required String expectedAccountId,
    required int pageSize,
    String? cursor,
  }) async {
    _checkAccount(expectedAccountId);
    final offset = cursor == null ? 0 : int.parse(cursor);
    if (offset < 0) throw const FormatException('Invalid Habit cursor');
    final response = await _client
        .from('habits')
        .select()
        .eq('owner', expectedAccountId)
        .order('id')
        .range(offset, offset + pageSize - 1);
    _checkAccount(expectedAccountId);
    final rows = [
      for (final row in response) Map<String, dynamic>.from(row as Map),
    ];
    return HabitRemotePage(
      rows: rows,
      nextCursor: rows.length == pageSize ? '${offset + rows.length}' : null,
    );
  }

  @override
  Future<HabitRemotePage> fetchDayPage({
    required String expectedAccountId,
    required int pageSize,
    String? cursor,
  }) async {
    _checkAccount(expectedAccountId);
    final offset = cursor == null ? 0 : int.parse(cursor);
    if (offset < 0) throw const FormatException('Invalid HabitDay cursor');
    final response = await _client
        .from('habit_days')
        .select()
        .eq('owner', expectedAccountId)
        .order('habit_id')
        .order('local_date')
        .range(offset, offset + pageSize - 1);
    _checkAccount(expectedAccountId);
    final rows = [
      for (final row in response) Map<String, dynamic>.from(row as Map),
    ];
    return HabitRemotePage(
      rows: rows,
      nextCursor: rows.length == pageSize ? '${offset + rows.length}' : null,
    );
  }
}

final class SupabaseHabitSyncAdapter implements CloudSyncPort {
  SupabaseHabitSyncAdapter({
    required SupabaseHabitGateway gateway,
    HabitPayloadCodec codec = const HabitPayloadCodec(),
  }) : _gateway = gateway,
       _codec = codec;
  final SupabaseHabitGateway _gateway;
  final HabitPayloadCodec _codec;

  @override
  Future<AppResult<DispatchOutcome>> dispatchChange(
    OutboundChange change,
  ) async {
    try {
      if (change.entityType != kHabitEntityType &&
          change.entityType != kHabitDayEntityType) {
        throw const FormatException('Unsupported Habit entity type');
      }
      final decoded = jsonDecode(change.payload);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Habit payload must be an object');
      }
      final isDay = change.entityType == kHabitDayEntityType;
      final localDate = isDay ? decoded['localDate'] as String? : null;
      if (isDay) {
        final day = _codec.decodeDay(change.payload);
        if (day.accountId != change.accountId ||
            '${day.habitId}:${day.localDate}' != change.entityId ||
            day.updatedAt != change.versionTimestamp) {
          throw const FormatException('HabitDay operation identity mismatch');
        }
      } else {
        final habit = _codec.decodeHabit(change.payload);
        if (habit.accountId != change.accountId ||
            habit.id != change.entityId ||
            habit.updatedAt != change.versionTimestamp ||
            habit.isDeleted != (change.kind == ChangeKind.delete)) {
          throw const FormatException('Habit operation identity mismatch');
        }
      }
      final habitId = isDay ? decoded['habitId'] as String : change.entityId;
      final row = await _gateway.applyChange(
        expectedAccountId: change.accountId,
        entityType: change.entityType,
        habitId: habitId,
        localDate: localDate,
        payload: {
          ...decoded,
          if (change.baseUpdatedAt != null)
            '_syncBaseUpdatedAt': change.baseUpdatedAt!
                .toUtc()
                .toIso8601String(),
        },
        operationId: change.operationId,
        kind: change.kind.name,
        updatedAt: change.versionTimestamp,
      );
      if (row['owner'] != change.accountId ||
          row['operation_id'] != change.operationId ||
          row['entity_type'] != change.entityType ||
          row['id'] != habitId ||
          (isDay && row['local_date'] != localDate)) {
        throw StateError('Habit receipt identity mismatch');
      }
      if (row['conflict_detected'] == true) {
        final activeAt = _timestamp(row['updated_at']);
        final retainedAt = _timestamp(row['retained_updated_at']);
        final incomingActive = activeAt == change.versionTimestamp;
        final competingAt = incomingActive ? retainedAt : activeAt;
        final competing = incomingActive
            ? row['retained_payload']
            : row['payload'];
        if (competingAt != null) {
          return AppResult.success(
            DispatchVersionConflict(
              remoteVersionTimestamp: competingAt,
              remotePayload: competing == null ? null : jsonEncode(competing),
            ),
          );
        }
      }
      return AppResult.success(
        DispatchAcknowledged(
          acknowledgementId: change.operationId,
          remoteVersionTimestamp: _timestamp(row['updated_at']),
        ),
      );
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  @override
  Future<AppResult<RemoteVersion?>> obtainRemoteVersion({
    required String entityType,
    required String entityId,
  }) async {
    try {
      if (entityType != kHabitEntityType && entityType != kHabitDayEntityType) {
        throw const FormatException('Unsupported Habit entity type');
      }
      final account = _gateway.currentAccountId;
      if (account == null) throw StateError('Not authenticated');
      String? cursor;
      final seen = <String>{};
      do {
        final page = entityType == kHabitEntityType
            ? await _gateway.fetchHabitPage(
                expectedAccountId: account,
                pageSize: kHabitRemotePageSize,
                cursor: cursor,
              )
            : await _gateway.fetchDayPage(
                expectedAccountId: account,
                pageSize: kHabitRemotePageSize,
                cursor: cursor,
              );
        for (final row in page.rows) {
          final id = entityType == kHabitEntityType
              ? row['id']
              : '${row['habit_id']}:${row['local_date']}';
          if (id == entityId) {
            if (row['owner'] != account) {
              throw StateError('Foreign Habit owner');
            }
            final at = _timestamp(row['updated_at']);
            if (at == null) {
              throw const FormatException('Missing Habit version');
            }
            return AppResult.success(
              RemoteVersion(
                entityType: entityType,
                entityId: entityId,
                versionTimestamp: at,
                payload: jsonEncode(row['payload']),
              ),
            );
          }
        }
        cursor = page.nextCursor;
        if (cursor != null && !seen.add(cursor)) {
          throw StateError('Repeated Habit cursor');
        }
      } while (cursor != null);
      return const AppResult.success(null);
    } catch (error) {
      return AppResult.failure(_failure(error));
    }
  }

  static DateTime? _timestamp(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
  static AppFailure _failure(Object error) => AppFailure.recoverable(
    category: AppFailureCategory.cloud,
    messageKey: 'habits.sync.failed',
    occurredAt: DateTime.now().toUtc(),
    technicalCause: error.runtimeType.toString(),
  );
}

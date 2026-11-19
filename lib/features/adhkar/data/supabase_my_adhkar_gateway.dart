import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'my_adhkar_remote_models.dart';

/// The My Adhkar remote boundary (contracts/adhkar-qiyam-sync.md): the two
/// typed RPCs of migration 0017 plus the single-row fetches the remote
/// version lookup uses. The client sends no owner and no XP of any kind.
abstract interface class SupabaseMyAdhkarGateway {
  String? get currentAccountId;

  /// `apply_my_adhkar_group_change_v1`.
  Future<MyAdhkarDispatchReceipt> applyGroupChange({
    required String expectedAccountId,
    required MyAdhkarGroup group,
    required String operationId,
    required DateTime? baseUpdatedAt,
  });

  /// `apply_my_adhkar_item_change_v1` (with `p_group_ids`; ignored by the
  /// server when the operation deletes the entry).
  Future<MyAdhkarDispatchReceipt> applyItemChange({
    required String expectedAccountId,
    required MyDhikrItem item,
    required String operationId,
    required DateTime? baseUpdatedAt,
  });

  /// The remote group row, or null when the server does not know it.
  Future<MyAdhkarRemoteGroup?> fetchGroup({
    required String expectedAccountId,
    required String groupId,
  });

  /// The remote entry row with its group set, or null when unknown.
  Future<MyAdhkarRemoteItem?> fetchItem({
    required String expectedAccountId,
    required String itemId,
  });
}

/// The exact RPC arguments for each outbox operation. They are built in one
/// place so the mapping is testable without a network: the group set of a
/// deleted entry is sent empty (the server ignores it), and no owner, XP
/// amount, count or day ever travels.
abstract final class MyAdhkarRpcParams {
  static Map<String, Object?> group({
    required MyAdhkarGroup group,
    required String operationId,
    required DateTime? baseUpdatedAt,
  }) => <String, Object?>{
    'p_group_id': group.groupId,
    'p_name': group.name,
    'p_created_at': group.createdAt.toUtc().toIso8601String(),
    'p_deleted': group.isDeleted,
    'p_updated_at': group.updatedAt.toUtc().toIso8601String(),
    'p_base_updated_at': baseUpdatedAt?.toUtc().toIso8601String(),
    'p_operation_id': operationId,
  };

  static Map<String, Object?> item({
    required MyDhikrItem item,
    required String operationId,
    required DateTime? baseUpdatedAt,
  }) => <String, Object?>{
    'p_item_id': item.itemId,
    'p_text': item.text,
    'p_source': item.source,
    'p_group_ids': item.isDeleted ? <String>[] : ([...item.groupIds]..sort()),
    'p_created_at': item.createdAt.toUtc().toIso8601String(),
    'p_deleted': item.isDeleted,
    'p_updated_at': item.updatedAt.toUtc().toIso8601String(),
    'p_base_updated_at': baseUpdatedAt?.toUtc().toIso8601String(),
    'p_operation_id': operationId,
  };
}

final class SupabaseMyAdhkarGatewayImpl implements SupabaseMyAdhkarGateway {
  SupabaseMyAdhkarGatewayImpl(this._client);

  final SupabaseClient _client;

  @override
  String? get currentAccountId => _client.auth.currentUser?.id;

  @override
  Future<MyAdhkarDispatchReceipt> applyGroupChange({
    required String expectedAccountId,
    required MyAdhkarGroup group,
    required String operationId,
    required DateTime? baseUpdatedAt,
  }) async {
    _requireOwner(expectedAccountId);
    if (group.accountId != expectedAccountId) {
      throw const FormatException('My Adhkar outbound owner mismatch');
    }
    final response = await _client.rpc<dynamic>(
      'apply_my_adhkar_group_change_v1',
      params: MyAdhkarRpcParams.group(
        group: group,
        operationId: operationId,
        baseUpdatedAt: baseUpdatedAt,
      ),
    );
    _requireOwner(expectedAccountId);
    if (response is! Map) {
      throw const FormatException('My Adhkar RPC returned no receipt');
    }
    return MyAdhkarRemoteModels.receipt(
      Map<String, dynamic>.from(response),
      accountId: expectedAccountId,
      operationId: operationId,
      recordId: group.groupId,
      entityType: 'group',
    );
  }

  @override
  Future<MyAdhkarDispatchReceipt> applyItemChange({
    required String expectedAccountId,
    required MyDhikrItem item,
    required String operationId,
    required DateTime? baseUpdatedAt,
  }) async {
    _requireOwner(expectedAccountId);
    if (item.accountId != expectedAccountId) {
      throw const FormatException('My Adhkar outbound owner mismatch');
    }
    final response = await _client.rpc<dynamic>(
      'apply_my_adhkar_item_change_v1',
      params: MyAdhkarRpcParams.item(
        item: item,
        operationId: operationId,
        baseUpdatedAt: baseUpdatedAt,
      ),
    );
    _requireOwner(expectedAccountId);
    if (response is! Map) {
      throw const FormatException('My Adhkar RPC returned no receipt');
    }
    return MyAdhkarRemoteModels.receipt(
      Map<String, dynamic>.from(response),
      accountId: expectedAccountId,
      operationId: operationId,
      recordId: item.itemId,
      entityType: 'item',
    );
  }

  @override
  Future<MyAdhkarRemoteGroup?> fetchGroup({
    required String expectedAccountId,
    required String groupId,
  }) async {
    _requireOwner(expectedAccountId);
    final response = await _client
        .from('my_adhkar_groups')
        .select()
        .eq('owner', expectedAccountId)
        .eq('group_id', groupId)
        .maybeSingle();
    _requireOwner(expectedAccountId);
    return response == null
        ? null
        : MyAdhkarRemoteGroup.fromJson(
            Map<String, dynamic>.from(response),
            expectedAccountId,
          );
  }

  @override
  Future<MyAdhkarRemoteItem?> fetchItem({
    required String expectedAccountId,
    required String itemId,
  }) async {
    _requireOwner(expectedAccountId);
    // One request: the entry with its membership rows embedded, so the group
    // set is always the one that belongs to the returned version.
    final response = await _client
        .from('my_adhkar_items')
        .select('*, my_adhkar_item_groups(group_id, added_at)')
        .eq('owner', expectedAccountId)
        .eq('item_id', itemId)
        .maybeSingle();
    _requireOwner(expectedAccountId);
    return response == null
        ? null
        : MyAdhkarRemoteItem.fromJson(
            Map<String, dynamic>.from(response),
            expectedAccountId,
          );
  }

  void _requireOwner(String expected) {
    if (currentAccountId != expected) {
      throw StateError('Authenticated account changed during My Adhkar sync');
    }
  }
}

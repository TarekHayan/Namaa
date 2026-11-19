import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_commands.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import 'my_adhkar_state.dart';

/// The My Adhkar state holder, composed beside `AdhkarCubit`
/// (contracts/adhkar-qiyam-application.md): the group list, the opened
/// group and the group and entry commands. It is bound to ONE owner; an
/// account change closes it and opens a new one, so nothing from the
/// previous owner is shown. It has no Adhkar clock or times dependency, so
/// it works the same when the Prayer schedule is unavailable, and it never
/// feeds the set completion, the celebration, the streak or XP (FR-026).
///
/// A command is ignored while another is in flight, so rapid taps cannot
/// stack. Nothing is emitted after close.
final class MyAdhkarCubit extends Cubit<MyAdhkarState> {
  MyAdhkarCubit({
    required String ownerId,
    required MyAdhkarRepository repository,
    required MyAdhkarCommandRunner commands,
  }) : _ownerId = ownerId,
       _repository = repository,
       _commands = commands,
       super(const MyAdhkarState());

  final String _ownerId;
  final MyAdhkarRepository _repository;
  final MyAdhkarCommandRunner _commands;

  Future<void>? _loading;
  StreamSubscription<List<MyAdhkarGroupSummary>>? _groupsSubscription;
  StreamSubscription<List<MyDhikrItem>>? _itemsSubscription;
  int _itemsGeneration = 0;
  bool _busy = false;

  /// Subscribes to the live groups; completes when the first list arrived.
  /// Safe to call again: the subscription is made once.
  Future<void> load() => _loading ??= _start();

  Future<void> _start() async {
    final first = Completer<void>();
    _groupsSubscription = _repository
        .watchGroups(_ownerId)
        .listen(
          (groups) {
            if (isClosed) return;
            _applyGroups(groups);
            if (!first.isCompleted) first.complete();
          },
          onError: (Object error) {
            if (isClosed) return;
            emit(state.copyWith(loadFailed: true));
            if (!first.isCompleted) first.complete();
          },
        );
    await first.future;
    if (!isClosed) await _refreshEntryCount();
  }

  void _applyGroups(List<MyAdhkarGroupSummary> groups) {
    final opened = state.openedGroupId;
    final openedStillLive =
        opened == null || groups.any((s) => s.group.groupId == opened);
    emit(
      state.copyWith(
        loaded: true,
        loadFailed: false,
        groups: groups,
        openedGroupId: openedStillLive ? opened : null,
        openedGroupItems: openedStillLive ? null : const [],
      ),
    );
    if (!openedStillLive) _stopWatchingItems();
    unawaited(_refreshEntryCount());
  }

  Future<void> _refreshEntryCount() async {
    final count = await _repository.liveEntryCount(accountId: _ownerId);
    if (isClosed) return;
    final value = count.valueOrNull;
    if (value != null && value != state.liveEntryCount) {
      emit(state.copyWith(liveEntryCount: value));
    }
  }

  /// Opens a group inside the tab; completes when its entries arrived.
  Future<void> openGroup(String groupId) {
    if (isClosed) return Future.value();
    _stopWatchingItems();
    final generation = _itemsGeneration;
    emit(state.copyWith(openedGroupId: groupId, openedGroupItems: const []));
    final first = Completer<void>();
    _itemsSubscription = _repository
        .watchGroupItems(accountId: _ownerId, groupId: groupId)
        .listen(
          (items) {
            if (isClosed || generation != _itemsGeneration) return;
            emit(state.copyWith(openedGroupItems: items));
            if (!first.isCompleted) first.complete();
          },
          onError: (Object error) {
            if (!first.isCompleted) first.complete();
          },
        );
    return first.future;
  }

  /// Back to the group list.
  Future<void> closeGroup() async {
    _stopWatchingItems();
    if (isClosed) return;
    emit(state.copyWith(openedGroupId: null, openedGroupItems: const []));
  }

  void _stopWatchingItems() {
    _itemsGeneration++;
    unawaited(_itemsSubscription?.cancel());
    _itemsSubscription = null;
  }

  Future<MyAdhkarActionResult> createGroup({required String name}) =>
      _run(() => _commands.createGroup(name: name));

  Future<MyAdhkarActionResult> renameGroup({
    required String groupId,
    required String name,
  }) => _run(() => _commands.renameGroup(groupId: groupId, name: name));

  /// How many entries deleting the group would remove, for the confirmation;
  /// null when the count could not be read.
  Future<int?> previewDeleteGroup({required String groupId}) async {
    try {
      return (await _commands.previewDeleteGroup(groupId: groupId)).valueOrNull;
    } catch (_) {
      return null;
    }
  }

  Future<MyAdhkarActionResult> deleteGroup({required String groupId}) async {
    final result = await _run(
      () => _commands.deleteGroup(groupId: groupId),
      deletesGroup: true,
    );
    if (result.succeeded && state.openedGroupId == groupId) {
      await closeGroup();
    }
    return result;
  }

  Future<MyAdhkarActionResult> addEntry({required MyDhikrDraft draft}) =>
      _run(() => _commands.add(draft: draft));

  Future<MyAdhkarActionResult> editEntry({
    required String itemId,
    required MyDhikrDraft draft,
  }) => _run(() => _commands.edit(itemId: itemId, draft: draft));

  Future<MyAdhkarActionResult> deleteEntry({required String itemId}) =>
      _run(() => _commands.delete(itemId: itemId));

  Future<MyAdhkarActionResult> _run(
    Future<AppResult<MyAdhkarCommandOutcome>> Function() action, {
    bool deletesGroup = false,
  }) async {
    if (_busy || isClosed) return const MyAdhkarActionResult.ignored();
    _busy = true;
    emit(state.copyWith(busy: true));
    try {
      final result = await action();
      final mapped = _map(result, deletesGroup: deletesGroup);
      if (mapped.succeeded && !isClosed) await _refreshEntryCount();
      return mapped;
    } catch (_) {
      return const MyAdhkarActionResult.failed(MyAdhkarFailure.unavailable);
    } finally {
      _busy = false;
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  MyAdhkarActionResult _map(
    AppResult<MyAdhkarCommandOutcome> result, {
    required bool deletesGroup,
  }) {
    final failure = result.failureOrNull;
    if (failure != null) {
      return MyAdhkarActionResult.failed(switch (failure.messageKey) {
        'my_adhkar.draft.invalid_text' => MyAdhkarFailure.textInvalid,
        'my_adhkar.draft.invalid_source' => MyAdhkarFailure.sourceInvalid,
        'my_adhkar.draft.empty_group_set' => MyAdhkarFailure.groupSetInvalid,
        'my_adhkar.group.invalid_name' => MyAdhkarFailure.groupNameInvalid,
        'my_adhkar.group.unknown' => MyAdhkarFailure.groupUnknown,
        'my_adhkar.item.unknown' => MyAdhkarFailure.itemUnknown,
        _ => MyAdhkarFailure.unavailable,
      });
    }
    return switch (result.valueOrNull) {
      MyAdhkarGroupCreated(:final groupId) => MyAdhkarActionResult.success(
        groupId: groupId,
      ),
      MyAdhkarAdded(:final itemId) => MyAdhkarActionResult.success(
        itemId: itemId,
      ),
      MyAdhkarGroupDeleted(:final cascadedEntries) =>
        deletesGroup
            ? MyAdhkarActionResult.success(deletedEntries: cascadedEntries)
            : const MyAdhkarActionResult.failed(MyAdhkarFailure.groupDeleted),
      MyAdhkarGroupLimitReached() => const MyAdhkarActionResult.failed(
        MyAdhkarFailure.groupLimitReached,
      ),
      MyAdhkarLimitReached() => const MyAdhkarActionResult.failed(
        MyAdhkarFailure.entryLimitReached,
      ),
      MyAdhkarItemDeleted() => const MyAdhkarActionResult.failed(
        MyAdhkarFailure.itemDeleted,
      ),
      _ => const MyAdhkarActionResult.success(),
    };
  }

  @override
  Future<void> close() async {
    await _groupsSubscription?.cancel();
    await _itemsSubscription?.cancel();
    return super.close();
  }
}

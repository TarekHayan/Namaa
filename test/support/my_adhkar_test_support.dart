import 'dart:async';

import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_commands.dart';
import 'package:namma_project/features/adhkar/application/my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';
import 'package:namma_project/features/adhkar/presentation/my_adhkar_cubit.dart';

/// An in-memory My Adhkar store for widget tests: the repository streams and
/// the command runner share one list of live groups and entries, so a widget
/// test exercises the real [MyAdhkarCubit] with no encrypted database.
final class MemoryMyAdhkarStore {
  MemoryMyAdhkarStore({this.owner = 'owner'});

  final String owner;
  final List<MyAdhkarGroup> groups = [];
  final List<MyDhikrItem> items = [];

  /// Live entries counted by the limit but not listed (to reach 1000 without
  /// building a thousand cards).
  int phantomEntries = 0;

  /// When set, the next add/edit/create/rename returns this outcome instead
  /// of writing (to show a rejected command inline).
  MyAdhkarCommandOutcome? rejectNextWith;

  final StreamController<void> _changes = StreamController<void>.broadcast(
    sync: true,
  );
  int _serial = 0;
  final DateTime _base = DateTime.utc(2026, 11, 16, 9);

  DateTime _tick() => _base.add(Duration(minutes: ++_serial));

  void notifyChanged() => _changes.add(null);

  MyAdhkarGroup addGroup(String name, {String? id}) {
    final at = _tick();
    final group = MyAdhkarGroup(
      accountId: owner,
      groupId: id ?? 'group-${groups.length + 1}',
      name: name,
      createdAt: at,
      updatedAt: at,
      lastAcknowledgedUpdatedAt: null,
      deletedAt: null,
    );
    groups.add(group);
    notifyChanged();
    return group;
  }

  MyDhikrItem addItem({
    required String text,
    String? source,
    required List<String> groupIds,
    String? id,
  }) {
    final at = _tick();
    final item = MyDhikrItem(
      accountId: owner,
      itemId: id ?? 'item-${items.length + 1}',
      text: text,
      source: source,
      groupIds: groupIds,
      createdAt: at,
      updatedAt: at,
      lastAcknowledgedUpdatedAt: null,
      deletedAt: null,
    );
    items.add(item);
    notifyChanged();
    return item;
  }

  List<MyAdhkarGroupSummary> summaries() => [
    for (final group in groups)
      MyAdhkarGroupSummary(
        group: group,
        liveEntryCount: items
            .where((item) => item.groupIds.contains(group.groupId))
            .length,
      ),
  ];

  List<MyDhikrItem> itemsOf(String groupId) => [
    for (final item in items)
      if (item.groupIds.contains(groupId)) item,
  ];

  int get liveEntryCount => items.length + phantomEntries;

  MyAdhkarCubit cubit() => MyAdhkarCubit(
    ownerId: owner,
    repository: MemoryMyAdhkarRepository(this),
    commands: MemoryMyAdhkarCommands(this),
  );
}

final class MemoryMyAdhkarRepository implements MyAdhkarRepository {
  MemoryMyAdhkarRepository(this._store);

  final MemoryMyAdhkarStore _store;

  /// A plain controller (not an `async*` generator): cancelling it completes
  /// at once, so a Cubit can be closed in a tearDown outside the widget
  /// test's fake-async zone.
  Stream<T> _watch<T>(T Function() read) {
    late final StreamController<T> controller;
    StreamSubscription<void>? subscription;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        subscription = _store._changes.stream.listen(
          (_) => controller.add(read()),
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Stream<List<MyAdhkarGroupSummary>> watchGroups(String accountId) =>
      _watch(_store.summaries);

  @override
  Stream<List<MyDhikrItem>> watchGroupItems({
    required String accountId,
    required String groupId,
  }) => _watch(() => _store.itemsOf(groupId));

  @override
  Future<AppResult<int>> liveEntryCount({required String accountId}) async =>
      AppResult.success(_store.liveEntryCount);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

AppFailure _validation(String key) => AppFailure.recoverable(
  category: AppFailureCategory.validation,
  messageKey: key,
  occurredAt: DateTime.utc(2026, 11, 16, 9),
);

final class MemoryMyAdhkarCommands implements MyAdhkarCommandRunner {
  MemoryMyAdhkarCommands(this._store);

  final MemoryMyAdhkarStore _store;

  /// Every command call, in order (for the in-flight guard and call counts).
  final List<String> calls = [];

  AppResult<MyAdhkarCommandOutcome>? _rejection() {
    final outcome = _store.rejectNextWith;
    if (outcome == null) return null;
    _store.rejectNextWith = null;
    return AppResult.success(outcome);
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> createGroup({
    required String name,
  }) async {
    calls.add('createGroup');
    if (MyAdhkarGroupDraft(name: name).violations().isNotEmpty) {
      return AppResult.failure(_validation('my_adhkar.group.invalid_name'));
    }
    if (_rejection() case final rejection?) return rejection;
    if (!canCreateMyAdhkarGroup(_store.groups.length)) {
      return const AppResult.success(MyAdhkarGroupLimitReached());
    }
    final group = _store.addGroup(name.trim());
    return AppResult.success(MyAdhkarGroupCreated(groupId: group.groupId));
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> renameGroup({
    required String groupId,
    required String name,
  }) async {
    calls.add('renameGroup');
    if (MyAdhkarGroupDraft(name: name).violations().isNotEmpty) {
      return AppResult.failure(_validation('my_adhkar.group.invalid_name'));
    }
    if (_rejection() case final rejection?) return rejection;
    final index = _store.groups.indexWhere((g) => g.groupId == groupId);
    if (index < 0) {
      return const AppResult.success(MyAdhkarGroupDeleted(cascadedEntries: 0));
    }
    _store.groups[index] = _store.groups[index].copyWith(
      name: name.trim(),
      updatedAt: _store._tick(),
    );
    _store.notifyChanged();
    return const AppResult.success(MyAdhkarGroupRenamed());
  }

  @override
  Future<AppResult<int>> previewDeleteGroup({required String groupId}) async =>
      AppResult.success(
        _store.items
            .where(
              (i) => i.groupIds.length == 1 && i.groupIds.single == groupId,
            )
            .length,
      );

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> deleteGroup({
    required String groupId,
  }) async {
    calls.add('deleteGroup');
    final cascaded = (await previewDeleteGroup(groupId: groupId)).valueOrNull!;
    _store.groups.removeWhere((g) => g.groupId == groupId);
    final kept = <MyDhikrItem>[];
    for (final item in _store.items) {
      if (!item.groupIds.contains(groupId)) {
        kept.add(item);
      } else if (item.groupIds.length > 1) {
        kept.add(
          item.copyWith(
            groupIds: item.groupIds.where((g) => g != groupId).toList(),
          ),
        );
      }
    }
    _store.items
      ..clear()
      ..addAll(kept);
    _store.notifyChanged();
    return AppResult.success(MyAdhkarGroupDeleted(cascadedEntries: cascaded));
  }

  AppFailure? _draftFailure(MyDhikrDraft draft) {
    final violations = draft.violations();
    if (violations.isEmpty) return null;
    return _validation(switch (violations.first) {
      MyDhikrDraftViolation.text => 'my_adhkar.draft.invalid_text',
      MyDhikrDraftViolation.source => 'my_adhkar.draft.invalid_source',
      MyDhikrDraftViolation.groupSet => 'my_adhkar.draft.empty_group_set',
    });
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> add({
    required MyDhikrDraft draft,
  }) async {
    calls.add('add');
    if (_draftFailure(draft) case final failure?) {
      return AppResult.failure(failure);
    }
    if (_rejection() case final rejection?) return rejection;
    if (!canAddMyDhikr(_store.liveEntryCount)) {
      return const AppResult.success(MyAdhkarLimitReached());
    }
    final item = _store.addItem(
      text: draft.trimmedText,
      source: draft.trimmedSource,
      groupIds: draft.groupIds,
    );
    return AppResult.success(MyAdhkarAdded(itemId: item.itemId));
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> edit({
    required String itemId,
    required MyDhikrDraft draft,
  }) async {
    calls.add('edit');
    if (_draftFailure(draft) case final failure?) {
      return AppResult.failure(failure);
    }
    if (_rejection() case final rejection?) return rejection;
    final index = _store.items.indexWhere((i) => i.itemId == itemId);
    if (index < 0) return const AppResult.success(MyAdhkarItemDeleted());
    _store.items[index] = _store.items[index].copyWith(
      text: draft.trimmedText,
      source: draft.trimmedSource,
      groupIds: draft.groupIds,
      updatedAt: _store._tick(),
    );
    _store.notifyChanged();
    return const AppResult.success(MyAdhkarEdited());
  }

  @override
  Future<AppResult<MyAdhkarCommandOutcome>> delete({
    required String itemId,
  }) async {
    calls.add('delete');
    _store.items.removeWhere((i) => i.itemId == itemId);
    _store.notifyChanged();
    return const AppResult.success(MyAdhkarDeleted());
  }
}

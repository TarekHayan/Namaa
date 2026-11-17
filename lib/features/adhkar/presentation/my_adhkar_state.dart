import 'package:namma_project/features/adhkar/application/my_adhkar_repository.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

/// Why a My Adhkar action did not happen, typed for the inline, localized
/// message (never a raw failure key in the UI).
enum MyAdhkarFailure {
  groupNameInvalid,
  textInvalid,
  sourceInvalid,
  groupSetInvalid,
  groupLimitReached,
  entryLimitReached,
  groupDeleted,
  groupUnknown,
  itemDeleted,
  itemUnknown,
  unavailable,
}

/// The result of one My Adhkar action: done (with the identity it created or
/// the entries a group delete cascaded), failed with a typed reason, or
/// ignored because another action was still in flight.
final class MyAdhkarActionResult {
  const MyAdhkarActionResult.success({
    this.groupId,
    this.itemId,
    this.deletedEntries,
  }) : failure = null,
       ignored = false;

  const MyAdhkarActionResult.failed(MyAdhkarFailure this.failure)
    : groupId = null,
      itemId = null,
      deletedEntries = null,
      ignored = false;

  const MyAdhkarActionResult.ignored()
    : failure = null,
      groupId = null,
      itemId = null,
      deletedEntries = null,
      ignored = true;

  final MyAdhkarFailure? failure;
  final bool ignored;
  final String? groupId;
  final String? itemId;
  final int? deletedEntries;

  bool get succeeded => failure == null && !ignored;
}

/// The My Adhkar tab state: the live groups with their entry counts, the
/// opened group and its entries, and the guards for the limits. It has no
/// counter, target, day, locked state, celebration or streak (FR-024,
/// FR-026): My Adhkar is a plain personal collection.
final class MyAdhkarState {
  const MyAdhkarState({
    this.loaded = false,
    this.loadFailed = false,
    this.groups = const [],
    this.openedGroupId,
    this.openedGroupItems = const [],
    this.liveEntryCount = 0,
    this.busy = false,
  });

  /// True once the first group list arrived.
  final bool loaded;
  final bool loadFailed;

  /// The live groups, oldest first.
  final List<MyAdhkarGroupSummary> groups;
  final String? openedGroupId;

  /// The opened group's live entries in the order they were added to it.
  final List<MyDhikrItem> openedGroupItems;

  /// The account's live entries (an entry in two groups counts once), for
  /// the 1000-entry limit.
  final int liveEntryCount;

  /// True while a command is in flight; further commands are ignored.
  final bool busy;

  bool get groupLimitReached => !canCreateMyAdhkarGroup(groups.length);
  bool get entryLimitReached => !canAddMyDhikr(liveEntryCount);

  MyAdhkarGroupSummary? get openedGroup {
    final id = openedGroupId;
    if (id == null) return null;
    for (final summary in groups) {
      if (summary.group.groupId == id) return summary;
    }
    return null;
  }

  static const Object _unset = Object();

  MyAdhkarState copyWith({
    bool? loaded,
    bool? loadFailed,
    List<MyAdhkarGroupSummary>? groups,
    Object? openedGroupId = _unset,
    List<MyDhikrItem>? openedGroupItems,
    int? liveEntryCount,
    bool? busy,
  }) => MyAdhkarState(
    loaded: loaded ?? this.loaded,
    loadFailed: loadFailed ?? this.loadFailed,
    groups: groups ?? this.groups,
    openedGroupId: identical(openedGroupId, _unset)
        ? this.openedGroupId
        : openedGroupId as String?,
    openedGroupItems: openedGroupItems ?? this.openedGroupItems,
    liveEntryCount: liveEntryCount ?? this.liveEntryCount,
    busy: busy ?? this.busy,
  );
}

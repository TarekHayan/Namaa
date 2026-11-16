/// The user's own collection of adhkar and supplications (My Adhkar,
/// FR-022…FR-029, data-model.md "My Adhkar" as reshaped 2026-11-16): named
/// groups, and entries made of exactly two fields — the text and an
/// optional free-text source (plain text, never opened). There is no
/// target, note, counter, Adhkar day or clamp, so it works the same when
/// the Prayer schedule is unavailable.
///
/// The drafts report their violations instead of throwing, so the commands
/// can reject a submission with typed failures; the stored classes throw
/// [ArgumentError] on any violation, because a persisted row must always
/// be valid (schema v11 mirrors the same checks). Every length is counted
/// in Unicode code points (`runes.length`), on the device and on the
/// server.
///
/// My Adhkar never touches XP, the set award, the streak or Home's x/N
/// values (FR-026).
library;

/// The entry-field rules a submission can violate.
enum MyDhikrDraftViolation { text, source, groupSet }

/// The draft of an entry add or edit submission: the two fields plus the
/// group set. `groupIds` must end up non-empty and reference live groups
/// (an omitted set is the empty-set violation); the liveness check itself
/// needs storage, so it is the command's job.
final class MyDhikrDraft {
  const MyDhikrDraft({
    required this.text,
    this.source,
    this.groupIds = const [],
  });

  /// The text rules (FR-023): required, 1–2000 code points after trimming.
  static const int minTextLength = 1;
  static const int maxTextLength = 2000;

  /// The source rules: optional, at most 500 code points after trimming;
  /// blank is stored as null. Plain text — never opened by the app.
  static const int maxSourceLength = 500;

  final String text;
  final String? source;
  final List<String> groupIds;

  /// The stored text: the entered text trimmed.
  String get trimmedText => text.trim();

  /// The stored source: the entered source trimmed, or null when blank.
  String? get trimmedSource {
    final value = source?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// The field rules this draft violates, empty when it is valid.
  List<MyDhikrDraftViolation> violations() {
    final violations = <MyDhikrDraftViolation>[];
    final textLength = trimmedText.runes.length;
    if (textLength < minTextLength || textLength > maxTextLength) {
      violations.add(MyDhikrDraftViolation.text);
    }
    if (source != null && source!.trim().runes.length > maxSourceLength) {
      violations.add(MyDhikrDraftViolation.source);
    }
    if (groupIds.isEmpty) {
      violations.add(MyDhikrDraftViolation.groupSet);
    }
    return violations;
  }
}

/// The group-name rules a submission can violate.
enum MyAdhkarGroupNameViolation { name }

/// The draft of a group create or rename submission.
final class MyAdhkarGroupDraft {
  const MyAdhkarGroupDraft({required this.name});

  /// The name rules (FR-028): required, 1–60 code points after trimming.
  /// Names need not be unique.
  static const int minNameLength = 1;
  static const int maxNameLength = 60;

  final String name;

  /// The stored name: the entered name trimmed.
  String get trimmedName => name.trim();

  /// The field rules this draft violates, empty when it is valid.
  List<MyAdhkarGroupNameViolation> violations() {
    final violations = <MyAdhkarGroupNameViolation>[];
    final nameLength = trimmedName.runes.length;
    if (nameLength < minNameLength || nameLength > maxNameLength) {
      violations.add(MyAdhkarGroupNameViolation.name);
    }
    return violations;
  }
}

/// An account holds at most 1000 live entries (FR-023).
const int kMyAdhkarEntryLimit = 1000;

/// An account holds at most 100 live groups (FR-028).
const int kMyAdhkarGroupLimit = 100;

/// Whether another live entry can be added given [liveEntryCount].
bool canAddMyDhikr(int liveEntryCount) => liveEntryCount < kMyAdhkarEntryLimit;

/// Whether another live group can be created given [liveGroupCount].
bool canCreateMyAdhkarGroup(int liveGroupCount) =>
    liveGroupCount < kMyAdhkarGroupLimit;

/// One stored My Adhkar entry row plus its group set (data-model.md,
/// `my_adhkar_items` + `my_adhkar_item_groups`).
final class MyDhikrItem {
  MyDhikrItem({
    required this.accountId,
    required this.itemId,
    required this.text,
    required this.source,
    required this.groupIds,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAcknowledgedUpdatedAt,
    required this.deletedAt,
  }) {
    if (accountId.trim().isEmpty || itemId.trim().isEmpty) {
      throw ArgumentError('My Adhkar entry needs an owner and an item id');
    }
    final textLength = text.trim().runes.length;
    if (textLength < MyDhikrDraft.minTextLength ||
        textLength > MyDhikrDraft.maxTextLength ||
        text != text.trim()) {
      throw ArgumentError.value(text, 'text');
    }
    if (source != null &&
        (source!.trim().runes.length > MyDhikrDraft.maxSourceLength ||
            source!.trim().isEmpty)) {
      throw ArgumentError.value(source, 'source');
    }
    final uniqueGroups = groupIds.toSet();
    if (uniqueGroups.length != groupIds.length) {
      throw ArgumentError.value(groupIds, 'groupIds', 'duplicates');
    }
    // A live entry belongs to at least one group (FR-023); a deleted entry
    // may have lost them all to a group-delete cascade.
    if (!isDeleted && groupIds.isEmpty) {
      throw ArgumentError.value(groupIds, 'groupIds', 'empty');
    }
    if (!createdAt.isUtc ||
        !updatedAt.isUtc ||
        updatedAt.isBefore(createdAt) ||
        (lastAcknowledgedUpdatedAt != null &&
            !lastAcknowledgedUpdatedAt!.isUtc)) {
      throw ArgumentError('Invalid My Adhkar entry timestamps');
    }
    // The tombstone must be UTC; it may sit before createdAt when the
    // device clock is skewed — the monotonic updated_at rule, not the
    // tombstone instant, carries the version order.
    if (deletedAt != null && !deletedAt!.isUtc) {
      throw ArgumentError.value(deletedAt, 'deletedAt');
    }
  }

  final String accountId;

  /// The random UUIDv4 created on the creating device; it never changes and
  /// is never reused (data-model.md, Identity).
  final String itemId;

  /// The stored text, trimmed and 1–2000 code points.
  final String text;

  /// The optional source, trimmed, at most 500 code points; null when
  /// blank. Plain text — never opened by the app.
  final String? source;

  /// The groups this entry belongs to (sorted for stable comparisons).
  /// Membership is part of the entry's version and is written in the same
  /// transaction as the entry (data-model.md). A live entry has at least
  /// one; a deleted entry may have none left after a group-delete cascade.
  final List<String> groupIds;

  /// UTC; when the entry was created.
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAcknowledgedUpdatedAt;

  /// The tombstone, set once on delete and never cleared: a deleted entry
  /// never comes back on sync (FR-025, FR-027).
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  static const Object _unset = Object();

  /// A changed copy of a live entry. There is no [deletedAt] parameter: no
  /// copy can clear or move the tombstone, so deletion stays final. Pass
  /// `source: null` explicitly to clear the source; pass `groupIds:`
  /// explicitly to change the group set.
  MyDhikrItem copyWith({
    String? text,
    Object? source = _unset,
    Object? groupIds = _unset,
    DateTime? updatedAt,
    DateTime? lastAcknowledgedUpdatedAt,
  }) => MyDhikrItem(
    accountId: accountId,
    itemId: itemId,
    text: text ?? this.text,
    source: identical(source, _unset) ? this.source : source as String?,
    groupIds: identical(groupIds, _unset)
        ? this.groupIds
        // Parenthesized: a cascade binds to the whole conditional
        // expression, not to its last branch.
        : (List<String>.from(groupIds as List<String>)..sort()),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastAcknowledgedUpdatedAt:
        lastAcknowledgedUpdatedAt ?? this.lastAcknowledgedUpdatedAt,
    deletedAt: deletedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is MyDhikrItem &&
      other.accountId == accountId &&
      other.itemId == itemId &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(accountId, itemId, updatedAt);
}

/// One stored My Adhkar group row (data-model.md, `my_adhkar_groups`).
final class MyAdhkarGroup {
  MyAdhkarGroup({
    required this.accountId,
    required this.groupId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAcknowledgedUpdatedAt,
    required this.deletedAt,
  }) {
    if (accountId.trim().isEmpty || groupId.trim().isEmpty) {
      throw ArgumentError('My Adhkar group needs an owner and a group id');
    }
    final nameLength = name.trim().runes.length;
    if (nameLength < MyAdhkarGroupDraft.minNameLength ||
        nameLength > MyAdhkarGroupDraft.maxNameLength ||
        name != name.trim()) {
      throw ArgumentError.value(name, 'name');
    }
    if (!createdAt.isUtc ||
        !updatedAt.isUtc ||
        updatedAt.isBefore(createdAt) ||
        (lastAcknowledgedUpdatedAt != null &&
            !lastAcknowledgedUpdatedAt!.isUtc)) {
      throw ArgumentError('Invalid My Adhkar group timestamps');
    }
    // The tombstone must be UTC; it may sit before createdAt when the
    // device clock is skewed — the monotonic updated_at rule, not the
    // tombstone instant, carries the version order.
    if (deletedAt != null && !deletedAt!.isUtc) {
      throw ArgumentError.value(deletedAt, 'deletedAt');
    }
  }

  final String accountId;

  /// The random UUIDv4 created on the creating device; it never changes and
  /// is never reused (data-model.md, Identity).
  final String groupId;

  /// The stored name, trimmed and 1–60 code points. Names need not be
  /// unique.
  final String name;

  /// UTC; the display order of the groups (oldest first).
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAcknowledgedUpdatedAt;

  /// The tombstone, set once on delete and never cleared (FR-029): a
  /// deleted group never comes back on sync.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// A renamed copy of a live group. There is no [deletedAt] parameter: no
  /// copy can clear or move the tombstone.
  MyAdhkarGroup copyWith({
    String? name,
    DateTime? updatedAt,
    DateTime? lastAcknowledgedUpdatedAt,
  }) => MyAdhkarGroup(
    accountId: accountId,
    groupId: groupId,
    name: name ?? this.name,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastAcknowledgedUpdatedAt:
        lastAcknowledgedUpdatedAt ?? this.lastAcknowledgedUpdatedAt,
    deletedAt: deletedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is MyAdhkarGroup &&
      other.accountId == accountId &&
      other.groupId == groupId &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(accountId, groupId, updatedAt);
}

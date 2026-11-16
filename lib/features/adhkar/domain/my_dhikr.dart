/// The user's own dhikr item and its count rules (My Adhkar, FR-022…FR-027,
/// data-model.md "My Adhkar", contracts/adhkar-qiyam-application.md).
///
/// The draft reports its violations instead of throwing, so the commands can
/// reject a submission with typed failures; the stored item throws
/// [ArgumentError] on any violation, because a persisted row must always be
/// valid (schema v11 mirrors the same checks). My Adhkar never touches XP,
/// the set award, the streak or Home's x/N values: it shares only the Adhkar
/// day and the counter rules.
library;

/// The field rules a submission can violate.
enum MyDhikrDraftViolation { text, target, note }

/// The draft of an add or an edit submission.
final class MyDhikrDraft {
  const MyDhikrDraft({required this.text, this.target = 1, this.note});

  /// The text rules (FR-023): required, 1–1000 characters after trimming.
  static const int minTextLength = 1;
  static const int maxTextLength = 1000;

  /// The target rules: a whole number from 1 to 1000, default 1.
  static const int minTarget = 1;
  static const int maxTarget = 1000;
  static const int defaultTarget = 1;

  /// The largest accepted note length.
  static const int maxNoteLength = 300;

  final String text;
  final int target;
  final String? note;

  /// The stored text: the entered text trimmed.
  String get trimmedText => text.trim();

  /// The stored note: the entered note trimmed, or null when blank.
  String? get trimmedNote {
    final value = note?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// The field rules this draft violates, empty when it is valid.
  List<MyDhikrDraftViolation> violations() {
    final violations = <MyDhikrDraftViolation>[];
    final textLength = trimmedText.length;
    if (textLength < minTextLength || textLength > maxTextLength) {
      violations.add(MyDhikrDraftViolation.text);
    }
    if (target < minTarget || target > maxTarget) {
      violations.add(MyDhikrDraftViolation.target);
    }
    if (note != null && note!.trim().length > maxNoteLength) {
      violations.add(MyDhikrDraftViolation.note);
    }
    return violations;
  }
}

/// The most live items one account holds (FR-023); deleted items do not
/// count against it.
const int kMyDhikrItemLimit = 100;

/// Whether another live item can be added given [liveItemCount].
bool canAddMyDhikr(int liveItemCount) => liveItemCount < kMyDhikrItemLimit;

/// Whether [count] has reached [target] (FR-004's completion rule); the
/// screen shows `min(count, target)`, so a target lowered on another device
/// never shows an overflow.
bool isMyDhikrCountComplete(int count, int target) => count >= target;

/// The count after an edit that changes the target (FR-025): an edit keeps
/// today's count, but lowering the target below it sets the count to the
/// new target.
int clampMyDhikrCount(int count, int target) => count < target ? count : target;

/// One stored My Adhkar item row (data-model.md, `my_adhkar_items`).
final class MyDhikrItem {
  MyDhikrItem({
    required this.accountId,
    required this.itemId,
    required this.text,
    required this.target,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAcknowledgedUpdatedAt,
    required this.deletedAt,
  }) {
    if (accountId.trim().isEmpty || itemId.trim().isEmpty) {
      throw ArgumentError('My Adhkar item needs an owner and an item id');
    }
    final textLength = text.trim().length;
    if (textLength < MyDhikrDraft.minTextLength ||
        textLength > MyDhikrDraft.maxTextLength ||
        text != text.trim()) {
      throw ArgumentError.value(text, 'text');
    }
    if (target < MyDhikrDraft.minTarget || target > MyDhikrDraft.maxTarget) {
      throw ArgumentError.value(target, 'target');
    }
    if (note != null &&
        (note!.trim().length > MyDhikrDraft.maxNoteLength ||
            note!.trim().isEmpty)) {
      throw ArgumentError.value(note, 'note');
    }
    if (!createdAt.isUtc ||
        !updatedAt.isUtc ||
        updatedAt.isBefore(createdAt) ||
        (lastAcknowledgedUpdatedAt != null &&
            !lastAcknowledgedUpdatedAt!.isUtc)) {
      throw ArgumentError('Invalid My Adhkar item timestamps');
    }
    if (deletedAt != null &&
        (!deletedAt!.isUtc || deletedAt!.isBefore(createdAt))) {
      throw ArgumentError.value(deletedAt, 'deletedAt');
    }
  }

  final String accountId;

  /// The random UUIDv4 created on the adding device; it never changes and
  /// is never reused (data-model.md, Identity).
  final String itemId;

  /// The stored text, trimmed and 1–1000 characters.
  final String text;
  final int target;

  /// The optional note, trimmed, at most 300 characters; null when blank.
  final String? note;

  /// UTC; the display order (oldest first).
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAcknowledgedUpdatedAt;

  /// The tombstone, set once on delete and never cleared: a deleted item
  /// never comes back on sync (FR-025, FR-027).
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  static const Object _unset = Object();

  /// A changed copy of a live item. There is no [deletedAt] parameter: no
  /// copy can clear or move the tombstone, so deletion stays final. Pass
  /// `note: null` explicitly to clear the note (an edit that removes it).
  MyDhikrItem copyWith({
    String? text,
    int? target,
    Object? note = _unset,
    DateTime? updatedAt,
    DateTime? lastAcknowledgedUpdatedAt,
  }) => MyDhikrItem(
    accountId: accountId,
    itemId: itemId,
    text: text ?? this.text,
    target: target ?? this.target,
    note: identical(note, _unset) ? this.note : note as String?,
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

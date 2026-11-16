import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

/// T083: the My Adhkar item domain rules (FR-023…FR-025, contracts/
/// adhkar-qiyam-application.md "My Adhkar ports and commands"): the draft's
/// text 1–1000 after trimming, target 1–1000 with default 1, note ≤ 300,
/// the 100-live-item limit, the target-lowering clamp, and that deletion
/// is final. All text below is placeholder text; no real religious text.
void main() {
  MyDhikrItem item({
    String itemId = '11111111-2222-4333-8444-555555555555',
    String text = 'test dhikr',
    int target = 33,
    String? note = 'test note',
    DateTime? deletedAt,
  }) => MyDhikrItem(
    accountId: 'owner',
    itemId: itemId,
    text: text,
    target: target,
    note: note,
    createdAt: DateTime.utc(2026, 11, 15, 8),
    updatedAt: DateTime.utc(2026, 11, 15, 9),
    lastAcknowledgedUpdatedAt: null,
    deletedAt: deletedAt,
  );

  group('MyDhikrDraft text rules', () {
    test('a blank or whitespace-only text is rejected', () {
      expect(
        const MyDhikrDraft(text: '').violations(),
        contains(MyDhikrDraftViolation.text),
      );
      expect(
        const MyDhikrDraft(text: '   ').violations(),
        contains(MyDhikrDraftViolation.text),
      );
    });

    test('text longer than 1000 characters after trimming is rejected', () {
      expect(
        MyDhikrDraft(text: 'ا' * 1001).violations(),
        contains(MyDhikrDraftViolation.text),
      );
      expect(
        MyDhikrDraft(text: ' ${'ا' * 1001} ').violations(),
        contains(MyDhikrDraftViolation.text),
      );
    });

    test('exactly 1000 characters after trimming is accepted', () {
      final draft = MyDhikrDraft(text: ' ${'ا' * 1000} ');
      expect(draft.violations(), isEmpty);
      expect(draft.trimmedText.length, 1000);
    });

    test('a one-character text after trimming is accepted', () {
      final draft = const MyDhikrDraft(text: '  ا  ');
      expect(draft.violations(), isEmpty);
      expect(draft.trimmedText, 'ا');
    });

    test('the trimmed text is what the draft reports', () {
      final draft = const MyDhikrDraft(text: '  test dhikr  ');
      expect(draft.violations(), isEmpty);
      expect(draft.trimmedText, 'test dhikr');
    });
  });

  group('MyDhikrDraft target rules', () {
    test('the target defaults to 1', () {
      final draft = const MyDhikrDraft(text: 'test dhikr');
      expect(draft.target, 1);
      expect(draft.violations(), isEmpty);
    });

    test('a target below 1 is rejected', () {
      expect(
        const MyDhikrDraft(text: 'test dhikr', target: 0).violations(),
        contains(MyDhikrDraftViolation.target),
      );
      expect(
        const MyDhikrDraft(text: 'test dhikr', target: -5).violations(),
        contains(MyDhikrDraftViolation.target),
      );
    });

    test('a target above 1000 is rejected and 1000 is accepted', () {
      expect(
        const MyDhikrDraft(text: 'test dhikr', target: 1001).violations(),
        contains(MyDhikrDraftViolation.target),
      );
      expect(
        const MyDhikrDraft(text: 'test dhikr', target: 1000).violations(),
        isEmpty,
      );
    });
  });

  group('MyDhikrDraft note rules', () {
    test('a note of at most 300 characters is accepted', () {
      final draft = MyDhikrDraft(text: 'test dhikr', note: 'ا' * 300);
      expect(draft.violations(), isEmpty);
    });

    test('a note longer than 300 characters is rejected', () {
      expect(
        MyDhikrDraft(text: 'test dhikr', note: 'ا' * 301).violations(),
        contains(MyDhikrDraftViolation.note),
      );
    });

    test('a missing or blank note is fine and normalizes to null', () {
      expect(const MyDhikrDraft(text: 'test dhikr').violations(), isEmpty);
      final blank = const MyDhikrDraft(text: 'test dhikr', note: '   ');
      expect(blank.violations(), isEmpty);
      expect(blank.trimmedNote, isNull);
    });
  });

  group('the live-item limit', () {
    test('an account holds at most 100 live items', () {
      expect(kMyDhikrItemLimit, 100);
      expect(canAddMyDhikr(0), isTrue);
      expect(canAddMyDhikr(99), isTrue);
      expect(canAddMyDhikr(100), isFalse);
    });
  });

  group('the count rules', () {
    test('a count completes exactly at its target and never passes it', () {
      expect(isMyDhikrCountComplete(32, 33), isFalse);
      expect(isMyDhikrCountComplete(33, 33), isTrue);
      expect(isMyDhikrCountComplete(34, 33), isTrue);
    });

    test('lowering the target below today\'s count clamps to the new '
        'target (FR-025)', () {
      expect(clampMyDhikrCount(33, 33), 33);
      expect(clampMyDhikrCount(33, 10), 10);
      expect(clampMyDhikrCount(5, 10), 5, reason: 'an edit keeps the count');
      expect(clampMyDhikrCount(0, 1), 0);
    });
  });

  group('a deleted item stays deleted', () {
    test('a tombstoned item reports deleted and keeps its fields', () {
      final deleted = item(deletedAt: DateTime.utc(2026, 11, 15, 10));
      expect(deleted.isDeleted, isTrue);
      expect(deleted.text, 'test dhikr');
      expect(deleted.target, 33);
    });

    test('no copy can clear the tombstone', () {
      final deleted = item(deletedAt: DateTime.utc(2026, 11, 15, 10));
      final edited = deleted.copyWith(text: 'edited dhikr');
      expect(edited.deletedAt, DateTime.utc(2026, 11, 15, 10));
      expect(edited.isDeleted, isTrue);
      expect(edited.text, 'edited dhikr');
    });

    test('a live item is not deleted', () {
      expect(item().isDeleted, isFalse);
    });

    test('an invalid stored item throws', () {
      expect(() => item(text: '   '), throwsArgumentError);
      expect(() => item(target: 0), throwsArgumentError);
      expect(() => item(note: 'ا' * 301), throwsArgumentError);
    });
  });
}

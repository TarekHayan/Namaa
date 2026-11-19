import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

/// T100: the reshaped My Adhkar domain rules (FR-023…FR-029, data-model.md
/// "My Adhkar", reshaped 2026-11-16): the entry is the text and an optional
/// source plus its groups; every length is code points; there is no target,
/// note, counter, day or clamp. All text below is placeholder text; no real
/// religious text.
void main() {
  MyDhikrItem item({
    String itemId = '11111111-2222-4333-8444-555555555555',
    String text = 'test dhikr',
    String? source = 'test source',
    List<String> groupIds = const ['gggggggg-1111-4111-8111-111111111111'],
    DateTime? deletedAt,
  }) => MyDhikrItem(
    accountId: 'owner',
    itemId: itemId,
    text: text,
    source: source,
    groupIds: groupIds,
    createdAt: DateTime.utc(2026, 11, 16, 8),
    updatedAt: DateTime.utc(2026, 11, 16, 9),
    lastAcknowledgedUpdatedAt: null,
    deletedAt: deletedAt,
  );

  MyAdhkarGroup makeGroup({String name = 'test group', DateTime? deletedAt}) =>
      MyAdhkarGroup(
        accountId: 'owner',
        groupId: 'gggggggg-1111-4111-8111-111111111111',
        name: name,
        createdAt: DateTime.utc(2026, 11, 16, 8),
        updatedAt: DateTime.utc(2026, 11, 16, 9),
        lastAcknowledgedUpdatedAt: null,
        deletedAt: deletedAt,
      );

  group('MyDhikrDraft text rules', () {
    test('a blank or whitespace-only text is rejected', () {
      expect(
        const MyDhikrDraft(text: '', groupIds: ['g1']).violations(),
        contains(MyDhikrDraftViolation.text),
      );
      expect(
        const MyDhikrDraft(text: '   ', groupIds: ['g1']).violations(),
        contains(MyDhikrDraftViolation.text),
      );
    });

    test('text over 2000 code points after trimming is rejected', () {
      expect(
        MyDhikrDraft(text: 'ا' * 2001, groupIds: ['g1']).violations(),
        contains(MyDhikrDraftViolation.text),
      );
      expect(
        MyDhikrDraft(text: ' ${'ا' * 2001} ', groupIds: ['g1']).violations(),
        contains(MyDhikrDraftViolation.text),
      );
    });

    test('exactly 2000 code points after trimming is accepted', () {
      final draft = MyDhikrDraft(text: ' ${'ا' * 2000} ', groupIds: ['g1']);
      expect(draft.violations(), isEmpty);
      expect(draft.trimmedText.runes.length, 2000);
    });

    test('a supplementary-plane character counts as one code point', () {
      // U+1D400 MATHEMATICAL BOLD CAPITAL A is one code point over two
      // UTF-16 units.
      const mathA = '𝐀';
      expect(mathA.runes.length, 1);
      expect(mathA.length, 2, reason: 'two UTF-16 code units');
      expect(
        MyDhikrDraft(text: mathA * 2000, groupIds: ['g1']).violations(),
        isEmpty,
        reason: '2000 code points of a supplementary character are valid',
      );
      expect(
        MyDhikrDraft(
          text: '${mathA * 2000}$mathA',
          groupIds: ['g1'],
        ).violations(),
        contains(MyDhikrDraftViolation.text),
        reason: '2001 code points are invalid',
      );
    });

    test('a one-code-point text after trimming is accepted', () {
      final draft = const MyDhikrDraft(text: '  ا  ', groupIds: ['g1']);
      expect(draft.violations(), isEmpty);
      expect(draft.trimmedText, 'ا');
    });

    test('the trimmed text is what the draft reports', () {
      final draft = const MyDhikrDraft(
        text: '  test dhikr  ',
        groupIds: ['g1'],
      );
      expect(draft.violations(), isEmpty);
      expect(draft.trimmedText, 'test dhikr');
    });
  });

  group('MyDhikrDraft source rules', () {
    test('a missing or blank source means no source', () {
      expect(
        const MyDhikrDraft(text: 'test dhikr', groupIds: ['g1']).violations(),
        isEmpty,
      );
      final blank = const MyDhikrDraft(
        text: 'test dhikr',
        source: '   ',
        groupIds: ['g1'],
      );
      expect(blank.violations(), isEmpty);
      expect(blank.trimmedSource, isNull);
    });

    test('a source over 500 code points is rejected and 500 is accepted', () {
      expect(
        MyDhikrDraft(
          text: 'test dhikr',
          source: 'ا' * 501,
          groupIds: ['g1'],
        ).violations(),
        contains(MyDhikrDraftViolation.source),
      );
      expect(
        MyDhikrDraft(
          text: 'test dhikr',
          source: 'ا' * 500,
          groupIds: ['g1'],
        ).violations(),
        isEmpty,
      );
    });

    test('a supplementary-plane source counts code points too', () {
      const mathA = '𝐀';
      expect(
        MyDhikrDraft(
          text: 'test dhikr',
          source: mathA * 500,
          groupIds: ['g1'],
        ).violations(),
        isEmpty,
      );
      expect(
        MyDhikrDraft(
          text: 'test dhikr',
          source: '${mathA * 500}$mathA',
          groupIds: ['g1'],
        ).violations(),
        contains(MyDhikrDraftViolation.source),
      );
    });
  });

  group('MyDhikrDraft group-set rules', () {
    test('an empty group set is rejected', () {
      expect(
        const MyDhikrDraft(text: 'test dhikr').violations(),
        contains(MyDhikrDraftViolation.groupSet),
      );
    });

    test('a non-empty group set passes the draft check', () {
      expect(
        const MyDhikrDraft(text: 'test dhikr', groupIds: ['g1']).violations(),
        isEmpty,
      );
    });
  });

  group('MyAdhkarGroupDraft name rules', () {
    test('a blank or whitespace-only name is rejected', () {
      expect(
        const MyAdhkarGroupDraft(name: '').violations(),
        contains(MyAdhkarGroupNameViolation.name),
      );
      expect(
        const MyAdhkarGroupDraft(name: '   ').violations(),
        contains(MyAdhkarGroupNameViolation.name),
      );
    });

    test('a name over 60 code points is rejected and 60 is accepted', () {
      expect(
        MyAdhkarGroupDraft(name: 'ا' * 61).violations(),
        contains(MyAdhkarGroupNameViolation.name),
      );
      expect(MyAdhkarGroupDraft(name: 'ا' * 60).violations(), isEmpty);
    });

    test('the trimmed name is what the draft reports', () {
      final draft = const MyAdhkarGroupDraft(name: '  test group  ');
      expect(draft.violations(), isEmpty);
      expect(draft.trimmedName, 'test group');
    });
  });

  group('the live limits', () {
    test('an account holds at most 1000 live entries and 100 live groups', () {
      expect(kMyAdhkarEntryLimit, 1000);
      expect(kMyAdhkarGroupLimit, 100);
      expect(canAddMyDhikr(0), isTrue);
      expect(canAddMyDhikr(999), isTrue);
      expect(canAddMyDhikr(1000), isFalse);
      expect(canCreateMyAdhkarGroup(0), isTrue);
      expect(canCreateMyAdhkarGroup(99), isTrue);
      expect(canCreateMyAdhkarGroup(100), isFalse);
    });
  });

  group('a deleted entry stays deleted', () {
    test('a tombstoned entry reports deleted and keeps its fields', () {
      final deleted = item(deletedAt: DateTime.utc(2026, 11, 16, 10));
      expect(deleted.isDeleted, isTrue);
      expect(deleted.text, 'test dhikr');
      expect(deleted.source, 'test source');
    });

    test('no copy can clear the tombstone', () {
      final deleted = item(deletedAt: DateTime.utc(2026, 11, 16, 10));
      final edited = deleted.copyWith(text: 'edited dhikr');
      expect(edited.deletedAt, DateTime.utc(2026, 11, 16, 10));
      expect(edited.isDeleted, isTrue);
      expect(edited.text, 'edited dhikr');
    });

    test('a live entry needs at least one group; a deleted one may lose '
        'them', () {
      expect(() => item(groupIds: const []), throwsArgumentError);
      final deleted = item(
        groupIds: const <String>[],
        deletedAt: DateTime.utc(2026, 11, 16, 10),
      );
      expect(deleted.isDeleted, isTrue);
      expect(deleted.groupIds, isEmpty);
    });

    test('a live item is not deleted', () {
      expect(item().isDeleted, isFalse);
    });

    test('an invalid stored entry throws', () {
      expect(() => item(text: '   '), throwsArgumentError);
      expect(() => item(source: 'ا' * 501), throwsArgumentError);
      expect(
        () => item(text: ' ${'ا' * 2001} '),
        throwsArgumentError,
        reason: 'stored text must be 1-2000 code points after trimming',
      );
    });
  });

  group('a deleted or renamed group stays final', () {
    test('a tombstoned group reports deleted and keeps its name', () {
      final deleted = makeGroup(deletedAt: DateTime.utc(2026, 11, 16, 10));
      expect(deleted.isDeleted, isTrue);
      expect(deleted.name, 'test group');
    });

    test('no copy can clear a group tombstone', () {
      final deleted = makeGroup(deletedAt: DateTime.utc(2026, 11, 16, 10));
      final renamed = deleted.copyWith(name: 'renamed group');
      expect(renamed.deletedAt, DateTime.utc(2026, 11, 16, 10));
      expect(renamed.isDeleted, isTrue);
      expect(renamed.name, 'renamed group');
    });

    test('an invalid stored group name throws', () {
      expect(() => makeGroup(name: '   '), throwsArgumentError);
      expect(() => makeGroup(name: 'ا' * 61), throwsArgumentError);
    });
  });
}

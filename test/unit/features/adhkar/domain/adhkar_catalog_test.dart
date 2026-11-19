import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

/// T004 + T080: catalog validation rules (data-model.md, revised
/// 2026-11-15). Rules: duplicate IDs, duplicate positions in a list,
/// target < 1, blank Arabic text or reference, an unknown list, an unknown
/// kind, the Quran fields exactly when kind = quran, a blank or missing
/// attribution, a blank nullable field when present, and an item not
/// marked approved which must be excluded. There is no English field
/// (owner decision D3); all content here is placeholder text.
void main() {
  Map<String, dynamic> item({
    String itemId = 'm1',
    String list = 'morning',
    int position = 1,
    int target = 1,
    String kind = 'dhikr',
    String textAr = 'test item',
    Object? virtueAr = 'test virtue',
    String referenceAr = 'test reference',
    Object? surah,
    Object? ayahFrom,
    Object? ayahTo,
    Object? prefaceAr,
    bool approved = true,
  }) => {
    'item_id': itemId,
    'list': list,
    'position': position,
    'target': target,
    'kind': kind,
    'text_ar': textAr,
    'virtue_ar': virtueAr,
    'reference_ar': referenceAr,
    'surah': ?surah,
    'ayah_from': ?ayahFrom,
    'ayah_to': ?ayahTo,
    'preface_ar': ?prefaceAr,
    if (approved) 'approved': true,
  };

  Map<String, dynamic> quranItem({
    String itemId = 'mq1',
    String list = 'morning',
    int position = 1,
    int target = 1,
    String textAr = 'placeholder verse text',
    Object? prefaceAr = 'placeholder preface',
    String surah = 'test surah',
    int ayahFrom = 255,
    int ayahTo = 255,
    bool approved = true,
  }) => {
    'item_id': itemId,
    'list': list,
    'position': position,
    'target': target,
    'kind': 'quran',
    'text_ar': textAr,
    'virtue_ar': null,
    'reference_ar': 'test reference',
    'surah': surah,
    'ayah_from': ayahFrom,
    'ayah_to': ayahTo,
    'preface_ar': prefaceAr,
    if (approved) 'approved': true,
  };

  Map<String, dynamic> catalog({
    int version = 1,
    String attribution = 'test attribution line',
    List<Map<String, dynamic>> items = const [],
    List<Map<String, dynamic>> supplications = const [],
  }) => {
    'catalog_version': version,
    'attribution': attribution,
    'items': items,
    'qiyam_supplications': supplications,
  };

  group('AdhkarCatalog.fromJson accepts', () {
    test('a well-formed single dhikr item', () {
      final parsed = AdhkarCatalog.fromJson(catalog(items: [item()]));
      expect(parsed.version, 1);
      expect(parsed.attribution, 'test attribution line');
      expect(parsed.items, hasLength(1));
      expect(parsed.items.single.itemId, 'm1');
      expect(parsed.items.single.list, AdhkarList.morning);
      expect(parsed.items.single.position, 1);
      expect(parsed.items.single.target, 1);
      expect(parsed.items.single.kind, DhikrKind.dhikr);
      expect(parsed.items.single.virtueAr, 'test virtue');
      expect(parsed.items.single.surah, isNull);
      expect(parsed.items.single.ayahFrom, isNull);
      expect(parsed.items.single.ayahTo, isNull);
      expect(parsed.items.single.prefaceAr, isNull);
    });

    test('a well-formed Quran item with surah, range and preface', () {
      final parsed = AdhkarCatalog.fromJson(catalog(items: [quranItem()]));
      final quran = parsed.items.single;
      expect(quran.kind, DhikrKind.quran);
      expect(quran.surah, 'test surah');
      expect(quran.ayahFrom, 255);
      expect(quran.ayahTo, 255);
      expect(quran.prefaceAr, 'placeholder preface');
      expect(quran.virtueAr, isNull);
    });

    test('a Quran item without a preface', () {
      final parsed = AdhkarCatalog.fromJson(
        catalog(items: [quranItem(prefaceAr: null)]),
      );
      expect(parsed.items.single.prefaceAr, isNull);
    });

    test('a dhikr item without a virtue (nullable)', () {
      final parsed = AdhkarCatalog.fromJson(
        catalog(items: [item(virtueAr: null)]),
      );
      expect(parsed.items.single.virtueAr, isNull);
    });

    test('items ordered per list by position', () {
      final json = catalog(
        items: [
          item(itemId: 'm2', position: 2),
          item(),
        ],
      );
      final parsed = AdhkarCatalog.fromJson(json);
      expect(parsed.items.map((i) => i.itemId), ['m1', 'm2']);
      expect(parsed.itemsOf(AdhkarList.morning), hasLength(2));
      expect(parsed.itemsOf(AdhkarList.evening), isEmpty);
    });

    test('two items sharing a position in different lists', () {
      final json = catalog(
        items: [
          item(),
          item(itemId: 'e1', list: 'evening'),
        ],
      );
      final parsed = AdhkarCatalog.fromJson(json);
      expect(parsed.items, hasLength(2));
    });

    test('a supplication list (Arabic source only)', () {
      final json = catalog(
        supplications: [
          {
            'id': 's1',
            'approved': true,
            'text_ar': 'test supplication',
            'source_ar': 'test source',
          },
        ],
      );
      final parsed = AdhkarCatalog.fromJson(json);
      expect(parsed.qiyamSupplications.single.id, 's1');
      expect(parsed.qiyamSupplications.single.textAr, 'test supplication');
      expect(parsed.qiyamSupplications.single.sourceAr, 'test source');
    });

    test('an unapproved supplication is excluded, approved ones stay', () {
      final json = catalog(
        supplications: [
          {
            'id': 's1',
            'approved': true,
            'text_ar': 'test supplication',
            'source_ar': 'test source',
          },
          {
            'id': 's2',
            'text_ar': 'test supplication unapproved',
            'source_ar': 'test source',
          },
          {
            'id': 's3',
            'approved': false,
            'text_ar': 'test supplication rejected',
            'source_ar': 'test source',
          },
        ],
      );
      final parsed = AdhkarCatalog.fromJson(json);
      expect(parsed.qiyamSupplications.map((s) => s.id), ['s1']);
    });
  });

  group('AdhkarCatalog.fromJson rejects', () {
    test('duplicate item IDs', () {
      final json = catalog(items: [item(), item()]);
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
    });

    test('duplicate positions within one list', () {
      final json = catalog(
        items: [
          item(position: 2),
          item(itemId: 'm2', position: 2),
        ],
      );
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
    });

    test('a target below 1', () {
      final json = catalog(items: [item(target: 0)]);
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
      final negative = catalog(items: [item(target: -3)]);
      expect(() => AdhkarCatalog.fromJson(negative), throwsArgumentError);
    });

    test('blank Arabic text', () {
      final json = catalog(items: [item(textAr: '   ')]);
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
    });

    test('a blank Arabic reference', () {
      final json = catalog(items: [item(referenceAr: '')]);
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
    });

    test('a blank virtue when present (null is allowed)', () {
      final json = catalog(items: [item(virtueAr: ' ')]);
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
    });

    test('an unknown list value', () {
      final json = catalog(items: [item(list: 'night')]);
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
    });

    test('a missing kind or an unknown kind', () {
      final missing = catalog(items: [item()..remove('kind')]);
      expect(() => AdhkarCatalog.fromJson(missing), throwsArgumentError);
      final unknown = catalog(items: [item(kind: 'hadith')]);
      expect(() => AdhkarCatalog.fromJson(unknown), throwsArgumentError);
    });

    test('a Quran item missing its surah or verse numbers', () {
      final noSurah = catalog(items: [quranItem()..remove('surah')]);
      expect(() => AdhkarCatalog.fromJson(noSurah), throwsArgumentError);
      final noFrom = catalog(items: [quranItem()..remove('ayah_from')]);
      expect(() => AdhkarCatalog.fromJson(noFrom), throwsArgumentError);
      final noTo = catalog(items: [quranItem()..remove('ayah_to')]);
      expect(() => AdhkarCatalog.fromJson(noTo), throwsArgumentError);
    });

    test('a Quran item whose verse range is inverted', () {
      final json = catalog(items: [quranItem(ayahTo: 254)]);
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
    });

    test('a dhikr item carrying Quran fields', () {
      final withSurah = catalog(items: [item(surah: 'test surah')]);
      expect(() => AdhkarCatalog.fromJson(withSurah), throwsArgumentError);
      final withPreface = catalog(items: [item(prefaceAr: 'placeholder')]);
      expect(() => AdhkarCatalog.fromJson(withPreface), throwsArgumentError);
    });

    test('a blank preface on a Quran item (null is allowed)', () {
      final json = catalog(items: [quranItem(prefaceAr: '  ')]);
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
    });

    test('a missing or blank top-level attribution', () {
      final blank = catalog(attribution: '  ', items: [item()]);
      expect(() => AdhkarCatalog.fromJson(blank), throwsArgumentError);
      final missing = catalog(items: [item()])..remove('attribution');
      expect(() => AdhkarCatalog.fromJson(missing), throwsArgumentError);
    });

    test('a missing or non-positive catalog version', () {
      expect(
        () => AdhkarCatalog.fromJson(catalog(version: 0)),
        throwsArgumentError,
      );
      final json = catalog(items: [item()])..remove('catalog_version');
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
    });
  });

  group('AdhkarCatalog.fromJson excludes', () {
    test('an item that is not marked approved', () {
      final json = catalog(
        items: [
          item(),
          item(itemId: 'm2', approved: false),
          item(itemId: 'e1', list: 'evening', approved: false),
        ],
      );
      final parsed = AdhkarCatalog.fromJson(json);
      expect(parsed.items.map((i) => i.itemId), ['m1']);
    });

    test('an unapproved Quran item before validation, even without its '
        'Quran fields', () {
      final json = catalog(
        items: [item(), quranItem(approved: false)..remove('surah')],
      );
      final parsed = AdhkarCatalog.fromJson(json);
      expect(parsed.items, hasLength(1));
    });

    test('an unapproved item before uniqueness checks, so a duplicate '
        'between one approved and one unapproved item stays valid', () {
      final json = catalog(items: [item(), item(approved: false)]);
      final parsed = AdhkarCatalog.fromJson(json);
      expect(parsed.items, hasLength(1));
    });
  });
}

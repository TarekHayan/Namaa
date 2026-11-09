import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

/// T004: catalog validation rules. These fail before T005 implements the
/// catalog model. Rules (tasks.md T004): duplicate IDs, duplicate positions
/// in a list, target < 1, blank text or reference, an unknown list, and an
/// item not marked approved which must be excluded.
void main() {
  Map<String, dynamic> item({
    String itemId = 'm1',
    String list = 'morning',
    int position = 1,
    int target = 1,
    String textAr = 'نص عربي',
    String translationEn = 'Arabic text',
    String virtueAr = 'فضل',
    String virtueEn = 'Virtue',
    String referenceAr = 'مرجع',
    String referenceEn = 'Reference',
    bool approved = true,
  }) => {
    'item_id': itemId,
    'list': list,
    'position': position,
    'target': target,
    'text_ar': textAr,
    'translation_en': translationEn,
    'virtue_ar': virtueAr,
    'virtue_en': virtueEn,
    'reference_ar': referenceAr,
    'reference_en': referenceEn,
    if (approved) 'approved': true,
  };

  Map<String, dynamic> catalog({
    int version = 1,
    List<Map<String, dynamic>> items = const [],
    List<Map<String, dynamic>> supplications = const [],
  }) => {
    'catalog_version': version,
    'items': items,
    'qiyam_supplications': supplications,
  };

  group('AdhkarCatalog.fromJson accepts', () {
    test('a well-formed single-item catalog', () {
      final json = catalog(items: [item()]);
      final parsed = AdhkarCatalog.fromJson(json);
      expect(parsed.version, 1);
      expect(parsed.items, hasLength(1));
      expect(parsed.items.single.itemId, 'm1');
      expect(parsed.items.single.list, AdhkarList.morning);
      expect(parsed.items.single.position, 1);
      expect(parsed.items.single.target, 1);
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
      expect(parsed.itemsFor(AdhkarList.morning), hasLength(2));
      expect(parsed.itemsFor(AdhkarList.evening), isEmpty);
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

    test('a supplication list', () {
      final json = catalog(
        supplications: [
          {
            'id': 's1',
            'text_ar': 'دعاء',
            'source_ar': 'مسلم 486',
            'source_en': 'Muslim 486',
          },
        ],
      );
      final parsed = AdhkarCatalog.fromJson(json);
      expect(parsed.qiyamSupplications.single.id, 's1');
      expect(parsed.qiyamSupplications.single.textAr, 'دعاء');
    });
  });

  group('AdhkarCatalog.fromJson rejects', () {
    test('duplicate item IDs', () {
      final json = catalog(
        items: [
          item(),
          item(),
        ],
      );
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

    test('blank references', () {
      final json = catalog(
        items: [item(referenceAr: '', referenceEn: '')],
      );
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
    });

    test('blank translations or virtues are rejected too', () {
      final json = catalog(
        items: [item(translationEn: '', virtueEn: ' ')],
      );
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
    });

    test('an unknown list value', () {
      final json = catalog(items: [item(list: 'night')]);
      expect(() => AdhkarCatalog.fromJson(json), throwsArgumentError);
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

    test('an unapproved item before uniqueness checks, so a duplicate '
        'between one approved and one unapproved item stays valid', () {
      final json = catalog(
        items: [
          item(),
          item(approved: false),
        ],
      );
      final parsed = AdhkarCatalog.fromJson(json);
      expect(parsed.items, hasLength(1));
    });
  });
}

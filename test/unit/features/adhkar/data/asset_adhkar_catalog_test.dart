import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/data/asset_adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

/// T007: the catalog loader. Until the owner approves the real content
/// (T006/T073) the loader runs against the review fixture under
/// test/fixtures/adhkar_qiyam/; the production wiring points it at
/// assets/religious/adhkar_catalog_v1.json. The loader never throws on a
/// malformed document: it reports the recoverable content-unavailable state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = File('test/fixtures/adhkar_qiyam/catalog_fixture.json');

  Future<String> loadFixture(String path) async => fixture.readAsString();

  test('the catalog document loads with approved items only', () async {
    final port = AssetAdhkarCatalog(load: loadFixture, assetPath: 'fixture');
    final snapshot = (await port.snapshot('owner')).valueOrNull!;
    expect(snapshot.version, 1);
    // m4 and supplication s2 are not approved and must be absent.
    expect(snapshot.items.map((i) => i.itemId), [
      'm1',
      'm2',
      'm3',
      'e1',
      'e2',
      'e3',
    ]);
    final targets = {for (final i in snapshot.items) i.itemId: i.target};
    expect(targets, {'m1': 1, 'm2': 3, 'm3': 10, 'e1': 1, 'e2': 3, 'e3': 10});
  });

  test(
    'a malformed document reports content unavailable instead of throwing',
    () async {
      Future<String> loadBroken(String path) async => '{ not json';
      final port = AssetAdhkarCatalog(load: loadBroken, assetPath: 'fixture');
      final result = await port.snapshot('owner');
      expect(result.failureOrNull, isNotNull);
      expect(result.failureOrNull!.messageKey, 'adhkar.content.unavailable');
    },
  );

  test(
    'a structurally invalid document reports content unavailable too',
    () async {
      Future<String> loadInvalid(String path) async => jsonEncode({
        'catalog_version': 1,
        'attribution': 'test attribution line',
        'items': [
          {
            'item_id': 'm1',
            'list': 'morning',
            'position': 1,
            'target': 0,
            'kind': 'dhikr',
            'text_ar': 'x',
            'virtue_ar': 'x',
            'reference_ar': 'x',
            'approved': true,
          },
        ],
        'qiyam_supplications': <Object?>[],
      });
      final port = AssetAdhkarCatalog(load: loadInvalid, assetPath: 'fixture');
      final result = await port.snapshot('owner');
      expect(result.failureOrNull!.messageKey, 'adhkar.content.unavailable');
    },
  );

  test('the loaded snapshot is cached per version', () async {
    var loads = 0;
    Future<String> loadCounting(String path) async {
      loads++;
      return fixture.readAsString();
    }

    final port = AssetAdhkarCatalog(load: loadCounting, assetPath: 'fixture');
    final first = await port.snapshot('owner');
    final second = await port.snapshot('owner');
    expect(loads, 1, reason: 'the catalog is read once per version');
    expect(identical(first.valueOrNull, second.valueOrNull), isTrue);
  });

  test('the fixture itself satisfies the catalog validation rules', () {
    final catalog = AdhkarCatalog.fromJson(
      jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>,
    );
    expect(catalog.version, 1);
    expect(catalog.qiyamSupplications.single.id, 's1');
  });

  group('the shipped asset (T006)', () {
    const assetPath = 'assets/religious/adhkar_catalog_v1.json';

    // Structure only: the real religious text is never copied into a test.
    test(
      'is registered in pubspec and loads with every item approved',
      () async {
        final port = AssetAdhkarCatalog(
          load: rootBundle.loadString,
          assetPath: assetPath,
        );
        final catalog = (await port.snapshot('owner')).valueOrNull!;
        expect(catalog.version, 1);
        expect(catalog.attribution.trim(), isNotEmpty);

        // The loader drops unapproved items, so the raw count proves that all
        // of the shipped items carry the owner's approval (content-sources.md).
        final raw =
            jsonDecode(await rootBundle.loadString(assetPath))
                as Map<String, dynamic>;
        final rawItems = (raw['items'] as List).cast<Map<String, dynamic>>();
        expect(rawItems.length, catalog.items.length);
        expect(rawItems.every((i) => i['approved'] == true), isTrue);

        expect(catalog.itemsOf(AdhkarList.morning), hasLength(25));
        expect(catalog.itemsOf(AdhkarList.evening), hasLength(23));
      },
    );

    test('lists are contiguous, with the Quran items first', () async {
      final port = AssetAdhkarCatalog(
        load: rootBundle.loadString,
        assetPath: assetPath,
      );
      final catalog = (await port.snapshot('owner')).valueOrNull!;
      for (final list in AdhkarList.values) {
        final items = catalog.itemsOf(list);
        expect(items.map((i) => i.position), [
          for (var n = 1; n <= items.length; n++) n,
        ]);
        final kinds = items.map((i) => i.kind).toList();
        final firstDhikr = kinds.indexOf(DhikrKind.dhikr);
        expect(
          kinds.skip(firstDhikr).every((k) => k == DhikrKind.dhikr),
          isTrue,
          reason: '${list.name}: Quran items come first (owner decision P1)',
        );
      }
      expect(
        catalog
            .itemsOf(AdhkarList.morning)
            .where((i) => i.kind == DhikrKind.quran),
        hasLength(4),
      );
      expect(
        catalog
            .itemsOf(AdhkarList.evening)
            .where((i) => i.kind == DhikrKind.quran),
        hasLength(5),
      );
    });

    test('Quran items carry verses only, with their surah and range', () async {
      final port = AssetAdhkarCatalog(
        load: rootBundle.loadString,
        assetPath: assetPath,
      );
      final catalog = (await port.snapshot('owner')).valueOrNull!;
      final verseEnd = RegExp(r'[٠-٩]+$');
      for (final item in catalog.items.where(
        (i) => i.kind == DhikrKind.quran,
      )) {
        expect(item.surah, isNotNull, reason: item.itemId);
        expect(item.ayahFrom, lessThanOrEqualTo(item.ayahTo!));
        expect(
          item.textAr.contains(':'),
          isFalse,
          reason: '${item.itemId}: the label is not part of the verse text',
        );
        expect(
          verseEnd.hasMatch(item.textAr),
          isTrue,
          reason: '${item.itemId}: ends with its verse-end marker',
        );
      }
      // The isti'adha preface: Ayat al-Kursi (both lists) and the end of
      // al-Baqara (owner decision P2); no other item has one.
      expect(
        catalog.items.where((i) => i.prefaceAr != null).map((i) => i.itemId),
        unorderedEquals(['m25', 'e23', 'e10']),
      );
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/data/asset_adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

/// T007: the catalog loader. Until the owner approves the real content
/// (T006/T073) the loader runs against the review fixture under
/// test/fixtures/adhkar_qiyam/; the production wiring points it at
/// assets/religious/adhkar_catalog_v1.json. The loader never throws on a
/// malformed document: it reports the recoverable content-unavailable state.
void main() {
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
        'items': [
          {
            'item_id': 'm1',
            'list': 'morning',
            'position': 1,
            'target': 0,
            'text_ar': 'x',
            'translation_en': 'x',
            'virtue_ar': 'x',
            'virtue_en': 'x',
            'reference_ar': 'x',
            'reference_en': 'x',
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
}

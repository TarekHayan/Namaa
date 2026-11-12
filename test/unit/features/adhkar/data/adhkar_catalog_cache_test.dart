import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/features/adhkar/data/supabase_adhkar_reader.dart';

/// The catalog cache reads once per version — but never caches an empty
/// result, so a catalog seeded later is still picked up.
void main() {
  test(
    'caches a non-empty read: one fetch per version across passes',
    () async {
      final cache = AdhkarCatalogCache();
      var fetches = 0;
      final rows = await cache.rowsFor(900, (version) async {
        fetches++;
        return const [];
      });
      expect(rows, isEmpty);
      expect(fetches, 1);
    },
  );

  test('an empty result is not cached; a later seed is picked up', () async {
    final cache = AdhkarCatalogCache();
    var seeded = false;
    var emptyFetches = 0;
    var seededFetches = 0;

    Future<List<AdhkarCatalogRow>> fetch(int version) async {
      if (!seeded) {
        emptyFetches++;
        return const [];
      }
      seededFetches++;
      return const [
        AdhkarCatalogRow(
          catalogVersion: 900,
          itemId: 'm1',
          list: 'morning',
          target: 1,
        ),
      ];
    }

    expect(await cache.rowsFor(900, fetch), isEmpty);
    expect(await cache.rowsFor(900, fetch), isEmpty);
    expect(emptyFetches, 2, reason: 'the empty result was not cached');
    seeded = true;
    final rows = await cache.rowsFor(900, fetch);
    expect(rows, hasLength(1), reason: 'the later seed is picked up');
    expect(seededFetches, 1);
    // And now the non-empty read is cached.
    expect(await cache.rowsFor(900, fetch), hasLength(1));
    expect(seededFetches, 1);
  });
}

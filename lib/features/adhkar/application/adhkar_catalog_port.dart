import 'package:namma_project/core/domain/results/app_result.dart';

/// One approved catalog item the commands and the screen work with.
final class AdhkarCatalogItemSnapshot {
  const AdhkarCatalogItemSnapshot({
    required this.itemId,
    required this.list,
    required this.position,
    required this.target,
    required this.textAr,
    required this.translationEn,
    required this.virtueAr,
    required this.virtueEn,
    required this.referenceAr,
    required this.referenceEn,
  });

  final String itemId;
  final String list;
  final int position;
  final int target;
  final String textAr;
  final String translationEn;
  final String virtueAr;
  final String virtueEn;
  final String referenceAr;
  final String referenceEn;
}

/// A validated catalog snapshot (the approved items only).
final class AdhkarCatalogSnapshot {
  const AdhkarCatalogSnapshot({required this.version, required this.items});

  final int version;
  final List<AdhkarCatalogItemSnapshot> items;

  AdhkarCatalogItemSnapshot? item(String itemId) {
    for (final item in items) {
      if (item.itemId == itemId) return item;
    }
    return null;
  }

  List<AdhkarCatalogItemSnapshot> itemsOf(String list) =>
      items.where((item) => item.list == list).toList();
}

/// The catalog boundary (contracts/adhkar-qiyam-application.md): the
/// validated catalog for the current version, loaded from the reviewed
/// asset once it ships (T006/T008).
abstract interface class AdhkarCatalogPort {
  Future<AppResult<AdhkarCatalogSnapshot>> snapshot(String ownerId);
}

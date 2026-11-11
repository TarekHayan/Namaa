/// The reviewed Adhkar catalog and Qiyam supplications (reference content,
/// not user data).
///
/// Content comes from `assets/religious/adhkar_catalog_v1.json`, whose texts
/// are approved by the product owner through
/// specs/009-adhkar-qiyam/content-sources.md. This model validates the
/// document on load (data-model.md): unique IDs, unique positions per list,
/// targets >= 1, non-blank texts and references, and known lists. Items the
/// owner has not marked approved are excluded before validation.
///
/// Validation failures throw [ArgumentError]; the loading adapter turns them
/// into a recoverable "content unavailable" state.
library;

/// The two fixed Adhkar lists.
enum AdhkarList { morning, evening }

/// One adhkar entry: stable identity, ordered position, target count and
/// reviewed Arabic/English content.
final class DhikrItem {
  const DhikrItem({
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
  final AdhkarList list;
  final int position;
  final int target;
  final String textAr;
  final String translationEn;
  final String virtueAr;
  final String virtueEn;
  final String referenceAr;
  final String referenceEn;

  @override
  bool operator ==(Object other) =>
      other is DhikrItem && other.itemId == itemId;

  @override
  int get hashCode => itemId.hashCode;
}

/// One authentic Witr/Sujood supplication shown on the Qiyam screen.
final class QiyamSupplication {
  const QiyamSupplication({
    required this.id,
    required this.textAr,
    required this.sourceAr,
    required this.sourceEn,
  });

  final String id;
  final String textAr;
  final String sourceAr;
  final String sourceEn;

  @override
  bool operator ==(Object other) =>
      other is QiyamSupplication && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A validated catalog snapshot. Cached per [version] by the loading adapter.
final class AdhkarCatalog {
  const AdhkarCatalog._({
    required this.version,
    required this.items,
    required this.qiyamSupplications,
  });

  /// Parses and validates a decoded catalog document.
  ///
  /// Throws [ArgumentError] when a structural rule is violated. Items without
  /// `"approved": true` are excluded before the uniqueness checks.
  factory AdhkarCatalog.fromJson(Map<String, dynamic> json) {
    final versionJson = json['catalog_version'];
    if (versionJson is! int || versionJson < 1) {
      throw ArgumentError.value(versionJson, 'catalog_version');
    }
    final itemsJson = json['items'];
    if (itemsJson is! List<Object?>) {
      throw ArgumentError.value(itemsJson, 'items');
    }
    final supplicationsJson = json['qiyam_supplications'];
    if (supplicationsJson is! List<Object?>) {
      throw ArgumentError.value(supplicationsJson, 'qiyam_supplications');
    }

    final items = <String, DhikrItem>{};
    final seenPositions = <AdhkarList, Set<int>>{};
    for (final entry in itemsJson) {
      if (entry is! Map<String, dynamic>) {
        throw ArgumentError.value(entry, 'items[]');
      }
      // Only owner-approved items ship (FR-002); the rest are excluded
      // before validation so they never affect uniqueness checks.
      if (entry['approved'] != true) {
        continue;
      }
      final item = _parseItem(entry);
      if (items.containsKey(item.itemId)) {
        throw ArgumentError.value(item.itemId, 'items[].item_id', 'duplicate');
      }
      final positions = seenPositions.putIfAbsent(item.list, () => <int>{});
      if (!positions.add(item.position)) {
        throw ArgumentError.value(
          item.position,
          'items[].position',
          'duplicate in ${item.list.name}',
        );
      }
      items[item.itemId] = item;
    }

    final supplications = <String, QiyamSupplication>{};
    for (final entry in supplicationsJson) {
      if (entry is! Map<String, dynamic>) {
        throw ArgumentError.value(entry, 'qiyam_supplications[]');
      }
      // The same owner-approval rule as the adhkar items (FR-002): only
      // approved supplications ship.
      if (entry['approved'] != true) {
        continue;
      }
      final supplication = _parseSupplication(entry);
      if (supplications.containsKey(supplication.id)) {
        throw ArgumentError.value(
          supplication.id,
          'qiyam_supplications[].id',
          'duplicate',
        );
      }
      supplications[supplication.id] = supplication;
    }

    final orderedItems = items.values.toList()
      ..sort((a, b) {
        final byList = a.list.index.compareTo(b.list.index);
        if (byList != 0) return byList;
        return a.position.compareTo(b.position);
      });

    return AdhkarCatalog._(
      version: versionJson,
      items: List.unmodifiable(orderedItems),
      qiyamSupplications: List.unmodifiable(supplications.values),
    );
  }

  static DhikrItem _parseItem(Map<String, dynamic> entry) {
    final itemId = _nonBlank(entry['item_id'], 'items[].item_id');
    final listJson = _nonBlank(entry['list'], 'items[].list');
    final AdhkarList list;
    switch (listJson) {
      case 'morning':
        list = AdhkarList.morning;
      case 'evening':
        list = AdhkarList.evening;
      default:
        throw ArgumentError.value(listJson, 'items[].list', 'unknown list');
    }
    final position = entry['position'];
    if (position is! int || position < 1) {
      throw ArgumentError.value(position, 'items[].position');
    }
    final target = entry['target'];
    if (target is! int || target < 1) {
      throw ArgumentError.value(target, 'items[].target');
    }
    return DhikrItem(
      itemId: itemId,
      list: list,
      position: position,
      target: target,
      textAr: _nonBlank(entry['text_ar'], 'items[].text_ar'),
      translationEn: _nonBlank(
        entry['translation_en'],
        'items[].translation_en',
      ),
      virtueAr: _nonBlank(entry['virtue_ar'], 'items[].virtue_ar'),
      virtueEn: _nonBlank(entry['virtue_en'], 'items[].virtue_en'),
      referenceAr: _nonBlank(entry['reference_ar'], 'items[].reference_ar'),
      referenceEn: _nonBlank(entry['reference_en'], 'items[].reference_en'),
    );
  }

  static QiyamSupplication _parseSupplication(Map<String, dynamic> entry) {
    return QiyamSupplication(
      id: _nonBlank(entry['id'], 'qiyam_supplications[].id'),
      textAr: _nonBlank(entry['text_ar'], 'qiyam_supplications[].text_ar'),
      sourceAr: _nonBlank(
        entry['source_ar'],
        'qiyam_supplications[].source_ar',
      ),
      sourceEn: _nonBlank(
        entry['source_en'],
        'qiyam_supplications[].source_en',
      ),
    );
  }

  static String _nonBlank(Object? value, String name) {
    if (value is! String || value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'blank');
    }
    return value;
  }

  final int version;
  final List<DhikrItem> items;
  final List<QiyamSupplication> qiyamSupplications;

  /// The target for [itemId], or null when the item is not in this catalog.
  int? targetOf(String itemId) {
    for (final item in items) {
      if (item.itemId == itemId) return item.target;
    }
    return null;
  }

  /// The approved items of one list, in catalog order.
  List<DhikrItem> itemsOf(AdhkarList list) =>
      items.where((item) => item.list == list).toList();

  /// The item with [itemId], or null when absent.
  DhikrItem? item(String itemId) {
    for (final item in items) {
      if (item.itemId == itemId) return item;
    }
    return null;
  }
}

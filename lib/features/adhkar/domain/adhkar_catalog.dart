/// The reviewed Adhkar catalog and Qiyam supplications (reference content,
/// not user data).
///
/// Content comes from `assets/religious/adhkar_catalog_v1.json`, whose texts
/// are approved by the product owner through
/// specs/009-adhkar-qiyam/content-sources.md. This model validates the
/// document on load (data-model.md, revised 2026-11-15): unique IDs, unique
/// positions per list, targets >= 1, non-blank Arabic texts and references,
/// known lists, a `kind` per item, the Quran fields exactly when
/// `kind = quran`, and a top-level attribution. Items the owner has not
/// marked approved are excluded before validation. There is no English
/// content field (owner decision D3).
///
/// Validation failures throw [ArgumentError]; the loading adapter turns them
/// into a recoverable "content unavailable" state.
library;

/// The two fixed Adhkar lists.
enum AdhkarList { morning, evening }

/// Whether an item is a plain dhikr or a Quran passage.
enum DhikrKind { dhikr, quran }

/// One adhkar entry: stable identity, ordered position, target count and
/// reviewed Arabic content. A [DhikrKind.quran] item additionally carries
/// its surah, verse range and optional preface; a [DhikrKind.dhikr] item
/// never does.
final class DhikrItem {
  const DhikrItem({
    required this.itemId,
    required this.list,
    required this.position,
    required this.target,
    required this.kind,
    required this.textAr,
    required this.virtueAr,
    required this.referenceAr,
    required this.surah,
    required this.ayahFrom,
    required this.ayahTo,
    required this.prefaceAr,
  });

  final String itemId;
  final AdhkarList list;
  final int position;
  final int target;
  final DhikrKind kind;
  final String textAr;

  /// The optional virtue text in Arabic; null when the source review has
  /// none for this item.
  final String? virtueAr;

  final String referenceAr;

  /// Quran fields: non-null exactly for a [DhikrKind.quran] item.
  final String? surah;
  final int? ayahFrom;
  final int? ayahTo;

  /// An optional preface shown apart from the verse text (for example the
  /// isti'adha), Arabic only.
  final String? prefaceAr;

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
  });

  final String id;
  final String textAr;
  final String sourceAr;

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
    required this.attribution,
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
    final attribution = _nonBlank(json['attribution'], 'attribution');
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
      attribution: attribution,
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
    final kindJson = _nonBlank(entry['kind'], 'items[].kind');
    final DhikrKind kind;
    switch (kindJson) {
      case 'dhikr':
        kind = DhikrKind.dhikr;
      case 'quran':
        kind = DhikrKind.quran;
      default:
        throw ArgumentError.value(kindJson, 'items[].kind', 'unknown kind');
    }
    final textAr = _nonBlank(entry['text_ar'], 'items[].text_ar');
    final virtueAr = _optionalText(entry['virtue_ar'], 'items[].virtue_ar');
    final referenceAr = _nonBlank(
      entry['reference_ar'],
      'items[].reference_ar',
    );

    String? surah;
    int? ayahFrom;
    int? ayahTo;
    String? prefaceAr;
    if (kind == DhikrKind.quran) {
      surah = _nonBlank(entry['surah'], 'items[].surah');
      final fromJson = entry['ayah_from'];
      final toJson = entry['ayah_to'];
      if (fromJson is! int || fromJson < 1) {
        throw ArgumentError.value(fromJson, 'items[].ayah_from');
      }
      if (toJson is! int || toJson < 1) {
        throw ArgumentError.value(toJson, 'items[].ayah_to');
      }
      if (toJson < fromJson) {
        throw ArgumentError.value(
          toJson,
          'items[].ayah_to',
          'before ayah_from',
        );
      }
      ayahFrom = fromJson;
      ayahTo = toJson;
      prefaceAr = _optionalText(entry['preface_ar'], 'items[].preface_ar');
    } else {
      // A dhikr item carries no Quran fields at all.
      for (final field in ['surah', 'ayah_from', 'ayah_to', 'preface_ar']) {
        if (entry[field] != null) {
          throw ArgumentError.value(entry[field], 'items[].$field', 'on dhikr');
        }
      }
    }

    return DhikrItem(
      itemId: itemId,
      list: list,
      position: position,
      target: target,
      kind: kind,
      textAr: textAr,
      virtueAr: virtueAr,
      referenceAr: referenceAr,
      surah: surah,
      ayahFrom: ayahFrom,
      ayahTo: ayahTo,
      prefaceAr: prefaceAr,
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
    );
  }

  /// A required non-blank string field.
  static String _nonBlank(Object? value, String name) {
    if (value is! String || value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'blank');
    }
    return value;
  }

  /// An optional field: either absent/null or a non-blank string.
  static String? _optionalText(Object? value, String name) {
    if (value == null) return null;
    return _nonBlank(value, name);
  }

  final int version;

  /// The attribution line for the Quran text (KFGQPC Madinah Mushaf, Hafs,
  /// through the Quran Foundation), shown wherever Quran content renders.
  final String attribution;

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

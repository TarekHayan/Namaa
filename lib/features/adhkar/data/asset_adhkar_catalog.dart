import 'dart:convert';

import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

/// Loads the reviewed Adhkar catalog from the bundled document
/// (assets/religious/adhkar_catalog_v1.json once T006 ships; the tests run
/// it against the review fixture). The document is read once and the
/// validated snapshot is cached per version; a malformed or invalid
/// document never throws — it reports the recoverable "content unavailable"
/// state (data-model.md).
final class AssetAdhkarCatalog implements AdhkarCatalogPort {
  AssetAdhkarCatalog({
    required Future<String> Function(String assetPath) load,
    required String assetPath,
  }) : _load = load,
       _assetPath = assetPath;

  final Future<String> Function(String assetPath) _load;
  final String _assetPath;

  AdhkarCatalogSnapshot? _cached;

  static const _contentUnavailableMessageKey = 'adhkar.content.unavailable';

  @override
  Future<AppResult<AdhkarCatalogSnapshot>> snapshot(String ownerId) async {
    final cached = _cached;
    if (cached != null) {
      return AppResult.success(cached);
    }
    try {
      final document = await _load(_assetPath);
      final catalog = AdhkarCatalog.fromJson(
        jsonDecode(document) as Map<String, dynamic>,
      );
      final snapshot = AdhkarCatalogSnapshot(
        version: catalog.version,
        items: [
          for (final item in catalog.items)
            AdhkarCatalogItemSnapshot(
              itemId: item.itemId,
              list: item.list.name,
              position: item.position,
              target: item.target,
              textAr: item.textAr,
              translationEn: item.translationEn,
              virtueAr: item.virtueAr,
              virtueEn: item.virtueEn,
              referenceAr: item.referenceAr,
              referenceEn: item.referenceEn,
            ),
        ],
      );
      _cached = snapshot;
      return AppResult.success(snapshot);
    } catch (error) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.configuration,
          messageKey: _contentUnavailableMessageKey,
          occurredAt: DateTime.now().toUtc(),
          technicalCause: error.runtimeType.toString(),
        ),
      );
    }
  }
}

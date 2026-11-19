import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

/// The catalog boundary (contracts/adhkar-qiyam-application.md): the
/// validated domain catalog (approved items only) for the current version,
/// loaded from the reviewed asset once it ships (T006/T008).
abstract interface class AdhkarCatalogPort {
  Future<AppResult<AdhkarCatalog>> snapshot(String ownerId);
}

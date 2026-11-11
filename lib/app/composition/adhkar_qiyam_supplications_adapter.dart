import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/qiyam/application/qiyam_supplications_port.dart';
import 'package:namma_project/features/qiyam/domain/qiyam_supplication.dart';

/// Maps the Adhkar catalog port to the Qiyam supplications port (T048,
/// contracts/adhkar-qiyam-ui.md): the supplications are reference content
/// shared through the reviewed catalog, but Qiyam keeps its own domain
/// type so Adhkar and Qiyam never import each other. A catalog failure is
/// the recoverable "content unavailable" state.
final class AdhkarQiyamSupplicationsAdapter implements QiyamSupplicationsPort {
  const AdhkarQiyamSupplicationsAdapter({required AdhkarCatalogPort catalog})
    : _catalog = catalog;

  final AdhkarCatalogPort _catalog;

  @override
  Future<AppResult<List<QiyamSupplication>>> supplications(
    String ownerId,
  ) async {
    final result = await _catalog.snapshot(ownerId);
    final failure = result.failureOrNull;
    if (failure != null) return AppResult.failure(failure);
    final catalog = result.valueOrNull!;
    return AppResult.success([
      for (final supplication in catalog.qiyamSupplications)
        QiyamSupplication(
          id: supplication.id,
          textAr: supplication.textAr,
          sourceAr: supplication.sourceAr,
          sourceEn: supplication.sourceEn,
        ),
    ]);
  }
}

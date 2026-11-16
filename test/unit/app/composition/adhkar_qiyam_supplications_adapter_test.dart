import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/adhkar_qiyam_supplications_adapter.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';

/// T048: the composition adapter that maps the shared reviewed Adhkar
/// catalog to the Qiyam supplications port, so Adhkar and Qiyam never
/// import each other. The fixture uses placeholder text (T006 pending);
/// real religious text never lives in code or tests.
void main() {
  final catalog = AdhkarCatalog.fromJson(const {
    'catalog_version': 1,
    'attribution': 'test attribution line',
    'items': <Map<String, Object?>>[],
    'qiyam_supplications': [
      {
        'id': 's1',
        'text_ar': 'test supplication s1',
        'source_ar': 'test source s1',
        'approved': true,
      },
      {
        'id': 's2',
        'text_ar': 'test supplication s2',
        'source_ar': 'test source s2',
        'approved': false,
      },
    ],
  });

  test(
    'the approved supplications map to the Qiyam domain type in order',
    () async {
      final adapter = AdhkarQiyamSupplicationsAdapter(
        catalog: FixedCatalog(catalog),
      );
      final result = await adapter.supplications('owner');
      final supplications = result.valueOrNull!;
      expect(supplications, hasLength(1));
      expect(supplications.single.id, 's1');
      expect(supplications.single.textAr, 'test supplication s1');
      expect(supplications.single.sourceAr, 'test source s1');
    },
  );

  test(
    'a catalog failure propagates as the content-unavailable state',
    () async {
      final adapter = AdhkarQiyamSupplicationsAdapter(
        catalog: FailingCatalog(),
      );
      final result = await adapter.supplications('owner');
      expect(result.failureOrNull!.messageKey, 'adhkar.content.unavailable');
    },
  );
}

final class FixedCatalog implements AdhkarCatalogPort {
  FixedCatalog(this.snapshotValue);

  final AdhkarCatalog snapshotValue;

  @override
  Future<AppResult<AdhkarCatalog>> snapshot(String ownerId) async =>
      AppResult.success(snapshotValue);
}

final class FailingCatalog implements AdhkarCatalogPort {
  @override
  Future<AppResult<AdhkarCatalog>> snapshot(String ownerId) async =>
      AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.configuration,
          messageKey: 'adhkar.content.unavailable',
          occurredAt: DateTime.utc(2026, 11, 11),
        ),
      );
}

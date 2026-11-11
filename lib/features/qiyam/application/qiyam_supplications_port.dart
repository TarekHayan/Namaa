import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/qiyam_supplication.dart';

/// The Qiyam supplications boundary (contracts/adhkar-qiyam-ui.md): the
/// approved Witr/Sujood supplications of the reviewed catalog, in catalog
/// order. Composition implements it by mapping the Adhkar catalog port; a
/// catalog failure is the recoverable "content unavailable" state.
abstract interface class QiyamSupplicationsPort {
  Future<AppResult<List<QiyamSupplication>>> supplications(String ownerId);
}

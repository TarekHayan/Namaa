import 'package:namma_project/core/domain/results/app_result.dart';

final class AdhkarInboundSummary {
  const AdhkarInboundSummary({
    required this.importedCounts,
    required this.importedConflicts,
    required this.importedAwards,
  });

  final int importedCounts;
  final int importedConflicts;
  final int importedAwards;
}

/// Downloads and settles one complete owner-scoped Adhkar snapshot.
abstract interface class AdhkarInboundSyncPort {
  Future<AppResult<AdhkarInboundSummary>> receive({
    required String accountId,
    required bool Function() isCurrentScope,
  });
}

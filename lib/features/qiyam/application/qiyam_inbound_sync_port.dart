import 'package:namma_project/core/domain/results/app_result.dart';

final class QiyamInboundSummary {
  const QiyamInboundSummary({
    required this.importedNights,
    required this.importedConflicts,
    required this.importedAwards,
  });

  final int importedNights;
  final int importedConflicts;
  final int importedAwards;
}

/// Downloads and settles one complete owner-scoped Qiyam snapshot.
abstract interface class QiyamInboundSyncPort {
  Future<AppResult<QiyamInboundSummary>> receive({
    required String accountId,
    required bool Function() isCurrentScope,
  });
}

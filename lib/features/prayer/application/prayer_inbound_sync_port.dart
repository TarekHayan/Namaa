import 'package:namma_project/core/domain/results/app_result.dart';

final class PrayerInboundSummary {
  const PrayerInboundSummary({
    required this.importedReports,
    required this.importedConflicts,
    required this.importedAwards,
  });

  final int importedReports;
  final int importedConflicts;
  final int importedAwards;
}

/// Downloads and settles one complete owner-scoped Prayer snapshot.
abstract interface class PrayerInboundSyncPort {
  Future<AppResult<PrayerInboundSummary>> receive({
    required String accountId,
    required bool Function() isCurrentScope,
  });
}

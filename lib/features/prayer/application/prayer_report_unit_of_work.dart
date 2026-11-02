import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../domain/prayer_report.dart';

final class PrayerReportCommit {
  PrayerReportCommit({
    required this.report,
    required this.operationId,
    required this.expectedCurrentVersion,
    required this.acknowledgedBase,
    required this.queueForSync,
    this.firstAward,
  }) {
    if (operationId.trim().isEmpty || !report.updatedAt.isUtc) {
      throw ArgumentError('Invalid prayer report commit');
    }
    final award = firstAward;
    if (award != null &&
        (award.accountId != report.accountId ||
            award.source != kPrayerDoneAwardSource ||
            award.sourceId != report.reportId ||
            award.awardedAt != report.reportedCompletionAt)) {
      throw ArgumentError('Prayer award does not match report');
    }
  }

  final PrayerReport report;
  final XpAward? firstAward;
  final String operationId;
  final DateTime? expectedCurrentVersion;
  final DateTime? acknowledgedBase;
  final bool queueForSync;
}

abstract interface class PrayerReportUnitOfWork {
  Future<AppResult<void>> commit(PrayerReportCommit request);
}

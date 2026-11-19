import 'package:namma_project/core/domain/results/app_result.dart';

final class MyAdhkarInboundSummary {
  const MyAdhkarInboundSummary({
    required this.importedGroups,
    required this.importedItems,
    required this.importedConflicts,
  });

  final int importedGroups;
  final int importedItems;
  final int importedConflicts;
}

/// Downloads and settles one complete owner-scoped My Adhkar snapshot. It
/// runs inside `AdhkarSyncService` so a failure stays isolated from the
/// other domains (T095).
abstract interface class MyAdhkarInboundSyncPort {
  Future<AppResult<MyAdhkarInboundSummary>> receive({
    required String accountId,
    required bool Function() isCurrentScope,
  });
}

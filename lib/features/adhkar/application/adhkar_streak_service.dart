import 'package:namma_project/core/domain/results/app_result.dart';

import '../domain/adhkar_catalog.dart';
import '../domain/adhkar_streak.dart';
import 'adhkar_catalog_port.dart';
import 'adhkar_repository.dart';

/// The derived Adhkar streak behind an application boundary (research.md
/// R9): the repository judges each day against the catalog version that
/// day's counts were made against, and the pure walk counts the consecutive
/// complete days with an early exit. The screen cubit and the Today port
/// both go through this service, so the walk is composed exactly once.
final class AdhkarStreakService {
  const AdhkarStreakService({
    required AdhkarRepository repository,
    required AdhkarCatalogPort catalog,
  }) : _repository = repository,
       _catalog = catalog;

  final AdhkarRepository _repository;
  final AdhkarCatalogPort _catalog;

  Future<AppResult<int>> streak({
    required String ownerId,
    required String today,
  }) async {
    final catalog = await _catalog.snapshot(ownerId);
    if (catalog.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final current = catalog.valueOrNull!;
    final completed = await _repository.fullyCompletedDays(
      accountId: ownerId,
      lastDay: today,
      maxLookBackDays: kAdhkarStreakWalkCapDays,
      catalogVersion: current.version,
      morningItems: _listItems(current, AdhkarList.morning),
      eveningItems: _listItems(current, AdhkarList.evening),
    );
    if (completed.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    return AppResult.success(
      adhkarStreak(
        completions: {
          for (final day in completed.valueOrNull!.completed)
            day: const AdhkarDayCompletion(
              morningComplete: true,
              eveningComplete: true,
            ),
        },
        today: today,
      ),
    );
  }

  List<AdhkarListItem> _listItems(AdhkarCatalog catalog, AdhkarList list) => [
    for (final item in catalog.itemsOf(list))
      AdhkarListItem(itemId: item.itemId, target: item.target),
  ];
}

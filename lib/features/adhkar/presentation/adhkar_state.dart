import 'package:namma_project/features/adhkar/application/adhkar_catalog_port.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';

/// The two Adhkar tabs of the screen's switch.
enum AdhkarTab { morning, evening }

/// Per-item command feedback (contracts/adhkar-qiyam-application.md).
enum AdhkarActionStatus { pending, saved, failed }

/// The Adhkar screen state: the catalog, the resolved clock, the current
/// day's counts, the selected tab and the derived streak.
final class AdhkarState {
  const AdhkarState({
    this.loading = false,
    this.catalog,
    this.clock,
    this.counts = const {},
    this.selectedTab = AdhkarTab.morning,
    this.streak = 0,
    this.itemStatus = const {},
    this.celebration,
  });

  final bool loading;
  final AdhkarCatalogSnapshot? catalog;
  final AdhkarClockState? clock;

  /// The counts of the resolved Adhkar day, keyed by item id.
  final Map<String, int> counts;
  final AdhkarTab selectedTab;
  final int streak;

  /// Per-item command feedback; entries clear when the next command for the
  /// item starts.
  final Map<String, AdhkarActionStatus> itemStatus;

  /// One-shot: set on the state emitted when a list's set completes, and
  /// null again afterwards.
  final AdhkarTab? celebration;

  /// True while the schedule is unavailable: the lists stay visible but
  /// counting is locked (owner decision, 2026-11-10).
  bool get countingLocked =>
      clock == null || clock!.scheduleState == AdhkarScheduleState.unavailable;

  bool get contentUnavailable => catalog == null;

  AdhkarState copyWith({
    bool? loading,
    AdhkarCatalogSnapshot? catalog,
    AdhkarClockState? clock,
    Map<String, int>? counts,
    AdhkarTab? selectedTab,
    int? streak,
    Map<String, AdhkarActionStatus>? itemStatus,
    AdhkarTab? celebration,
    bool clearCelebration = false,
  }) => AdhkarState(
    loading: loading ?? this.loading,
    catalog: catalog ?? this.catalog,
    clock: clock ?? this.clock,
    counts: counts ?? this.counts,
    selectedTab: selectedTab ?? this.selectedTab,
    streak: streak ?? this.streak,
    itemStatus: itemStatus ?? this.itemStatus,
    celebration: clearCelebration ? null : (celebration ?? this.celebration),
  );

  /// The count of an item for the current day; a missing row is 0.
  int countOf(String itemId) => counts[itemId] ?? 0;

  /// Completed items and the total of one list (FR-005).
  int completedOf(String list) {
    final items = catalog?.itemsOf(list) ?? const [];
    return items.where((item) => countOf(item.itemId) >= item.target).length;
  }

  int totalOf(String list) => catalog?.itemsOf(list).length ?? 0;
}

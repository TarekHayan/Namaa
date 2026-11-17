import 'package:namma_project/features/adhkar/domain/adhkar_catalog.dart';
import 'package:namma_project/features/adhkar/domain/adhkar_clock.dart';

/// The Adhkar screen's tabs: the two reviewed lists and the user's own
/// collection (FR-022). The switch never opens on My Adhkar by itself.
enum AdhkarTab { morning, evening, myAdhkar }

/// Per-item command feedback (contracts/adhkar-qiyam-application.md).
enum AdhkarActionStatus { pending, saved, failed, outsidePeriod, locked }

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
    this.outsidePeriodStartsAtUtc,
  });

  final bool loading;
  final AdhkarCatalog? catalog;
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

  /// When a command landed outside its list's period: when that period
  /// opens (the "its time starts at ..." feedback). Cleared on the next
  /// command.
  final DateTime? outsidePeriodStartsAtUtc;

  /// True while the schedule is unavailable: the lists stay visible but
  /// counting is locked (owner decision, 2026-11-10).
  bool get countingLocked =>
      clock == null || clock!.scheduleState == AdhkarScheduleState.unavailable;

  bool get contentUnavailable => catalog == null;

  AdhkarState copyWith({
    bool? loading,
    AdhkarCatalog? catalog,
    AdhkarClockState? clock,
    Map<String, int>? counts,
    AdhkarTab? selectedTab,
    int? streak,
    Map<String, AdhkarActionStatus>? itemStatus,
    AdhkarTab? celebration,
    bool clearCelebration = false,
    DateTime? outsidePeriodStartsAtUtc,
    bool clearOutsidePeriod = false,
  }) => AdhkarState(
    loading: loading ?? this.loading,
    catalog: catalog ?? this.catalog,
    clock: clock ?? this.clock,
    counts: counts ?? this.counts,
    selectedTab: selectedTab ?? this.selectedTab,
    streak: streak ?? this.streak,
    itemStatus: itemStatus ?? this.itemStatus,
    celebration: clearCelebration ? null : (celebration ?? this.celebration),
    outsidePeriodStartsAtUtc: clearOutsidePeriod
        ? null
        : (outsidePeriodStartsAtUtc ?? this.outsidePeriodStartsAtUtc),
  );

  /// The count of an item for the current day; a missing row is 0.
  int countOf(String itemId) => counts[itemId] ?? 0;

  /// Completed items and the total of one list (FR-005).
  int completedOf(AdhkarList list) {
    final items = catalog?.itemsOf(list) ?? const [];
    return items.where((item) => countOf(item.itemId) >= item.target).length;
  }

  int totalOf(AdhkarList list) => catalog?.itemsOf(list).length ?? 0;
}

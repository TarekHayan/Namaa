import 'package:flutter/foundation.dart';

import 'dashboard_display_value.dart';

/// Unfinished Dashboard destinations represented by presentation-only samples.
enum DashboardPreviewFeature {
  prayer,
  quran,
  focus,
  qiyam,
  adhkar,
  finance,
  counters,
}

enum DashboardPrayerName { fajr, dhuhr, asr, maghrib, isha }

enum DashboardPreviewLocation { riyadh }

enum DashboardMetricUnit { count, ratio, percent, minutes, rakats }

enum DashboardQuranPortion { alKahf }

@immutable
final class DashboardClockTime {
  const DashboardClockTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour <= 23),
      assert(minute >= 0 && minute <= 59);

  final int hour;
  final int minute;
}

@immutable
final class DashboardMetricAmount {
  const DashboardMetricAmount({
    required this.amount,
    required this.unit,
    this.total,
  }) : assert(total == null || total >= amount);

  final num amount;
  final num? total;
  final DashboardMetricUnit unit;
}

@immutable
final class DashboardPreviewMetric {
  const DashboardPreviewMetric({required this.feature, required this.value});

  final DashboardPreviewFeature feature;
  final DashboardDisplayValue<DashboardMetricAmount> value;
}

@immutable
final class DashboardPrayerPreview {
  const DashboardPrayerPreview({
    required this.nextPrayer,
    required this.nextPrayerTime,
    required this.remainingMinutes,
    required this.location,
    required this.followingPrayer,
    required this.followingPrayerTime,
  });

  final DashboardDisplayValue<DashboardPrayerName> nextPrayer;
  final DashboardDisplayValue<DashboardClockTime> nextPrayerTime;
  final DashboardDisplayValue<int> remainingMinutes;
  final DashboardDisplayValue<DashboardPreviewLocation> location;
  final DashboardDisplayValue<DashboardPrayerName> followingPrayer;
  final DashboardDisplayValue<DashboardClockTime> followingPrayerTime;
}

@immutable
final class DashboardQuranPreview {
  const DashboardQuranPreview({
    required this.portion,
    required this.startPage,
    required this.endPage,
    required this.progress,
    required this.remainingPages,
  });

  final DashboardDisplayValue<DashboardQuranPortion> portion;
  final DashboardDisplayValue<int> startPage;
  final DashboardDisplayValue<int> endPage;
  final DashboardDisplayValue<double> progress;
  final DashboardDisplayValue<int> remainingPages;
}

@immutable
final class DashboardFinancePreview {
  const DashboardFinancePreview({
    required this.spent,
    required this.saved,
    required this.budgetProgress,
  });

  final DashboardDisplayValue<int> spent;
  final DashboardDisplayValue<int> saved;
  final DashboardDisplayValue<double> budgetProgress;
}

@immutable
final class DashboardCounterPreview {
  const DashboardCounterPreview({required this.id, required this.count});

  /// A fixture key used only to select localized presentation copy.
  final String id;
  final DashboardDisplayValue<int> count;
}

/// Central read-only fixture for every Dashboard value without an owner yet.
///
/// The fixture contains no account, Task, Habit, XP, or other owner identifier.
@immutable
final class DashboardPreviewData {
  const DashboardPreviewData({
    required this.overallProgress,
    required this.level,
    required this.streakDays,
    required this.metrics,
    required this.prayer,
    required this.quran,
    required this.finance,
    required this.focusMinutes,
    required this.qiyamRakats,
    required this.adhkarCompleted,
    required this.counters,
  });

  static const standard = DashboardPreviewData(
    overallProgress: DashboardDisplayValue.sample(0.68),
    level: DashboardDisplayValue.sample(4),
    streakDays: DashboardDisplayValue.sample(7),
    metrics: [
      DashboardPreviewMetric(
        feature: DashboardPreviewFeature.prayer,
        value: DashboardDisplayValue.sample(
          DashboardMetricAmount(
            amount: 4,
            total: 5,
            unit: DashboardMetricUnit.ratio,
          ),
        ),
      ),
      DashboardPreviewMetric(
        feature: DashboardPreviewFeature.quran,
        value: DashboardDisplayValue.sample(
          DashboardMetricAmount(amount: 75, unit: DashboardMetricUnit.percent),
        ),
      ),
      DashboardPreviewMetric(
        feature: DashboardPreviewFeature.adhkar,
        value: DashboardDisplayValue.sample(
          DashboardMetricAmount(
            amount: 19,
            total: 43,
            unit: DashboardMetricUnit.ratio,
          ),
        ),
      ),
      DashboardPreviewMetric(
        feature: DashboardPreviewFeature.focus,
        value: DashboardDisplayValue.sample(
          DashboardMetricAmount(amount: 50, unit: DashboardMetricUnit.minutes),
        ),
      ),
      DashboardPreviewMetric(
        feature: DashboardPreviewFeature.qiyam,
        value: DashboardDisplayValue.sample(
          DashboardMetricAmount(amount: 2, unit: DashboardMetricUnit.rakats),
        ),
      ),
    ],
    prayer: DashboardPrayerPreview(
      nextPrayer: DashboardDisplayValue.sample(DashboardPrayerName.asr),
      nextPrayerTime: DashboardDisplayValue.sample(
        DashboardClockTime(hour: 15, minute: 25),
      ),
      remainingMinutes: DashboardDisplayValue.sample(204),
      location: DashboardDisplayValue.sample(DashboardPreviewLocation.riyadh),
      followingPrayer: DashboardDisplayValue.sample(
        DashboardPrayerName.maghrib,
      ),
      followingPrayerTime: DashboardDisplayValue.sample(
        DashboardClockTime(hour: 18, minute: 9),
      ),
    ),
    quran: DashboardQuranPreview(
      portion: DashboardDisplayValue.sample(DashboardQuranPortion.alKahf),
      startPage: DashboardDisplayValue.sample(302),
      endPage: DashboardDisplayValue.sample(304),
      progress: DashboardDisplayValue.sample(0.75),
      remainingPages: DashboardDisplayValue.sample(2),
    ),
    finance: DashboardFinancePreview(
      spent: DashboardDisplayValue.sample(3640),
      saved: DashboardDisplayValue.sample(8200),
      budgetProgress: DashboardDisplayValue.sample(0.52),
    ),
    focusMinutes: DashboardDisplayValue.sample(50),
    qiyamRakats: DashboardDisplayValue.sample(2),
    adhkarCompleted: DashboardDisplayValue.sample(19),
    counters: [
      DashboardCounterPreview(
        id: 'morning',
        count: DashboardDisplayValue.sample(12),
      ),
      DashboardCounterPreview(
        id: 'evening',
        count: DashboardDisplayValue.sample(7),
      ),
      DashboardCounterPreview(
        id: 'istighfar',
        count: DashboardDisplayValue.sample(33),
      ),
      DashboardCounterPreview(
        id: 'salawat',
        count: DashboardDisplayValue.sample(21),
      ),
    ],
  );

  final DashboardDisplayValue<double> overallProgress;
  final DashboardDisplayValue<int> level;
  final DashboardDisplayValue<int> streakDays;
  final List<DashboardPreviewMetric> metrics;
  final DashboardPrayerPreview prayer;
  final DashboardQuranPreview quran;
  final DashboardFinancePreview finance;
  final DashboardDisplayValue<int> focusMinutes;
  final DashboardDisplayValue<int> qiyamRakats;
  final DashboardDisplayValue<int> adhkarCompleted;
  final List<DashboardCounterPreview> counters;
}

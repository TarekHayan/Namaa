/// One independently observed Today source, with explicit unknown vs empty.
library;

import 'package:namma_project/core/domain/failures/app_failure.dart';

enum TodaySectionStatus { loading, available, empty, unavailable, stale }

final class TodaySection<T> {
  TodaySection._(this.status, this.value, this.failure) {
    final hasConfirmedValue =
        status == TodaySectionStatus.available ||
        status == TodaySectionStatus.empty ||
        status == TodaySectionStatus.stale;
    if (hasConfirmedValue != (value != null) ||
        ((status == TodaySectionStatus.unavailable ||
                status == TodaySectionStatus.stale) !=
            (failure != null))) {
      throw ArgumentError('Inconsistent Today section state');
    }
  }

  factory TodaySection.loading() =>
      TodaySection._(TodaySectionStatus.loading, null, null);

  factory TodaySection.available(T value) =>
      TodaySection._(TodaySectionStatus.available, value, null);

  factory TodaySection.empty(T value) =>
      TodaySection._(TodaySectionStatus.empty, value, null);

  factory TodaySection.unavailable(AppFailure failure) =>
      TodaySection._(TodaySectionStatus.unavailable, null, failure);

  factory TodaySection.stale(T value, AppFailure failure) =>
      TodaySection._(TodaySectionStatus.stale, value, failure);

  final TodaySectionStatus status;
  final T? value;
  final AppFailure? failure;

  bool get hasConfirmedValue => value != null;
  bool get allowsMutation => status == TodaySectionStatus.available;
  bool get needsRetry =>
      status == TodaySectionStatus.unavailable ||
      status == TodaySectionStatus.stale;
}

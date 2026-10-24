import 'package:flutter/foundation.dart';

/// Describes where a Dashboard value came from and whether it is current.
enum DashboardValueProvenance {
  live,
  sample,
  loading,
  empty,
  stale,
  unavailable,
}

/// A transient value prepared for display on the Dashboard.
///
/// This type deliberately has no serialization or persistence contract. Live
/// values come from an owning feature; sample values are presentation fixtures.
@immutable
final class DashboardDisplayValue<T> {
  const DashboardDisplayValue._({required this.provenance, this.value});

  const DashboardDisplayValue.live(T value)
    : this._(provenance: DashboardValueProvenance.live, value: value);

  const DashboardDisplayValue.sample(T value)
    : this._(provenance: DashboardValueProvenance.sample, value: value);

  const DashboardDisplayValue.loading()
    : this._(provenance: DashboardValueProvenance.loading);

  const DashboardDisplayValue.empty()
    : this._(provenance: DashboardValueProvenance.empty);

  const DashboardDisplayValue.stale(T value)
    : this._(provenance: DashboardValueProvenance.stale, value: value);

  const DashboardDisplayValue.unavailable()
    : this._(provenance: DashboardValueProvenance.unavailable);

  final DashboardValueProvenance provenance;
  final T? value;

  bool get hasValue => switch (provenance) {
    DashboardValueProvenance.live ||
    DashboardValueProvenance.sample ||
    DashboardValueProvenance.stale => true,
    DashboardValueProvenance.loading ||
    DashboardValueProvenance.empty ||
    DashboardValueProvenance.unavailable => false,
  };

  bool get isSample => provenance == DashboardValueProvenance.sample;
}

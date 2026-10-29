import 'prayer_city.dart';

final class PrayerPreferences {
  PrayerPreferences({
    required this.accountId,
    required this.city,
    required this.calculationMethod,
    required this.revision,
    required this.updatedAt,
  }) {
    if (accountId.trim().isEmpty ||
        calculationMethod.trim().isEmpty ||
        revision < 1 ||
        !updatedAt.isUtc) {
      throw ArgumentError('Invalid prayer preferences');
    }
  }

  final String accountId;
  final PrayerCity city;
  final String calculationMethod;
  final int revision;
  final DateTime updatedAt;

  PrayerPreferences copyWith({
    PrayerCity? city,
    String? calculationMethod,
    int? revision,
    DateTime? updatedAt,
  }) => PrayerPreferences(
    accountId: accountId,
    city: city ?? this.city,
    calculationMethod: calculationMethod ?? this.calculationMethod,
    revision: revision ?? this.revision,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is PrayerPreferences &&
      other.accountId == accountId &&
      other.city == city &&
      other.calculationMethod == calculationMethod &&
      other.revision == revision &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(accountId, city, calculationMethod, revision, updatedAt);
}

final class PrayerCity {
  PrayerCity({
    required this.provider,
    required this.providerCityId,
    required this.name,
    required this.countryCode,
    required this.countryName,
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
    this.adminName,
  }) {
    if ([
          provider,
          providerCityId,
          name,
          countryCode,
          countryName,
          timeZoneId,
        ].any((part) => part.trim().isEmpty) ||
        !latitude.isFinite ||
        latitude.abs() > 90 ||
        !longitude.isFinite ||
        longitude.abs() > 180) {
      throw ArgumentError('Invalid prayer city');
    }
  }

  final String provider;
  final String providerCityId;
  final String name;
  final String countryCode;
  final String countryName;
  final String? adminName;
  final double latitude;
  final double longitude;
  final String timeZoneId;

  PrayerCity copyWith({
    String? name,
    String? countryName,
    String? adminName,
    double? latitude,
    double? longitude,
    String? timeZoneId,
  }) => PrayerCity(
    provider: provider,
    providerCityId: providerCityId,
    name: name ?? this.name,
    countryCode: countryCode,
    countryName: countryName ?? this.countryName,
    adminName: adminName ?? this.adminName,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    timeZoneId: timeZoneId ?? this.timeZoneId,
  );

  @override
  bool operator ==(Object other) =>
      other is PrayerCity &&
      other.provider == provider &&
      other.providerCityId == providerCityId &&
      other.name == name &&
      other.countryCode == countryCode &&
      other.countryName == countryName &&
      other.adminName == adminName &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.timeZoneId == timeZoneId;

  @override
  int get hashCode => Object.hash(
    provider,
    providerCityId,
    name,
    countryCode,
    countryName,
    adminName,
    latitude,
    longitude,
    timeZoneId,
  );
}

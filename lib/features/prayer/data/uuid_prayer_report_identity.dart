import 'package:uuid/uuid.dart';
import '../application/prayer_report_identity_port.dart';
import '../domain/prayer_local_date.dart';
import '../domain/prayer_name.dart';

final class UuidPrayerReportIdentity implements PrayerReportIdentityPort {
  static const namespace = '9d63d7a6-bb43-4b93-b2a1-c1d22c68b008';
  static const Uuid _uuid = Uuid();

  @override
  String reportId(PrayerLocalDate date, PrayerName name) =>
      _uuid.v5(namespace, '${date.value}/${name.name}');

  String conflictId(
    String reportId,
    String lowerDescriptor,
    String higherDescriptor,
  ) => _uuid.v5(
    namespace,
    'conflict/$reportId/$lowerDescriptor/$higherDescriptor',
  );

  String conflictNameId(String name) => _uuid.v5(namespace, name);
}

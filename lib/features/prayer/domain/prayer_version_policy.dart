import 'prayer_status.dart';

final class PrayerVersionDescriptor {
  PrayerVersionDescriptor({
    required this.updatedAt,
    required this.status,
    required this.completionAt,
    required this.zoneId,
    required this.offsetMinutes,
  }) {
    if (!updatedAt.isUtc ||
        (completionAt != null && !completionAt!.isUtc) ||
        zoneId.trim().isEmpty ||
        zoneId.contains('|') ||
        offsetMinutes.abs() > 1080 ||
        !PrayerStatus.values.any((entry) => entry.wireName == status) ||
        ((completionAt != null) !=
            (status == 'completed_on_time' || status == 'completed_late'))) {
      throw ArgumentError('Invalid prayer version');
    }
  }

  final DateTime updatedAt;
  final String status;
  final DateTime? completionAt;
  final String zoneId;
  final int offsetMinutes;

  String get semanticKey =>
      '$status|'
      '${completionAt?.microsecondsSinceEpoch.toString() ?? 'null'}|'
      '$zoneId|$offsetMinutes';

  String get descriptor => '${updatedAt.microsecondsSinceEpoch}:$semanticKey';
}

abstract final class PrayerVersionPolicy {
  static PrayerVersionDescriptor choose(
    PrayerVersionDescriptor first,
    PrayerVersionDescriptor second,
  ) =>
      first.updatedAt.microsecondsSinceEpoch >
          second.updatedAt.microsecondsSinceEpoch
      ? first
      : first.updatedAt.microsecondsSinceEpoch <
            second.updatedAt.microsecondsSinceEpoch
      ? second
      : first.semanticKey.compareTo(second.semanticKey) >= 0
      ? first
      : second;

  static String conflictName(
    String reportId,
    PrayerVersionDescriptor first,
    PrayerVersionDescriptor second,
  ) {
    if (first.descriptor == second.descriptor) {
      throw ArgumentError('Identical versions do not conflict');
    }
    final descriptors = [first.descriptor, second.descriptor]..sort();
    return 'conflict/$reportId/${descriptors[0]}/${descriptors[1]}';
  }
}

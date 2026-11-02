import 'dart:math';

import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/xp/domain/xp_award.dart';

import '../domain/prayer_local_date.dart';
import '../domain/prayer_name.dart';
import '../domain/prayer_report.dart';
import '../domain/prayer_status.dart';
import 'prayer_clock_port.dart';
import 'prayer_report_identity_port.dart';
import 'prayer_report_unit_of_work.dart';
import 'prayer_repository.dart';

typedef PrayerOperationIdProvider = String Function();
typedef PrayerScopeValidator = bool Function(PrayerReportCommandContext value);

final class PrayerReportCommandContext {
  const PrayerReportCommandContext({
    required this.localDate,
    required this.timeZoneId,
    required this.preferenceRevision,
    required this.scopeGeneration,
  });

  final PrayerLocalDate localDate;
  final String timeZoneId;
  final int preferenceRevision;
  final int scopeGeneration;

  @override
  bool operator ==(Object other) =>
      other is PrayerReportCommandContext &&
      other.localDate == localDate &&
      other.timeZoneId == timeZoneId &&
      other.preferenceRevision == preferenceRevision &&
      other.scopeGeneration == scopeGeneration;

  @override
  int get hashCode => Object.hash(
    localDate,
    timeZoneId,
    preferenceRevision,
    scopeGeneration,
  );
}

/// Owns today's explicit Prayer state transition. It never infers a state from
/// the schedule or current clock.
final class PrayerReportCommands {
  PrayerReportCommands({
    required String ownerId,
    required PrayerRepository repository,
    required PrayerReportUnitOfWork unitOfWork,
    required PrayerReportIdentityPort identity,
    required PrayerClockPort clock,
    required PrayerScopeValidator isCurrentScope,
    PrayerScopeValidator? isCurrentOwnerContext,
    required bool queueForSync,
    PrayerOperationIdProvider? nextOperationId,
  }) : _ownerId = ownerId,
       _repository = repository,
       _unitOfWork = unitOfWork,
       _identity = identity,
       _clock = clock,
       _isCurrentScope = isCurrentScope,
       _isCurrentOwnerContext = isCurrentOwnerContext ?? isCurrentScope,
       _queueForSync = queueForSync,
       _nextOperationId = nextOperationId ?? _newOperationId {
    if (ownerId.trim().isEmpty) throw ArgumentError('Owner is required');
  }

  final String _ownerId;
  final PrayerRepository _repository;
  final PrayerReportUnitOfWork _unitOfWork;
  final PrayerReportIdentityPort _identity;
  final PrayerClockPort _clock;
  final PrayerScopeValidator _isCurrentScope;
  final PrayerScopeValidator _isCurrentOwnerContext;
  final bool _queueForSync;
  final PrayerOperationIdProvider _nextOperationId;

  Future<AppResult<PrayerReport?>> setStatus({
    required PrayerName name,
    required PrayerStatus status,
    required PrayerReportCommandContext capturedContext,
  }) async {
    final sampledNow = _clock.nowUtc();
    if (!_validAtSubmission(capturedContext, sampledNow)) {
      return AppResult.failure(_stale(sampledNow));
    }
    final read = await _repository.readFresh(
      accountId: _ownerId,
      date: capturedContext.localDate,
      prayerName: name,
    );
    if (read.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    final prior = read.valueOrNull;
    if (prior == null && status == PrayerStatus.pending) {
      return const AppResult.success(null);
    }
    if (prior?.status == status) return AppResult.success(prior);
    if (!_isCurrentOwnerContext(capturedContext)) {
      return AppResult.failure(_stale(_clock.nowUtc()));
    }

    final version = prior != null && !sampledNow.isAfter(prior.updatedAt)
        ? prior.updatedAt.add(const Duration(microseconds: 1))
        : sampledNow;
    final completionAt = status.isCompleted
        ? (prior?.reportedCompletionAt ?? version)
        : null;
    final report = PrayerReport(
      accountId: _ownerId,
      reportId:
          prior?.reportId ??
          _identity.reportId(capturedContext.localDate, name),
      date: capturedContext.localDate,
      name: name,
      status: status,
      reportedCompletionAt: completionAt,
      recordedZoneId: capturedContext.timeZoneId,
      recordedOffsetMinutes: _clock.cityOffsetMinutes(
        sampledNow,
        capturedContext.timeZoneId,
      ),
      createdAt: prior?.createdAt ?? version,
      updatedAt: version,
      lastAcknowledgedUpdatedAt: prior?.lastAcknowledgedUpdatedAt,
      canonicalRewardConfirmedAt: prior?.canonicalRewardConfirmedAt,
    );
    final award = status.isCompleted
        ? XpAward(
            accountId: _ownerId,
            source: kPrayerDoneAwardSource,
            sourceId: report.reportId,
            amount: status == PrayerStatus.completedOnTime ? 10 : 5,
            awardedAt: completionAt!,
          )
        : null;
    if (!_isCurrentOwnerContext(capturedContext)) {
      return AppResult.failure(_stale(_clock.nowUtc()));
    }
    final saved = await _unitOfWork.commit(
      PrayerReportCommit(
        report: report,
        firstAward: award,
        operationId: _nextOperationId(),
        expectedCurrentVersion: prior?.updatedAt,
        acknowledgedBase: prior?.lastAcknowledgedUpdatedAt,
        queueForSync: _queueForSync,
      ),
    );
    if (saved.failureOrNull case final failure?) {
      return AppResult.failure(failure);
    }
    return AppResult.success(report);
  }

  bool _validAtSubmission(PrayerReportCommandContext context, DateTime now) =>
      context.timeZoneId.trim().isNotEmpty &&
      _clock.cityDate(now, context.timeZoneId) == context.localDate &&
      _isCurrentScope(context);

  static AppFailure _stale(DateTime now) => AppFailure.recoverable(
    category: AppFailureCategory.validation,
    messageKey: 'prayer.report.stale_context',
    occurredAt: now,
  );

  static String _newOperationId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String byte(int index) => bytes[index].toRadixString(16).padLeft(2, '0');
    return '${byte(0)}${byte(1)}${byte(2)}${byte(3)}-'
        '${byte(4)}${byte(5)}-${byte(6)}${byte(7)}-'
        '${byte(8)}${byte(9)}-'
        '${byte(10)}${byte(11)}${byte(12)}${byte(13)}${byte(14)}${byte(15)}';
  }
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/application/synchronization_engine.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/adhkar/application/adhkar_inbound_sync_port.dart';
import 'package:namma_project/features/adhkar/application/adhkar_sync_service.dart';
import 'package:namma_project/features/prayer/application/prayer_inbound_sync_port.dart';
import 'package:namma_project/features/prayer/application/prayer_sync_service.dart';

/// T064: the Adhkar sync service is domain-scoped. Its inbound reader
/// failing leaves this domain recoverably failed while ANOTHER domain —
/// the real PrayerSyncService over its own fakes — still syncs, and neither
/// the outbound engine nor the global status is touched by the failure.
void main() {
  test('outbound precedes inbound, then the summary is ready', () async {
    final log = <String>[];
    final session = _Session();
    final service = AdhkarSyncService(
      session: session,
      connectivity: const _Connectivity(),
      outbound: _Outbound(log),
      inbound: _Inbound(log),
    );
    addTearDown(service.dispose);
    final result = await service.synchronize();
    expect(result.failureOrNull, isNull);
    expect(log, ['outbound', 'inbound']);
    expect(result.valueOrNull!.outbound.acknowledged, 1);
    expect(result.valueOrNull!.inbound.importedCounts, 2);
  });

  test('a failing Adhkar inbound fails only this domain; Prayer still '
      'syncs', () async {
    final session = _Session();
    final failingInbound = _Inbound([], failure: true);
    final adhkar = AdhkarSyncService(
      session: session,
      connectivity: const _Connectivity(),
      outbound: _Outbound([]),
      inbound: failingInbound,
    );
    final prayerLog = <String>[];
    final prayer = PrayerSyncService(
      session: session,
      connectivity: const _Connectivity(),
      outbound: _Outbound(prayerLog),
      inbound: _PrayerInbound(prayerLog),
    );
    addTearDown(adhkar.dispose);
    addTearDown(prayer.dispose);

    final adhkarResult = await adhkar.synchronize();
    expect(
      adhkarResult.failureOrNull?.category,
      AppFailureCategory.cloud,
      reason: 'the Adhkar domain reports its own recoverable failure',
    );
    expect(
      await adhkar.synchronize(),
      isA<AppResult<AdhkarSyncSummary>>(),
      reason: 'the failure stays scoped to this service',
    );

    final prayerResult = await prayer.synchronize();
    expect(
      prayerResult.failureOrNull,
      isNull,
      reason: 'another domain still syncs when the Adhkar reader fails',
    );
    expect(prayerLog, ['outbound', 'inbound']);
    expect(prayerResult.valueOrNull!.inbound.importedReports, 3);
  });
}

const _owner = 'sync-owner';

final class _Session implements CloudSessionPort {
  String? account = _owner;

  @override
  Future<AppResult<void>> initialize() async => const AppResult.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult.success(CloudSyncContext(accountId: account ?? _owner));
}

final class _Connectivity implements ConnectivityPort {
  const _Connectivity();

  @override
  ConnectivityStatus get current => ConnectivityStatus.online;

  @override
  Stream<ConnectivityStatus> get changes => const Stream.empty();
}

final class _Outbound implements PendingSynchronizationEngine {
  _Outbound(this.log);

  final List<String> log;

  @override
  Future<AppResult<SyncSummary>> synchronize() async {
    log.add('outbound');
    return AppResult.success(
      const SyncSummary(
        acknowledged: 1,
        conflictsRecorded: 0,
        equalTimestampConflicts: 0,
        recoverableFailures: 0,
      ),
    );
  }
}

final class _Inbound implements AdhkarInboundSyncPort {
  _Inbound(this.log, {this.failure = false});

  final List<String> log;
  final bool failure;

  @override
  Future<AppResult<AdhkarInboundSummary>> receive({
    required String accountId,
    required bool Function() isCurrentScope,
  }) async {
    log.add('inbound');
    if (failure) {
      return AppResult.failure(
        AppFailure.recoverable(
          category: AppFailureCategory.cloud,
          messageKey: 'adhkar.sync.failed',
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    }
    return AppResult.success(
      const AdhkarInboundSummary(
        importedCounts: 2,
        importedConflicts: 0,
        importedAwards: 1,
      ),
    );
  }
}

final class _PrayerInbound implements PrayerInboundSyncPort {
  _PrayerInbound(this.log);

  final List<String> log;

  @override
  Future<AppResult<PrayerInboundSummary>> receive({
    required String accountId,
    required bool Function() isCurrentScope,
  }) async {
    log.add('inbound');
    return AppResult.success(
      const PrayerInboundSummary(
        importedReports: 3,
        importedConflicts: 0,
        importedAwards: 1,
      ),
    );
  }
}

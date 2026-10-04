/// In-memory Foundation preference store for theme tests.
library;

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

class ThemeMemoryLocalStore implements LocalStorePort {
  ThemeMemoryLocalStore({
    Map<String, String>? preferences,
    this.writeFailure,
    this.throwOnRead = false,
    this.throwOnWrite = false,
  }) : preferences = <String, String>{...?preferences};

  final Map<String, String> preferences;
  final AppFailure? writeFailure;
  final bool throwOnRead;
  final bool throwOnWrite;

  @override
  Future<AppResult<String?>> readPreference(String key) async {
    if (throwOnRead) {
      throw StateError('unexpected preference read failure');
    }
    return AppResult<String?>.success(preferences[key]);
  }

  @override
  Future<AppResult<void>> savePreference(String key, String value) async {
    if (throwOnWrite) {
      throw StateError('unexpected preference write failure');
    }
    if (writeFailure != null) {
      return AppResult<void>.failure(writeFailure!);
    }
    preferences[key] = value;
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> acknowledgeChange(
    String operationId,
    String acknowledgementId,
  ) async => AppResult<void>.success(null);

  @override
  Future<AppResult<void>> commitLocalChange(
    LocalRecordChange change,
    PendingChangeRequest pending,
  ) async => AppResult<void>.success(null);

  @override
  Future<AppResult<void>> markChangeConflicted(String operationId) async =>
      AppResult<void>.success(null);

  @override
  Future<AppResult<List<PendingChangeRecord>>> readPendingChanges(
    String accountId,
  ) async => AppResult<List<PendingChangeRecord>>.success(const []);

  @override
  Future<AppResult<void>> recordConflict(ConflictRecordInput conflict) async =>
      AppResult<void>.success(null);

  @override
  Future<AppResult<void>> recordConflictAndFinalize({
    required ConflictRecordInput conflict,
    required String operationId,
  }) async => AppResult<void>.success(null);

  @override
  Future<AppResult<void>> recordRecoverableFailure(
    String operationId,
    String summary,
  ) async => AppResult<void>.success(null);

  @override
  Future<AppResult<MigrationOutcome>> runMigration(
    int targetSchemaVersion,
  ) async => AppResult<MigrationOutcome>.success(
    MigrationOutcome(completedVersion: targetSchemaVersion, recovered: false),
  );
}

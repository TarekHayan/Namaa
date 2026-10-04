import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/foundation/application/locale_preferences.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';

class _LocaleStore implements LocalStorePort {
  _LocaleStore({
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
      throw StateError('unexpected read failure');
    }
    return AppResult<String?>.success(preferences[key]);
  }

  @override
  Future<AppResult<void>> savePreference(String key, String value) async {
    if (throwOnWrite) {
      throw StateError('unexpected write failure');
    }
    final failure = writeFailure;
    if (failure != null) {
      return AppResult<void>.failure(failure);
    }
    preferences[key] = value;
    return AppResult<void>.success(null);
  }

  @override
  Future<AppResult<void>> acknowledgeChange(String a, String b) async =>
      AppResult<void>.success(null);
  @override
  Future<AppResult<void>> commitLocalChange(
    LocalRecordChange a,
    PendingChangeRequest b,
  ) async => AppResult<void>.success(null);
  @override
  Future<AppResult<void>> markChangeConflicted(String a) async =>
      AppResult<void>.success(null);
  @override
  Future<AppResult<List<PendingChangeRecord>>> readPendingChanges(
    String a,
  ) async => AppResult<List<PendingChangeRecord>>.success(const []);
  @override
  Future<AppResult<void>> recordConflict(ConflictRecordInput a) async =>
      AppResult<void>.success(null);
  @override
  Future<AppResult<void>> recordConflictAndFinalize({
    required ConflictRecordInput conflict,
    required String operationId,
  }) async => AppResult<void>.success(null);
  @override
  Future<AppResult<void>> recordRecoverableFailure(String a, String b) async =>
      AppResult<void>.success(null);
  @override
  Future<AppResult<MigrationOutcome>> runMigration(int a) async =>
      AppResult<MigrationOutcome>.success(
        MigrationOutcome(completedVersion: a, recovered: false),
      );
}

LocaleCubit _cubit(_LocaleStore store) => LocaleCubit(
  restore: RestoreLocalePreferenceUseCase(localStore: store),
  save: SaveLocalePreferenceUseCase(localStore: store),
);

void main() {
  blocTest<LocaleCubit, LocaleState>(
    'restores the persisted Arabic locale',
    build: () => _cubit(_LocaleStore(preferences: {'locale': 'ar'})),
    act: (cubit) => cubit.restore(),
    expect: () => <Matcher>[
      isA<LocaleReady>()
          .having((state) => state.languageCode, 'languageCode', 'ar')
          .having((state) => state.usedFallback, 'usedFallback', isFalse),
    ],
  );

  blocTest<LocaleCubit, LocaleState>(
    'uses and persists the English fallback for an unsupported language',
    build: () => _cubit(_LocaleStore()),
    act: (cubit) => cubit.selectLanguage('fr'),
    expect: () => <Matcher>[
      isA<LocaleReady>()
          .having((state) => state.languageCode, 'languageCode', 'en')
          .having((state) => state.usedFallback, 'usedFallback', isTrue),
    ],
  );

  blocTest<LocaleCubit, LocaleState>(
    'keeps the active language and exposes a recoverable state when saving fails',
    build: () => _cubit(
      _LocaleStore(
        writeFailure: AppFailure.recoverable(
          category: AppFailureCategory.persistence,
          messageKey: 'foundation.locale.recoverable',
          occurredAt: DateTime.utc(2026),
        ),
      ),
    ),
    act: (cubit) => cubit.selectLanguage('ar'),
    expect: () => <Matcher>[
      isA<LocalePersistenceFailure>()
          .having((state) => state.languageCode, 'languageCode', 'en')
          .having(
            (state) => state.messageKey,
            'messageKey',
            'foundation.locale.recoverable',
          ),
    ],
  );

  blocTest<LocaleCubit, LocaleState>(
    'uses the safe English fallback when restoring throws unexpectedly',
    build: () => _cubit(_LocaleStore(throwOnRead: true)),
    act: (cubit) => cubit.restore(),
    expect: () => <Matcher>[
      isA<LocalePersistenceFailure>()
          .having((state) => state.languageCode, 'languageCode', 'en')
          .having(
            (state) => state.messageKey,
            'messageKey',
            kMessageKeyLocaleRecoverable,
          ),
    ],
  );

  blocTest<LocaleCubit, LocaleState>(
    'keeps the active language when saving throws unexpectedly',
    build: () => _cubit(_LocaleStore(throwOnWrite: true)),
    act: (cubit) => cubit.selectLanguage('ar'),
    expect: () => <Matcher>[
      isA<LocalePersistenceFailure>()
          .having((state) => state.languageCode, 'languageCode', 'en')
          .having(
            (state) => state.messageKey,
            'messageKey',
            kMessageKeyLocaleRecoverable,
          ),
    ],
  );
}

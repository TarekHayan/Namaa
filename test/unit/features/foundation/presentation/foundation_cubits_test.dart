import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/foundation/application/foundation_use_cases.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_state.dart';

/// Fake Cloud Session port backed only by injected results; no SDK types.
class FakeCloudSessionPort implements CloudSessionPort {
  FakeCloudSessionPort({this.initializeResult});

  final AppResult<void>? initializeResult;

  @override
  Future<AppResult<void>> initialize() async =>
      initializeResult ?? AppResult<void>.success(null);

  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult<CloudSyncContext>.success(
        const CloudSyncContext(accountId: 'account-1'),
      );
}

AppFailure _recoverableFailure() => AppFailure.recoverable(
  category: AppFailureCategory.network,
  messageKey: 'foundation.sync.recoverable',
  occurredAt: DateTime.utc(2026, 9, 5),
);

AppFailure _blockingFailure() => AppFailure.blocking(
      category: AppFailureCategory.configuration,
      messageKey: 'foundation.bootstrap.blocking',
      occurredAt: DateTime.utc(2026, 9, 5),
    );

/// Cloud Session port whose initialize resolves only when the caller
/// completes the injected future; used to race bootstrap against close.
class _ControlledCloudSessionPort implements CloudSessionPort {
  _ControlledCloudSessionPort(this._initializeFuture);

  final Future<AppResult<void>> _initializeFuture;

  @override
  Future<AppResult<void>> initialize() => _initializeFuture;

  @override
  Stream<CloudSessionSnapshot> observeSession() => const Stream.empty();

  @override
  Future<AppResult<CloudSyncContext>> obtainSyncContext() async =>
      AppResult<CloudSyncContext>.success(const CloudSyncContext(accountId: 'account-1'));
}

void main() {
  group('FoundationCubit bootstrap', () {
    blocTest<FoundationCubit, FoundationState>(
      'emits ready after a successful bootstrap',
      build: () => FoundationCubit(
        BootstrapUseCase(cloudSession: FakeCloudSessionPort()),
      ),
      act: (cubit) => cubit.bootstrap(),
      expect: () => <Matcher>[isA<FoundationReady>()],
    );

    blocTest<FoundationCubit, FoundationState>(
      'emits a recoverable failure with a localized message key',
      build: () => FoundationCubit(
        BootstrapUseCase(
          cloudSession: FakeCloudSessionPort(
            initializeResult: AppResult<void>.failure(_recoverableFailure()),
          ),
        ),
      ),
      act: (cubit) => cubit.bootstrap(),
      expect: () => <Matcher>[
        isA<FoundationRecoverableFailure>()
            .having(
              (s) => s.messageKey,
              'messageKey',
              kMessageKeyBootstrapRecoverable,
            )
            .having((s) => s.canRetry, 'canRetry', isTrue),
      ],
    );

    blocTest<FoundationCubit, FoundationState>(
      'emits a blocking failure without infrastructure error text',
      build: () => FoundationCubit(
        BootstrapUseCase(
          cloudSession: FakeCloudSessionPort(
            initializeResult: AppResult<void>.failure(_blockingFailure()),
          ),
        ),
      ),
      act: (cubit) => cubit.bootstrap(),
      expect: () => <Matcher>[
        isA<FoundationBlockingFailure>().having(
          (s) => s.messageKey,
          'messageKey',
          kMessageKeyBootstrapBlocking,
        ),
      ],
    );

    test('states never expose infrastructure failure text', () {
      const state = FoundationBlockingFailure(
        messageKey: kMessageKeyBootstrapBlocking,
      );
      expect(state.messageKey.startsWith('foundation.'), isTrue);
    });

    test('closing during a pending bootstrap never throws', () async {
      final completer = Completer<AppResult<void>>();
      final session = _ControlledCloudSessionPort(completer.future);
      final cubit = FoundationCubit(BootstrapUseCase(cloudSession: session));

      final pending = cubit.bootstrap();
      await cubit.close();
      // The use-case outcome arrives after close; the Cubit must discard it
      // instead of emitting into a closed stream.
      completer.complete(AppResult<void>.success(null));
      await pending;

      expect(cubit.isClosed, isTrue);
      expect(cubit.state, isA<FoundationStartup>());
    });
  });

  group('Cubit boundary', () {
    test('presentation state files import no infrastructure libraries', () {
      const forbiddenPrefixes = <String>[
        'package:drift',
        'package:supabase',
        'package:flutter_secure_storage',
        'package:shared_preferences',
        'package:namma_project/core/data',
        'package:namma_project/core/platform',
      ];
      const stateDir = 'lib/features/foundation/presentation/state';
      final violations = <String>[];
      for (final entity in Directory(stateDir).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final directive = RegExp(
          r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
          multiLine: true,
        );
        for (final match in directive.allMatches(entity.readAsStringSync())) {
          final target = match.group(1)!;
          if (forbiddenPrefixes.any(target.startsWith)) {
            violations.add('${entity.path}: $target');
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason: 'Cubits call use cases, not adapters',
      );
    });
  });
}

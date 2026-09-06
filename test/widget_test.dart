import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:namma_project/app/app.dart';
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

FoundationCubit _cubitWith(AppResult<void> initializeResult) => FoundationCubit(
  BootstrapUseCase(
    cloudSession: FakeCloudSessionPort(initializeResult: initializeResult),
  ),
);

void main() {
  testWidgets('boot success reaches the ready shell', (tester) async {
    await tester.pumpWidget(
      FoundationApp(cubitOverride: _cubitWith(AppResult<void>.success(null))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(kFoundationRootReadyKey), findsOneWidget);
    expect(find.byKey(kFoundationRootFailureKey), findsNothing);
  });

  testWidgets('a recoverable boot failure shows a safe retryable shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      FoundationApp(
        cubitOverride: _cubitWith(
          AppResult<void>.failure(
            AppFailure.recoverable(
              category: AppFailureCategory.network,
              messageKey: 'foundation.sync.recoverable',
              occurredAt: DateTime.utc(2026, 9, 5),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(kFoundationRootFailureKey), findsOneWidget);
    expect(find.byKey(kFoundationRootReadyKey), findsNothing);
    expect(find.text(kMessageKeyBootstrapRecoverable), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a boot error renders a safe blocking state, not a crash', (
    tester,
  ) async {
    // No composition configured: resolving the Cubit fails, and the shell
    // must still render a safe failure state.
    await tester.pumpWidget(const FoundationApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(kFoundationRootFailureKey), findsOneWidget);
    expect(find.text(kMessageKeyBootstrapBlocking), findsOneWidget);
  });

  testWidgets('the shell closes the Cubit it resolved from the composition root', (
    tester,
  ) async {
    final getIt = GetIt.instance;
    await getIt.reset();
    addTearDown(() async => getIt.reset());

    late final FoundationCubit shellCubit;
    getIt.registerFactory<FoundationCubit>(() {
      final cubit = FoundationCubit(
        BootstrapUseCase(cloudSession: FakeCloudSessionPort()),
      );
      shellCubit = cubit;
      return cubit;
    });

    await tester.pumpWidget(const FoundationApp());
    await tester.pumpAndSettle();
    expect(shellCubit.isClosed, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(shellCubit.isClosed, isTrue);
  });

  testWidgets('the shell leaves an injected Cubit to its owner', (
    tester,
  ) async {
    final injected = _cubitWith(AppResult<void>.success(null));

    await tester.pumpWidget(FoundationApp(cubitOverride: injected));
    await tester.pumpAndSettle();
    expect(injected.isClosed, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(injected.isClosed, isFalse);
  });
}

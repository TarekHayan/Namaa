import 'package:flutter_test/flutter_test.dart';
import 'package:namma_project/app/composition/today_scope_resolver.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/features/today/domain/today_scope.dart';

import '../../../support/today_fixtures.dart';

void main() {
  test('preview always binds the two existing durable owner IDs', () async {
    final resolver = TodayScopeResolver.preview();
    final scope = await resolver.resolveInitial();
    expect(scope, isNotNull);
    expect(scope!.mode, TodayScopeMode.preview);
    expect(scope.taskOwnerId, TodayFixtureAccounts.tasksMapsXpPreview);
    expect(scope.xpOwnerId, TodayFixtureAccounts.tasksMapsXpPreview);
    expect(scope.habitOwnerId, TodayFixtureAccounts.habitsPreview);
    expect(scope.taskOwnerId, isNot(scope.habitOwnerId));
  });

  test('resolved real account uses one owner for all sources', () async {
    final session = TodayControlledSession(
      initialAccountId: TodayFixtureAccounts.accountA,
    );
    addTearDown(session.close);
    final resolver = TodayScopeResolver.account(session);
    final scope = await resolver.resolveSnapshot(
      const CloudSessionSnapshot(
        status: CloudSessionStatus.signedIn,
        accountId: TodayFixtureAccounts.accountA,
      ),
    );
    expect(scope?.mode, TodayScopeMode.account);
    expect(scope?.taskOwnerId, TodayFixtureAccounts.accountA);
    expect(scope?.habitOwnerId, TodayFixtureAccounts.accountA);
    expect(scope?.xpOwnerId, TodayFixtureAccounts.accountA);
  });

  test('unknown and signed-out states clear any previous account', () async {
    final session = TodayControlledSession(
      initialAccountId: TodayFixtureAccounts.accountA,
    );
    addTearDown(session.close);
    final resolver = TodayScopeResolver.account(session);
    expect(await resolver.resolveInitial(), isNotNull);
    expect(
      await resolver.resolveSnapshot(
        const CloudSessionSnapshot(status: CloudSessionStatus.unknown),
      ),
      isNull,
    );
    expect(resolver.current, isNull);
    expect(
      await resolver.resolveSnapshot(
        const CloudSessionSnapshot(status: CloudSessionStatus.signedOut),
      ),
      isNull,
    );
    expect(resolver.current, isNull);
  });

  test('a mismatched account context cannot bind owners', () async {
    final session = TodayControlledSession(
      initialAccountId: TodayFixtureAccounts.accountB,
    );
    addTearDown(session.close);
    final resolver = TodayScopeResolver.account(session);
    final scope = await resolver.resolveSnapshot(
      const CloudSessionSnapshot(
        status: CloudSessionStatus.signedIn,
        accountId: TodayFixtureAccounts.accountA,
      ),
    );
    expect(scope, isNull);
    expect(resolver.current, isNull);
  });

  test(
    'real resolver rejects a preview ID supplied by its session',
    () async {
      final session = TodayControlledSession(
        initialAccountId: TodayFixtureAccounts.tasksMapsXpPreview,
      );
      addTearDown(session.close);
      final resolver = TodayScopeResolver.account(session);
      expect(await resolver.resolveInitial(), isNull);
      expect(resolver.current, isNull);
    },
  );

  test('late initial context cannot restore a signed-out scope', () async {
    final session = TodayControlledSession(
      initialAccountId: TodayFixtureAccounts.accountA,
    );
    addTearDown(session.close);
    final resolver = TodayScopeResolver.account(session);
    session.holdContext();
    final oldLookup = resolver.resolveInitial();
    expect(
      await resolver.resolveSnapshot(
        const CloudSessionSnapshot(status: CloudSessionStatus.signedOut),
      ),
      isNull,
    );
    session.releaseContextFor(TodayFixtureAccounts.accountA);
    expect(await oldLookup, isNull);
    expect(resolver.current, isNull);
  });
}

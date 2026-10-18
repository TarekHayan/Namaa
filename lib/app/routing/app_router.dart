/// Foundation root-route registry and authenticated feature boundaries.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';

/// The only registered route in the Foundation scope.
const String kFoundationRootRoute = '/';

/// Account-scoped Tasks entry point.
const String kTasksRoute = '/tasks';
const String kHabitsRoute = '/habits';

/// Key used by tests and diagnostics to identify handled route failures.
const Key kFoundationUnknownRouteKey = Key('foundation_unknown_route');

/// Keys used to verify that account data is never opened before a session is
/// resolved.
const Key kTasksRouteLoadingKey = Key('tasks_route_loading');
const Key kTasksRouteSignedOutKey = Key('tasks_route_signed_out');
const Key kHabitsRouteLoadingKey = Key('habits_route_loading');
const Key kHabitsRouteSignedOutKey = Key('habits_route_signed_out');

typedef AuthenticatedTasksBuilder =
    Widget Function(BuildContext context, String accountId);
typedef AuthenticatedHabitsBuilder =
    Widget Function(BuildContext context, String accountId);

/// Owns Foundation routing only. Future features register their own entries;
/// no product feature route or screen is created here.
class FoundationAppRouter {
  FoundationAppRouter({
    required WidgetBuilder rootBuilder,
    CloudSessionPort? cloudSession,
    AuthenticatedTasksBuilder? tasksBuilder,
    CloudSessionPort? habitsSession,
    AuthenticatedHabitsBuilder? habitsBuilder,
  }) : router = GoRouter(
         initialLocation: kFoundationRootRoute,
         routes: _routes(
           rootBuilder,
           cloudSession,
           tasksBuilder,
           habitsSession,
           habitsBuilder,
         ),
         errorBuilder: (context, state) => const _UnknownRouteBoundary(),
       );

  final GoRouter router;

  void go(String location) => router.go(location);

  void dispose() => router.dispose();

  static List<RouteBase> _routes(
    WidgetBuilder rootBuilder,
    CloudSessionPort? cloudSession,
    AuthenticatedTasksBuilder? tasksBuilder,
    CloudSessionPort? habitsSession,
    AuthenticatedHabitsBuilder? habitsBuilder,
  ) => <RouteBase>[
    GoRoute(
      path: kFoundationRootRoute,
      name: 'foundation-root',
      builder: (context, _) => rootBuilder(context),
    ),
    if (cloudSession != null && tasksBuilder != null)
      GoRoute(
        path: kTasksRoute,
        name: 'tasks',
        builder: (context, _) => _TasksRouteGate(
          cloudSession: cloudSession,
          tasksBuilder: tasksBuilder,
        ),
      ),
    if (habitsSession != null && habitsBuilder != null)
      GoRoute(
        path: kHabitsRoute,
        name: 'habits',
        builder: (context, _) => _TasksRouteGate(
          cloudSession: habitsSession,
          tasksBuilder: habitsBuilder,
          habits: true,
        ),
      ),
  ];
}

/// Resolves the non-secret account identity before creating the Tasks graph.
/// A signed-out session stays at a localized boundary and cannot resolve an
/// account-scoped repository stream.
class _TasksRouteGate extends StatefulWidget {
  const _TasksRouteGate({
    required this.cloudSession,
    required this.tasksBuilder,
    this.habits = false,
  });

  final CloudSessionPort cloudSession;
  final AuthenticatedTasksBuilder tasksBuilder;
  final bool habits;

  @override
  State<_TasksRouteGate> createState() => _TasksRouteGateState();
}

class _TasksRouteGateState extends State<_TasksRouteGate> {
  StreamSubscription<CloudSessionSnapshot>? _subscription;
  CloudSessionStatus _status = CloudSessionStatus.unknown;
  String? _accountId;
  int _sessionRevision = 0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.cloudSession.observeSession().listen(
      _applySnapshot,
      onError: (_, _) => _applySignedOut(),
    );
    unawaited(_resolveInitialSession());
  }

  Future<void> _resolveInitialSession() async {
    final revision = _sessionRevision;
    final result = await widget.cloudSession.obtainSyncContext();
    if (!mounted || revision != _sessionRevision) {
      return;
    }
    final accountId = result.valueOrNull?.accountId;
    if (accountId == null || accountId.isEmpty) {
      _applySignedOut();
      return;
    }
    setState(() {
      _status = CloudSessionStatus.signedIn;
      _accountId = accountId;
    });
  }

  void _applySnapshot(CloudSessionSnapshot snapshot) {
    if (!mounted) {
      return;
    }
    _sessionRevision++;
    final accountId = snapshot.accountId;
    if (snapshot.status != CloudSessionStatus.signedIn ||
        accountId == null ||
        accountId.isEmpty) {
      if (snapshot.status == CloudSessionStatus.unknown) {
        setState(() {
          _status = CloudSessionStatus.unknown;
          _accountId = null;
        });
        // An initial unknown event can invalidate the first session lookup.
        // Resolve again so a signed-out user does not remain on the spinner.
        unawaited(_resolveInitialSession());
      } else {
        _applySignedOut();
      }
      return;
    }
    setState(() {
      _status = CloudSessionStatus.signedIn;
      _accountId = accountId;
    });
  }

  void _applySignedOut() {
    if (!mounted) {
      return;
    }
    setState(() {
      _status = CloudSessionStatus.signedOut;
      _accountId = null;
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountId = _accountId;
    if (_status == CloudSessionStatus.signedIn && accountId != null) {
      return widget.tasksBuilder(context, accountId);
    }
    if (_status == CloudSessionStatus.signedOut) {
      return Scaffold(
        key: widget.habits ? kHabitsRouteSignedOutKey : kTasksRouteSignedOutKey,
        body: Center(
          child: Text(
            widget.habits
                ? FoundationLocalizations.of(context).habitsSignInRequired
                : FoundationLocalizations.of(context).tasksSignInRequired,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Scaffold(
      key: widget.habits ? kHabitsRouteLoadingKey : kTasksRouteLoadingKey,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Safe, localized presentation for an unresolved route.
class _UnknownRouteBoundary extends StatelessWidget {
  const _UnknownRouteBoundary();

  @override
  Widget build(BuildContext context) => Scaffold(
    key: kFoundationUnknownRouteKey,
    body: Center(
      child: Text(
        FoundationLocalizations.of(context).foundationRouteUnavailable,
      ),
    ),
  );
}

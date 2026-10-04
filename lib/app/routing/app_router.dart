/// Foundation root-route registry and unknown-route boundary.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';

/// The only registered route in the Foundation scope.
const String kFoundationRootRoute = '/';

/// Key used by tests and diagnostics to identify handled route failures.
const Key kFoundationUnknownRouteKey = Key('foundation_unknown_route');

/// Owns Foundation routing only. Future features register their own entries;
/// no product feature route or screen is created here.
class FoundationAppRouter {
  FoundationAppRouter({required WidgetBuilder rootBuilder})
    : router = GoRouter(
        initialLocation: kFoundationRootRoute,
        routes: <RouteBase>[
          GoRoute(
            path: kFoundationRootRoute,
            name: 'foundation-root',
            builder: (context, _) => rootBuilder(context),
          ),
        ],
        errorBuilder: (context, state) => const _UnknownRouteBoundary(),
      );

  final GoRouter router;

  void go(String location) => router.go(location);

  void dispose() => router.dispose();
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

/// The minimal Foundation app shell.
///
/// No product screens: the shell only represents bootstrap progress, the
/// ready root, and safe failure states. Boot errors surface as safe startup
/// state rather than uncaught exceptions
/// (specs/001-namaa-foundation/contracts/application-boundaries.md).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:namma_project/app/composition/habits_preview_adapters.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/habits_strings_adapter.dart';
import 'package:namma_project/app/l10n/tasks_strings_adapter.dart';
import 'package:namma_project/app/routing/app_router.dart';
import 'package:namma_project/app/theme/app_theme.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_state.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/synchronization_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/theme_cubit.dart';
import 'package:namma_project/features/habits/presentation/habits_cubit.dart';
import 'package:namma_project/features/habits/presentation/habits_screen.dart';
import 'package:namma_project/features/tasks/presentation/tasks_cubit.dart';
import 'package:namma_project/features/tasks/presentation/tasks_screen.dart';

export 'theme/app_theme.dart' show kProjectFontFamily;

/// Keys used by tests to locate the shell states.
const Key kFoundationRootStartupKey = Key('foundation_root_startup');
const Key kFoundationRootReadyKey = Key('foundation_root_ready');
const Key kFoundationRootFailureKey = Key('foundation_root_failure');
const Key kFoundationTasksNavigationKey = Key('foundation_tasks_navigation');
const Key kFoundationHabitsNavigationKey = Key('foundation_habits_navigation');

class FoundationApp extends StatefulWidget {
  const FoundationApp({
    super.key,
    this.cubitOverride,
    this.localeCubitOverride,
    this.themeCubitOverride,
    this.synchronizationCubitOverride,
  });

  /// Optional direct injection for widget tests; when null, the Cubit is
  /// resolved from the composition root.
  final FoundationCubit? cubitOverride;

  /// Optional locale binding for widget tests. Production resolves it from
  /// the composition root and restores the persisted Foundation preference.
  final LocaleCubit? localeCubitOverride;

  /// Optional appearance binding for widget tests. Production resolves it
  /// from the composition root and restores the persisted preference.
  final ThemeCubit? themeCubitOverride;

  /// Optional synchronization binding for widget tests. Production resolves it
  /// from the composition root and starts it after a successful bootstrap.
  final SynchronizationCubit? synchronizationCubitOverride;

  @override
  State<FoundationApp> createState() => _FoundationAppState();
}

class _FoundationAppState extends State<FoundationApp> {
  FoundationCubit? _cubit;
  LocaleCubit? _localeCubit;
  ThemeCubit? _themeCubit;
  SynchronizationCubit? _synchronizationCubit;

  /// True only when this shell resolved the Cubit from the composition root.
  ///
  /// An injected `cubitOverride` stays owned by its caller (BlocProvider.value
  /// semantics); only a shell-resolved Cubit is closed here.
  bool _ownsCubit = false;
  bool _ownsLocaleCubit = false;
  bool _ownsThemeCubit = false;
  bool _ownsSynchronizationCubit = false;

  /// Set when the composition root itself cannot provide a Cubit; the shell
  /// then renders a safe blocking failure instead of crashing.
  bool _bootFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  @override
  void dispose() {
    if (_ownsCubit) {
      unawaited(_cubit?.close());
      _cubit = null;
    }
    if (_ownsSynchronizationCubit) {
      unawaited(_synchronizationCubit?.close());
      _synchronizationCubit = null;
    }
    if (_ownsLocaleCubit) {
      unawaited(_localeCubit?.close());
      _localeCubit = null;
    }
    if (_ownsThemeCubit) {
      unawaited(_themeCubit?.close());
      _themeCubit = null;
    }
    super.dispose();
  }

  Future<void> _boot() async {
    FoundationCubit? cubit;
    try {
      cubit = widget.cubitOverride ?? GetIt.instance<FoundationCubit>();
    } catch (_) {
      if (mounted) {
        setState(() => _bootFailed = true);
      }
      return;
    }
    final bool owns = !identical(cubit, widget.cubitOverride);
    if (!mounted) {
      // The shell unmounted before bootstrap; release the instance we own.
      if (owns) {
        unawaited(cubit.close());
      }
      return;
    }
    _ownsCubit = owns;
    setState(() => _cubit = cubit);
    await _restoreLocale();
    await _restoreTheme();
    // Bootstrap failures are mapped to failure states inside the Cubit.
    await cubit.bootstrap();
    if (!mounted || cubit.state is! FoundationReady) {
      return;
    }

    // A caller that injects only the bootstrap Cubit is exercising the shell
    // in isolation. The production path never takes this branch: it resolves
    // both Cubits from the composition root.
    if (widget.cubitOverride != null &&
        widget.synchronizationCubitOverride == null) {
      return;
    }

    try {
      final synchronizationCubit =
          widget.synchronizationCubitOverride ??
          GetIt.instance<SynchronizationCubit>();
      _ownsSynchronizationCubit = !identical(
        synchronizationCubit,
        widget.synchronizationCubitOverride,
      );
      _synchronizationCubit = synchronizationCubit;
      synchronizationCubit.start();
    } catch (_) {
      // A configured Foundation must start its retry orchestration. Treat a
      // missing binding as a safe startup failure instead of silently running
      // a local-only shell that never synchronizes.
      if (mounted) {
        setState(() => _bootFailed = true);
      }
    }
  }

  /// Resolves and restores the app-wide locale independently from bootstrap.
  ///
  /// A missing locale registration must not stop the safe Foundation shell
  /// from launching; English remains the deterministic root fallback until
  /// the application composition is available.
  Future<void> _restoreLocale() async {
    LocaleCubit? cubit;
    try {
      cubit = widget.localeCubitOverride ?? GetIt.instance<LocaleCubit>();
    } catch (_) {
      return;
    }
    final owns = !identical(cubit, widget.localeCubitOverride);
    if (!mounted) {
      if (owns) {
        unawaited(cubit.close());
      }
      return;
    }
    _ownsLocaleCubit = owns;
    setState(() => _localeCubit = cubit);
    await cubit.restore();
  }

  /// Resolves the app-wide appearance independently from bootstrap.
  ///
  /// A missing registration leaves the root in system appearance, so a
  /// composition problem never blocks a safe Foundation launch.
  Future<void> _restoreTheme() async {
    ThemeCubit? cubit;
    try {
      cubit = widget.themeCubitOverride ?? GetIt.instance<ThemeCubit>();
    } catch (_) {
      return;
    }
    final owns = !identical(cubit, widget.themeCubitOverride);
    if (!mounted) {
      if (owns) {
        unawaited(cubit.close());
      }
      return;
    }
    _ownsThemeCubit = owns;
    setState(() => _themeCubit = cubit);
    await cubit.restore();
  }

  @override
  Widget build(BuildContext context) {
    final home = _bootFailed
        ? const _SafeFailureShell(messageKey: kMessageKeyBootstrapBlocking)
        : _cubit == null
        ? const _StartupShell()
        : BlocProvider.value(value: _cubit!, child: const _FoundationShell());
    final localeCubit = _localeCubit;
    final themeCubit = _themeCubit;
    Widget appFor(Locale locale, ThemeMode themeMode) =>
        _LocalizedFoundationApp(
          locale: locale,
          themeMode: themeMode,
          home: home,
        );

    if (localeCubit == null && themeCubit == null) {
      return appFor(const Locale('en'), ThemeMode.system);
    }
    if (localeCubit == null) {
      return BlocProvider.value(
        value: themeCubit!,
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) =>
              appFor(const Locale('en'), state.themeMode),
        ),
      );
    }
    if (themeCubit == null) {
      return BlocProvider.value(
        value: localeCubit,
        child: BlocBuilder<LocaleCubit, LocaleState>(
          builder: (context, state) =>
              appFor(Locale(state.languageCode), ThemeMode.system),
        ),
      );
    }
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<LocaleCubit>.value(value: localeCubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) => BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) =>
              appFor(Locale(localeState.languageCode), themeState.themeMode),
        ),
      ),
    );
  }
}

/// The root MaterialApp configuration for the two approved Foundation
/// languages. Flutter's localization delegates provide RTL/LTR directionality
/// for the whole tree; individual widgets never force direction manually.
class _LocalizedFoundationApp extends StatefulWidget {
  const _LocalizedFoundationApp({
    required this.locale,
    required this.themeMode,
    required this.home,
  });

  final Locale locale;
  final ThemeMode themeMode;
  final Widget home;

  @override
  State<_LocalizedFoundationApp> createState() =>
      _LocalizedFoundationAppState();
}

class _LocalizedFoundationAppState extends State<_LocalizedFoundationApp> {
  late final FoundationAppRouter _router;

  @override
  void initState() {
    super.initState();
    final getIt = GetIt.instance;
    final tasksAvailable =
        getIt.isRegistered<CloudSessionPort>() &&
        getIt.isRegistered<TasksCubit>();
    final habitsAvailable =
        getIt.isRegistered<HabitsCubit>() &&
        getIt.isRegistered<CloudSessionPort>();
    _router = FoundationAppRouter(
      rootBuilder: (_) => widget.home,
      cloudSession: tasksAvailable ? getIt<CloudSessionPort>() : null,
      tasksBuilder: tasksAvailable
          ? (_, accountId) => _TasksRouteScope(accountId: accountId)
          : null,
      habitsSession: habitsAvailable
          ? (getIt.isRegistered<HabitsPreviewSession>()
                ? getIt<HabitsPreviewSession>()
                : getIt<CloudSessionPort>())
          : null,
      habitsBuilder: habitsAvailable
          ? (_, accountId) => _HabitsRouteScope(
              key: ValueKey(accountId),
              accountId: accountId,
            )
          : null,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    locale: widget.locale,
    supportedLocales: FoundationLocalizations.supportedLocales,
    localizationsDelegates: FoundationLocalizations.localizationsDelegates,
    onGenerateTitle: (context) => FoundationLocalizations.of(context).appTitle,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: widget.themeMode,
    routerConfig: _router.router,
  );
}

class _FoundationShell extends StatelessWidget {
  const _FoundationShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FoundationCubit, FoundationState>(
        builder: (context, state) => switch (state) {
          FoundationStartup() => const _StartupShell(),
          FoundationReady() => const _ReadyShell(),
          FoundationRecoverableFailure(:final messageKey) => _SafeFailureShell(
            messageKey: messageKey,
            canRetry: state.canRetry,
          ),
          FoundationBlockingFailure(:final messageKey) => _SafeFailureShell(
            messageKey: messageKey,
          ),
        },
      ),
    );
  }
}

class _ReadyShell extends StatelessWidget {
  const _ReadyShell();

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    key: kFoundationRootReadyKey,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(FoundationLocalizations.of(context).foundationReady),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: kFoundationTasksNavigationKey,
            onPressed: () => GoRouter.of(context).go(kTasksRoute),
            icon: const Icon(Icons.task_alt),
            label: Text(FoundationLocalizations.of(context).tasksTitle),
          ),
          if (GetIt.instance.isRegistered<HabitsCubit>()) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              key: kFoundationHabitsNavigationKey,
              onPressed: () => GoRouter.of(context).go(kHabitsRoute),
              icon: const Icon(Icons.repeat),
              label: Text(FoundationLocalizations.of(context).habitsTitle),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Owns the feature Cubit for one authenticated Tasks route visit. The Cubit
/// is created only after the router has resolved a non-secret account ID and
/// is closed when the route leaves the tree.
class _TasksRouteScope extends StatefulWidget {
  const _TasksRouteScope({required this.accountId});

  final String accountId;

  @override
  State<_TasksRouteScope> createState() => _TasksRouteScopeState();
}

class _TasksRouteScopeState extends State<_TasksRouteScope> {
  late final TasksCubit _cubit = GetIt.instance<TasksCubit>();

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TasksScreen(
    cubit: _cubit,
    accountId: widget.accountId,
    stringsResolver: resolveTasksStrings,
    session: GetIt.instance<CloudSessionPort>(),
  );
}

/// Creates an account-scoped controller only after the router resolves the
/// active Habits owner. A route visit owns and closes its controller.
class _HabitsRouteScope extends StatefulWidget {
  const _HabitsRouteScope({super.key, required this.accountId});
  final String accountId;
  @override
  State<_HabitsRouteScope> createState() => _HabitsRouteScopeState();
}

class _HabitsRouteScopeState extends State<_HabitsRouteScope> {
  late final HabitsCubit _cubit = GetIt.instance<HabitsCubit>();

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HabitsScreen(
    cubit: _cubit,
    accountId: widget.accountId,
    stringsResolver: resolveHabitsStrings,
  );
}

class _StartupShell extends StatelessWidget {
  const _StartupShell();

  @override
  Widget build(BuildContext context) => const SizedBox.expand(
    key: kFoundationRootStartupKey,
    child: Center(child: CircularProgressIndicator()),
  );
}

/// The safe failure outcome: localized message key only, retry when the
/// failure is recoverable, never infrastructure error text.
class _SafeFailureShell extends StatelessWidget {
  const _SafeFailureShell({required this.messageKey, this.canRetry = false});

  final String messageKey;
  final bool canRetry;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    key: kFoundationRootFailureKey,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_localizedFoundationMessage(context, messageKey)),
          if (canRetry)
            TextButton(
              onPressed: () => context.read<FoundationCubit>().bootstrap(),
              child: Text(FoundationLocalizations.of(context).retry),
            ),
        ],
      ),
    ),
  );
}

String _localizedFoundationMessage(BuildContext context, String messageKey) {
  final l10n = FoundationLocalizations.of(context);
  return switch (messageKey) {
    kMessageKeyBootstrapRecoverable => l10n.foundationBootstrapRecoverable,
    kMessageKeyBootstrapBlocking => l10n.foundationBootstrapBlocking,
    kMessageKeyLocaleRecoverable => l10n.foundationLocaleRecoverable,
    kMessageKeyThemeRecoverable => l10n.foundationThemeRecoverable,
    _ => l10n.foundationGenericFailure,
  };
}

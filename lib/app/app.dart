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
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/foundation_state.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/synchronization_cubit.dart';

/// Keys used by tests to locate the shell states.
const Key kFoundationRootStartupKey = Key('foundation_root_startup');
const Key kFoundationRootReadyKey = Key('foundation_root_ready');
const Key kFoundationRootFailureKey = Key('foundation_root_failure');

/// The Thmanyah Sans family is the default UI typeface for every app theme.
const String kProjectFontFamily = 'ThmanyahSans';

class FoundationApp extends StatefulWidget {
  const FoundationApp({
    super.key,
    this.cubitOverride,
    this.localeCubitOverride,
    this.synchronizationCubitOverride,
  });

  /// Optional direct injection for widget tests; when null, the Cubit is
  /// resolved from the composition root.
  final FoundationCubit? cubitOverride;

  /// Optional locale binding for widget tests. Production resolves it from
  /// the composition root and restores the persisted Foundation preference.
  final LocaleCubit? localeCubitOverride;

  /// Optional synchronization binding for widget tests. Production resolves it
  /// from the composition root and starts it after a successful bootstrap.
  final SynchronizationCubit? synchronizationCubitOverride;

  @override
  State<FoundationApp> createState() => _FoundationAppState();
}

class _FoundationAppState extends State<FoundationApp> {
  FoundationCubit? _cubit;
  LocaleCubit? _localeCubit;
  SynchronizationCubit? _synchronizationCubit;

  /// True only when this shell resolved the Cubit from the composition root.
  ///
  /// An injected `cubitOverride` stays owned by its caller (BlocProvider.value
  /// semantics); only a shell-resolved Cubit is closed here.
  bool _ownsCubit = false;
  bool _ownsLocaleCubit = false;
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

  @override
  Widget build(BuildContext context) {
    final home = _bootFailed
        ? const _SafeFailureShell(messageKey: kMessageKeyBootstrapBlocking)
        : _cubit == null
        ? const _StartupShell()
        : BlocProvider.value(value: _cubit!, child: const _FoundationShell());
    final localeCubit = _localeCubit;
    if (localeCubit == null) {
      return _LocalizedFoundationApp(locale: const Locale('en'), home: home);
    }
    return BlocProvider.value(
      value: localeCubit,
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, state) => _LocalizedFoundationApp(
          locale: Locale(state.languageCode),
          home: home,
        ),
      ),
    );
  }
}

/// The root MaterialApp configuration for the two approved Foundation
/// languages. Flutter's localization delegates provide RTL/LTR directionality
/// for the whole tree; individual widgets never force direction manually.
class _LocalizedFoundationApp extends StatelessWidget {
  const _LocalizedFoundationApp({required this.locale, required this.home});

  final Locale locale;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      supportedLocales: FoundationLocalizations.supportedLocales,
      localizationsDelegates: FoundationLocalizations.localizationsDelegates,
      onGenerateTitle: (context) =>
          FoundationLocalizations.of(context).appTitle,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: kProjectFontFamily,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: kProjectFontFamily,
      ),
      home: home,
    );
  }
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
      child: Text(FoundationLocalizations.of(context).foundationReady),
    ),
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
    _ => l10n.foundationGenericFailure,
  };
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/prayer_localization_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_status_view.dart';

import '../application/prayer_device_location_port.dart';
import '../application/prayer_preferences_commands.dart';
import '../domain/prayer_conflict_evidence.dart';
import '../domain/prayer_day_snapshot.dart';
import '../domain/prayer_preferences.dart';
import 'prayer_conflicts_view.dart';
import 'prayer_cubit.dart';
import 'prayer_settings_sheet.dart';
import 'prayer_state.dart';
import 'widgets/prayer_guidance_section.dart';
import 'widgets/prayer_header.dart';
import 'widgets/prayer_schedule_list.dart';
import 'widgets/prayer_supplementary_times.dart';

class PrayerScreen extends StatelessWidget {
  const PrayerScreen({
    super.key,
    required this.ownerId,
    required this.cubit,
    required this.commands,
    this.location,
    this.conflicts,
  });
  final String ownerId;
  final PrayerCubit cubit;
  final PrayerPreferencesCommands commands;
  final PrayerDeviceLocationPort? location;
  final Stream<List<PrayerConflictEvidence>>? conflicts;

  void _edit(BuildContext context, PrayerPreferences current) {
    Widget sheet(BuildContext sheetContext, {required bool asSheet}) =>
        PrayerSettingsSheet(
          ownerId: ownerId,
          commands: commands,
          current: current,
          asSheet: asSheet,
          onSaved: () => Navigator.pop(sheetContext),
          location: location == null
              ? null
              : _LocationAction(
                  ownerId: ownerId,
                  location: location!,
                  commands: commands,
                  current: current,
                  onSaved: () => Navigator.pop(sheetContext),
                ),
        );
    if (MediaQuery.sizeOf(context).width < 600) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => sheet(sheetContext, asSheet: true),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => sheet(dialogContext, asSheet: false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    // Like every other feature route, the screen owns its Material surface.
    // Without it, unstyled text falls back to Flutter's debug style (large
    // red text with a yellow underline) inside the navigation shell.
    return Scaffold(backgroundColor: colors.background, body: _body(context));
  }

  Widget _body(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    return BlocBuilder<PrayerCubit, PrayerState>(
      bloc: cubit,
      builder: (context, result) {
        if (result.failed) {
          return AppStatusView.error(
            title: copy.prayerScheduleUnavailable,
            actionLabel: copy.retry,
            onAction: cubit.retry,
          );
        }
        if (result.snapshot == null) {
          return AppStatusView.loading(message: copy.todayLoading);
        }
        final snapshot = result.snapshot!;
        if (snapshot.health == PrayerSnapshotHealth.setupRequired) {
          // Times come from the device location only; there is no city
          // search to fall back to.
          if (location != null) {
            return _LocationSetup(
              ownerId: ownerId,
              location: location!,
              commands: commands,
            );
          }
          return AppStatusView.error(
            title: copy.prayerSetupTitle,
            message: copy.prayerSetupBody,
          );
        }
        if (snapshot.preferences == null) {
          return AppStatusView.error(title: copy.prayerScheduleUnavailable);
        }
        final pref = snapshot.preferences!;
        final schedule = snapshot.schedule;
        final colors = Theme.of(context).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light;
        final locale = Localizations.localeOf(context).languageCode;
        final projection = snapshot.projection;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrayerHeader(
                      city: pref.city.provider == 'device'
                          ? copy.prayerCurrentLocation
                          : '${pref.city.name}, ${pref.city.countryName}',
                      details:
                          '${prayerLocalDateLabel(snapshot.localDate!, locale)} · ${pref.city.timeZoneId} · ${prayerMethodLabel(copy, pref.calculationMethod)}',
                      // Only the labelled local fallback needs a warning;
                      // the cached annual timetable is the normal source.
                      source:
                          schedule != null &&
                              !schedule.provenance.startsWith('AlAdhan')
                          ? copy.prayerSourceLocal
                          : null,
                      completedCount: snapshot.completedCount,
                      actions: [
                        IconButton(
                          key: const Key('prayer_settings'),
                          tooltip: copy.prayerCityEdit,
                          icon: const Icon(Icons.tune_rounded),
                          color: colors.textSecondary,
                          onPressed: () => _edit(context, pref),
                        ),
                      ],
                    ),
                    // A device location is re-checked quietly on each visit;
                    // once granted, it needs no permanent on-screen control.
                    if (location != null && pref.city.provider == 'device')
                      _LocationAction(
                        ownerId: ownerId,
                        location: location!,
                        commands: commands,
                        current: pref,
                        autoStart: true,
                        silent: true,
                      ),
                    const SizedBox(height: 16),
                    if (schedule == null) ...[
                      AppStatusView.error(
                        title: copy.prayerScheduleUnavailable,
                        actionLabel: copy.retry,
                        onAction: cubit.retry,
                      ),
                      const SizedBox(height: 16),
                    ],
                    PrayerScheduleList(
                      schedule: schedule,
                      timeZoneId: pref.city.timeZoneId,
                      reports: snapshot.reports,
                      actions: result.actions,
                      onStatusChanged: cubit.setStatus,
                    ),
                    const SizedBox(height: 4),
                    PrayerSupplementaryTimes(
                      timeZoneId: pref.city.timeZoneId,
                      sunriseUtc: schedule?.sunriseUtc,
                      middleOfNightUtc: projection?.middleOfNightUtc,
                      lastThirdUtc: projection?.lastThirdUtc,
                    ),
                    const SizedBox(height: 16),
                    if (conflicts != null) ...[
                      PrayerConflictsView(conflicts: conflicts!),
                      const SizedBox(height: 16),
                    ],
                    const PrayerGuidanceSection(),
                    const SizedBox(height: 16),
                    Text(
                      copy.prayerAttribution,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LocationSetup extends StatelessWidget {
  const _LocationSetup({
    required this.ownerId,
    required this.location,
    required this.commands,
  });
  final String ownerId;
  final PrayerDeviceLocationPort location;
  final PrayerPreferencesCommands commands;

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.prayerSetupTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  copy.prayerSetupBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                _LocationAction(
                  ownerId: ownerId,
                  location: location,
                  commands: commands,
                  autoStart: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationAction extends StatefulWidget {
  const _LocationAction({
    required this.ownerId,
    required this.location,
    required this.commands,
    this.current,
    this.autoStart = false,
    this.silent = false,
    this.onSaved,
  });
  final String ownerId;
  final PrayerDeviceLocationPort location;
  final PrayerPreferencesCommands commands;
  final PrayerPreferences? current;
  final bool autoStart;

  /// Re-check without any visible control (a saved device location).
  final bool silent;

  /// Called once the device location is saved or confirmed unchanged.
  final VoidCallback? onSaved;

  @override
  State<_LocationAction> createState() => _LocationActionState();
}

class _LocationActionState extends State<_LocationAction>
    with WidgetsBindingObserver {
  bool _busy = false;
  PrayerLocationProblem? _problem;
  bool _openedSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_useLocation());
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from the system settings page retries once by itself.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openedSettings) {
      _openedSettings = false;
      unawaited(_useLocation());
    }
  }

  Future<void> _openSettings(PrayerLocationProblem problem) async {
    _openedSettings = true;
    await widget.location.openSettings(problem);
  }

  Future<void> _useLocation() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final resolved = await widget.location.locate();
      if (!mounted) return;
      final current = widget.current?.city;
      if (current?.provider == 'device' &&
          (current!.latitude - resolved.city.latitude).abs() < 0.025 &&
          (current.longitude - resolved.city.longitude).abs() < 0.025 &&
          current.timeZoneId == resolved.city.timeZoneId) {
        widget.onSaved?.call();
        return;
      }
      final saved = await widget.commands.confirm(
        ownerId: widget.ownerId,
        city: resolved.city,
        method: widget.current?.calculationMethod ?? resolved.suggestedMethod,
        expectedRevision: widget.current?.revision,
        nowUtc: DateTime.now().toUtc(),
      );
      if (saved.valueOrNull == null) {
        throw const PrayerLocationException(PrayerLocationProblem.unavailable);
      }
      if (mounted) widget.onSaved?.call();
    } on PrayerLocationException catch (error) {
      if (mounted) setState(() => _problem = error.problem);
    } catch (_) {
      if (mounted) {
        setState(() => _problem = PrayerLocationProblem.unavailable);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A failed quiet re-check keeps the saved location; nothing to show.
    if (widget.silent) return const SizedBox.shrink();
    final copy = FoundationLocalizations.of(context);
    final error = switch (_problem) {
      PrayerLocationProblem.serviceDisabled => copy.prayerLocationDisabled,
      PrayerLocationProblem.permissionDenied => copy.prayerLocationDenied,
      PrayerLocationProblem.unavailable => copy.prayerLocationUnavailable,
      null => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          key: const Key('prayer_use_location'),
          label: _problem == null
              ? copy.prayerUseLocation
              : copy.prayerLocationRetry,
          icon: Icons.my_location,
          loading: _busy,
          onPressed: _busy ? null : _useLocation,
        ),
        if (_problem == PrayerLocationProblem.permissionDenied ||
            _problem == PrayerLocationProblem.serviceDisabled) ...[
          const SizedBox(height: 8),
          AppButton(
            key: const Key('prayer_open_settings'),
            label: copy.prayerOpenSettings,
            icon: Icons.settings_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: _busy ? null : () => _openSettings(_problem!),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

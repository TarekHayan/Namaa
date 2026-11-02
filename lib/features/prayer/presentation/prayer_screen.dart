import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/prayer_localization_adapter.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_status_view.dart';

import '../application/city_search_port.dart';
import '../application/prayer_device_location_port.dart';
import '../application/prayer_preferences_commands.dart';
import '../domain/prayer_day_snapshot.dart';
import '../domain/prayer_preferences.dart';
import 'prayer_city_editor.dart';
import 'prayer_cubit.dart';
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
    required this.search,
    required this.commands,
    this.location,
  });
  final String ownerId;
  final PrayerCubit cubit;
  final CitySearchPort search;
  final PrayerPreferencesCommands commands;
  final PrayerDeviceLocationPort? location;

  void _edit(BuildContext context, PrayerDaySnapshot? snapshot) {
    Widget editor(BuildContext editorContext, {required bool asSheet}) =>
        PrayerCityEditor(
          ownerId: ownerId,
          search: search,
          commands: commands,
          current: snapshot?.preferences,
          asSheet: asSheet,
          onSaved: () => Navigator.pop(editorContext),
        );
    if (MediaQuery.sizeOf(context).width < 600) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => editor(sheetContext, asSheet: true),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => editor(dialogContext, asSheet: false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          if (location != null) {
            return _LocationSetup(
              ownerId: ownerId,
              location: location!,
              commands: commands,
              onManual: () => _edit(context, snapshot),
            );
          }
          return AppStatusView.error(
            title: copy.prayerSetupTitle,
            message: copy.prayerSetupBody,
            actionLabel: copy.prayerCitySearch,
            onAction: () => _edit(context, snapshot),
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
                      completedCount: snapshot.completedCount,
                      actions: [
                        if (location != null)
                          _LocationAction(
                            ownerId: ownerId,
                            location: location!,
                            commands: commands,
                            current: pref,
                            autoStart: pref.city.provider == 'device',
                          ),
                        AppButton(
                          label: copy.prayerCityEdit,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => _edit(context, snapshot),
                          icon: Icons.edit_location_alt_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (schedule == null)
                      AppStatusView.error(
                        title: copy.prayerScheduleUnavailable,
                        actionLabel: copy.retry,
                        onAction: cubit.retry,
                      )
                    else ...[
                      Text(
                        schedule.provenance.startsWith('AlAdhan')
                            ? copy.prayerSourceApi
                            : copy.prayerSourceLocal,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 10),
                    PrayerScheduleList(
                      schedule: schedule,
                      timeZoneId: pref.city.timeZoneId,
                      reports: snapshot.reports,
                      actions: result.actions,
                      onStatusChanged: cubit.setStatus,
                    ),
                    const SizedBox(height: 8),
                    PrayerSupplementaryTimes(
                      timeZoneId: pref.city.timeZoneId,
                      sunriseUtc: schedule?.sunriseUtc,
                      middleOfNightUtc: projection?.middleOfNightUtc,
                      lastThirdUtc: projection?.lastThirdUtc,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      copy.prayerGuidanceContext,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    const PrayerGuidanceSection(),
                    const SizedBox(height: 8),
                    Text(
                      copy.prayerAttribution,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
    required this.onManual,
  });
  final String ownerId;
  final PrayerDeviceLocationPort location;
  final PrayerPreferencesCommands commands;
  final VoidCallback onManual;

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
                const SizedBox(height: 8),
                AppButton(
                  label: copy.prayerCitySearch,
                  variant: AppButtonVariant.secondary,
                  onPressed: onManual,
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
  });
  final String ownerId;
  final PrayerDeviceLocationPort location;
  final PrayerPreferencesCommands commands;
  final PrayerPreferences? current;
  final bool autoStart;

  @override
  State<_LocationAction> createState() => _LocationActionState();
}

class _LocationActionState extends State<_LocationAction> {
  bool _busy = false;
  PrayerLocationProblem? _problem;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_useLocation());
      });
    }
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
          label: copy.prayerUseLocation,
          icon: Icons.my_location,
          loading: _busy,
          onPressed: _busy ? null : _useLocation,
        ),
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

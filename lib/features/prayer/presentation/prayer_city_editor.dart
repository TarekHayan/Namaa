import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/prayer_localization_adapter.dart';
import 'package:namma_project/app/theme/app_select_field.dart';
import 'package:namma_project/app/widgets/app_button.dart';

import '../application/city_search_port.dart';
import '../application/prayer_preferences_commands.dart';
import '../data/adhan_prayer_calculator.dart';
import '../domain/prayer_preferences.dart';
import 'city_search_cubit.dart';
import 'city_search_state.dart';

class PrayerCityEditor extends StatefulWidget {
  const PrayerCityEditor({
    super.key,
    required this.ownerId,
    required this.search,
    required this.commands,
    this.current,
    this.asSheet = false,
    required this.onSaved,
  });
  final String ownerId;
  final CitySearchPort search;
  final PrayerPreferencesCommands commands;
  final PrayerPreferences? current;
  final bool asSheet;
  final VoidCallback onSaved;

  @override
  State<PrayerCityEditor> createState() => _PrayerCityEditorState();
}

class _PrayerCityEditorState extends State<PrayerCityEditor> {
  late final CitySearchCubit _cubit;
  late String _method = widget.current?.calculationMethod ?? 'egyptian';
  bool _savingMethod = false;
  bool _saveFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _cubit = CitySearchCubit(
        search: widget.search,
        commands: widget.commands,
        ownerId: widget.ownerId,
        locale: Localizations.localeOf(context).languageCode,
      );
    } else {
      _cubit.updateLocale(Localizations.localeOf(context).languageCode);
    }
  }

  bool _initialized = false;

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _confirm(CitySearchState state) async {
    if (state.candidate != null) {
      final saved = await _cubit.confirm(
        method: _method,
        expectedRevision: widget.current?.revision,
      );
      if (saved && mounted) widget.onSaved();
      return;
    }
    final current = widget.current;
    if (current == null) return;
    setState(() {
      _savingMethod = true;
      _saveFailed = false;
    });
    final saved = await widget.commands.confirm(
      ownerId: widget.ownerId,
      city: current.city,
      method: _method,
      expectedRevision: current.revision,
      nowUtc: DateTime.now().toUtc(),
    );
    if (!mounted) return;
    setState(() {
      _savingMethod = false;
      _saveFailed = saved.valueOrNull == null;
    });
    if (saved.valueOrNull != null) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          widget.asSheet ? MediaQuery.viewInsetsOf(context).bottom + 20 : 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                copy.prayerSetupTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (widget.current != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.current!.city.provider == 'device'
                      ? copy.prayerCurrentLocation
                      : '${widget.current!.city.name}, ${widget.current!.city.countryName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                key: const Key('prayer_city_search'),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: copy.prayerCitySearch,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _cubit.updateQuery,
              ),
              const SizedBox(height: 12),
              BlocBuilder<CitySearchCubit, CitySearchState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.phase == CitySearchPhase.searching)
                        const LinearProgressIndicator(),
                      if (state.phase == CitySearchPhase.noResults)
                        Text(copy.prayerSearchNoResults),
                      if (state.phase == CitySearchPhase.offline)
                        Text(copy.prayerSearchOffline),
                      if (state.phase == CitySearchPhase.throttled)
                        Text(copy.prayerSearchThrottled),
                      if (state.phase == CitySearchPhase.invalidResponse)
                        Text(copy.prayerSearchInvalidResponse),
                      if (state.phase == CitySearchPhase.unavailable)
                        Text(copy.prayerSearchUnavailable),
                      if (state.failure != null &&
                          state.phase == CitySearchPhase.results)
                        Text(copy.prayerSaveFailed),
                      for (final city in state.results)
                        ListTile(
                          key: Key('prayer_city_${city.providerCityId}'),
                          title: Text(city.name),
                          subtitle: Text(
                            [
                              city.adminName,
                              city.countryName,
                              city.timeZoneId,
                            ].whereType<String>().join(' · '),
                          ),
                          selected:
                              state.candidate?.providerCityId ==
                              city.providerCityId,
                          leading: Icon(
                            state.candidate?.providerCityId ==
                                    city.providerCityId
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                          ),
                          onTap: () => _cubit.select(city),
                        ),
                      const SizedBox(height: 12),
                      AppSelectField<String>(
                        initialValue: _method,
                        decoration: InputDecoration(
                          labelText: copy.prayerMethod,
                        ),
                        items: [
                          for (final key in AdhanPrayerCalculator.methods)
                            DropdownMenuItem(
                              value: key,
                              child: Text(prayerMethodLabel(copy, key)),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _method = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        copy.prayerAttribution,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      if (_saveFailed) Text(copy.prayerSaveFailed),
                      AppButton(
                        key: const Key('prayer_city_confirm'),
                        label: copy.prayerCityConfirm,
                        loading:
                            state.phase == CitySearchPhase.saving ||
                            _savingMethod,
                        onPressed:
                            state.candidate != null || widget.current != null
                            ? () => _confirm(state)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      AppButton(
                        key: const Key('prayer_city_cancel'),
                        label: copy.prayerCancel,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    return BlocProvider.value(
      value: _cubit,
      child: widget.asSheet
          ? Material(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(top: false, child: content),
            )
          : Dialog(child: content),
    );
  }
}

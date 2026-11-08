import 'package:flutter/material.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/l10n/prayer_localization_adapter.dart';
import 'package:namma_project/app/theme/app_select_field.dart';
import 'package:namma_project/app/widgets/app_button.dart';

import '../application/prayer_preferences_commands.dart';
import '../domain/prayer_calculation_methods.dart';
import '../domain/prayer_preferences.dart';

/// Prayer settings: refresh the device location and pick the calculation
/// method. Prayer times always come from the device location; there is no
/// city search.
class PrayerSettingsSheet extends StatefulWidget {
  const PrayerSettingsSheet({
    super.key,
    required this.ownerId,
    required this.commands,
    required this.current,
    required this.onSaved,
    this.asSheet = false,
    this.location,
  });

  final String ownerId;
  final PrayerPreferencesCommands commands;
  final PrayerPreferences current;
  final VoidCallback onSaved;
  final bool asSheet;

  /// The "update my location" control.
  final Widget? location;

  @override
  State<PrayerSettingsSheet> createState() => _PrayerSettingsSheetState();
}

class _PrayerSettingsSheetState extends State<PrayerSettingsSheet> {
  late String _method = widget.current.calculationMethod;
  bool _saving = false;
  bool _saveFailed = false;

  @override
  void didUpdateWidget(covariant PrayerSettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerId != widget.ownerId) {
      _method = widget.current.calculationMethod;
      _saving = false;
      _saveFailed = false;
    }
  }

  Future<void> _save() async {
    final ownerId = widget.ownerId;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    final saved = await widget.commands.confirm(
      ownerId: ownerId,
      city: widget.current.city,
      method: _method,
      expectedRevision: widget.current.revision,
      nowUtc: DateTime.now().toUtc(),
    );
    if (!mounted || widget.ownerId != ownerId) return;
    setState(() {
      _saving = false;
      _saveFailed = saved.valueOrNull == null;
    });
    if (saved.valueOrNull != null) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final copy = FoundationLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final city = widget.current.city;
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
              Text(copy.prayerCityEdit, style: text.headlineSmall),
              const SizedBox(height: 8),
              Text(
                city.provider == 'device'
                    ? copy.prayerCurrentLocation
                    : '${city.name}, ${city.countryName}',
                style: text.bodyMedium,
              ),
              if (widget.location != null) ...[
                const SizedBox(height: 16),
                widget.location!,
              ],
              const SizedBox(height: 20),
              AppSelectField<String>(
                key: const Key('prayer_method'),
                initialValue: _method,
                decoration: InputDecoration(labelText: copy.prayerMethod),
                items: [
                  for (final key in kPrayerCalculationMethods)
                    DropdownMenuItem(
                      value: key,
                      child: Text(prayerMethodLabel(copy, key)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 12),
              Text(copy.prayerAttribution, style: text.bodySmall),
              const SizedBox(height: 20),
              if (_saveFailed) ...[
                Text(copy.prayerSaveFailed),
                const SizedBox(height: 8),
              ],
              AppButton(
                key: const Key('prayer_settings_save'),
                label: copy.prayerSettingsSave,
                loading: _saving,
                onPressed:
                    _saving || _method == widget.current.calculationMethod
                    ? null
                    : _save,
              ),
              const SizedBox(height: 8),
              AppButton(
                key: const Key('prayer_settings_cancel'),
                label: copy.prayerCancel,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
    return widget.asSheet
        ? Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(top: false, child: content),
          )
        : Dialog(child: content);
  }
}

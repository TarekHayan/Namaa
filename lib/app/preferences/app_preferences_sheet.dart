library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/today_localization_adapter.dart';
import 'package:namma_project/features/foundation/presentation/state/locale_cubit.dart';
import 'package:namma_project/features/foundation/presentation/state/theme_cubit.dart';

/// A small app-owned preference surface backed by the existing persisted Cubits.
Future<void> showAppPreferencesSheet(
  BuildContext context,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) => BlocBuilder<LocaleCubit, LocaleState>(
    builder: (context, localeState) {
      final strings = resolveTodayStrings(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.preferences,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(strings.language),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(strings.english),
                    selected: localeState.languageCode == 'en',
                    onSelected: (_) =>
                        context.read<LocaleCubit>().selectLanguage('en'),
                  ),
                  ChoiceChip(
                    label: Text(strings.arabic),
                    selected: localeState.languageCode == 'ar',
                    onSelected: (_) =>
                        context.read<LocaleCubit>().selectLanguage('ar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(strings.appearance),
              BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, state) => Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(strings.system),
                      selected: state.appearanceMode == 'system',
                      onSelected: (_) =>
                          context.read<ThemeCubit>().selectAppearance('system'),
                    ),
                    ChoiceChip(
                      label: Text(strings.light),
                      selected: state.appearanceMode == 'light',
                      onSelected: (_) =>
                          context.read<ThemeCubit>().selectAppearance('light'),
                    ),
                    ChoiceChip(
                      label: Text(strings.dark),
                      selected: state.appearanceMode == 'dark',
                      onSelected: (_) =>
                          context.read<ThemeCubit>().selectAppearance('dark'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
);

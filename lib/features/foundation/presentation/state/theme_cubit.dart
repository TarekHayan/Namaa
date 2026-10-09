/// Presentation state for the Foundation appearance preference.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/features/foundation/application/theme_preferences.dart';

/// Localized message key for a recoverable appearance-persistence failure.
const String kMessageKeyThemeRecoverable = 'foundation.theme.recoverable';

sealed class ThemeState {
  const ThemeState({required this.appearanceMode});

  /// One of `light`, `dark`, or `system`.
  final String appearanceMode;

  ThemeMode get themeMode => switch (appearanceMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

final class ThemeReady extends ThemeState {
  const ThemeReady({required super.appearanceMode, required this.usedFallback});

  final bool usedFallback;
}

/// The active appearance remains usable while local persistence is retried.
final class ThemePersistenceFailure extends ThemeState {
  const ThemePersistenceFailure({
    required super.appearanceMode,
    required this.messageKey,
  });

  final String messageKey;
}

/// Owns restoration and selection of the root appearance preference.
///
/// The Cubit calls application use cases only and never accesses the local
/// database directly.
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({
    required RestoreThemePreferenceUseCase restore,
    required SaveThemePreferenceUseCase save,
  }) : _restore = restore,
       _save = save,
       super(const ThemeReady(appearanceMode: 'system', usedFallback: false));

  final RestoreThemePreferenceUseCase _restore;
  final SaveThemePreferenceUseCase _save;

  Future<void> restore() async {
    try {
      final result = await _restore();
      if (isClosed) {
        return;
      }
      result.when(
        success: (preference) => emit(
          ThemeReady(
            appearanceMode: preference.appearanceMode,
            usedFallback: preference.usedFallback,
          ),
        ),
        failure: (_) => _emitSystemFailure(),
      );
    } catch (_) {
      if (!isClosed) {
        _emitSystemFailure();
      }
    }
  }

  Future<void> selectAppearance(String appearanceMode) async {
    try {
      final result = await _save(appearanceMode);
      if (isClosed) {
        return;
      }
      result.when(
        success: (preference) => emit(
          ThemeReady(
            appearanceMode: preference.appearanceMode,
            usedFallback: preference.usedFallback,
          ),
        ),
        failure: (_) => _emitActiveFailure(),
      );
    } catch (_) {
      if (!isClosed) {
        _emitActiveFailure();
      }
    }
  }

  void _emitSystemFailure() => emit(
    const ThemePersistenceFailure(
      appearanceMode: 'system',
      messageKey: kMessageKeyThemeRecoverable,
    ),
  );

  void _emitActiveFailure() => emit(
    ThemePersistenceFailure(
      appearanceMode: state.appearanceMode,
      messageKey: kMessageKeyThemeRecoverable,
    ),
  );
}

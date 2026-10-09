/// Foundation appearance-preference use cases.
///
/// Appearance values remain strings here so the application layer does not
/// depend on Flutter presentation types.
library;

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/foundation/domain/foundation_entities.dart';

/// A supported appearance preference after validation and fallback.
final class ResolvedThemePreference {
  const ResolvedThemePreference({
    required this.appearanceMode,
    required this.usedFallback,
  });

  /// Always `light`, `dark`, or `system`.
  final String appearanceMode;

  /// True when a missing or unsupported value became the system fallback.
  final bool usedFallback;
}

/// Restores the persisted Foundation appearance without allowing an invalid
/// preference to prevent a safe root launch.
class RestoreThemePreferenceUseCase {
  RestoreThemePreferenceUseCase({required LocalStorePort localStore})
    : _localStore = localStore;

  final LocalStorePort _localStore;

  Future<AppResult<ResolvedThemePreference>> call() async {
    final read = await _localStore.readPreference(
      FoundationPreferenceKey.appearance.name,
    );
    final failure = read.failureOrNull;
    if (failure != null) {
      return AppResult<ResolvedThemePreference>.failure(failure);
    }
    return AppResult<ResolvedThemePreference>.success(
      _resolve(read.valueOrNull),
    );
  }
}

/// Saves a validated Foundation appearance preference locally.
class SaveThemePreferenceUseCase {
  SaveThemePreferenceUseCase({required LocalStorePort localStore})
    : _localStore = localStore;

  final LocalStorePort _localStore;

  Future<AppResult<ResolvedThemePreference>> call(String appearanceMode) async {
    final preference = _resolve(appearanceMode);
    final saved = await _localStore.savePreference(
      FoundationPreferenceKey.appearance.name,
      preference.appearanceMode,
    );
    final failure = saved.failureOrNull;
    if (failure != null) {
      return AppResult<ResolvedThemePreference>.failure(failure);
    }
    return AppResult<ResolvedThemePreference>.success(preference);
  }
}

ResolvedThemePreference _resolve(String? appearanceMode) {
  if (appearanceMode != null &&
      FoundationPreferenceKey.appearance.isValidValue(appearanceMode)) {
    return ResolvedThemePreference(
      appearanceMode: appearanceMode,
      usedFallback: false,
    );
  }
  return ResolvedThemePreference(
    appearanceMode: FoundationPreferenceKey.appearance.fallbackValue,
    usedFallback: true,
  );
}

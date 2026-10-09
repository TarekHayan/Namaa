/// Foundation locale-preference use cases.
///
/// This application-layer boundary handles only the approved Arabic and
/// English language codes. It deliberately exposes strings rather than
/// Flutter's [Locale] type so application logic stays independent of UI.
library;

import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/core/domain/results/app_result.dart';
import 'package:namma_project/features/foundation/domain/foundation_entities.dart';

/// A supported locale preference after validation and fallback resolution.
final class ResolvedLocalePreference {
  const ResolvedLocalePreference({
    required this.languageCode,
    required this.usedFallback,
  });

  /// Always one of the approved language codes: `ar` or `en`.
  final String languageCode;

  /// Whether a missing or unsupported value became the English fallback.
  final bool usedFallback;
}

/// Restores the persisted locale without allowing an invalid value to block
/// the root application from launching.
class RestoreLocalePreferenceUseCase {
  RestoreLocalePreferenceUseCase({required LocalStorePort localStore})
    : _localStore = localStore;

  final LocalStorePort _localStore;

  Future<AppResult<ResolvedLocalePreference>> call() async {
    final read = await _localStore.readPreference(
      FoundationPreferenceKey.locale.name,
    );
    final failure = read.failureOrNull;
    if (failure != null) {
      return AppResult<ResolvedLocalePreference>.failure(failure);
    }
    return AppResult<ResolvedLocalePreference>.success(
      _resolve(read.valueOrNull),
    );
  }
}

/// Saves a requested locale after resolving unsupported values to the
/// approved English fallback.
class SaveLocalePreferenceUseCase {
  SaveLocalePreferenceUseCase({required LocalStorePort localStore})
    : _localStore = localStore;

  final LocalStorePort _localStore;

  Future<AppResult<ResolvedLocalePreference>> call(String languageCode) async {
    final preference = _resolve(languageCode);
    final saved = await _localStore.savePreference(
      FoundationPreferenceKey.locale.name,
      preference.languageCode,
    );
    final failure = saved.failureOrNull;
    if (failure != null) {
      return AppResult<ResolvedLocalePreference>.failure(failure);
    }
    return AppResult<ResolvedLocalePreference>.success(preference);
  }
}

ResolvedLocalePreference _resolve(String? languageCode) {
  if (languageCode != null &&
      FoundationPreferenceKey.locale.isValidValue(languageCode)) {
    return ResolvedLocalePreference(
      languageCode: languageCode,
      usedFallback: false,
    );
  }
  return ResolvedLocalePreference(
    languageCode: FoundationPreferenceKey.locale.fallbackValue,
    usedFallback: true,
  );
}

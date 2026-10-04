/// Presentation state for the application-wide locale preference.
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/features/foundation/application/locale_preferences.dart';

/// Localized message key for a recoverable locale-persistence failure.
const String kMessageKeyLocaleRecoverable = 'foundation.locale.recoverable';

/// Locale state contains an approved language code even after a persistence
/// failure, so the root can remain usable and directionality stays defined.
sealed class LocaleState {
  const LocaleState({required this.languageCode});

  final String languageCode;
}

/// A resolved supported language, either restored or selected in this run.
final class LocaleReady extends LocaleState {
  const LocaleReady({required super.languageCode, required this.usedFallback});

  final bool usedFallback;
}

/// The selected language remains active but saving or restoration failed.
final class LocalePersistenceFailure extends LocaleState {
  const LocalePersistenceFailure({
    required super.languageCode,
    required this.messageKey,
  });

  final String messageKey;
}

/// Owns restoration and selection of the Foundation locale through use cases.
///
/// It never accesses the local database directly and never exposes
/// infrastructure errors in presentation state.
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit({
    required RestoreLocalePreferenceUseCase restore,
    required SaveLocalePreferenceUseCase save,
  }) : _restore = restore,
       _save = save,
       super(const LocaleReady(languageCode: 'en', usedFallback: false));

  final RestoreLocalePreferenceUseCase _restore;
  final SaveLocalePreferenceUseCase _save;

  /// Restores the stored language, applying the approved English fallback for
  /// missing or unsupported preference values.
  Future<void> restore() async {
    try {
      final result = await _restore();
      if (isClosed) {
        return;
      }
      result.when(
        success: (preference) => emit(
          LocaleReady(
            languageCode: preference.languageCode,
            usedFallback: preference.usedFallback,
          ),
        ),
        failure: (_) => emit(
          const LocalePersistenceFailure(
            languageCode: 'en',
            messageKey: kMessageKeyLocaleRecoverable,
          ),
        ),
      );
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(
        const LocalePersistenceFailure(
          languageCode: 'en',
          messageKey: kMessageKeyLocaleRecoverable,
        ),
      );
    }
  }

  /// Selects and persists an approved language. Unsupported requests become
  /// the English fallback rather than leaving an invalid root locale active.
  Future<void> selectLanguage(String languageCode) async {
    try {
      final result = await _save(languageCode);
      if (isClosed) {
        return;
      }
      result.when(
        success: (preference) => emit(
          LocaleReady(
            languageCode: preference.languageCode,
            usedFallback: preference.usedFallback,
          ),
        ),
        failure: (_) => emit(
          LocalePersistenceFailure(
            languageCode: state.languageCode,
            messageKey: kMessageKeyLocaleRecoverable,
          ),
        ),
      );
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(
        LocalePersistenceFailure(
          languageCode: state.languageCode,
          messageKey: kMessageKeyLocaleRecoverable,
        ),
      );
    }
  }
}

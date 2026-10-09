/// The root Foundation Cubit: drives bootstrap and represents boot errors as
/// safe startup states rather than uncaught exceptions.
///
/// The Cubit calls application use cases only; it never accesses Drift,
/// Supabase, or secure storage directly
/// (specs/001-namaa-foundation/contracts/application-boundaries.md).
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/features/foundation/application/foundation_use_cases.dart';

import 'foundation_state.dart';

class FoundationCubit extends Cubit<FoundationState> {
  FoundationCubit(this._bootstrap) : super(const FoundationStartup());

  final BootstrapUseCase _bootstrap;

  /// Runs the bootstrap use case and maps its outcome onto the root state.
  ///
  /// Any unexpected error becomes a blocking failure state; nothing escapes
  /// as an uncaught exception during startup. A close during a pending
  /// bootstrap is ignored: emitting after close is never attempted.
  Future<void> bootstrap() async {
    try {
      final result = await _bootstrap();
      if (isClosed) {
        return;
      }
      result.when(
        success: (_) => emit(
          const FoundationReady(
            languageCode: kDefaultLanguageCode,
            appearanceMode: kDefaultAppearanceMode,
            rootRouteReady: true,
          ),
        ),
        failure: (failure) {
          if (failure.recoverable) {
            emit(
              const FoundationRecoverableFailure(
                messageKey: kMessageKeyBootstrapRecoverable,
                canRetry: true,
              ),
            );
          } else {
            emit(
              const FoundationBlockingFailure(
                messageKey: kMessageKeyBootstrapBlocking,
              ),
            );
          }
        },
      );
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(
        const FoundationBlockingFailure(
          messageKey: kMessageKeyBootstrapBlocking,
        ),
      );
    }
  }
}

/// Public, infrastructure-free result types for recoverable and blocking
/// outcomes.
///
/// These types are part of the Foundation Domain: they must never import
/// Flutter, Drift, Supabase, routing, notification, or platform-adapter
/// libraries (specs/001-namaa-foundation/contracts/application-boundaries.md).
library;

import 'package:namma_project/core/domain/failures/app_failure.dart';

/// The outcome of a Foundation application operation.
///
/// Either a success carrying [T], or a failure carrying an [AppFailure].
/// Infrastructure error text never crosses this boundary un-wrapped.
sealed class AppResult<T> {
  const AppResult();

  const factory AppResult.success(T value) = _AppSuccess<T>;

  const factory AppResult.failure(AppFailure failure) = _AppFailure<T>;

  /// Pattern-matches the outcome.
  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    final self = this;
    if (self is _AppSuccess<T>) {
      return success(self.value);
    }
    if (self is _AppFailure<T>) {
      return failure(self.failure);
    }
    throw StateError('Unknown AppResult subtype: $runtimeType');
  }

  /// The success value, or null when the outcome is a failure.
  T? get valueOrNull => switch (this) {
    _AppSuccess<T>(:final value) => value,
    _ => null,
  };

  /// The failure description, or null when the outcome is a success.
  AppFailure? get failureOrNull => switch (this) {
    _AppFailure<T>(:final failure) => failure,
    _ => null,
  };
}

final class _AppSuccess<T> extends AppResult<T> {
  const _AppSuccess(this.value);

  final T value;
}

final class _AppFailure<T> extends AppResult<T> {
  const _AppFailure(this.failure);

  final AppFailure failure;
}

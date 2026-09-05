/// Public, infrastructure-free result types for recoverable and blocking
/// outcomes.
///
/// These types are part of the Foundation Domain: they must never import
/// Flutter, Drift, Supabase, routing, notification, or platform-adapter
/// libraries (specs/001-namaa-foundation/contracts/application-boundaries.md).
library;

/// The outcome of a Foundation application operation.
///
/// Either [AppSuccess] with a value, or [AppAppFailure] carrying a
/// user-facing failure description. Infrastructure error text never crosses
/// this boundary un-wrapped.
sealed class AppResult<T> {
  const AppResult();

  /// Pattern-matches the outcome.
  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    final self = this;
    if (self is AppSuccess<T>) {
      return success(self.value);
    }
    if (self is AppAppFailure<T>) {
      return failure(self.failure);
    }
    throw StateError('Unknown AppResult subtype: $runtimeType');
  }
}

/// A completed operation carrying its value.
final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);

  final T value;
}

/// A failed operation carrying a Domain-level failure description.
final class AppAppFailure<T> extends AppResult<T> {
  const AppAppFailure(this.failure);

  final AppFailure failure;
}

/// A Domain-level failure: a public category, a localized message key, and a
/// secret-free diagnostic cause.
///
/// [messageKey] references an Arabic and English localization resource;
/// [technicalCause] is diagnostic only and must never contain credentials,
/// tokens, or database key material.
class AppFailure {
  const AppFailure({
    required this.category,
    required this.recoverable,
    required this.messageKey,
    this.technicalCause,
  });

  /// Public failure category only; never infrastructure exception text.
  final AppFailureCategory category;

  /// Whether the operation may be retried.
  final bool recoverable;

  /// Localized message reference (Arabic and English resources exist).
  final String messageKey;

  /// Secret-free diagnostic detail, if any.
  final String? technicalCause;

  @override
  String toString() =>
      'AppFailure(category: $category, recoverable: $recoverable, '
      'messageKey: $messageKey)';
}

/// Public categories of Foundation failures.
enum AppFailureCategory {
  persistence,
  migration,
  network,
  cloud,
  routing,
  configuration,
}

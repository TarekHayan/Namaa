/// Public, infrastructure-free failure types for Foundation outcomes.
///
/// These types are part of the Foundation Domain: they must never import
/// Flutter, Drift, Supabase, routing, notification, or platform-adapter
/// libraries (specs/001-namaa-foundation/contracts/application-boundaries.md).
library;

/// Public categories of Foundation failures.
///
/// The category is the only classification that crosses the boundary;
/// infrastructure exception text never does.
enum AppFailureCategory {
  persistence,
  migration,
  network,
  cloud,
  routing,
  configuration,
}

/// A Domain-level failure description: a public category, a localized message
/// key, and a secret-free diagnostic cause.
///
/// [messageKey] references an Arabic and English localization resource;
/// [technicalCause] is diagnostic only and must never contain credentials,
/// tokens, or database key material.
class AppFailure {
  AppFailure({
    required this.category,
    required this.recoverable,
    required this.messageKey,
    required this.occurredAt,
    this.technicalCause,
  }) {
    if (messageKey.isEmpty) {
      throw ArgumentError.value(messageKey, 'messageKey', 'must not be empty');
    }
    if (!occurredAt.isUtc) {
      throw ArgumentError.value(
        occurredAt,
        'occurredAt',
        'must be a UTC instant',
      );
    }
  }

  /// A failure the operation may recover from by retrying.
  factory AppFailure.recoverable({
    required AppFailureCategory category,
    required String messageKey,
    required DateTime occurredAt,
    String? technicalCause,
  }) => AppFailure(
    category: category,
    recoverable: true,
    messageKey: messageKey,
    occurredAt: occurredAt,
    technicalCause: technicalCause,
  );

  /// A failure that cannot be retried and requires a safe diagnostic outcome.
  factory AppFailure.blocking({
    required AppFailureCategory category,
    required String messageKey,
    required DateTime occurredAt,
    String? technicalCause,
  }) => AppFailure(
    category: category,
    recoverable: false,
    messageKey: messageKey,
    occurredAt: occurredAt,
    technicalCause: technicalCause,
  );

  /// Public failure category only; never infrastructure exception text.
  final AppFailureCategory category;

  /// Whether the operation may be retried.
  final bool recoverable;

  /// Localized message reference (Arabic and English resources exist).
  final String messageKey;

  /// Secret-free diagnostic detail, if any.
  final String? technicalCause;

  /// Required UTC audit instant.
  final DateTime occurredAt;

  @override
  String toString() =>
      'AppFailure(category: $category, recoverable: $recoverable, '
      'messageKey: $messageKey)';
}

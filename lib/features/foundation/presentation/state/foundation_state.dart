/// Foundation presentation state contracts.
///
/// Root bootstrap, failure, locale, theme, and synchronization status are
/// represented as states carrying localized message keys — never
/// infrastructure error text
/// (specs/001-namaa-foundation/contracts/application-boundaries.md,
/// Presentation State Contract).
library;

/// Localized message keys (Arabic and English resources are added in US2).
const String kMessageKeyBootstrapRecoverable =
    'foundation.bootstrap.recoverable';
const String kMessageKeyBootstrapBlocking = 'foundation.bootstrap.blocking';
const String kMessageKeySyncRecoverable = 'foundation.sync.recoverable';
const String kMessageKeyUnconfigured = 'foundation.composition.unconfigured';

/// Provisional defaults until locale/theme use cases own restoration (US2/US3).
const String kDefaultLanguageCode = 'en';
const String kDefaultAppearanceMode = 'system';

/// Root application state.
sealed class FoundationState {
  const FoundationState();
}

/// Bootstrap progress without product data.
final class FoundationStartup extends FoundationState {
  const FoundationStartup();
}

/// Ready: locale, theme, and root-route readiness.
final class FoundationReady extends FoundationState {
  const FoundationReady({
    required this.languageCode,
    required this.appearanceMode,
    required this.rootRouteReady,
  });

  /// Supported locale code ('ar' or 'en').
  final String languageCode;

  /// Supported appearance mode ('light', 'dark', or 'system').
  final String appearanceMode;

  /// Whether the registered root route is ready.
  final bool rootRouteReady;
}

/// A recoverable failure: localized message key and retry availability.
final class FoundationRecoverableFailure extends FoundationState {
  const FoundationRecoverableFailure({
    required this.messageKey,
    required this.canRetry,
  });

  final String messageKey;
  final bool canRetry;
}

/// A blocking failure: a safe diagnostic outcome with no secret and no
/// infrastructure error text.
final class FoundationBlockingFailure extends FoundationState {
  const FoundationBlockingFailure({required this.messageKey});

  final String messageKey;
}

/// Synchronization status state.
sealed class SyncStatusState {
  const SyncStatusState();
}

/// No pending work; local state is synchronized.
final class SyncIdle extends SyncStatusState {
  const SyncIdle();
}

/// A synchronization pass is dispatching pending operations.
final class SyncInProgress extends SyncStatusState {
  const SyncInProgress({required this.pendingCount});

  final int pendingCount;
}

/// Waiting for connectivity to retry pending operations.
final class SyncRetryWaiting extends SyncStatusState {
  const SyncRetryWaiting({required this.pendingCount});

  final int pendingCount;
}

/// A recoverable synchronization failure with a localized message key.
final class SyncRecoverableFailure extends SyncStatusState {
  const SyncRecoverableFailure({required this.messageKey});

  final String messageKey;
}

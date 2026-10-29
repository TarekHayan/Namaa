import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:namma_project/core/domain/failures/app_failure.dart';
import 'package:namma_project/core/domain/results/app_result.dart';

enum PrayerSearchMode { evaluation, licensedGateway }

/// Validated city-discovery configuration only. Offline schedule calculation
/// must not require this configuration or a reachable provider.
final class PrayerSearchConfiguration {
  const PrayerSearchConfiguration._(this.mode, this.endpoint);

  final PrayerSearchMode mode;
  final Uri endpoint;

  /// Release cannot use the evaluation service. A configured HTTPS gateway
  /// origin supplies discovery through /v1/cities/search; upstream keys stay
  /// server-side. Invalid configuration fails without a public fallback.
  static AppResult<PrayerSearchConfiguration> resolve({
    bool isRelease = kReleaseMode,
    String mode = const String.fromEnvironment(
      'NAMAA_CITY_SEARCH_MODE',
      defaultValue: 'evaluation',
    ),
    String gatewayUrl = const String.fromEnvironment(
      'NAMAA_CITY_SEARCH_GATEWAY_URL',
    ),
    DateTime? nowUtc,
  }) {
    AppResult<PrayerSearchConfiguration> unavailable(String reason) =>
        AppResult.failure(
          AppFailure.recoverable(
            category: AppFailureCategory.configuration,
            messageKey: 'prayerSearchUnavailable',
            occurredAt: (nowUtc ?? DateTime.now()).toUtc(),
            technicalCause: reason,
          ),
        );

    switch (mode) {
      case 'evaluation':
        if (isRelease) return unavailable('evaluation_disabled_in_release');
        return AppResult.success(
          PrayerSearchConfiguration._(
            PrayerSearchMode.evaluation,
            Uri.https('geocoding-api.open-meteo.com', '/v1/search'),
          ),
        );
      case 'licensedGateway':
        final origin = Uri.tryParse(gatewayUrl);
        if (origin == null ||
            origin.scheme != 'https' ||
            origin.host.isEmpty ||
            origin.userInfo.isNotEmpty ||
            (origin.path.isNotEmpty && origin.path != '/') ||
            origin.hasQuery ||
            origin.hasFragment ||
            origin.host.toLowerCase() == 'geocoding-api.open-meteo.com') {
          return unavailable('invalid_gateway_origin');
        }
        return AppResult.success(
          PrayerSearchConfiguration._(
            PrayerSearchMode.licensedGateway,
            origin.resolve('/v1/cities/search'),
          ),
        );
      default:
        return unavailable('unknown_search_mode');
    }
  }
}

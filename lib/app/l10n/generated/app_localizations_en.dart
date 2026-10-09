// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class FoundationLocalizationsEn extends FoundationLocalizations {
  FoundationLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Namaa';

  @override
  String get foundationReady => 'Namaa is ready';

  @override
  String get foundationBootstrapRecoverable =>
      'Namaa could not finish starting. Please try again.';

  @override
  String get foundationBootstrapBlocking => 'Namaa could not start safely.';

  @override
  String get foundationLocaleRecoverable =>
      'Your language preference could not be saved.';

  @override
  String get foundationThemeRecoverable =>
      'Your appearance preference could not be saved.';

  @override
  String get foundationRouteUnavailable => 'This route is unavailable.';

  @override
  String get foundationPlatformRecoverable =>
      'This platform capability could not be verified.';

  @override
  String get foundationGenericFailure =>
      'Namaa needs attention before it can continue.';

  @override
  String get retry => 'Retry';
}

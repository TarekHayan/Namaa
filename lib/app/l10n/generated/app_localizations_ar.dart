// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class FoundationLocalizationsAr extends FoundationLocalizations {
  FoundationLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نماء';

  @override
  String get foundationReady => 'نماء جاهز';

  @override
  String get foundationBootstrapRecoverable =>
      'تعذر إكمال بدء نماء. حاول مرة أخرى.';

  @override
  String get foundationBootstrapBlocking => 'تعذر بدء نماء بأمان.';

  @override
  String get foundationLocaleRecoverable => 'تعذر حفظ تفضيل اللغة.';

  @override
  String get foundationThemeRecoverable => 'تعذر حفظ تفضيل المظهر.';

  @override
  String get foundationRouteUnavailable => 'هذا المسار غير متاح.';

  @override
  String get foundationPlatformRecoverable => 'تعذر التحقق من قدرة هذه المنصة.';

  @override
  String get foundationGenericFailure => 'يحتاج نماء إلى معالجة قبل المتابعة.';

  @override
  String get retry => 'إعادة المحاولة';
}

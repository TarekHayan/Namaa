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

  @override
  String get tasksSignInRequired => 'سجّل الدخول للوصول إلى مهامك.';

  @override
  String get tasksTitle => 'المهام';

  @override
  String get tasksFilterToday => 'اليوم';

  @override
  String get tasksFilterUrgent => 'عاجل';

  @override
  String get tasksFilterAll => 'الكل';

  @override
  String get tasksFilterCompleted => 'المكتملة';

  @override
  String get tasksViewList => 'قائمة';

  @override
  String get tasksViewMatrix => 'المصفوفة';

  @override
  String get tasksCategoryFilter => 'التصنيف';

  @override
  String get tasksAllCategories => 'جميع التصنيفات';

  @override
  String get taskCategoryWork => 'عمل';

  @override
  String get taskCategoryStudy => 'دراسة';

  @override
  String get taskCategoryPersonal => 'شخصي';

  @override
  String get taskCategoryHealth => 'صحة';

  @override
  String get taskCategorySpiritual => 'إيماني';

  @override
  String get taskCategoryFinance => 'مالي';

  @override
  String get taskCategoryOther => 'أخرى';

  @override
  String get quadrantUrgentImportant => 'عاجل ومهم';

  @override
  String get quadrantNotUrgentImportant => 'مهم وغير عاجل';

  @override
  String get quadrantUrgentNotImportant => 'عاجل وغير مهم';

  @override
  String get quadrantNotUrgentNotImportant => 'غير عاجل وغير مهم';

  @override
  String get quadrantDo => 'افعل أولاً';

  @override
  String get quadrantSchedule => 'خطط له';

  @override
  String get quadrantDelegate => 'فوّض';

  @override
  String get quadrantEliminate => 'تجاهل';

  @override
  String get taskCreate => 'مهمة جديدة';

  @override
  String get taskEdit => 'تعديل المهمة';

  @override
  String get taskDelete => 'حذف';

  @override
  String get taskSave => 'حفظ';

  @override
  String get taskCancel => 'إلغاء';

  @override
  String get taskTitleLabel => 'العنوان';

  @override
  String get taskTitleHint => 'عنوان المهمة';

  @override
  String get taskDescriptionLabel => 'الوصف';

  @override
  String get taskDescriptionHint => 'ملاحظات أو تفاصيل';

  @override
  String get taskDurationLabel => 'المدة التقديرية (بالدقائق)';

  @override
  String get taskDurationHint => '30';

  @override
  String get taskScheduledDateLabel => 'التاريخ المجدول';

  @override
  String get taskScheduledTimeLabel => 'الوقت';

  @override
  String get taskDeadlineLabel => 'الموعد النهائي';

  @override
  String get taskDateTodayDefault => 'اليوم (افتراضي)';

  @override
  String get taskNotSet => 'غير محدد';

  @override
  String get taskClear => 'مسح';

  @override
  String get taskCategoryLabel => 'التصنيف';

  @override
  String get taskQuadrantLabel => 'الأولوية';

  @override
  String get taskTitleRequired => 'العنوان مطلوب';

  @override
  String get taskDurationInvalid => 'يجب أن تكون المدة إيجابية';

  @override
  String get taskDurationUnit => 'دقيقة';

  @override
  String get tasksEmpty => 'لا توجد مهام حتى الآن';

  @override
  String get tasksLoading => 'جاري تحميل المهام...';

  @override
  String get tasksFailure => 'تعذر تحميل المهام';

  @override
  String get tasksConflictNotice =>
      'تم اكتشاف تعارض في المزامنة. تم الاحتفاظ بالتغييرات المحلية بجانب التغييرات البعيدة.';

  @override
  String get tasksActiveLocal => 'النسخة المحلية';

  @override
  String get tasksRetainedRemote => 'النسخة البعيدة';
}

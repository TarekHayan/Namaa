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
  String get todayTitle => 'اليوم';

  @override
  String get todayXp => 'نقاط اليوم';

  @override
  String get todayOpen => 'المتبقي';

  @override
  String get todayCompleted => 'المكتمل';

  @override
  String get todayStreak => 'سلسلة الإنجاز';

  @override
  String get todayDoFirst => 'ابدأ بالأهم';

  @override
  String get todayOverdue => 'المتأخر';

  @override
  String get todayNoTasks => 'لا توجد مهام مجدولة اليوم';

  @override
  String get todayNoHabits => 'لا توجد عادات مستحقة اليوم';

  @override
  String get todayShowMore => 'عرض المزيد';

  @override
  String get todayLoading => 'جارٍ تحميل هذا القسم…';

  @override
  String get todaySourceUnavailable => 'هذا القسم غير متاح الآن.';

  @override
  String get todayOutdated => 'المعلومات المعروضة قديمة. حاول مجددًا لتحديثها.';

  @override
  String get todayPreferences => 'التفضيلات';

  @override
  String get todayLanguage => 'اللغة';

  @override
  String get todayAppearance => 'المظهر';

  @override
  String get todayEnglish => 'English';

  @override
  String get todayArabic => 'العربية';

  @override
  String get todaySystem => 'حسب النظام';

  @override
  String get todayLight => 'فاتح';

  @override
  String get todayDark => 'داكن';

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
  String get tasksEmptyHint => 'أضف مهمة جديدة لتبدأ تنظيم يومك.';

  @override
  String get tasksFilterToday => 'اليوم';

  @override
  String get tasksFilterUrgent => 'عاجل';

  @override
  String get tasksFilterAll => 'الكل';

  @override
  String get tasksFilterCompleted => 'المكتملة';

  @override
  String get tasksFilterHistory => 'السجل';

  @override
  String get tasksFilterOverdue => 'المتأخرة';

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
  String get taskComplete => 'إكمال';

  @override
  String get taskReopen => 'إعادة الفتح';

  @override
  String get taskChecklistTitle => 'قائمة الخطوات';

  @override
  String get taskChecklistNewHint => 'أضف خطوة';

  @override
  String get taskChecklistAdd => 'إضافة خطوة';

  @override
  String get taskChecklistSave => 'حفظ الخطوة';

  @override
  String get taskChecklistRemove => 'حذف الخطوة';

  @override
  String get taskChecklistTextRequired => 'نص الخطوة مطلوب';

  @override
  String taskCompletedAt(String timestamp) {
    return 'اكتملت في $timestamp';
  }

  @override
  String get taskSave => 'حفظ';

  @override
  String get taskCancel => 'إلغاء';

  @override
  String get taskMoreDetails => 'تفاصيل إضافية';

  @override
  String get taskLessDetails => 'إخفاء التفاصيل';

  @override
  String get taskMatrixLabel => 'مصفوفة آيزنهاور';

  @override
  String get taskTitleLabel => 'العنوان';

  @override
  String get taskTitleHint => 'ما الذي ترغب في إنجازه اليوم؟';

  @override
  String get taskDescriptionLabel => 'الوصف';

  @override
  String get taskDescriptionHint => 'أضف ملاحظات أو تفاصيل اختيارية...';

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

  @override
  String get habitsTitle => 'العادات';

  @override
  String get habitsEmpty => 'لا توجد عادات بعد';

  @override
  String get habitsCreate => 'عادة جديدة';

  @override
  String get habitEdit => 'تعديل العادة';

  @override
  String get habitDelete => 'حذف العادة';

  @override
  String get habitDeleteConfirmation =>
      'هل تريد حذف هذه العادة؟ سيُحتفظ بسجلها للاسترجاع، لكنها ستختفي من قائمة العادات.';

  @override
  String get habitReminderTime => 'وقت التذكير';

  @override
  String get habitReminderClear => 'مسح الوقت';

  @override
  String get habitReminderInactive =>
      'الإشعارات غير مفعّلة بعد. سيُحفظ الوقت المختار لتفعيلها لاحقًا.';

  @override
  String get habitsSyncing => 'جارٍ مزامنة العادات…';

  @override
  String get habitsSyncFailed =>
      'تعذر إكمال مزامنة العادات. تغييراتك المحفوظة ما زالت على هذا الجهاز.';

  @override
  String get habitsSyncRetry => 'إعادة المزامنة';

  @override
  String get habitsConflict => 'تغيير في العادة يحتاج للمراجعة';

  @override
  String get habitsActiveVersion => 'النسخة الحالية';

  @override
  String get habitsRetainedVersion => 'النسخة المحفوظة';

  @override
  String get habitsUnresolvedConflict =>
      'للنسختين التوقيت نفسه وتحتاجان للمراجعة.';

  @override
  String get habitNameLabel => 'اسم العادة';

  @override
  String get habitNameRequired => 'اكتب اسم العادة';

  @override
  String get habitWeekdaysRequired => 'اختر يومًا واحدًا على الأقل';

  @override
  String get habitSave => 'حفظ العادة';

  @override
  String get habitCancel => 'إلغاء';

  @override
  String get habitComplete => 'إنجاز اليوم';

  @override
  String get habitUndo => 'التراجع عن إنجاز اليوم';

  @override
  String get habitDueToday => 'مطلوبة اليوم';

  @override
  String get habitNotDueToday => 'غير مطلوبة اليوم';

  @override
  String get habitsLoadFailure => 'تعذر تحميل العادات. حاول مرة أخرى.';

  @override
  String get habitsSaveFailure => 'تعذر حفظ التغيير. حاول مرة أخرى.';

  @override
  String get habitsSignInRequired => 'سجّل الدخول للوصول إلى عاداتك.';

  @override
  String get habitHistory => 'السجل';

  @override
  String get habitCurrentStreak => 'السلسلة الحالية (أيام)';

  @override
  String get habitCompletedDates => 'تواريخ الإنجاز';

  @override
  String get habitNoCompletedDates => 'لا توجد أيام مكتملة بعد';

  @override
  String get habitPendingToday => 'اليوم لم ينته بعد';

  @override
  String get habitScheduleHistory => 'سجل الجدول';

  @override
  String get habitEffectiveFrom => 'سارٍ من';

  @override
  String get habitCompletedOn => 'أُنجزت في';

  @override
  String get habitCloseHistory => 'إغلاق السجل';

  @override
  String get habitMonday => 'الاثنين';

  @override
  String get habitTuesday => 'الثلاثاء';

  @override
  String get habitWednesday => 'الأربعاء';

  @override
  String get habitThursday => 'الخميس';

  @override
  String get habitFriday => 'الجمعة';

  @override
  String get habitSaturday => 'السبت';

  @override
  String get habitSunday => 'الأحد';

  @override
  String get mindMapsTitle => 'الخرائط الذهنية';

  @override
  String get mindMapsCreate => 'خريطة جديدة';

  @override
  String get mindMapsSearch => 'ابحث في الخرائط';

  @override
  String get mindMapsEmptyLibrary => 'لا توجد خرائط بعد. أنشئ خريطتك الأولى.';

  @override
  String get mindMapsEmptySearch => 'لا توجد خرائط تطابق البحث.';

  @override
  String get mindMapTitleLabel => 'عنوان الخريطة';

  @override
  String get mindMapDescriptionLabel => 'الوصف';

  @override
  String get mindMapEditTitle => 'تغيير الاسم';

  @override
  String get mindMapEditDescription => 'تعديل الوصف';

  @override
  String get mindMapDuplicate => 'نسخ الخريطة';

  @override
  String get mindMapDelete => 'حذف';

  @override
  String get mindMapDeleteConfirmation =>
      'هل تريد حذف هذه الخريطة؟ ستختفي من القائمة، وستظل المهام المرتبطة بها محفوظة.';

  @override
  String get mindMapSave => 'حفظ';

  @override
  String get mindMapCancel => 'إلغاء';

  @override
  String get mindMapTitleRequired => 'اكتب عنوانًا للخريطة';

  @override
  String get mindMapsLoadFailure => 'تعذر تحميل الخرائط. حاول مرة أخرى.';

  @override
  String get mindMapsSaveFailure => 'تعذر حفظ تغيير الخريطة. حاول مرة أخرى.';

  @override
  String get mindMapsAccountFailure => 'لا يمكن لهذا الحساب تعديل الخريطة.';

  @override
  String get mindMapsNotFound => 'هذه الخريطة لم تعد متاحة.';

  @override
  String get mindMapsRetry => 'إعادة المحاولة';

  @override
  String get mindMapSyncing => 'جارٍ مزامنة الخرائط الذهنية…';

  @override
  String get mindMapSyncFailed =>
      'تعذرت مزامنة الخرائط الذهنية. التغييرات المحلية محفوظة.';

  @override
  String get mindMapSyncRetry => 'إعادة المزامنة';

  @override
  String get mindMapConflicts => 'مراجعة النسخ الأخرى';

  @override
  String get mindMapConflictActive => 'النسخة الحالية';

  @override
  String get mindMapConflictRetained => 'النسخة الأخرى';

  @override
  String get mindMapConflictUnresolved => 'تحتاج مراجعة';

  @override
  String get mindMapNodeCount => 'العقد';

  @override
  String get mindMapCompletedCount => 'المكتملة';

  @override
  String get mindMapCentralNode => 'الفكرة الرئيسية';

  @override
  String get mindMapsSignInRequired => 'سجّل الدخول للوصول إلى خرائطك الذهنية.';

  @override
  String get mindMapsBack => 'العودة للخرائط';

  @override
  String get mindMapEditMap => 'تعديل الخريطة';

  @override
  String get mindMapAddNode => 'إضافة عقدة';

  @override
  String get mindMapEditNode => 'تعديل العقدة';

  @override
  String get mindMapNodeTitle => 'عنوان العقدة';

  @override
  String get mindMapNodeDescription => 'وصف العقدة';

  @override
  String get mindMapNodeKind => 'النوع';

  @override
  String get mindMapNodePriority => 'الأولوية';

  @override
  String get mindMapNodeStatus => 'الحالة';

  @override
  String get mindMapKindCentral => 'الفكرة المركزية';

  @override
  String get mindMapKindMainIdea => 'فكرة رئيسية';

  @override
  String get mindMapKindBranch => 'فرع';

  @override
  String get mindMapKindTask => 'فكرة مهمة';

  @override
  String get mindMapKindNote => 'ملاحظة';

  @override
  String get mindMapStatusNotStarted => 'لم تبدأ';

  @override
  String get mindMapStatusInProgress => 'قيد التنفيذ';

  @override
  String get mindMapStatusCompleted => 'مكتملة';

  @override
  String get mindMapPriorityLow => 'منخفضة';

  @override
  String get mindMapPriorityMedium => 'متوسطة';

  @override
  String get mindMapPriorityHigh => 'مرتفعة';

  @override
  String get mindMapNodeTitleRequired => 'اكتب عنوان العقدة';

  @override
  String get mindMapDeleteNode => 'حذف العقدة';

  @override
  String get mindMapDeleteNodeConfirmation =>
      'حذف هذه العقدة؟ سيبقى أبناؤها عقدًا مستقلة.';

  @override
  String get mindMapParent => 'العقدة الأم';

  @override
  String get mindMapDetach => 'فصل عن الأم';

  @override
  String get mindMapSideLink => 'رابط مرئي';

  @override
  String get mindMapConnect => 'توصيل';

  @override
  String get mindMapDisconnect => 'فصل الرابط';

  @override
  String get mindMapMoveNode => 'تحريك العقدة';

  @override
  String get mindMapUndo => 'تراجع';

  @override
  String get mindMapRedo => 'إعادة';

  @override
  String get mindMapGraphError =>
      'تعذر حفظ التعديل في الخريطة. راجع الرابط وحاول مرة أخرى.';

  @override
  String get mindMapNoParent => 'مستقلة';

  @override
  String get mindMapProgress => 'التقدم';

  @override
  String get mindMapChooseTask => 'اختر مهمة';

  @override
  String get mindMapLinkTask => 'ربط مهمة';

  @override
  String get mindMapChangeTask => 'تغيير المهمة المرتبطة';

  @override
  String get mindMapUnlinkTask => 'فصل المهمة';

  @override
  String get mindMapLinkedTask => 'مهمة مرتبطة';

  @override
  String get mindMapTaskUnavailable => 'المهمة المرتبطة غير متاحة';

  @override
  String get mindMapCompleteTask => 'إكمال المهمة';

  @override
  String get mindMapReopenTask => 'إعادة فتح المهمة';

  @override
  String get mindMapLoadingTasks => 'جارٍ تحميل المهام…';

  @override
  String get mindMapRetryTasks => 'إعادة تحميل المهام';

  @override
  String get mindMapNoTasks => 'لا توجد مهام متاحة';

  @override
  String get mindMapTaskLinkFailure =>
      'تعذر تحميل المهمة أو ربطها. حاول مرة أخرى.';

  @override
  String get mindMapSettings => 'إعدادات الخريطة';

  @override
  String get mindMapLayout => 'التخطيط';

  @override
  String get mindMapApplyLayout => 'تطبيق التخطيط';

  @override
  String get mindMapLayoutRadial => 'دائري';

  @override
  String get mindMapLayoutTree => 'شجري';

  @override
  String get mindMapLayoutHorizontal => 'أفقي';

  @override
  String get mindMapLayoutVertical => 'رأسي';

  @override
  String get mindMapLayoutFreeform => 'حر';

  @override
  String get mindMapBackground => 'خلفية مساحة الرسم';

  @override
  String get mindMapDefaultNode => 'مظهر العقد الجديدة';

  @override
  String get mindMapConnectionStyle => 'مظهر الروابط الجديدة';

  @override
  String get mindMapSpacing => 'المسافة بين العقد';

  @override
  String get mindMapNodeColor => 'لون العقدة';

  @override
  String get mindMapConnectionColor => 'لون الرابط';

  @override
  String get mindMapConnectionWidth => 'سُمك الرابط';

  @override
  String get mindMapNodeIcon => 'رمز العقدة';

  @override
  String get mindMapNodeShape => 'شكل العقدة';

  @override
  String get mindMapNodeSize => 'حجم العقدة';

  @override
  String get mindMapTextSize => 'حجم النص';

  @override
  String get mindMapShapeRectangle => 'مستطيل';

  @override
  String get mindMapShapeRounded => 'مستدير';

  @override
  String get mindMapShapeCircle => 'دائرة';

  @override
  String get mindMapShapePill => 'كبسولة';

  @override
  String get mindMapShapeGlass => 'زجاجي';

  @override
  String get mindMapSizeSmall => 'صغير';

  @override
  String get mindMapSizeMedium => 'متوسط';

  @override
  String get mindMapSizeLarge => 'كبير';

  @override
  String get mindMapIconIdea => 'فكرة';

  @override
  String get mindMapIconTask => 'مهمة';

  @override
  String get mindMapIconNote => 'ملاحظة';

  @override
  String get mindMapIconStar => 'نجمة';

  @override
  String get mindMapIconFlag => 'علم';

  @override
  String get mindMapColorWhite => 'أبيض';

  @override
  String get mindMapColorBlue => 'أزرق';

  @override
  String get mindMapColorGreen => 'أخضر';

  @override
  String get mindMapColorAmber => 'كهرماني';

  @override
  String get mindMapColorPurple => 'بنفسجي';

  @override
  String get mindMapColorDark => 'داكن';

  @override
  String get mindMapColorCurrent => 'اللون الحالي';

  @override
  String get mindMapFit => 'احتواء الخريطة';

  @override
  String get mindMapCenter => 'توسيط الخريطة';

  @override
  String get mindMapZoomIn => 'تكبير';

  @override
  String get mindMapZoomOut => 'تصغير';

  @override
  String get mindMapPanLeft => 'تحريك لليسار';

  @override
  String get mindMapPanRight => 'تحريك لليمين';

  @override
  String get mindMapPanUp => 'تحريك لأعلى';

  @override
  String get mindMapPanDown => 'تحريك لأسفل';

  @override
  String get mindMapDragNode => 'اسحب العقدة لتحريكها';

  @override
  String get mindMapKeyboardHelp =>
      'لوحة المفاتيح: الأسهم للتحريك، زائد وناقص للتكبير والتصغير، F لاحتواء الخريطة، C للتوسيط';

  @override
  String get todayNewTask => 'مهمة جديدة';

  @override
  String get todayNewHabit => 'عادة جديدة';

  @override
  String get todayCompleteTask => 'إنجاز المهمة';

  @override
  String get todayReopenTask => 'إعادة فتح المهمة';

  @override
  String get todayCompleteHabit => 'إنجاز العادة';

  @override
  String get todayUndoHabit => 'التراجع عن إنجاز العادة';

  @override
  String get todaySaving => 'جارٍ الحفظ…';

  @override
  String get todaySaveFailed => 'تعذر الحفظ. راجع العنصر وحاول مرة أخرى.';

  @override
  String get todayUncertain =>
      'نتيجة الحفظ غير مؤكدة. راجع حالة العنصر قبل المحاولة مجددًا.';

  @override
  String get todayStaleDay =>
      'تغير اليوم. راجع عناصر اليوم الحالي قبل التنفيذ.';

  @override
  String get todayAgenda => 'جدول اليوم';

  @override
  String get todayTimed => 'بموعد محدد';

  @override
  String get todayUntimed => 'بدون موعد محدد';

  @override
  String get todayMinuteUnit => 'دقيقة';

  @override
  String get todayNoPriorityTasks =>
      'لا توجد مهام عاجلة ومهمة لليوم أو متأخرة.';

  @override
  String get todayOpenMatrix => 'فتح مصفوفة المهام';

  @override
  String get todayOpenOverdue => 'فتح المهام المتأخرة';

  @override
  String get dashboardGreetingMorning => 'صباح الخير';

  @override
  String get dashboardGreetingLater => 'مساء الخير';

  @override
  String get dashboardSubtitle => 'أولوياتك وإيقاع يومك في مكان واحد.';

  @override
  String get dashboardOverview => 'يومك في لمحة';

  @override
  String get dashboardTasksProgress => 'المهام المنجزة';

  @override
  String get dashboardHabitsProgress => 'العادات المنجزة';

  @override
  String get dashboardXpEarned => 'نقاط اليوم';

  @override
  String get dashboardExplore => 'اكتشف مساحتك';

  @override
  String get dashboardMindMapsHint => 'حوّل أفكارك إلى خطوات واضحة';

  @override
  String get dashboardPreviewTitle => 'مساحات قادمة';

  @override
  String get dashboardPreviewDescription =>
      'لمحة عن الأقسام التي نجهزها لاحقًا.';

  @override
  String get dashboardSampleBadge => 'بيانات تجريبية';

  @override
  String get dashboardSidebarTagline => 'مساحتك ليوم متزن';

  @override
  String get dashboardComingSoon => 'قريبًا';

  @override
  String get dashboardPrayerShort => 'الصلوات';

  @override
  String get dashboardMore => 'المزيد';

  @override
  String get dashboardQuickAdd => 'إضافة سريعة';

  @override
  String get dashboardPrayer => 'مواقيت الصلاة';

  @override
  String get dashboardPrayerDetail => 'القادمة: العصر · ٣:٢٥ م';

  @override
  String get dashboardQuran => 'ورد القرآن';

  @override
  String get dashboardQuranDetail => '٧ من ٢٠ صفحة هذا الأسبوع';

  @override
  String get dashboardFinance => 'المالية الشخصية';

  @override
  String get dashboardFinanceDetail => 'هدف الشهر · ٤٬٢٥٠ / ٨٬٠٠٠';

  @override
  String get dashboardFocus => 'وقت التركيز';

  @override
  String get dashboardFocusDetail => 'جلستان مخططتان · ٥٠ دقيقة';

  @override
  String get dashboardEncryptedBadge => 'محفوظ محلياً ومشفّر';

  @override
  String get dashboardProductiveDay => 'يوم منتج متزن';

  @override
  String dashboardLevelBadge(int level, int xp) {
    return 'مستوى $level • $xp XP';
  }

  @override
  String get dashboardSampleNotice =>
      'عرض تجريبي للميزة قيد التطوير. البيانات توضيحية.';

  @override
  String get dashboardPrayerTitle => 'مواقيت الصلوات الخمس';

  @override
  String get dashboardPrayerCity => 'الرياض';

  @override
  String get dashboardPrayerFajr => 'الفجر';

  @override
  String get dashboardPrayerDhuhr => 'الظهر';

  @override
  String get dashboardPrayerAsr => 'العصر';

  @override
  String get dashboardPrayerMaghrib => 'المغرب';

  @override
  String get dashboardPrayerIsha => 'العشاء';

  @override
  String get dashboardPrayerNext => 'الصلاة القادمة';

  @override
  String get dashboardPrayerRemaining => 'متبقي ٣:٢٤ س';

  @override
  String get dashboardPrayerDone => 'تمت';

  @override
  String get dashboardPrayerUpcoming => 'انتظار';

  @override
  String get dashboardQuranSectionTitle => 'ورد القرآن الكريم وحفظه';

  @override
  String get dashboardQuranWirdTitle => 'ورد اليوم • سورة الكهف';

  @override
  String get dashboardQuranProgressInfo =>
      'الجزء ١٥ • صفحة ٣٠٢ من ٣٠٤ • ٧٥٪ مكتمل';

  @override
  String get dashboardQuranRemainingPages => 'متبقي صفحتان لختام الورد';

  @override
  String get dashboardQuranAyahQuote =>
      '«وَأَمَّا الْجِدَارُ فَكَانَ لِغُلَامَيْنِ يَتِيمَيْنِ فِي الْمَدِينَةِ وَكَانَ تَحْتَهُ كَنزٌ لَّهُمَا...»';

  @override
  String get dashboardQuranAyahRef => 'سورة الكهف • الآية ٨٢';

  @override
  String get dashboardQuranContinueReading => 'متابعة التلاوة';

  @override
  String get dashboardQuranMemorizationTitle => 'تثبيت الحفظ • سورة الملك';

  @override
  String get dashboardQuranMemorizationDetail =>
      'الآيات (1 - 5 تم بنجاح ✓) • الآيات 6 - 10 بانتظار البدء';

  @override
  String get dashboardQuranStartRecite => 'ابدأ التسميع';

  @override
  String get dashboardFinanceSectionTitle => 'المحفظة والمالية الشخصية';

  @override
  String get dashboardFinanceMonth => 'مثال للشهر الحالي';

  @override
  String get dashboardFinanceTotalBalance => 'الرصيد الإجمالي';

  @override
  String get dashboardFinanceAvailable => 'المتاح للصرف';

  @override
  String get dashboardFinanceSavings => 'المدخرات';

  @override
  String get dashboardFinanceCurrency => 'ر.س';

  @override
  String get dashboardFinanceFlowTitle => 'التدفق لآخر ٧ أيام';

  @override
  String get dashboardFinanceIncome => 'دخل';

  @override
  String get dashboardFinanceExpense => 'مصروف';

  @override
  String get dashboardFinanceBudgetConsumption => 'استهلاك ميزانية الشهر';

  @override
  String get dashboardFinanceBudgetConsumed => '٥٢٪ مستهلك';

  @override
  String get dashboardFinanceSpent => 'المصروف';

  @override
  String get dashboardFinanceRemaining => 'المتبقي';

  @override
  String get dashboardFinanceDaysLeft => '١٦ يوماً متبقية';

  @override
  String get dashboardFinanceAddIncome => '+ دخل';

  @override
  String get dashboardFinanceAddExpense => '- مصروف';

  @override
  String get dashboardFinanceAddSaving => 'ادخار';

  @override
  String get dashboardFocusSectionTitle => 'جلسات التركيز والأوراد الروحية';

  @override
  String get dashboardFocusPomodoroTitle => 'جلسة تركيز مقترحة';

  @override
  String get dashboardFocusPomodoroDuration => 'المدة: ٢٥ دقيقة';

  @override
  String get dashboardFocusStart => 'بدء الجلسة';

  @override
  String get dashboardFocusCompletedToday => '٥٠ دقيقة منجزة اليوم';

  @override
  String get dashboardAdhkarTitle => 'الأوراد الروحية والسنن';

  @override
  String get dashboardAdhkarMorning => 'أذكار الصباح';

  @override
  String get dashboardAdhkarEvening => 'أذكار المساء';

  @override
  String get dashboardAdhkarQiyam => 'الوتر والقيام';

  @override
  String get dashboardReflectionTitle => 'إشراقة اليوم';

  @override
  String get dashboardReflectionQuote => '«أحب الأعمال إلى الله أدومها وإن قل»';

  @override
  String get dashboardReflectionAction => 'تدوين خاطرة';

  @override
  String get dashboardHome => 'الرئيسية';

  @override
  String get dashboardTrack => 'المتابعة';

  @override
  String get dashboardCounters => 'العدادات';

  @override
  String get dashboardTodayProgress => 'تقدم اليوم';

  @override
  String get dashboardNextPrayer => 'الصلاة القادمة';

  @override
  String get dashboardDailyQuran => 'ورد القرآن اليومي';

  @override
  String get dashboardQuickAccess => 'وصول سريع';

  @override
  String get dashboardDailyTimeline => 'الجدول اليومي';

  @override
  String get dashboardFinancialSummary => 'الملخص المالي';

  @override
  String get dashboardCountersSection => 'لمحة عن العدادات';

  @override
  String get dashboardOverallProgress => 'التقدم العام';

  @override
  String get dashboardLevel => 'المستوى';

  @override
  String get dashboardStreak => 'سلسلة الإنجاز';

  @override
  String get dashboardLiveValue => 'بيانات فعلية';

  @override
  String get dashboardSampleValue => 'بيانات تجريبية';

  @override
  String get dashboardLoadingValue => 'جارٍ تحميل القيمة…';

  @override
  String get dashboardEmptyValue => 'لا توجد قيمة بعد';

  @override
  String get dashboardStaleValue => 'بيانات قديمة';

  @override
  String get dashboardUnavailableValue => 'القيمة غير متاحة';

  @override
  String get dashboardUmmAlQuraCalendar => 'تقويم أم القرى';

  @override
  String get dashboardHijriDateUnavailable => 'التاريخ الهجري غير متاح';

  @override
  String dashboardHijriDate(String day, String month, String year) {
    return '$day $month $year هـ';
  }

  @override
  String get dashboardHijriMuharram => 'محرم';

  @override
  String get dashboardHijriSafar => 'صفر';

  @override
  String get dashboardHijriRabiAlAwwal => 'ربيع الأول';

  @override
  String get dashboardHijriRabiAlThani => 'ربيع الآخر';

  @override
  String get dashboardHijriJumadaAlAwwal => 'جمادى الأولى';

  @override
  String get dashboardHijriJumadaAlThani => 'جمادى الآخرة';

  @override
  String get dashboardHijriRajab => 'رجب';

  @override
  String get dashboardHijriShaban => 'شعبان';

  @override
  String get dashboardHijriRamadan => 'رمضان';

  @override
  String get dashboardHijriShawwal => 'شوال';

  @override
  String get dashboardHijriDhuAlQidah => 'ذو القعدة';

  @override
  String get dashboardHijriDhuAlHijjah => 'ذو الحجة';

  @override
  String get dashboardComingSoonTrackTitle => 'المتابعة';

  @override
  String get dashboardComingSoonPrayerTitle => 'مواقيت الصلاة';

  @override
  String get dashboardComingSoonFocusTitle => 'التركيز';

  @override
  String get dashboardComingSoonQuranTitle => 'القرآن';

  @override
  String get dashboardComingSoonAdhkarTitle => 'الأذكار';

  @override
  String get dashboardComingSoonQiyamTitle => 'القيام';

  @override
  String get dashboardComingSoonCountersTitle => 'العدادات';

  @override
  String get dashboardComingSoonFinanceTitle => 'المالية';

  @override
  String get dashboardComingSoonDescription =>
      'نعمل على تجهيز هذه المساحة وستتوفر قريبًا.';

  @override
  String get dashboardBackToHome => 'العودة إلى الرئيسية';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'سفرة';

  @override
  String get appTagline => 'صحتك على سفرتك';

  @override
  String get splashBlessing => 'بالهنا والشفا';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingStart => 'يلا نبدأ';

  @override
  String onboardingCounter(int current, int total) {
    return '$current / $total';
  }

  @override
  String get onboarding1Title => 'سجّل أكلك بالكلام';

  @override
  String get onboarding1Body => 'قول اللي أكلته بالعامية وإحنا نفهمك في ثواني';

  @override
  String get onboarding2Title => 'أرقام تقدر تثق فيها';

  @override
  String get onboarding2Body => 'بنحسب من مكونات الطبق نفسه، مش تخمين';

  @override
  String get onboarding3Title => 'أكلك المصري كله';

  @override
  String get onboarding3Body => 'كشري، فول، ملوخية، محشي... كلها في سفرة';

  @override
  String get loginTitleA => 'ما تاكلش أقل،';

  @override
  String get loginTitleB => 'كُل صح';

  @override
  String get loginSubtitle => 'سجّل دخولك وكمّل رحلتك الصحية';

  @override
  String get emailHint => 'الإيميل';

  @override
  String get passwordHint => 'كلمة السر';

  @override
  String get forgotPassword => 'نسيت كلمة السر؟';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get orContinueWith => 'أو كمّل بـ';

  @override
  String get googleProvider => 'جوجل';

  @override
  String get phoneProvider => 'رقم الموبايل';

  @override
  String get providerNotConfigured => 'الطريقة دي مش متاحة دلوقتي.';

  @override
  String get phoneComingToast => 'هنبعتلك كود تأكيد على رقم موبايلك';

  @override
  String get noAccount => 'معندكش حساب؟';

  @override
  String get createAccountLink => 'أنشئ حساب جديد';

  @override
  String get resetEmailSent => 'بعتنا لك لينك إعادة تعيين كلمة السر على إيميلك';

  @override
  String get registerTitleA => 'ابدأ سفرتك،';

  @override
  String get registerTitleB => 'كُل حقيقي';

  @override
  String get nameHint => 'الاسم';

  @override
  String get passwordRegisterHint => 'كلمة السر (٨ حروف على الأقل)';

  @override
  String get passwordStrengthWeak => 'ضعيفة';

  @override
  String get passwordStrengthMedium => 'متوسطة';

  @override
  String get passwordStrengthStrong => 'قوية';

  @override
  String get interestHealthyFasting => 'صيام صحي';

  @override
  String get interestWeightLoss => 'تخسيس';

  @override
  String get interestFitness => 'لياقة';

  @override
  String get agreeTermsPrefix => 'أوافق على ';

  @override
  String get agreeTermsLink => 'الشروط والخصوصية';

  @override
  String get createAccountButton => 'إنشاء الحساب';

  @override
  String get haveAccount => 'عندك حساب؟';

  @override
  String get signInLink => 'سجّل دخول';

  @override
  String welcomeTitle(String name) {
    return 'أهلاً بيك يا $name';
  }

  @override
  String get welcomeSubtitle => 'حسابك اتعمل، وسفرتك جاهزة. بالهنا والشفا';

  @override
  String get welcomePoint1 => 'تسجّل أكلك بصوتك بالعامية';

  @override
  String get welcomePoint2 => 'أرقام من مكونات الطبق نفسه';

  @override
  String get welcomePoint3 => 'كشري وفول وملوخية وأكتر';

  @override
  String get welcomeCta => 'يلا نبدأ';

  @override
  String wizardStepOf(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get wizardBack => 'رجوع';

  @override
  String get wizardNext => 'التالي';

  @override
  String get wizardFinish => 'احسب خطتي';

  @override
  String get wizardGenderTitle => 'عرّفنا عليك';

  @override
  String get wizardGenderBody => 'المعلومات دي بتساعدنا نحسب احتياجك بدقة';

  @override
  String get wizardGenderMale => 'ذكر';

  @override
  String get wizardGenderFemale => 'أنثى';

  @override
  String get wizardDobTitle => 'تاريخ ميلادك';

  @override
  String get wizardDobBody => 'عمرك بيأثر على معدل الحرق الأساسي';

  @override
  String get wizardHeightTitle => 'طولك كام؟';

  @override
  String get wizardHeightBody => 'بالسنتيمتر';

  @override
  String get wizardWeightTitle => 'وزنك الحالي';

  @override
  String get wizardWeightBody => 'بالكيلوجرام';

  @override
  String get wizardTargetTitle => 'الوزن اللي عايز توصله';

  @override
  String get wizardTargetBody => 'هدف واقعي أحسن من هدف مستحيل';

  @override
  String get wizardActivityTitle => 'مستوى نشاطك اليومي';

  @override
  String get wizardActivityBody => 'اختار الأقرب لروتينك';

  @override
  String get activitySedentary => 'نشاط قليل';

  @override
  String get activitySedentaryBody => 'شغل مكتبي وحركة بسيطة';

  @override
  String get activityLight => 'نشاط خفيف';

  @override
  String get activityLightBody => 'مشي أو تمرين خفيف ١-٣ أيام';

  @override
  String get activityModerate => 'نشاط متوسط';

  @override
  String get activityModerateBody => 'تمرين ٣-٥ أيام في الأسبوع';

  @override
  String get activityActive => 'نشاط عالي';

  @override
  String get activityActiveBody => 'تمرين عنيف ٦-٧ أيام';

  @override
  String get wizardGoalTitle => 'هدفك إيه؟';

  @override
  String get wizardGoalBody => 'اختار، وسفرة تظبط كل حاجة على مقاسك';

  @override
  String get goalLose => 'أنزّل وزني';

  @override
  String get goalLoseBody => 'سعرات أقل وأكل مشبع';

  @override
  String get goalMaintain => 'أثبّت وزني';

  @override
  String get goalMaintainBody => 'توازن يحافظ على وزنك';

  @override
  String get goalGain => 'أزوّد وزني';

  @override
  String get goalGainBody => 'سعرات أعلى وبروتين أكتر';

  @override
  String get unitCm => 'سم';

  @override
  String get unitKg => 'كجم';

  @override
  String get planTitleUnnamed => 'خطتك جاهزة!';

  @override
  String get welcomeTitleUnnamed => 'أهلاً بيك';

  @override
  String planTitle(String name) {
    return 'خطتك جاهزة يا $name!';
  }

  @override
  String get planDailyCalories => 'سعرك اليومي';

  @override
  String get planProtein => 'بروتين · جم';

  @override
  String get planCarbs => 'كارب · جم';

  @override
  String get planFat => 'دهون · جم';

  @override
  String planTimeline(int weeks) {
    return 'تقدير مبدئي: ممكن تحتاج حوالي $weeks أسبوع، والمدة الفعلية ممكن تختلف';
  }

  @override
  String get planTimelineMaintain => 'هدفك تحافظ على وزنك الحالي';

  @override
  String get planDisclaimer => 'أرقام تقديرية للتوعية';

  @override
  String get planCta => 'ابدأ رحلتك';

  @override
  String get homeGreetingMorning => 'صباح الخير يا';

  @override
  String get homeGreetingEvening => 'مساء الخير يا';

  @override
  String get homeSearchHint => 'دوّر على أكلة أو منتج…';

  @override
  String get homeHeroChip => 'سفرة · اختيارات أذكى';

  @override
  String get homeHeroTitleA => 'أكل بتحبه،';

  @override
  String get homeHeroTitleB => 'وتوازن يناسبك';

  @override
  String get homeHeroBody => 'نظّم وجباتك وصحتك من غير حرمان.';

  @override
  String get homeHeroCta => 'خطّط وجباتك';

  @override
  String get homeEatenToday => 'اللي أكلته النهاردة';

  @override
  String get unitKcal => 'سعر';

  @override
  String homeGoalRemaining(int target, int remaining) {
    return 'الهدف $target · فاضل $remaining';
  }

  @override
  String get homeNoGoalYet => 'كمّل إعدادك الشخصي عشان نحسب هدفك';

  @override
  String get homeStreakDays => 'أيام ورا بعض';

  @override
  String get homeStreakCta => 'كمّل يا بطل';

  @override
  String get macroProtein => 'بروتين';

  @override
  String get macroCarbs => 'كارب';

  @override
  String get macroFat => 'دهون';

  @override
  String get homeMealsToday => 'وجباتك النهاردة';

  @override
  String get homeNoMeals => 'لسه مسجلتش وجبات النهاردة';

  @override
  String get homeAddFirstMeal => 'سجّل أول وجبة';

  @override
  String get homeTipsTitle => 'نصايح سفرة';

  @override
  String get tipWaterTitle => 'اشرب كوباية مية';

  @override
  String tipWaterBody(int count, int goal) {
    return '$count من $goal أكواب';
  }

  @override
  String get tipProteinTitle => 'راجع بروتين يومك';

  @override
  String get tipProteinBody =>
      'راجع المتبقي من هدفك واختار الكمية المناسبة ليك';

  @override
  String get tipLogTitle => 'سجّل أكلك أول بأول';

  @override
  String get tipLogBody => 'التسجيل المنتظم هو سر النتيجة';

  @override
  String get mealBreakfast => 'فطار';

  @override
  String get mealLunch => 'غدا';

  @override
  String get mealDinner => 'عشا';

  @override
  String get mealSnack => 'خفيف';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navDiary => 'اليومية';

  @override
  String get navProgress => 'تقدمي';

  @override
  String get navAccount => 'حسابي';

  @override
  String get comingSoonTitle => 'قريبًا في سفرة';

  @override
  String get comingSoonBody => 'الميزة دي لسه مش متاحة.';

  @override
  String get stateLoading => 'بنحمّل…';

  @override
  String get stateError => 'حصلت مشكلة في التحميل. جرّب تاني';

  @override
  String get stateRetry => 'حاول تاني';

  @override
  String get validationRequired => 'الحقل ده مطلوب';

  @override
  String get validationEmail => 'اكتب إيميل صحيح';

  @override
  String get validationPassword => 'كلمة السر لازم تكون ٨ حروف على الأقل';

  @override
  String get validationName => 'اكتب اسمك';

  @override
  String get validationTerms => 'لازم توافق على الشروط والخصوصية';

  @override
  String get validationNumber => 'اكتب رقم صحيح';

  @override
  String get validationStep => 'كمّل الخطوة دي الأول';

  @override
  String get authInvalidCredentials => 'الإيميل أو كلمة السر غلط';

  @override
  String get authEmailInUse => 'الإيميل ده مسجل قبل كده. جرّب تسجّل دخول';

  @override
  String get authWeakPassword => 'كلمة السر ضعيفة. استخدم ٨ حروف على الأقل';

  @override
  String get authUserNotFound => 'مفيش حساب بالإيميل ده';

  @override
  String get authNetworkError =>
      'مفيش اتصال بالإنترنت. تأكد من الشبكة وحاول تاني';

  @override
  String get authGenericError => 'حصلت مشكلة. حاول تاني بعد شوية';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get logHubTitle => 'هتسجل أكلك إزاي؟';

  @override
  String get logHubSubtitle => 'اختار الطريقة الأنسب، وكلها لمسة واحدة';

  @override
  String get logHubChipPhoto => 'صورة';

  @override
  String get logHubChipBarcode => 'باركود';

  @override
  String get logHubChipVoice => 'صوت';

  @override
  String get logHubChipSearch => 'بحث';

  @override
  String get logHubVoiceTitle => 'بالصوت أو الكتابة';

  @override
  String get logHubVoiceSubtitle => 'قول الأكل وراجع النوع والجرامات';

  @override
  String get logHubFastest => 'الأسرع';

  @override
  String get logHubPhotoTitle => 'صوّر وجبتك';

  @override
  String get logHubPhotoSubtitle => 'صوّر وراجع يدويًا';

  @override
  String get logHubBarcodeTitle => 'امسح باركود';

  @override
  String get logHubBarcodeSubtitle => 'منتج معبّأ';

  @override
  String get logHubSearchTitle => 'ابحث يدويًا';

  @override
  String get logHubSearchSubtitle => 'اختار من قاعدة الأكل';

  @override
  String get logHubFavoritesTitle => 'من المفضلة';

  @override
  String get logHubFavoritesSubtitle => 'بلمسة واحدة';

  @override
  String get logHubRecentTitle => 'آخر وجباتك';

  @override
  String logHubRecentMeal(String name, int calories) {
    return '$name · $calories سعرة';
  }

  @override
  String get logHubRelog => 'أعد التسجيل';

  @override
  String get logHubRelogDone => 'اتسجلت وجبتك في يومك';

  @override
  String get foodSearchHint => 'دوّر على أكلة...';

  @override
  String get foodCatalogTitle => 'دليل الأكل';

  @override
  String get foodSearchStart => 'اكتب اسم الأكلة عشان ندوّر عليها';

  @override
  String get foodSearchEmpty => 'مفيش نتائج. جرّب اسم تاني';

  @override
  String foodPer100g(String value) {
    return '١٠٠ جم · $value سعرة';
  }

  @override
  String get foodNutritionUnknown => 'القيم الغذائية غير متاحة';

  @override
  String get foodGrams => 'الكمية بالجرام';

  @override
  String get foodInvalidGrams => 'اكتب كمية أكبر من صفر ولحد ١٠٬٠٠٠ جم';

  @override
  String get foodUnknown => 'غير معروف';

  @override
  String get foodKcal => 'سعرة';

  @override
  String get foodMg => 'مجم';

  @override
  String get foodGramUnit => 'جم';

  @override
  String foodSource(String source) {
    return 'مصدر البيانات: $source';
  }

  @override
  String get foodIncompleteWarning =>
      'فيه قيم غذائية أو مصدر بيانات ناقص. مش هنحفظ أرقام مجهولة كأنها صفر.';

  @override
  String get foodCalories => 'السعرات';

  @override
  String get foodProtein => 'بروتين';

  @override
  String get foodCarbs => 'كارب';

  @override
  String get foodFat => 'دهون';

  @override
  String get foodFiber => 'ألياف';

  @override
  String get foodSugar => 'سكر';

  @override
  String get foodSodium => 'صوديوم';

  @override
  String get mealReviewTitle => 'راجع وجبتك';

  @override
  String get mealReviewTotal => 'الإجمالي من بيانات المصدر';

  @override
  String get mealTypeLabel => 'نوع الوجبة';

  @override
  String get mealSessionExpired => 'الجلسة اتغيرت. ارجع وسجّل دخول تاني';

  @override
  String get mealSave => 'بالهنا والشفا، احفظ';

  @override
  String get diaryTitle => 'اليومية';

  @override
  String get diaryEmpty => 'لسه مفيش وجبات في اليوم ده';

  @override
  String get diaryPrevious => 'اليوم اللي قبله';

  @override
  String get diaryNext => 'اليوم اللي بعده';

  @override
  String get artRotateHint => 'اسحب عشان تدوّرها';

  @override
  String get diaryChooseDate => 'اختار اليوم';

  @override
  String get diaryEmptySlot => 'لسه فاضي';

  @override
  String get diaryAddMeal => '+ ضيف أكلة';

  @override
  String get diaryOtherMeals => 'وجبات تانية';

  @override
  String get foodRecipes => 'وصفات';

  @override
  String get foodAlternatives => 'بدائل الأكل';

  @override
  String get mealEdit => 'تعديل';

  @override
  String get mealDelete => 'حذف';

  @override
  String get mealDeleteConfirm =>
      'تحب تحذف الوجبة دي؟ إجمالي اليوم هيتحدّث بعدها.';

  @override
  String get mealName => 'اسم الوجبة';

  @override
  String get mealNotes => 'ملاحظات';

  @override
  String get mealEditInvalid => 'راجع اسم الوجبة وكميات المكونات.';

  @override
  String get mealNotFound => 'الوجبة دي مش موجودة للحساب واليوم ده.';

  @override
  String get actionSave => 'حفظ التعديلات';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get mealSuhoor => 'سحور';

  @override
  String get mealIftar => 'إفطار رمضان';

  @override
  String get discoveryMsg001 => 'لم يتم الحفظ. حاول مرة أخرى.';

  @override
  String get discoveryMsg002 => 'الوصفة محجوبة لحين اعتماد ترخيص النشر.';

  @override
  String get discoveryMsg003 => 'الوصفة غير موجودة.';

  @override
  String get discoveryMsg004 => 'رجوع';

  @override
  String get discoveryMsg005 => 'الوقت مش محدد';

  @override
  String get discoveryMsg006 => 'السعرات غير معروفة';

  @override
  String get discoveryMsg007 => 'الحصص غير محددة';

  @override
  String get discoveryMsg008 =>
      'المقادير والخطوات كما نشرها المصدر، وليست ترجمة أو تقديرًا بالجرام.';

  @override
  String get discoveryMsg009 =>
      'لا يمكن تسجيل الوصفة بقيم غذائية دقيقة قبل توثيق أوزان المكونات وعدد الحصص.';

  @override
  String get discoveryMsg010 => 'المصدر والترخيص';

  @override
  String get discoveryMsg011 => 'المصدر والترخيص · تطوير فقط';

  @override
  String get discoveryMsg012 => 'أوزان وحصص وقيم غذائية غير موثقة';

  @override
  String get discoveryMsg013 => 'سجّلها كوجبة';

  @override
  String get discoveryMsg014 => 'تعذر الاقتراح';

  @override
  String get discoveryMsg015 => 'مقدرناش نجيب وصفات دلوقتي. حاول تاني.';

  @override
  String get discoveryMsg016 => 'ضيف مكوناتك';

  @override
  String get discoveryMsg017 =>
      'ضيف مكونًا واحدًا على الأقل عشان نقارن بالمقادير المنشورة.';

  @override
  String get discoveryMsg018 => 'الوصفات دي مش متاحة في النسخة دي دلوقتي.';

  @override
  String get discoveryMsg019 => 'اقترح لي وجبة';

  @override
  String get discoveryMsg020 => 'عندي';

  @override
  String get discoveryMsg021 => '+ ضيف';

  @override
  String get discoveryMsg022 => 'السعرات';

  @override
  String get discoveryMsg023 => 'الوقت';

  @override
  String get discoveryMsg024 => 'مش محدد';

  @override
  String get discoveryMsg025 =>
      'السعرات وأغلب أوقات الوصفات غير متاحة. فلتر الوقت بيقبل الوصفات ذات الوقت الكلي الموثق بس.';

  @override
  String get discoveryMsg026 => 'اقترح';

  @override
  String get discoveryMsg027 => 'مطابقة محلية حسب المكونات';

  @override
  String get discoveryMsg028 => 'عن الاقتراح';

  @override
  String get discoveryMsg029 => 'المصدر وطريقة الاقتراح';

  @override
  String get discoveryMsg030 =>
      'مطابقة كلمات المكونات حرفيًا. نوع الوجبة تفضيل ولا يغير تصنيف المصدر. راجع المكونات الناقصة والحساسيات. TheMealDB للتطوير والتعليم فقط. الذكاء الاصطناعي الاختياري غير مهيأ ما لم تضف خدمة موثقة.';

  @override
  String get discoveryMsg031 => 'اقترح عليّا';

  @override
  String get discoveryMsg032 => 'عرض كل الوصفات';

  @override
  String get discoveryMsg033 => 'ابحث في الوصفات المحلية';

  @override
  String get discoveryMsg034 => 'مسح';

  @override
  String get discoveryMsg035 => 'المحفوظة فقط';

  @override
  String get discoveryMsg036 => 'TheMealDB · تطوير وتعليم فقط';

  @override
  String get discoveryMsg037 => 'لا توجد وصفات مطابقة.';

  @override
  String get discoveryMsg038 => 'سعرات غير معروفة';

  @override
  String get discoveryMsg039 => 'ضيف مكون';

  @override
  String get discoveryMsg040 => 'اسم المكون';

  @override
  String get discoveryMsg041 => 'إلغاء';

  @override
  String get discoveryMsg042 => 'إضافة';

  @override
  String get discoveryMsg043 => 'الرئيسية';

  @override
  String get discoveryMsg044 => 'اليومية';

  @override
  String get discoveryMsg045 => 'تقدمي';

  @override
  String get discoveryMsg046 => 'حسابي';

  @override
  String get discoveryMsg047 => 'تعذر تحميل البيانات. حاول مرة أخرى.';

  @override
  String get discoveryMsg048 => 'إعادة المحاولة';

  @override
  String get discoveryMsg049 => 'تمام';

  @override
  String get discoveryMsg050 => 'التقدم الحالي';

  @override
  String get discoveryMsg051 => 'الهدف';

  @override
  String get discoveryMsg052 => 'عايز بدائل لإيه؟';

  @override
  String get discoveryMsg053 => 'ابحث باسم الطعام الأصلي';

  @override
  String get discoveryMsg054 =>
      'لا توجد مقارنة موثقة لهذا الطعام في الكتالوج الحالي. جرّب اللبن أو الأرز أو الخبز.';

  @override
  String get discoveryMsg055 => 'بدائل من بيانات موثقة';

  @override
  String get discoveryMsg056 =>
      'مقارنة لكل ١٠٠ جم من بيانات الأطعمة المسجلة، مش توصية طبية.';

  @override
  String get discoveryMsg057 => 'منتجات حقيقية';

  @override
  String get discoveryMsg058 =>
      'لا توجد منتجات معبأة موثقة في الكتالوج المحلي.';

  @override
  String get discoveryMsg059 =>
      'لم يتم ربط البحث عن المنتجات بعد. لن نعرض أسعارًا أو درجات غذائية افتراضية.';

  @override
  String get discoveryMsg060 => 'طاقة لكل ١٠٠ جم';

  @override
  String get discoveryMsg061 => 'USDA · تفاصيل المصدر والمقارنة';

  @override
  String get discoveryMsg062 => 'مقارنة لكل ١٠٠ جم';

  @override
  String get discoveryMsg063 => 'الأصل';

  @override
  String get discoveryMsg064 => 'البديل';

  @override
  String get discoveryMsg065 =>
      'الحالة والتحضير يؤثران على المقارنة؛ ليست الحصص متكافئة تلقائيًا.';

  @override
  String get discoveryMsg066 => 'الطاقة (سعرة)';

  @override
  String get discoveryMsg067 => 'الألياف (جم)';

  @override
  String get discoveryMsg068 => 'الدهون (جم)';

  @override
  String get discoveryMsg069 => 'البروتين (جم)';

  @override
  String get discoveryMsg070 => 'أيام ورا بعض';

  @override
  String get discoveryMsg071 => 'مسجل';

  @override
  String get discoveryMsg072 => 'غير مسجل';

  @override
  String get discoveryMsg073 => 'الفانوس الذهبي';

  @override
  String get discoveryMsg074 => 'يوم';

  @override
  String get discoveryMsg075 => 'أوسمتك';

  @override
  String get discoveryMsg076 =>
      'كل تسجيل بيقرّبك من وسام جديد. حدد هدف المياه عشان تتابع تقدّمك فيه.';

  @override
  String get discoveryMsg077 => 'مكتمل';

  @override
  String get discoveryMsg078 => 'لسه مش معروف';

  @override
  String get discoveryMsg079 => 'محتاجين تسجيلات أكتر عشان نعرض تقدمك.';

  @override
  String get discoveryMsg080 => 'وقت تسجيل الإنجاز لأول مرة مش معروف.';

  @override
  String get discoveryMsg081 =>
      'أول مرة سفرة سجّل فيها الإنجاز، مش بالضرورة وقت تحقيقه';

  @override
  String get discoveryMsg082 => 'فانوس الإنجازات';

  @override
  String get discoveryCloudFavoritesNote => 'الحفظ متزامن مع حسابك.';

  @override
  String get discoveryLocalFavoritesNote =>
      'الحفظ على هذا الجهاز لحسابك الحالي.';

  @override
  String get discoverySaved => 'محفوظة';

  @override
  String get discoverySave => 'حفظ';

  @override
  String get discoveryBreakfast => 'فطار';

  @override
  String get discoveryLunch => 'غدا';

  @override
  String get discoveryDinner => 'عشا';

  @override
  String get discoveryWeekday1 => 'ن';

  @override
  String get discoveryWeekday2 => 'ث';

  @override
  String get discoveryWeekday3 => 'ر';

  @override
  String get discoveryWeekday4 => 'خ';

  @override
  String get discoveryWeekday5 => 'ج';

  @override
  String get discoveryWeekday6 => 'س';

  @override
  String get discoveryWeekday7 => 'ح';

  @override
  String get mealIngredientAdd => 'إضافة مكوّن';

  @override
  String get mealIngredientEdit => 'تغيير المكوّن';

  @override
  String get mealIngredientRemove => 'إزالة المكوّن';

  @override
  String get mealDraftIncomplete =>
      'اختار مكوّن ببيانات سعرات معروفة ومصدر واضح، وراجع الكميات واسم الوجبة.';

  @override
  String get mealReviewCatalogHint => 'راجع المكوّنات والكميات قبل الحفظ.';

  @override
  String get progressNavHome => 'الرئيسية';

  @override
  String get progressNavDiary => 'اليومية';

  @override
  String get progressNavProgress => 'تقدمي';

  @override
  String get progressNavAccount => 'حسابي';

  @override
  String get statsTitle => 'تقدمي';

  @override
  String get statsTabWeek => 'أسبوع';

  @override
  String get statsTabMonth => 'شهر';

  @override
  String statsStreakDays(Object count) {
    return '$count أيام ورا بعض';
  }

  @override
  String get statsStreakCheer => 'عاش! كمّل';

  @override
  String get statsCaloriesTitle => 'السعرات';

  @override
  String statsCaloriesAverage(Object avg, Object target) {
    return 'المتوسط $avg / $target';
  }

  @override
  String get statsWeightTitle => 'الوزن';

  @override
  String statsWeightDown(Object kg) {
    return '▼ $kg كجم';
  }

  @override
  String statsWeightUp(Object kg) {
    return '▲ $kg كجم';
  }

  @override
  String get statsBadgesTitle => 'شارات';

  @override
  String get statsNoTrackedDays => 'لسه مفيش أيام متسجلة الفترة دي';

  @override
  String get statsNoWeightData => 'سجّل وزنك عشان تشوف تقدمك';

  @override
  String get reportTitle => 'التقرير';

  @override
  String get reportSubtitle => 'أسبوعك في صورة واحدة';

  @override
  String get reportAverageCalories => 'متوسط السعرات';

  @override
  String reportRingCalories(Object pct) {
    return 'السعرات: $pct٪ من الهدف';
  }

  @override
  String reportRingProtein(Object pct) {
    return 'البروتين: $pct٪ من الهدف';
  }

  @override
  String reportRingFiber(Object pct) {
    return 'ألياف $pct٪';
  }

  @override
  String get reportDailyCommitment => 'الأيام اللي سجلت فيها أكلك';

  @override
  String get reportWaterTitle => 'المياه';

  @override
  String reportWaterCupsOf(Object goal, Object have) {
    return '$have من $goal أكواب';
  }

  @override
  String get reportMealDistribution => 'الوجبات المتسجلة';

  @override
  String reportSugarAlertTitle(Object day) {
    return 'انتبه: سكر $day';
  }

  @override
  String reportSugarAlertBody(Object pct) {
    return 'زاد $pct٪ عن المعتاد، غالبًا من الحلو بعد الغدا';
  }

  @override
  String get waterScreenTitle => 'مية النهاردة';

  @override
  String waterCupsOf(Object goal, Object have) {
    return '$have من $goal أكواب';
  }

  @override
  String waterMlOf(Object goal, Object have) {
    return '$have من $goal مل';
  }

  @override
  String get waterAdd250 => '+ ٢٥٠ مل';

  @override
  String get waterAdd500 => '+ ٥٠٠ مل';

  @override
  String get waterAddCustom => 'مخصص';

  @override
  String get waterAddConfirm => 'أضف';

  @override
  String waterMlValue(Object value) {
    return '$value مل';
  }

  @override
  String get weightScreenTitle => 'وزنك';

  @override
  String get weightSubtitle => 'رحلتك ماشية، وكل خطوة صغيرة بتتحسب';

  @override
  String get weightCurrent => 'وزنك دلوقتي';

  @override
  String get weightKg => 'كجم';

  @override
  String get weightOfYourGoal => 'من هدفك';

  @override
  String weightLighterBy(Object kg) {
    return '▼ أخف بـ $kg كجم';
  }

  @override
  String weightHeavierBy(Object kg) {
    return '▲ أتقل بـ $kg كجم';
  }

  @override
  String get weightYouAreHere => 'إنت هنا';

  @override
  String weightGoalLabel(Object kg) {
    return 'الهدف $kg';
  }

  @override
  String get weightGreatWork => 'شغل ممتاز يا بطل!';

  @override
  String weightToNextMilestone(Object kg) {
    return 'باقي $kg كجم على هدفك. وزنك ممكن يطلع وينزل يوميًا، فتابع الاتجاه مع الوقت.';
  }

  @override
  String get weightLogCta => '+ سجّل وزن اليوم';

  @override
  String get weightLogTitle => 'سجّل وزنك';

  @override
  String get weightLogHint => 'الوزن بالكيلو';

  @override
  String get weightLogSave => 'احفظ';

  @override
  String get weightLogInvalid => 'اكتب وزن صحيح أكبر من صفر';

  @override
  String get exportTitle => 'سفرة · تقرير التغذية';

  @override
  String get exportSubtitle => 'الفترة اللي اخترتها';

  @override
  String get exportPdfBadge => 'PDF';

  @override
  String get exportAdherenceLabel => 'الالتزام';

  @override
  String get exportMacrosTitle => 'المغذيات: المسجّل مقارنة بأهدافك المحفوظة';

  @override
  String get exportMacrosHint => '(الخط الأسود = الهدف)';

  @override
  String get exportProteinLabel => 'بروتين';

  @override
  String get exportCarbsLabel => 'كربوهيدرات';

  @override
  String get exportFatLabel => 'دهون';

  @override
  String get exportAdherenceMapTitle => 'خريطة الالتزام (٢ أسابيع)';

  @override
  String get exportReviewPointsTitle => 'نقاط تحتاج مراجعتك';

  @override
  String get exportReviewSodium =>
      'الصوديوم المسجّل أعلى من متوسط الفترة ٣ أيام ورا بعض';

  @override
  String exportReviewFiber(Object pct) {
    return 'ألياف أقل من الموصى به ($pct٪)';
  }

  @override
  String get exportReviewWaterOk => 'الميّه في آخر يوم وصلت لهدفك المحفوظ';

  @override
  String get exportPdfButton => 'تصدير PDF';

  @override
  String get exportSendToDoctor => 'إرسال للدكتور';

  @override
  String exportGoalLoss(Object kg) {
    return 'الهدف: خفض وزن $kg كجم';
  }

  @override
  String exportBmiLabel(Object bmi) {
    return 'BMI $bmi';
  }

  @override
  String exportYearsOld(Object age) {
    return '$age سنة';
  }

  @override
  String exportCmLabel(Object height) {
    return '$height سم';
  }

  @override
  String get waterGoalDefaultNote => 'هدف استرشادي غير مخصّص';

  @override
  String get statsBadgesUnknown => 'حالة الشارات لم تُحمَّل بعد';

  @override
  String get weekdayLetter1 => 'س';

  @override
  String get weekdayLetter2 => 'ح';

  @override
  String get weekdayLetter3 => 'ن';

  @override
  String get weekdayLetter4 => 'ث';

  @override
  String get weekdayLetter5 => 'ر';

  @override
  String get weekdayLetter6 => 'خ';

  @override
  String get weekdayLetter7 => 'ج';

  @override
  String get weekdayName1 => 'سبت';

  @override
  String get weekdayName2 => 'حد';

  @override
  String get weekdayName3 => 'اتنين';

  @override
  String get weekdayName4 => 'تلات';

  @override
  String get weekdayName5 => 'أربع';

  @override
  String get weekdayName6 => 'خميس';

  @override
  String get weekdayName7 => 'جمعة';

  @override
  String get cameraTitle => 'صوّر وجبتك';

  @override
  String get cameraClose => 'إغلاق';

  @override
  String get cameraFlash => 'الفلاش';

  @override
  String get cameraFlashUnavailable => 'الفلاش مش متاح على الكاميرا دي';

  @override
  String get cameraDenied =>
      'محتاجين إذن الكاميرا. تقدر تجرّب تاني أو تدخل الوجبة بإيدك.';

  @override
  String get cameraRestricted =>
      'افتح إعدادات الجهاز واسمح للتطبيق يستخدم الكاميرا، أو دخل الوجبة بإيدك.';

  @override
  String get cameraMissing => 'مفيش كاميرا متاحة على الجهاز ده';

  @override
  String get cameraFailed =>
      'الكاميرا مش جاهزة. جرّب تاني أو استخدم الإدخال اليدوي.';

  @override
  String get cameraPaused => 'الكاميرا متوقفة';

  @override
  String get cameraStarting => 'بنجهّز الكاميرا';

  @override
  String get cameraRetry => 'جرّب تاني';

  @override
  String get cameraTooLarge => 'الصورة كبيرة شوية. جرّب صورة أصغر.';

  @override
  String get cameraBadImage => 'معرفناش نفتح الصورة دي. جرّب صورة تانية.';

  @override
  String get cameraAiUnavailable =>
      'مش قادرين نقرا الصور دلوقتي. ممكن تدوّر على أكلك وتضيفه بنفسك.';

  @override
  String get cameraEmpty =>
      'مش شايفين أكل واضح في الصورة دي. جرّب صورة تانية أو دوّر على أكلك.';

  @override
  String get cameraInvalidResponse =>
      'معرفناش نقرا الصورة دي. جرّب صورة تانية أو دوّر على أكلك.';

  @override
  String get cameraNetwork =>
      'معرفناش نقرا الصورة دلوقتي. جرّب تاني بعد شوية أو دوّر على أكلك.';

  @override
  String get cameraFrameHint => 'حط الطبق كله جوه الإطار';

  @override
  String get cameraLightHint => 'إضاءة كويسة · ثبّت الموبايل · الطبق كامل';

  @override
  String get cameraCapture => 'التقاط الصورة';

  @override
  String get cameraRetake => 'إعادة التصوير';

  @override
  String get cameraMealType => 'نوع الوجبة';

  @override
  String get cameraNotes => 'ملاحظات تساعد التحليل (اختياري)';

  @override
  String get cameraNotesHint => 'اكتب طريقة التحضير أو أي تفاصيل مهمة';

  @override
  String get cameraNoOil => 'بدون زيت';

  @override
  String get cameraLarge => 'كمية كبيرة';

  @override
  String get cameraSmall => 'كمية صغيرة';

  @override
  String get cameraSugar => 'سكر زيادة';

  @override
  String get cameraGhee => 'مقلي بالسمن';

  @override
  String get cameraPrivacy =>
      'الصورة بتتبعت بعد موافقتك في كل مرة. نوع الوجبة والملاحظات مش بيتبعتوا للتحليل. راجع النتيجة والكميات قبل الحفظ.';

  @override
  String get cameraNoUpload =>
      'تحليل الصور غير مفعّل. الصورة بتفضل مؤقتاً على جهازك ومش بتتبعت لأي خدمة.';

  @override
  String get cameraAnalyzing => 'بنحلّل وجبتك';

  @override
  String get cameraAnalyze => 'حلّل الصورة';

  @override
  String get cameraReviewWarning =>
      'دي اقتراحات مش قياسات. اختار الأكل والكميات من القاعدة قبل الحفظ.';

  @override
  String get cameraManual => 'اختار الأكل من القاعدة';

  @override
  String get cameraSkip => 'استبعاد الاقتراح';

  @override
  String get cameraSkipped => 'مستبعد';

  @override
  String get exportKgUnit => 'كجم';

  @override
  String get progressUnknownNote =>
      'الشرطة (—) معناها إن البيانات أو الأهداف وقت التسجيل مش متاحة، مش صفر.';

  @override
  String get reportUnknownCalories => 'السعرات: غير متاحة';

  @override
  String get reportUnknownProtein => 'البروتين: غير متاح';

  @override
  String get reportUnknownFiber => 'الألياف: غير متاحة';

  @override
  String get voiceListening => 'سامعينك… قول وصف وجبتك';

  @override
  String get voiceStarting => 'بنجهّز الميكروفون';

  @override
  String get voiceReady => 'اضغط على الميكروفون أو اكتب وصف وجبتك';

  @override
  String get voiceDenied =>
      'إذن الميكروفون مش متاح. راجع إعدادات الجهاز أو اكتب الوصف.';

  @override
  String get voiceUnavailable =>
      'التعرف على الصوت مش متاح على الجهاز ده. تقدر تكتب الوصف.';

  @override
  String get voiceLanguageUnavailable =>
      'لغة التطبيق مش متاحة للتعرف على الصوت على الجهاز ده. اكتب الوصف.';

  @override
  String get voiceNoSpeech => 'مسمعناش كلام واضح. جرّب تاني أو اكتب الوصف.';

  @override
  String get voiceFailed => 'التعرف على الصوت موصلش. جرّب تاني أو اكتب الوصف.';

  @override
  String get voiceStop => 'وقف التسجيل';

  @override
  String get voiceStart => 'ابدأ وصف بالصوت';

  @override
  String get voicePrivacy =>
      'الميكروفون بيشتغل لما تضغط بس. خدمة التعرف على الصوت في جهازك ممكن تبعت الصوت لمقدمها. سفرة مش بتحفظ تسجيل صوتي.';

  @override
  String get voiceTextHint => 'مثال: فول وعيش وخيار';

  @override
  String get voiceDescription => 'وصف الوجبة، قابل للتعديل';

  @override
  String get voiceFindFoods => 'دوّر على الأكل في القاعدة';

  @override
  String get voicePortionWarning =>
      'البحث بيقترح أصناف من القاعدة، مش بيحسب وزن من الكلام. اختار الأصناف وراجع الجرامات قبل الحفظ.';

  @override
  String get voiceNoFoods =>
      'ملقيناش أصناف مطابقة. دوّر باسم الأكلة أو اختارها من القاعدة.';

  @override
  String get waterWeekRecordedTitle => 'المية المسجلة آخر ٧ أيام';

  @override
  String get barcodeTitle => 'امسح الباركود';

  @override
  String get barcodeClose => 'إغلاق';

  @override
  String get barcodeFlash => 'فلاش';

  @override
  String get barcodeFlashUnavailable => 'الفلاش مش متاح على الجهاز ده';

  @override
  String get barcodeStartCamera => 'شغّل الكاميرا';

  @override
  String get barcodeAim => 'وجّه الكاميرا ناحية الباركود';

  @override
  String get barcodeSearching => 'بيدوّر على الباركود…';

  @override
  String get barcodeManualLabel => 'أو اكتب الرقم اللي تحت الباركود';

  @override
  String get barcodeManualField => 'رقم الباركود';

  @override
  String get barcodeLookup => 'دوّر';

  @override
  String get barcodePhotoFallback => 'صوّر الجدول الغذائي';

  @override
  String get barcodeSearchFallback => 'ابحث في الأكلات';

  @override
  String get barcodeCameraDenied =>
      'الكاميرا مش مسموحة للتطبيق. اكتب الرقم تحت، أو فعّل إذن الكاميرا من إعدادات الجهاز.';

  @override
  String get barcodeCameraUnsupported =>
      'الجهاز ده مفيهوش كاميرا متاحة. اكتب الرقم تحت.';

  @override
  String get barcodeCameraError =>
      'الكاميرا مش شغالة دلوقتي. اكتب الرقم تحت أو جرّب تاني.';

  @override
  String get barcodeRetryCamera => 'جرّب الكاميرا تاني';

  @override
  String barcodeLooking(String code) {
    return 'بنجيب بيانات $code';
  }

  @override
  String get barcodeInvalid =>
      'الرقم غلط. لازم يكون ٨ أو ١٢ أو ١٣ أو ١٤ رقم وصحيح حسب رقم التحقق.';

  @override
  String barcodeNotFound(String code) {
    return 'ملقيناش المنتج $code. اتأكد من الرقم أو دوّر باسمه.';
  }

  @override
  String get barcodeNotFoundHelp =>
      'ممكن تدوّر عليه بالاسم أو تصوّر الجدول الغذائي. مش هنسجّل أرقام من عندنا.';

  @override
  String get barcodeRetry => 'حاول تاني';

  @override
  String get barcodeOffline =>
      'مفيش اتصال بالإنترنت أو الاتصال بطيء. اتأكد وحاول تاني، أو اكتب الأكلة يدوي.';

  @override
  String barcodeRateLimited(int seconds) {
    return 'طلبات كتير في وقت قصير. جرّب بعد $seconds ثانية.';
  }

  @override
  String get barcodeUnavailable =>
      'خدمة Open Food Facts مش متاحة دلوقتي. حاول بعد شوية.';

  @override
  String get barcodeBadResponse =>
      'الرد من المصدر مش مفهوم. حاول تاني بعد شوية.';

  @override
  String get barcodeNotConfigured =>
      'البحث بالباركود مش متاح في النسخة دي لسه.';

  @override
  String get productTitle => 'بيانات المنتج';

  @override
  String get productBack => 'رجوع';

  @override
  String get productNoImage => 'مفيش صورة للمنتج في المصدر';

  @override
  String get productNutritionPer100g => 'القيم الغذائية لكل ١٠٠ جم';

  @override
  String get productNutritionPer100ml => 'القيم الغذائية لكل ١٠٠ مل';

  @override
  String get productNotProvided => 'غير مذكور';

  @override
  String get productCalories => 'السعرات';

  @override
  String get productProtein => 'بروتين';

  @override
  String get productCarbs => 'كربوهيدرات';

  @override
  String get productFat => 'دهون';

  @override
  String get productFiber => 'ألياف';

  @override
  String get productSugars => 'سكر';

  @override
  String get productSodium => 'صوديوم';

  @override
  String get productKcalUnit => 'سعرة';

  @override
  String get productGramUnit => 'جم';

  @override
  String get productMgUnit => 'ملليجرام';

  @override
  String productServing(String serving) {
    return 'حجم الحصة المذكور: $serving';
  }

  @override
  String productQuantity(String quantity) {
    return 'الكمية في العبوة: $quantity';
  }

  @override
  String get productIngredients => 'المكوّنات (كما في المصدر)';

  @override
  String get productAllergens => 'مسببات الحساسية المذكورة في المصدر';

  @override
  String get productAllergensNone =>
      'المصدر مذكرش مسببات حساسية. ده مش معناه إن المنتج خالٍ منها.';

  @override
  String get productAllergensUnknown =>
      'المصدر ملوش بيانات عن مسببات الحساسية. اقرأ العبوة.';

  @override
  String get productAllergensCaveat =>
      'البيانات من مساهمين وقد تكون ناقصة. اقرأ العبوة دايمًا لو عندك حساسية.';

  @override
  String get productNutriScore => 'نوتري سكور';

  @override
  String get productNutriScoreFromSource => 'كما ورد في المصدر';

  @override
  String get productAttribution =>
      'المصدر: Open Food Facts. البيانات من مساهمين ومرخّصة بترخيص ODbL وقد تكون ناقصة أو قديمة.';

  @override
  String get productFromCache => 'نسخة محفوظة على الجهاز';

  @override
  String get productPortionLabel => 'الكمية بالجرام';

  @override
  String productUseServing(String grams) {
    return 'حصة $grams جم';
  }

  @override
  String get productAddToDiary => 'أضف لليومية';

  @override
  String get productGramsInvalid => 'اكتب كمية بالجرام أكبر من صفر وحتى ١٠٠٠٠.';

  @override
  String get productCannotLogMl =>
      'القيم دي لكل ١٠٠ مل. مش هنحوّلها لجرامات لأن كثافة المنتج مش معروفة، فمفيش تسجيل بالجرام.';

  @override
  String get productCannotLogNoEnergy =>
      'السعرات مش مذكورة في المصدر، فمش هينفع نسجّل المنتج ده.';

  @override
  String get productNutritionBasisUnknown =>
      'القيم كما وردت، وحدة الأساس غير مؤكدة';

  @override
  String get productCannotLogUnknownBasis =>
      'الوحدة الأساسية مش واضحة أو متعارضة في المصدر. مش هنحوّل القيم لجرامات. راجع الملصق أو اختار أكلة من القاعدة.';

  @override
  String get favoritesTitle => 'المفضلة';

  @override
  String get favoritesTabMeals => 'وجبات مفضلة';

  @override
  String get favoritesTabRecipes => 'وصفات محفوظة';

  @override
  String get favoritesTabFrequent => 'الأكتر تسجيلًا';

  @override
  String get favoritesHeroChip => 'الأكثر تسجيلًا';

  @override
  String favoritesHeroCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عدد مرات تسجيلها في آخر ٣٠ يوم: $count',
      few: 'سجّلتها $count مرات في آخر ٣٠ يوم',
      two: 'سجّلتها مرتين في آخر ٣٠ يوم',
      one: 'سجّلتها مرة في آخر ٣٠ يوم',
    );
    return '$_temp0';
  }

  @override
  String get favoritesSortLabel => 'ترتيب';

  @override
  String get favoritesSortRecent => 'الأحدث';

  @override
  String get favoritesSortName => 'الاسم';

  @override
  String get favoritesSortCalories => 'السعرات';

  @override
  String get favoritesRemove => 'شيل من المفضلة';

  @override
  String get favoritesRemoved => 'اتشالت من المفضلة';

  @override
  String get favoritesRemoveFailed => 'معرفناش نشيلها. جرّب تاني.';

  @override
  String get favoritesAddToDiary => 'أضف لليومية';

  @override
  String get favoritesAdded => 'اتضافت لليومية';

  @override
  String get favoritesAddFailed => 'معرفناش نضيفها. جرّب تاني.';

  @override
  String get favoritesSaved => 'اتحفظت في المفضلة';

  @override
  String get favoritesSaveFailed => 'معرفناش نحفظها في المفضلة. جرّب تاني.';

  @override
  String get favoritesPickMealType => 'تضيفها كـ';

  @override
  String get favoritesUnavailable => 'الوجبة الأصلية اتمسحت';

  @override
  String get favoritesUnavailableHint => 'تقدر تشيلها من المفضلة بس.';

  @override
  String favoritesMealMeta(String kcal) {
    return '$kcal سعرة';
  }

  @override
  String favoritesMealMetaProtein(String kcal, String protein) {
    return '$kcal سعرة · $protein جم بروتين';
  }

  @override
  String favoritesFrequentCount(int count) {
    return 'اتسجّل $count مرات';
  }

  @override
  String get favoritesFrequentNote => 'من وجباتك المسجّلة آخر ٣٠ يوم.';

  @override
  String get favoritesEmptyMealsTitle => 'لسه مفيش وجبات مفضلة';

  @override
  String get favoritesEmptyMealsBody =>
      'افتح وجبة اتسجلت واضغط القلب عشان تلاقيها هنا.';

  @override
  String get favoritesEmptyRecipesTitle => 'لسه مفيش وصفات محفوظة';

  @override
  String get favoritesEmptyRecipesBody =>
      'احفظ وصفة من اقتراحات الوصفات وهتظهر هنا.';

  @override
  String get favoritesEmptyFrequentTitle => 'مفيش أكل متكرر لسه';

  @override
  String get favoritesEmptyFrequentBody =>
      'لما تسجّل أكلك كذا مرة هيظهر الأكتر تكرارًا هنا.';

  @override
  String get favoritesLoadFailed => 'معرفناش نحمّل المفضلة.';

  @override
  String get favoritesRetry => 'حاول تاني';

  @override
  String get favoritesExpired => 'الجلسة خلصت. ادخل تاني.';

  @override
  String get premiumTitle => 'سفرة بريميوم';

  @override
  String get premiumSubtitle => 'ميزات إضافية جاية قريب';

  @override
  String get premiumComingSoonChip => 'قريبًا';

  @override
  String get premiumFeatureCoachTitle => 'مدرّب ذكي';

  @override
  String get premiumFeatureCoachBody => 'نصايح مبنية على أكلك';

  @override
  String get premiumFeatureReportsTitle => 'تقارير أسبوعية';

  @override
  String get premiumFeatureReportsBody => 'ملخص لتقدمك كل أسبوع';

  @override
  String get premiumFeaturePlanTitle => 'تخطيط وجبات';

  @override
  String get premiumFeaturePlanBody => 'خطة أسبوع على مقاسك';

  @override
  String get premiumNotAvailable => 'الاشتراك مش متاح دلوقتي';

  @override
  String get premiumBack => 'رجوع';

  @override
  String get plannerTitle => 'خطة الأسبوع';

  @override
  String get plannerEmpty =>
      'لسه مفيش خطة للأسبوع ده. اضغط ولّد خطة جديدة عشان تبدأ.';

  @override
  String get plannerDayEmpty =>
      'مفيش وجبات في اليوم ده. ضيف وجبة من الأزرار تحت.';

  @override
  String get plannerTotal => 'المجموع';

  @override
  String get plannerMissingTarget =>
      'كمّل إعدادك الشخصي عشان نعرف هدفك اليومي ونجهّز خطة مناسبة.';

  @override
  String get plannerGenerate => 'ولّد خطة جديدة';

  @override
  String get plannerShoppingCta => 'قائمة التسوق';

  @override
  String get plannerReplace => 'استبدال';

  @override
  String get plannerAddMeal => 'ضيف';

  @override
  String get weekdaySat => 'س';

  @override
  String get weekdaySun => 'ح';

  @override
  String get weekdayMon => 'ن';

  @override
  String get weekdayTue => 'ث';

  @override
  String get weekdayWed => 'ر';

  @override
  String get weekdayThu => 'خ';

  @override
  String get weekdayFri => 'ج';

  @override
  String get shoppingTitle => 'قايمة التسوق';

  @override
  String get shoppingEmpty =>
      'القايمة فاضية. ولّدها من خطة الأسبوع أو ضيف صنف بنفسك.';

  @override
  String get shoppingGenerateFromPlan => 'ولّد من خطة الأسبوع';

  @override
  String get shoppingRegenerate => 'حدّث من خطة الأسبوع';

  @override
  String get shoppingNoPlan =>
      'ولّد واحفظ خطة الأسبوع الأول عشان تقدر تولّد القايمة منها.';

  @override
  String shoppingSkipped(int count) {
    return '$count صنف محتاجين تراجع كميتهم في الخطة قبل إضافتهم.';
  }

  @override
  String shoppingItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صنف',
      many: '$count صنف',
      few: '$count أصناف',
      two: 'صنفين',
      one: 'صنف واحد',
      zero: '٠ أصناف',
    );
    return '$_temp0';
  }

  @override
  String get shoppingGroupProduce => 'خضار وفاكهة';

  @override
  String get shoppingGroupProtein => 'بروتين';

  @override
  String get shoppingGroupDairy => 'ألبان';

  @override
  String get shoppingGroupGrains => 'حبوب ونشويات';

  @override
  String get shoppingGroupOther => 'أخرى';

  @override
  String get shoppingAddTitle => 'ضيف صنف بنفسك';

  @override
  String get shoppingAddName => 'اسم الصنف';

  @override
  String get shoppingAddInvalid => 'اكتب اسم الصنف وكمية أكبر من صفر';

  @override
  String get coachTitle => 'مدرّب سفرة';

  @override
  String get coachStatusReviewing => 'بيراجع سجلات وجباتك المحفوظة';

  @override
  String get coachStatusIdle => 'مستني أول تسجيل منك';

  @override
  String get coachRuleBadge => 'من سجلاتك';

  @override
  String get coachRuleBadgeShort => 'سجلاتك';

  @override
  String get coachToday => 'النهاردة';

  @override
  String get coachReviewNote => 'المدرّب بيراجع وجباتك آخر ٧ أيام';

  @override
  String get coachNoRecordsNote => 'لسه مفيش سجلات كفاية — سجّل وجبتك الأولى';

  @override
  String get coachSendFailed => 'الرسالة متسجلتش. حاول تاني.';

  @override
  String get coachInputHint => 'اسأل مدرّب سفرة...';

  @override
  String get coachAdviceLabel => 'نصيحة';

  @override
  String get coachQuickPlan => 'اعمل لي خطة غدا';

  @override
  String get coachQuickWeek => 'حلل أسبوعي';

  @override
  String get coachQuickWater => 'أشرب كام مية؟';

  @override
  String get ramadanGreeting => 'رمضان كريم';

  @override
  String get ramadanUntilIftar => 'فاضل على الإفطار';

  @override
  String get ramadanUntilTaraweeh => 'فاضل على بعد التراويح';

  @override
  String get ramadanUntilSuhoor => 'فاضل على آخر السحور';

  @override
  String get ramadanSeconds => 'ثانية';

  @override
  String get ramadanMinutes => 'دقيقة';

  @override
  String get ramadanHours => 'ساعة';

  @override
  String get ramadanSuhoorEnd => 'آخر السحور';

  @override
  String get ramadanIftarAt => 'الإفطار';

  @override
  String get ramadanTaraweeh => 'بعد التراويح';

  @override
  String get ramadanCups => 'أكواب';

  @override
  String get ramadanCupsUserNote => 'هدف الأكواب ده انت اللي ظبطه';

  @override
  String get ramadanCupsDefaultNote =>
      '٨ أكواب عرض افتراضي من التصميم، مش هدف صحي شخصي — تقدر تظبطه';

  @override
  String get ramadanEditTimes => 'ظبط مواعيدك';

  @override
  String get ramadanDisclaimer => 'للتوعية فقط، استشر طبيبك لو عندك سكر أو حمل';

  @override
  String get ramadanSetupBody =>
      'التطبيق مش بيخترع مواعيد صلاة. ظبط مواعيد الإفطار والسحور على حسب بلدك وجدولك، وهنكمل العد والتنظيم عليها.';

  @override
  String get ramadanSetupCta => 'ظبط مواعيد رمضان';

  @override
  String get ramadanChooseTime => 'اختار الوقت';

  @override
  String get ramadanTimesTitle => 'مواعيد رمضان بتاعتك';

  @override
  String get ramadanTimesNote =>
      'اختار كل وقت حسب مدينتك ومواعيدك. التطبيق مش بيحسب مواقيت الصلاة هنا، وتقدر تغيّرها في أي وقت.';

  @override
  String get plannerAllergyWarning =>
      'لو عندك حساسية، راجع مكونات كل وجبة وعبوتها قبل الأكل. الخطة مش ضمان لخلو الوجبة من مسببات الحساسية.';

  @override
  String get coachVoicePrivacy =>
      'الإملاء الصوتي ممكن يبعت الصوت لمزوّد التعرف على الكلام في جهازك. سفرة مش بيحفظ الصوت؛ الكلام هيظهر هنا عشان تراجعه وتعدّله قبل الإرسال.';

  @override
  String get coachVoiceCancel => 'إلغاء';

  @override
  String get coachVoiceStart => 'إملاء صوتي';

  @override
  String get coachVoiceListening => 'جاري الاستماع. راجع الكلام قبل ما تبعته.';

  @override
  String get coachVoiceUnavailable =>
      'الإملاء غير متاح أو لم يسمع كلاماً. راجع إذن الميكروفون واللغة، أو اكتب رسالتك.';

  @override
  String statsBadgesEarned(String earned, String total) {
    return '$earned من $total شارات متحققة';
  }

  @override
  String plannerWeekTotal(String calories) {
    return 'مجموع الأسبوع: $calories سعرة';
  }

  @override
  String get avatarLocalNote =>
      'اختار صورة لحسابك، هتتحفظ على الجهاز ده بس ومش هتترفع لأي خدمة.';

  @override
  String get avatarChoose => 'اختار صورة البروفايل';

  @override
  String get avatarFailed => 'مقدرناش نحفظ الصورة. جرب صورة تانية.';

  @override
  String get appLanguage => 'اللغة';

  @override
  String get cameraGallery => 'اختار صورة من المعرض';

  @override
  String get exportSelectRange => 'اختار فترة التقرير';

  @override
  String get exportRangeLimit => 'اختار فترة لحد سنة واحدة لكل تقرير.';

  @override
  String get exportLoggedWater => 'المية المسجلة حسب اليوم (مل)';

  @override
  String get exportWeightHistory => 'سجل الوزن المسجل (كجم)';

  @override
  String get exportNoWeightHistory => 'مفيش تسجيلات وزن خلال الفترة المختارة.';

  @override
  String get exportNoWaterRecord => 'مفيش كمية مية مسجلة';

  @override
  String exportTrackingDays(String days) {
    return 'خريطة التسجيل (عدد أيام الفترة: $days)';
  }

  @override
  String get themeAccentPicker => 'ألوان المظهر الحالي';

  @override
  String get remindersTitle => 'التذكيرات';

  @override
  String get remindersWaterTitle => 'تذكير المية';

  @override
  String get remindersWaterAdd => 'أضف ميعاد';

  @override
  String get remindersWaterRemove => 'شيل الميعاد';

  @override
  String get remindersWaterFull => 'وصلت لأقصى عدد مواعيد للمية.';

  @override
  String get remindersMealsTitle => 'تذكير الوجبات';

  @override
  String get remindersWeightTitle => 'تذكير الوزن';

  @override
  String remindersWeightEvery(String day) {
    return 'كل أسبوع يوم $day';
  }

  @override
  String get remindersPickDay => 'اختار اليوم';

  @override
  String get remindersNotSet => 'لسه مفيش ميعاد';

  @override
  String get remindersPermissionOff =>
      'إشعارات سفرة مقفولة من إعدادات الجهاز. افتحها من هناك عشان التذكيرات توصلك.';

  @override
  String get remindersPermissionDenied =>
      'من غير إذن الإشعارات مش هنقدر نبعتلك تذكير.';

  @override
  String get remindersScheduleFailed =>
      'معرفناش نظبط التذكير على الجهاز. جرّب تاني.';

  @override
  String get remindersTimezoneUnavailable =>
      'معرفناش نحدد توقيت الجهاز، فالتذكيرات متظبطتش.';

  @override
  String get remindersSaveFailed => 'معرفناش نحفظ التغيير. جرّب تاني.';

  @override
  String get remindersInexactNote =>
      'التذكيرات مش بتتحدد بالدقيقة بالظبط. ممكن توصل متأخرة شوية، خصوصًا لو الموبايل في وضع توفير الطاقة.';

  @override
  String get remindersPrivacyNote =>
      'التذكيرات محفوظة على جهازك بس، وبتشتغل لحسابك الحالي.';

  @override
  String get remindersNotifTitle => 'سفرة';

  @override
  String get remindersNotifWater =>
      'لو مناسب ليك، خد لحظة للمية. افتح سفرة وسجّل اللي شربته.';

  @override
  String remindersNotifMeal(String meal) {
    return 'جاهز تسجّل $meal؟ افتح سفرة وراجع أكلك وكميته.';
  }

  @override
  String get remindersNotifWeight =>
      'لو ده وقت مناسب، سجّل وزنك. ركّز على الاتجاه مش رقم يوم واحد.';

  @override
  String get remindersChannelWater => 'تذكير المية';

  @override
  String get remindersChannelMeals => 'تذكير الوجبات';

  @override
  String get remindersChannelWeight => 'تذكير الوزن';

  @override
  String get reminderCleanupFailed =>
      'تعذر تأكيد إلغاء التذكيرات. ممكن تفضل تظهر على الجهاز لحد فتح التطبيق ومحاولة الإلغاء تاني.';

  @override
  String get reportMeasuredAverages => 'متوسط القيم المسجّلة';

  @override
  String reportMetricCoverage(String measured, String total) {
    return '$measured من $total يوم فيه قيمة مسجّلة';
  }

  @override
  String reportRangeLabel(String start, String end) {
    return 'الفترة: $start لحد $end';
  }

  @override
  String get waterGoalChoose => 'غيّر هدف الميّه';

  @override
  String get waterGoalChosenNote =>
      'هدفك اللي اخترته، محفوظ على الجهاز للحساب ده';

  @override
  String get waterGoalLocalHint =>
      'اختار هدفك بالملليلتر. مش توصية طبية، ومش بيتزامن بين الأجهزة.';

  @override
  String get waterGoalInvalid => 'اكتب كمية أكبر من صفر ولحد ٢٠٠٠٠ مل';

  @override
  String get alternativesPreferenceNote =>
      'البدائل بتراعي حساسية وتفضيلات ملفك بمطابقة الأسماء والفئات فقط، مش فحص أمان للحساسية. راجع المكونات والملصق. لو عندك قيد غذائي مش مدعوم، مش هنعرض بديل على إنه مناسب.';

  @override
  String cameraConsentTitle(String provider) {
    return 'إرسال الصورة إلى $provider؟';
  }

  @override
  String get cameraConsentDetail =>
      'الإرسال للصورة دي بس حسب الشرح أعلاه. نوع الوجبة والملاحظات مش بيتبعتوا للتحليل، وبيفضلوا للوجبة اللي تراجعها وتحفظها. تقدر تلغي وتختار الأكل يدوي.';

  @override
  String get cameraConsentTitleShort => 'نبعت الصورة للتحليل؟';

  @override
  String get cameraConsentShort =>
      'الصورة بتتستخدم للتحليل ده بس ومش بتتحفظ. وإنت اللي بتراجع كل حاجة قبل الحفظ.';

  @override
  String get cameraConsentDetailsToggle => 'التفاصيل';

  @override
  String get cameraConsentSend => 'وافق وابعت المرة دي';

  @override
  String get recipeCalorieLimit => 'حد أقصى للسعرات للحصة';

  @override
  String get recipeTimeLimit => 'وقت الطبخ بحد أقصى';

  @override
  String get recipeNoLimit => 'من غير حد';

  @override
  String get recipeStrictConstraints =>
      'الاقتراح بيحتاج نوع وجبة موثّق، ومع الحدود كمان وقت وسعرات موثّقة. الوصفات اللي بياناتها ناقصة مش هنعتبرها مطابقة. تقدر تتصفحها من غير اقتراح مقيّد.';

  @override
  String get recipeYourVersion => 'نسختك بالكميات اللي راجعتها';

  @override
  String get recipeQuantifiedNotice =>
      'دي نسخة من اختيارك مش قيم المصدر. طابق كل مكوّن بصنف وحالة التحضير من القاعدة، واكتب جرامات الوصفة كلها والعائد. أي مكوّن مستبعد لازم يكون مش موجود فعلاً. القيم هتتحسب من الجرامات دي بس، ومش هنسجّل حاجة قبل المراجعة.';

  @override
  String get recipeExcludeIngredient => 'مش مستخدم في نسختي';

  @override
  String get recipeYield => 'عدد الحصص الناتجة من الوصفة';

  @override
  String get recipeServingsToLog => 'الحصص اللي هتسجّلها';

  @override
  String get recipeMatchEveryIngredient =>
      'راجع كل مكوّن: طابقه وادخل جراماته، أو أكّد إنه مش مستخدم.';

  @override
  String get recipeBuildQuantified => 'راجع كمياتي وسجّل';

  @override
  String get recipeExcludedCount => 'عدد المكونات المستبعدة';

  @override
  String get foodCategoryAll => 'كل الأصناف';

  @override
  String get foodCategoryEgyptian => 'أساسيات الأكل المصري';

  @override
  String get foodCategoryGrains => 'حبوب';

  @override
  String get foodCategoryLegumes => 'بقوليات';

  @override
  String get foodCategoryVegetables => 'خضار';

  @override
  String get foodCategoryDairy => 'ألبان';

  @override
  String get foodCategoryPoultry => 'فراخ';

  @override
  String get foodCategoryProducts => 'منتجات بالباركود';

  @override
  String get foodManualTitle => 'أضف صنف يدوي';

  @override
  String get foodManualNote =>
      'اكتب قيم كل ١٠٠ جرام من الملصق أو مصدرك. دي قيم من إدخالك مش موثّقة من سفرة. البيانات الناقصة هتفضل غير معروفة.';

  @override
  String get foodManualSource => 'اسم العبوة';

  @override
  String get foodManualRequired => 'مطلوب';

  @override
  String get foodManualConfirm => 'راجعت إن القيم لكل ١٠٠ جرام ونقلتها صح';

  @override
  String get foodManualInvalid =>
      'راجع الاسم والمصدر والسعرات والقيم وأكّد المراجعة';

  @override
  String get registrationPolicyUnavailable =>
      'التسجيل الجديد متوقف لحد ما سياسة الخصوصية والشروط المعتمدة تتضاف. تسجيل الدخول للحسابات الموجودة متاح.';

  @override
  String get statsMacroPerformance => 'متوسط أداء الماكروز';

  @override
  String statsMacroCoverage(String count, String total, String goal) {
    return '$count من $total يوم فيه قيمة مسجّلة. متوسط الهدف: $goal جم';
  }

  @override
  String get ownerTerms => 'شروط الاستخدام';

  @override
  String get ownerPrivacy => 'سياسة الخصوصية';

  @override
  String get cameraCandidateSafetyNote =>
      'ده اقتراح من الصورة بس. أكد المكونات ووزن الكمية بنفسك.';

  @override
  String get cameraNutritionSafetyNote =>
      'التعرّف من الصورة مش بيقيس الوزن بالجرام ومش بيدي قيم غذائية مؤكدة.';

  @override
  String get homeBrowseMeals => 'قسّم سفرتك';

  @override
  String get homeMealSuggestions => 'أطباق سفرتك';

  @override
  String get homeRecipeNutritionUnknown => 'التغذية محتاجة كميات المكونات';

  @override
  String get homeRecipeSourceNote => 'TheMealDB · كتالوج تعليمي للتطوير';

  @override
  String get homeRecipeUnavailable => 'اقتراحات الوصفات مش متاحة في النسخة دي.';

  @override
  String get homeOpenRecipes => 'تصفّح الوصفات';

  @override
  String get homeFeaturedRecipe => 'من أطباق سفرة';

  @override
  String get homeSourceCategoryNote =>
      'التقسيم حسب فئات المصدر، مش توصية غذائية.';

  @override
  String get homeCategoryVegetarian => 'نباتي · تصنيف المصدر';

  @override
  String get homeCategoryChicken => 'فراخ';

  @override
  String get homeCategoryBeef => 'لحوم بقري';

  @override
  String get homeCategorySide => 'أطباق جانبية';

  @override
  String get unitMinutesShort => 'دقيقة';

  @override
  String get plannerPortionNote =>
      'دي بداية لترتيب وجباتك، مش نظام كامل. عدّل الكميات حسب احتياجك؛ المجموع قد يختلف عن هدفك.';

  @override
  String reportLoggedCoverage(int count, int total) {
    return 'المتوسط من الأيام اللي سجلت فيها: $count من $total';
  }

  @override
  String get reportWaterToday => 'ميّه النهارده';

  @override
  String get reportNoMeals => 'مفيش تفاصيل وجبات نعرض توزيعها';

  @override
  String get reportOtherMeals => 'وجبات تانية';

  @override
  String get reportRecordedFiber => 'الألياف المسجّلة';

  @override
  String get weightHistoryNeeded =>
      'التقدم مش متاح بالبيانات الحالية. محتاج هدف مختلف عن وزن البداية وتسجيلين في وقتين مختلفين. الوزن الواحد مش كفاية عشان نعرف الاتجاه.';

  @override
  String get weightLoadedProgress =>
      'التقدم من أقدم وزن ظاهر في السجل الحالي، مش من بداية استخدام التطبيق.';

  @override
  String weightBaselineDetail(String kg, String date) {
    return 'بداية السجل الظاهر: $kg كجم، $date';
  }

  @override
  String weightCurrentDetail(String kg) {
    return 'الوزن الحالي: $kg كجم';
  }

  @override
  String weightTargetDetail(String kg) {
    return 'هدفك المحفوظ: $kg كجم';
  }

  @override
  String get weightProgressBaselineLabel => 'من بداية السجل';
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'سفرة'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In ar, this message translates to:
  /// **'صحتك على سفرتك'**
  String get appTagline;

  /// No description provided for @splashBlessing.
  ///
  /// In ar, this message translates to:
  /// **'بالهنا والشفا'**
  String get splashBlessing;

  /// No description provided for @onboardingSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In ar, this message translates to:
  /// **'يلا نبدأ'**
  String get onboardingStart;

  /// No description provided for @onboardingCounter.
  ///
  /// In ar, this message translates to:
  /// **'{current} / {total}'**
  String onboardingCounter(int current, int total);

  /// No description provided for @onboarding1Title.
  ///
  /// In ar, this message translates to:
  /// **'سجّل أكلك بالكلام'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In ar, this message translates to:
  /// **'قول اللي أكلته بالعامية وإحنا نفهمك في ثواني'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In ar, this message translates to:
  /// **'أرقام تقدر تثق فيها'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In ar, this message translates to:
  /// **'بنحسب من مكونات الطبق نفسه، مش تخمين'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In ar, this message translates to:
  /// **'أكلك المصري كله'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In ar, this message translates to:
  /// **'كشري، فول، ملوخية، محشي... كلها في سفرة'**
  String get onboarding3Body;

  /// No description provided for @loginTitleA.
  ///
  /// In ar, this message translates to:
  /// **'ما تاكلش أقل،'**
  String get loginTitleA;

  /// No description provided for @loginTitleB.
  ///
  /// In ar, this message translates to:
  /// **'كُل صح'**
  String get loginTitleB;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك وكمّل رحلتك الصحية'**
  String get loginSubtitle;

  /// No description provided for @emailHint.
  ///
  /// In ar, this message translates to:
  /// **'الإيميل'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة السر؟'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginButton;

  /// No description provided for @orContinueWith.
  ///
  /// In ar, this message translates to:
  /// **'أو كمّل بـ'**
  String get orContinueWith;

  /// No description provided for @googleProvider.
  ///
  /// In ar, this message translates to:
  /// **'جوجل'**
  String get googleProvider;

  /// No description provided for @phoneProvider.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get phoneProvider;

  /// No description provided for @providerNotConfigured.
  ///
  /// In ar, this message translates to:
  /// **'الطريقة دي مش متاحة دلوقتي.'**
  String get providerNotConfigured;

  /// No description provided for @phoneComingToast.
  ///
  /// In ar, this message translates to:
  /// **'هنبعتلك كود تأكيد على رقم موبايلك'**
  String get phoneComingToast;

  /// No description provided for @noAccount.
  ///
  /// In ar, this message translates to:
  /// **'معندكش حساب؟'**
  String get noAccount;

  /// No description provided for @createAccountLink.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حساب جديد'**
  String get createAccountLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In ar, this message translates to:
  /// **'بعتنا لك لينك إعادة تعيين كلمة السر على إيميلك'**
  String get resetEmailSent;

  /// No description provided for @registerTitleA.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ سفرتك،'**
  String get registerTitleA;

  /// No description provided for @registerTitleB.
  ///
  /// In ar, this message translates to:
  /// **'كُل حقيقي'**
  String get registerTitleB;

  /// No description provided for @nameHint.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get nameHint;

  /// No description provided for @passwordRegisterHint.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر (٨ حروف على الأقل)'**
  String get passwordRegisterHint;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In ar, this message translates to:
  /// **'ضعيفة'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthMedium.
  ///
  /// In ar, this message translates to:
  /// **'متوسطة'**
  String get passwordStrengthMedium;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In ar, this message translates to:
  /// **'قوية'**
  String get passwordStrengthStrong;

  /// No description provided for @interestHealthyFasting.
  ///
  /// In ar, this message translates to:
  /// **'صيام صحي'**
  String get interestHealthyFasting;

  /// No description provided for @interestWeightLoss.
  ///
  /// In ar, this message translates to:
  /// **'تخسيس'**
  String get interestWeightLoss;

  /// No description provided for @interestFitness.
  ///
  /// In ar, this message translates to:
  /// **'لياقة'**
  String get interestFitness;

  /// No description provided for @agreeTermsPrefix.
  ///
  /// In ar, this message translates to:
  /// **'أوافق على '**
  String get agreeTermsPrefix;

  /// No description provided for @agreeTermsLink.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والخصوصية'**
  String get agreeTermsLink;

  /// No description provided for @createAccountButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get createAccountButton;

  /// No description provided for @haveAccount.
  ///
  /// In ar, this message translates to:
  /// **'عندك حساب؟'**
  String get haveAccount;

  /// No description provided for @signInLink.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخول'**
  String get signInLink;

  /// No description provided for @welcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بيك يا {name}'**
  String welcomeTitle(String name);

  /// No description provided for @welcomeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابك اتعمل، وسفرتك جاهزة. بالهنا والشفا'**
  String get welcomeSubtitle;

  /// No description provided for @welcomePoint1.
  ///
  /// In ar, this message translates to:
  /// **'تسجّل أكلك بصوتك بالعامية'**
  String get welcomePoint1;

  /// No description provided for @welcomePoint2.
  ///
  /// In ar, this message translates to:
  /// **'أرقام من مكونات الطبق نفسه'**
  String get welcomePoint2;

  /// No description provided for @welcomePoint3.
  ///
  /// In ar, this message translates to:
  /// **'كشري وفول وملوخية وأكتر'**
  String get welcomePoint3;

  /// No description provided for @welcomeCta.
  ///
  /// In ar, this message translates to:
  /// **'يلا نبدأ'**
  String get welcomeCta;

  /// No description provided for @wizardStepOf.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {current} من {total}'**
  String wizardStepOf(int current, int total);

  /// No description provided for @wizardBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get wizardBack;

  /// No description provided for @wizardNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get wizardNext;

  /// No description provided for @wizardFinish.
  ///
  /// In ar, this message translates to:
  /// **'احسب خطتي'**
  String get wizardFinish;

  /// No description provided for @wizardGenderTitle.
  ///
  /// In ar, this message translates to:
  /// **'عرّفنا عليك'**
  String get wizardGenderTitle;

  /// No description provided for @wizardGenderBody.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات دي بتساعدنا نحسب احتياجك بدقة'**
  String get wizardGenderBody;

  /// No description provided for @wizardGenderMale.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get wizardGenderMale;

  /// No description provided for @wizardGenderFemale.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get wizardGenderFemale;

  /// No description provided for @wizardDobTitle.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ ميلادك'**
  String get wizardDobTitle;

  /// No description provided for @wizardDobBody.
  ///
  /// In ar, this message translates to:
  /// **'عمرك بيأثر على معدل الحرق الأساسي'**
  String get wizardDobBody;

  /// No description provided for @wizardHeightTitle.
  ///
  /// In ar, this message translates to:
  /// **'طولك كام؟'**
  String get wizardHeightTitle;

  /// No description provided for @wizardHeightBody.
  ///
  /// In ar, this message translates to:
  /// **'بالسنتيمتر'**
  String get wizardHeightBody;

  /// No description provided for @wizardWeightTitle.
  ///
  /// In ar, this message translates to:
  /// **'وزنك الحالي'**
  String get wizardWeightTitle;

  /// No description provided for @wizardWeightBody.
  ///
  /// In ar, this message translates to:
  /// **'بالكيلوجرام'**
  String get wizardWeightBody;

  /// No description provided for @wizardTargetTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوزن اللي عايز توصله'**
  String get wizardTargetTitle;

  /// No description provided for @wizardTargetBody.
  ///
  /// In ar, this message translates to:
  /// **'هدف واقعي أحسن من هدف مستحيل'**
  String get wizardTargetBody;

  /// No description provided for @wizardActivityTitle.
  ///
  /// In ar, this message translates to:
  /// **'مستوى نشاطك اليومي'**
  String get wizardActivityTitle;

  /// No description provided for @wizardActivityBody.
  ///
  /// In ar, this message translates to:
  /// **'اختار الأقرب لروتينك'**
  String get wizardActivityBody;

  /// No description provided for @activitySedentary.
  ///
  /// In ar, this message translates to:
  /// **'نشاط قليل'**
  String get activitySedentary;

  /// No description provided for @activitySedentaryBody.
  ///
  /// In ar, this message translates to:
  /// **'شغل مكتبي وحركة بسيطة'**
  String get activitySedentaryBody;

  /// No description provided for @activityLight.
  ///
  /// In ar, this message translates to:
  /// **'نشاط خفيف'**
  String get activityLight;

  /// No description provided for @activityLightBody.
  ///
  /// In ar, this message translates to:
  /// **'مشي أو تمرين خفيف ١-٣ أيام'**
  String get activityLightBody;

  /// No description provided for @activityModerate.
  ///
  /// In ar, this message translates to:
  /// **'نشاط متوسط'**
  String get activityModerate;

  /// No description provided for @activityModerateBody.
  ///
  /// In ar, this message translates to:
  /// **'تمرين ٣-٥ أيام في الأسبوع'**
  String get activityModerateBody;

  /// No description provided for @activityActive.
  ///
  /// In ar, this message translates to:
  /// **'نشاط عالي'**
  String get activityActive;

  /// No description provided for @activityActiveBody.
  ///
  /// In ar, this message translates to:
  /// **'تمرين عنيف ٦-٧ أيام'**
  String get activityActiveBody;

  /// No description provided for @wizardGoalTitle.
  ///
  /// In ar, this message translates to:
  /// **'هدفك إيه؟'**
  String get wizardGoalTitle;

  /// No description provided for @wizardGoalBody.
  ///
  /// In ar, this message translates to:
  /// **'اختار، وسفرة تظبط كل حاجة على مقاسك'**
  String get wizardGoalBody;

  /// No description provided for @goalLose.
  ///
  /// In ar, this message translates to:
  /// **'أنزّل وزني'**
  String get goalLose;

  /// No description provided for @goalLoseBody.
  ///
  /// In ar, this message translates to:
  /// **'سعرات أقل وأكل مشبع'**
  String get goalLoseBody;

  /// No description provided for @goalMaintain.
  ///
  /// In ar, this message translates to:
  /// **'أثبّت وزني'**
  String get goalMaintain;

  /// No description provided for @goalMaintainBody.
  ///
  /// In ar, this message translates to:
  /// **'توازن يحافظ على وزنك'**
  String get goalMaintainBody;

  /// No description provided for @goalGain.
  ///
  /// In ar, this message translates to:
  /// **'أزوّد وزني'**
  String get goalGain;

  /// No description provided for @goalGainBody.
  ///
  /// In ar, this message translates to:
  /// **'سعرات أعلى وبروتين أكتر'**
  String get goalGainBody;

  /// No description provided for @unitCm.
  ///
  /// In ar, this message translates to:
  /// **'سم'**
  String get unitCm;

  /// No description provided for @unitKg.
  ///
  /// In ar, this message translates to:
  /// **'كجم'**
  String get unitKg;

  /// No description provided for @planTitleUnnamed.
  ///
  /// In ar, this message translates to:
  /// **'خطتك جاهزة!'**
  String get planTitleUnnamed;

  /// No description provided for @welcomeTitleUnnamed.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بيك'**
  String get welcomeTitleUnnamed;

  /// No description provided for @planTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطتك جاهزة يا {name}!'**
  String planTitle(String name);

  /// No description provided for @planDailyCalories.
  ///
  /// In ar, this message translates to:
  /// **'سعرك اليومي'**
  String get planDailyCalories;

  /// No description provided for @planProtein.
  ///
  /// In ar, this message translates to:
  /// **'بروتين · جم'**
  String get planProtein;

  /// No description provided for @planCarbs.
  ///
  /// In ar, this message translates to:
  /// **'كارب · جم'**
  String get planCarbs;

  /// No description provided for @planFat.
  ///
  /// In ar, this message translates to:
  /// **'دهون · جم'**
  String get planFat;

  /// No description provided for @planTimeline.
  ///
  /// In ar, this message translates to:
  /// **'تقدير مبدئي: ممكن تحتاج حوالي {weeks} أسبوع، والمدة الفعلية ممكن تختلف'**
  String planTimeline(int weeks);

  /// No description provided for @planTimelineMaintain.
  ///
  /// In ar, this message translates to:
  /// **'هدفك تحافظ على وزنك الحالي'**
  String get planTimelineMaintain;

  /// No description provided for @planDisclaimer.
  ///
  /// In ar, this message translates to:
  /// **'أرقام تقديرية للتوعية'**
  String get planDisclaimer;

  /// No description provided for @planCta.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ رحلتك'**
  String get planCta;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير يا'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير يا'**
  String get homeGreetingEvening;

  /// No description provided for @homeSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'دوّر على أكلة أو منتج…'**
  String get homeSearchHint;

  /// No description provided for @homeHeroChip.
  ///
  /// In ar, this message translates to:
  /// **'سفرة · اختيارات أذكى'**
  String get homeHeroChip;

  /// No description provided for @homeHeroTitleA.
  ///
  /// In ar, this message translates to:
  /// **'أكل بتحبه،'**
  String get homeHeroTitleA;

  /// No description provided for @homeHeroTitleB.
  ///
  /// In ar, this message translates to:
  /// **'وتوازن يناسبك'**
  String get homeHeroTitleB;

  /// No description provided for @homeHeroBody.
  ///
  /// In ar, this message translates to:
  /// **'نظّم وجباتك وصحتك من غير حرمان.'**
  String get homeHeroBody;

  /// No description provided for @homeHeroCta.
  ///
  /// In ar, this message translates to:
  /// **'خطّط وجباتك'**
  String get homeHeroCta;

  /// No description provided for @homeEatenToday.
  ///
  /// In ar, this message translates to:
  /// **'اللي أكلته النهاردة'**
  String get homeEatenToday;

  /// No description provided for @unitKcal.
  ///
  /// In ar, this message translates to:
  /// **'سعر'**
  String get unitKcal;

  /// No description provided for @homeGoalRemaining.
  ///
  /// In ar, this message translates to:
  /// **'الهدف {target} · فاضل {remaining}'**
  String homeGoalRemaining(int target, int remaining);

  /// No description provided for @homeNoGoalYet.
  ///
  /// In ar, this message translates to:
  /// **'كمّل إعدادك الشخصي عشان نحسب هدفك'**
  String get homeNoGoalYet;

  /// No description provided for @homeStreakDays.
  ///
  /// In ar, this message translates to:
  /// **'أيام ورا بعض'**
  String get homeStreakDays;

  /// No description provided for @homeStreakCta.
  ///
  /// In ar, this message translates to:
  /// **'كمّل يا بطل'**
  String get homeStreakCta;

  /// No description provided for @macroProtein.
  ///
  /// In ar, this message translates to:
  /// **'بروتين'**
  String get macroProtein;

  /// No description provided for @macroCarbs.
  ///
  /// In ar, this message translates to:
  /// **'كارب'**
  String get macroCarbs;

  /// No description provided for @macroFat.
  ///
  /// In ar, this message translates to:
  /// **'دهون'**
  String get macroFat;

  /// No description provided for @homeMealsToday.
  ///
  /// In ar, this message translates to:
  /// **'وجباتك النهاردة'**
  String get homeMealsToday;

  /// No description provided for @homeNoMeals.
  ///
  /// In ar, this message translates to:
  /// **'لسه مسجلتش وجبات النهاردة'**
  String get homeNoMeals;

  /// No description provided for @homeAddFirstMeal.
  ///
  /// In ar, this message translates to:
  /// **'سجّل أول وجبة'**
  String get homeAddFirstMeal;

  /// No description provided for @homeTipsTitle.
  ///
  /// In ar, this message translates to:
  /// **'نصايح سفرة'**
  String get homeTipsTitle;

  /// No description provided for @tipWaterTitle.
  ///
  /// In ar, this message translates to:
  /// **'اشرب كوباية مية'**
  String get tipWaterTitle;

  /// No description provided for @tipWaterBody.
  ///
  /// In ar, this message translates to:
  /// **'{count} من {goal} أكواب'**
  String tipWaterBody(int count, int goal);

  /// No description provided for @tipProteinTitle.
  ///
  /// In ar, this message translates to:
  /// **'راجع بروتين يومك'**
  String get tipProteinTitle;

  /// No description provided for @tipProteinBody.
  ///
  /// In ar, this message translates to:
  /// **'راجع المتبقي من هدفك واختار الكمية المناسبة ليك'**
  String get tipProteinBody;

  /// No description provided for @tipLogTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل أكلك أول بأول'**
  String get tipLogTitle;

  /// No description provided for @tipLogBody.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل المنتظم هو سر النتيجة'**
  String get tipLogBody;

  /// No description provided for @mealBreakfast.
  ///
  /// In ar, this message translates to:
  /// **'فطار'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In ar, this message translates to:
  /// **'غدا'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In ar, this message translates to:
  /// **'عشا'**
  String get mealDinner;

  /// No description provided for @mealSnack.
  ///
  /// In ar, this message translates to:
  /// **'خفيف'**
  String get mealSnack;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navDiary.
  ///
  /// In ar, this message translates to:
  /// **'اليومية'**
  String get navDiary;

  /// No description provided for @navProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدمي'**
  String get navProgress;

  /// No description provided for @navAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get navAccount;

  /// No description provided for @comingSoonTitle.
  ///
  /// In ar, this message translates to:
  /// **'قريبًا في سفرة'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In ar, this message translates to:
  /// **'الميزة دي لسه مش متاحة.'**
  String get comingSoonBody;

  /// No description provided for @stateLoading.
  ///
  /// In ar, this message translates to:
  /// **'بنحمّل…'**
  String get stateLoading;

  /// No description provided for @stateError.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة في التحميل. جرّب تاني'**
  String get stateError;

  /// No description provided for @stateRetry.
  ///
  /// In ar, this message translates to:
  /// **'حاول تاني'**
  String get stateRetry;

  /// No description provided for @validationRequired.
  ///
  /// In ar, this message translates to:
  /// **'الحقل ده مطلوب'**
  String get validationRequired;

  /// No description provided for @validationEmail.
  ///
  /// In ar, this message translates to:
  /// **'اكتب إيميل صحيح'**
  String get validationEmail;

  /// No description provided for @validationPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر لازم تكون ٨ حروف على الأقل'**
  String get validationPassword;

  /// No description provided for @validationName.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسمك'**
  String get validationName;

  /// No description provided for @validationTerms.
  ///
  /// In ar, this message translates to:
  /// **'لازم توافق على الشروط والخصوصية'**
  String get validationTerms;

  /// No description provided for @validationNumber.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقم صحيح'**
  String get validationNumber;

  /// No description provided for @validationStep.
  ///
  /// In ar, this message translates to:
  /// **'كمّل الخطوة دي الأول'**
  String get validationStep;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'الإيميل أو كلمة السر غلط'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailInUse.
  ///
  /// In ar, this message translates to:
  /// **'الإيميل ده مسجل قبل كده. جرّب تسجّل دخول'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر ضعيفة. استخدم ٨ حروف على الأقل'**
  String get authWeakPassword;

  /// No description provided for @authUserNotFound.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حساب بالإيميل ده'**
  String get authUserNotFound;

  /// No description provided for @authNetworkError.
  ///
  /// In ar, this message translates to:
  /// **'مفيش اتصال بالإنترنت. تأكد من الشبكة وحاول تاني'**
  String get authNetworkError;

  /// No description provided for @authGenericError.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة. حاول تاني بعد شوية'**
  String get authGenericError;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @logHubTitle.
  ///
  /// In ar, this message translates to:
  /// **'هتسجل أكلك إزاي؟'**
  String get logHubTitle;

  /// No description provided for @logHubSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار الطريقة الأنسب، وكلها لمسة واحدة'**
  String get logHubSubtitle;

  /// No description provided for @logHubChipPhoto.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get logHubChipPhoto;

  /// No description provided for @logHubChipBarcode.
  ///
  /// In ar, this message translates to:
  /// **'باركود'**
  String get logHubChipBarcode;

  /// No description provided for @logHubChipVoice.
  ///
  /// In ar, this message translates to:
  /// **'صوت'**
  String get logHubChipVoice;

  /// No description provided for @logHubChipSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get logHubChipSearch;

  /// No description provided for @logHubVoiceTitle.
  ///
  /// In ar, this message translates to:
  /// **'بالصوت أو الكتابة'**
  String get logHubVoiceTitle;

  /// No description provided for @logHubVoiceSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'قول الأكل وراجع النوع والجرامات'**
  String get logHubVoiceSubtitle;

  /// No description provided for @logHubFastest.
  ///
  /// In ar, this message translates to:
  /// **'الأسرع'**
  String get logHubFastest;

  /// No description provided for @logHubPhotoTitle.
  ///
  /// In ar, this message translates to:
  /// **'صوّر وجبتك'**
  String get logHubPhotoTitle;

  /// No description provided for @logHubPhotoSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'صوّر وراجع يدويًا'**
  String get logHubPhotoSubtitle;

  /// No description provided for @logHubBarcodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'امسح باركود'**
  String get logHubBarcodeTitle;

  /// No description provided for @logHubBarcodeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'منتج معبّأ'**
  String get logHubBarcodeSubtitle;

  /// No description provided for @logHubSearchTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابحث يدويًا'**
  String get logHubSearchTitle;

  /// No description provided for @logHubSearchSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار من قاعدة الأكل'**
  String get logHubSearchSubtitle;

  /// No description provided for @logHubFavoritesTitle.
  ///
  /// In ar, this message translates to:
  /// **'من المفضلة'**
  String get logHubFavoritesTitle;

  /// No description provided for @logHubFavoritesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'بلمسة واحدة'**
  String get logHubFavoritesSubtitle;

  /// No description provided for @logHubRecentTitle.
  ///
  /// In ar, this message translates to:
  /// **'آخر وجباتك'**
  String get logHubRecentTitle;

  /// No description provided for @logHubRecentMeal.
  ///
  /// In ar, this message translates to:
  /// **'{name} · {calories} سعرة'**
  String logHubRecentMeal(String name, int calories);

  /// No description provided for @logHubRelog.
  ///
  /// In ar, this message translates to:
  /// **'أعد التسجيل'**
  String get logHubRelog;

  /// No description provided for @logHubRelogDone.
  ///
  /// In ar, this message translates to:
  /// **'اتسجلت وجبتك في يومك'**
  String get logHubRelogDone;

  /// No description provided for @foodSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'دوّر على أكلة...'**
  String get foodSearchHint;

  /// No description provided for @foodCatalogTitle.
  ///
  /// In ar, this message translates to:
  /// **'دليل الأكل'**
  String get foodCatalogTitle;

  /// No description provided for @foodSearchStart.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم الأكلة عشان ندوّر عليها'**
  String get foodSearchStart;

  /// No description provided for @foodSearchEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش نتائج. جرّب اسم تاني'**
  String get foodSearchEmpty;

  /// No description provided for @foodPer100g.
  ///
  /// In ar, this message translates to:
  /// **'١٠٠ جم · {value} سعرة'**
  String foodPer100g(String value);

  /// No description provided for @foodNutritionUnknown.
  ///
  /// In ar, this message translates to:
  /// **'القيم الغذائية غير متاحة'**
  String get foodNutritionUnknown;

  /// No description provided for @foodGrams.
  ///
  /// In ar, this message translates to:
  /// **'الكمية بالجرام'**
  String get foodGrams;

  /// No description provided for @foodInvalidGrams.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كمية أكبر من صفر ولحد ١٠٬٠٠٠ جم'**
  String get foodInvalidGrams;

  /// No description provided for @foodUnknown.
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get foodUnknown;

  /// No description provided for @foodKcal.
  ///
  /// In ar, this message translates to:
  /// **'سعرة'**
  String get foodKcal;

  /// No description provided for @foodMg.
  ///
  /// In ar, this message translates to:
  /// **'مجم'**
  String get foodMg;

  /// No description provided for @foodGramUnit.
  ///
  /// In ar, this message translates to:
  /// **'جم'**
  String get foodGramUnit;

  /// No description provided for @foodSource.
  ///
  /// In ar, this message translates to:
  /// **'مصدر البيانات: {source}'**
  String foodSource(String source);

  /// No description provided for @foodIncompleteWarning.
  ///
  /// In ar, this message translates to:
  /// **'فيه قيم غذائية أو مصدر بيانات ناقص. مش هنحفظ أرقام مجهولة كأنها صفر.'**
  String get foodIncompleteWarning;

  /// No description provided for @foodCalories.
  ///
  /// In ar, this message translates to:
  /// **'السعرات'**
  String get foodCalories;

  /// No description provided for @foodProtein.
  ///
  /// In ar, this message translates to:
  /// **'بروتين'**
  String get foodProtein;

  /// No description provided for @foodCarbs.
  ///
  /// In ar, this message translates to:
  /// **'كارب'**
  String get foodCarbs;

  /// No description provided for @foodFat.
  ///
  /// In ar, this message translates to:
  /// **'دهون'**
  String get foodFat;

  /// No description provided for @foodFiber.
  ///
  /// In ar, this message translates to:
  /// **'ألياف'**
  String get foodFiber;

  /// No description provided for @foodSugar.
  ///
  /// In ar, this message translates to:
  /// **'سكر'**
  String get foodSugar;

  /// No description provided for @foodSodium.
  ///
  /// In ar, this message translates to:
  /// **'صوديوم'**
  String get foodSodium;

  /// No description provided for @mealReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'راجع وجبتك'**
  String get mealReviewTitle;

  /// No description provided for @mealReviewTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي من بيانات المصدر'**
  String get mealReviewTotal;

  /// No description provided for @mealTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الوجبة'**
  String get mealTypeLabel;

  /// No description provided for @mealSessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'الجلسة اتغيرت. ارجع وسجّل دخول تاني'**
  String get mealSessionExpired;

  /// No description provided for @mealSave.
  ///
  /// In ar, this message translates to:
  /// **'بالهنا والشفا، احفظ'**
  String get mealSave;

  /// No description provided for @diaryTitle.
  ///
  /// In ar, this message translates to:
  /// **'اليومية'**
  String get diaryTitle;

  /// No description provided for @diaryEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش وجبات في اليوم ده'**
  String get diaryEmpty;

  /// No description provided for @diaryPrevious.
  ///
  /// In ar, this message translates to:
  /// **'اليوم اللي قبله'**
  String get diaryPrevious;

  /// No description provided for @diaryNext.
  ///
  /// In ar, this message translates to:
  /// **'اليوم اللي بعده'**
  String get diaryNext;

  /// No description provided for @artRotateHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب عشان تدوّرها'**
  String get artRotateHint;

  /// No description provided for @diaryChooseDate.
  ///
  /// In ar, this message translates to:
  /// **'اختار اليوم'**
  String get diaryChooseDate;

  /// No description provided for @diaryEmptySlot.
  ///
  /// In ar, this message translates to:
  /// **'لسه فاضي'**
  String get diaryEmptySlot;

  /// No description provided for @diaryAddMeal.
  ///
  /// In ar, this message translates to:
  /// **'+ ضيف أكلة'**
  String get diaryAddMeal;

  /// No description provided for @diaryOtherMeals.
  ///
  /// In ar, this message translates to:
  /// **'وجبات تانية'**
  String get diaryOtherMeals;

  /// No description provided for @foodRecipes.
  ///
  /// In ar, this message translates to:
  /// **'وصفات'**
  String get foodRecipes;

  /// No description provided for @foodAlternatives.
  ///
  /// In ar, this message translates to:
  /// **'بدائل الأكل'**
  String get foodAlternatives;

  /// No description provided for @mealEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get mealEdit;

  /// No description provided for @mealDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get mealDelete;

  /// No description provided for @mealDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تحب تحذف الوجبة دي؟ إجمالي اليوم هيتحدّث بعدها.'**
  String get mealDeleteConfirm;

  /// No description provided for @mealName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الوجبة'**
  String get mealName;

  /// No description provided for @mealNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get mealNotes;

  /// No description provided for @mealEditInvalid.
  ///
  /// In ar, this message translates to:
  /// **'راجع اسم الوجبة وكميات المكونات.'**
  String get mealEditInvalid;

  /// No description provided for @mealNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الوجبة دي مش موجودة للحساب واليوم ده.'**
  String get mealNotFound;

  /// No description provided for @actionSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get actionCancel;

  /// No description provided for @mealSuhoor.
  ///
  /// In ar, this message translates to:
  /// **'سحور'**
  String get mealSuhoor;

  /// No description provided for @mealIftar.
  ///
  /// In ar, this message translates to:
  /// **'إفطار رمضان'**
  String get mealIftar;

  /// No description provided for @discoveryMsg001.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم الحفظ. حاول مرة أخرى.'**
  String get discoveryMsg001;

  /// No description provided for @discoveryMsg002.
  ///
  /// In ar, this message translates to:
  /// **'الوصفة محجوبة لحين اعتماد ترخيص النشر.'**
  String get discoveryMsg002;

  /// No description provided for @discoveryMsg003.
  ///
  /// In ar, this message translates to:
  /// **'الوصفة غير موجودة.'**
  String get discoveryMsg003;

  /// No description provided for @discoveryMsg004.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get discoveryMsg004;

  /// No description provided for @discoveryMsg005.
  ///
  /// In ar, this message translates to:
  /// **'الوقت مش محدد'**
  String get discoveryMsg005;

  /// No description provided for @discoveryMsg006.
  ///
  /// In ar, this message translates to:
  /// **'السعرات غير معروفة'**
  String get discoveryMsg006;

  /// No description provided for @discoveryMsg007.
  ///
  /// In ar, this message translates to:
  /// **'الحصص غير محددة'**
  String get discoveryMsg007;

  /// No description provided for @discoveryMsg008.
  ///
  /// In ar, this message translates to:
  /// **'المقادير والخطوات كما نشرها المصدر، وليست ترجمة أو تقديرًا بالجرام.'**
  String get discoveryMsg008;

  /// No description provided for @discoveryMsg009.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تسجيل الوصفة بقيم غذائية دقيقة قبل توثيق أوزان المكونات وعدد الحصص.'**
  String get discoveryMsg009;

  /// No description provided for @discoveryMsg010.
  ///
  /// In ar, this message translates to:
  /// **'المصدر والترخيص'**
  String get discoveryMsg010;

  /// No description provided for @discoveryMsg011.
  ///
  /// In ar, this message translates to:
  /// **'المصدر والترخيص · تطوير فقط'**
  String get discoveryMsg011;

  /// No description provided for @discoveryMsg012.
  ///
  /// In ar, this message translates to:
  /// **'أوزان وحصص وقيم غذائية غير موثقة'**
  String get discoveryMsg012;

  /// No description provided for @discoveryMsg013.
  ///
  /// In ar, this message translates to:
  /// **'سجّلها كوجبة'**
  String get discoveryMsg013;

  /// No description provided for @discoveryMsg014.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاقتراح'**
  String get discoveryMsg014;

  /// No description provided for @discoveryMsg015.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نجيب وصفات دلوقتي. حاول تاني.'**
  String get discoveryMsg015;

  /// No description provided for @discoveryMsg016.
  ///
  /// In ar, this message translates to:
  /// **'ضيف مكوناتك'**
  String get discoveryMsg016;

  /// No description provided for @discoveryMsg017.
  ///
  /// In ar, this message translates to:
  /// **'ضيف مكونًا واحدًا على الأقل عشان نقارن بالمقادير المنشورة.'**
  String get discoveryMsg017;

  /// No description provided for @discoveryMsg018.
  ///
  /// In ar, this message translates to:
  /// **'الوصفات دي مش متاحة في النسخة دي دلوقتي.'**
  String get discoveryMsg018;

  /// No description provided for @discoveryMsg019.
  ///
  /// In ar, this message translates to:
  /// **'اقترح لي وجبة'**
  String get discoveryMsg019;

  /// No description provided for @discoveryMsg020.
  ///
  /// In ar, this message translates to:
  /// **'عندي'**
  String get discoveryMsg020;

  /// No description provided for @discoveryMsg021.
  ///
  /// In ar, this message translates to:
  /// **'+ ضيف'**
  String get discoveryMsg021;

  /// No description provided for @discoveryMsg022.
  ///
  /// In ar, this message translates to:
  /// **'السعرات'**
  String get discoveryMsg022;

  /// No description provided for @discoveryMsg023.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get discoveryMsg023;

  /// No description provided for @discoveryMsg024.
  ///
  /// In ar, this message translates to:
  /// **'مش محدد'**
  String get discoveryMsg024;

  /// No description provided for @discoveryMsg025.
  ///
  /// In ar, this message translates to:
  /// **'السعرات وأغلب أوقات الوصفات غير متاحة. فلتر الوقت بيقبل الوصفات ذات الوقت الكلي الموثق بس.'**
  String get discoveryMsg025;

  /// No description provided for @discoveryMsg026.
  ///
  /// In ar, this message translates to:
  /// **'اقترح'**
  String get discoveryMsg026;

  /// No description provided for @discoveryMsg027.
  ///
  /// In ar, this message translates to:
  /// **'مطابقة محلية حسب المكونات'**
  String get discoveryMsg027;

  /// No description provided for @discoveryMsg028.
  ///
  /// In ar, this message translates to:
  /// **'عن الاقتراح'**
  String get discoveryMsg028;

  /// No description provided for @discoveryMsg029.
  ///
  /// In ar, this message translates to:
  /// **'المصدر وطريقة الاقتراح'**
  String get discoveryMsg029;

  /// No description provided for @discoveryMsg030.
  ///
  /// In ar, this message translates to:
  /// **'مطابقة كلمات المكونات حرفيًا. نوع الوجبة تفضيل ولا يغير تصنيف المصدر. راجع المكونات الناقصة والحساسيات. TheMealDB للتطوير والتعليم فقط. الذكاء الاصطناعي الاختياري غير مهيأ ما لم تضف خدمة موثقة.'**
  String get discoveryMsg030;

  /// No description provided for @discoveryMsg031.
  ///
  /// In ar, this message translates to:
  /// **'اقترح عليّا'**
  String get discoveryMsg031;

  /// No description provided for @discoveryMsg032.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل الوصفات'**
  String get discoveryMsg032;

  /// No description provided for @discoveryMsg033.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الوصفات المحلية'**
  String get discoveryMsg033;

  /// No description provided for @discoveryMsg034.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get discoveryMsg034;

  /// No description provided for @discoveryMsg035.
  ///
  /// In ar, this message translates to:
  /// **'المحفوظة فقط'**
  String get discoveryMsg035;

  /// No description provided for @discoveryMsg036.
  ///
  /// In ar, this message translates to:
  /// **'TheMealDB · تطوير وتعليم فقط'**
  String get discoveryMsg036;

  /// No description provided for @discoveryMsg037.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وصفات مطابقة.'**
  String get discoveryMsg037;

  /// No description provided for @discoveryMsg038.
  ///
  /// In ar, this message translates to:
  /// **'سعرات غير معروفة'**
  String get discoveryMsg038;

  /// No description provided for @discoveryMsg039.
  ///
  /// In ar, this message translates to:
  /// **'ضيف مكون'**
  String get discoveryMsg039;

  /// No description provided for @discoveryMsg040.
  ///
  /// In ar, this message translates to:
  /// **'اسم المكون'**
  String get discoveryMsg040;

  /// No description provided for @discoveryMsg041.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get discoveryMsg041;

  /// No description provided for @discoveryMsg042.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get discoveryMsg042;

  /// No description provided for @discoveryMsg043.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get discoveryMsg043;

  /// No description provided for @discoveryMsg044.
  ///
  /// In ar, this message translates to:
  /// **'اليومية'**
  String get discoveryMsg044;

  /// No description provided for @discoveryMsg045.
  ///
  /// In ar, this message translates to:
  /// **'تقدمي'**
  String get discoveryMsg045;

  /// No description provided for @discoveryMsg046.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get discoveryMsg046;

  /// No description provided for @discoveryMsg047.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل البيانات. حاول مرة أخرى.'**
  String get discoveryMsg047;

  /// No description provided for @discoveryMsg048.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get discoveryMsg048;

  /// No description provided for @discoveryMsg049.
  ///
  /// In ar, this message translates to:
  /// **'تمام'**
  String get discoveryMsg049;

  /// No description provided for @discoveryMsg050.
  ///
  /// In ar, this message translates to:
  /// **'التقدم الحالي'**
  String get discoveryMsg050;

  /// No description provided for @discoveryMsg051.
  ///
  /// In ar, this message translates to:
  /// **'الهدف'**
  String get discoveryMsg051;

  /// No description provided for @discoveryMsg052.
  ///
  /// In ar, this message translates to:
  /// **'عايز بدائل لإيه؟'**
  String get discoveryMsg052;

  /// No description provided for @discoveryMsg053.
  ///
  /// In ar, this message translates to:
  /// **'ابحث باسم الطعام الأصلي'**
  String get discoveryMsg053;

  /// No description provided for @discoveryMsg054.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مقارنة موثقة لهذا الطعام في الكتالوج الحالي. جرّب اللبن أو الأرز أو الخبز.'**
  String get discoveryMsg054;

  /// No description provided for @discoveryMsg055.
  ///
  /// In ar, this message translates to:
  /// **'بدائل من بيانات موثقة'**
  String get discoveryMsg055;

  /// No description provided for @discoveryMsg056.
  ///
  /// In ar, this message translates to:
  /// **'مقارنة لكل ١٠٠ جم من بيانات الأطعمة المسجلة، مش توصية طبية.'**
  String get discoveryMsg056;

  /// No description provided for @discoveryMsg057.
  ///
  /// In ar, this message translates to:
  /// **'منتجات حقيقية'**
  String get discoveryMsg057;

  /// No description provided for @discoveryMsg058.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات معبأة موثقة في الكتالوج المحلي.'**
  String get discoveryMsg058;

  /// No description provided for @discoveryMsg059.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم ربط البحث عن المنتجات بعد. لن نعرض أسعارًا أو درجات غذائية افتراضية.'**
  String get discoveryMsg059;

  /// No description provided for @discoveryMsg060.
  ///
  /// In ar, this message translates to:
  /// **'طاقة لكل ١٠٠ جم'**
  String get discoveryMsg060;

  /// No description provided for @discoveryMsg061.
  ///
  /// In ar, this message translates to:
  /// **'USDA · تفاصيل المصدر والمقارنة'**
  String get discoveryMsg061;

  /// No description provided for @discoveryMsg062.
  ///
  /// In ar, this message translates to:
  /// **'مقارنة لكل ١٠٠ جم'**
  String get discoveryMsg062;

  /// No description provided for @discoveryMsg063.
  ///
  /// In ar, this message translates to:
  /// **'الأصل'**
  String get discoveryMsg063;

  /// No description provided for @discoveryMsg064.
  ///
  /// In ar, this message translates to:
  /// **'البديل'**
  String get discoveryMsg064;

  /// No description provided for @discoveryMsg065.
  ///
  /// In ar, this message translates to:
  /// **'الحالة والتحضير يؤثران على المقارنة؛ ليست الحصص متكافئة تلقائيًا.'**
  String get discoveryMsg065;

  /// No description provided for @discoveryMsg066.
  ///
  /// In ar, this message translates to:
  /// **'الطاقة (سعرة)'**
  String get discoveryMsg066;

  /// No description provided for @discoveryMsg067.
  ///
  /// In ar, this message translates to:
  /// **'الألياف (جم)'**
  String get discoveryMsg067;

  /// No description provided for @discoveryMsg068.
  ///
  /// In ar, this message translates to:
  /// **'الدهون (جم)'**
  String get discoveryMsg068;

  /// No description provided for @discoveryMsg069.
  ///
  /// In ar, this message translates to:
  /// **'البروتين (جم)'**
  String get discoveryMsg069;

  /// No description provided for @discoveryMsg070.
  ///
  /// In ar, this message translates to:
  /// **'أيام ورا بعض'**
  String get discoveryMsg070;

  /// No description provided for @discoveryMsg071.
  ///
  /// In ar, this message translates to:
  /// **'مسجل'**
  String get discoveryMsg071;

  /// No description provided for @discoveryMsg072.
  ///
  /// In ar, this message translates to:
  /// **'غير مسجل'**
  String get discoveryMsg072;

  /// No description provided for @discoveryMsg073.
  ///
  /// In ar, this message translates to:
  /// **'الفانوس الذهبي'**
  String get discoveryMsg073;

  /// No description provided for @discoveryMsg074.
  ///
  /// In ar, this message translates to:
  /// **'يوم'**
  String get discoveryMsg074;

  /// No description provided for @discoveryMsg075.
  ///
  /// In ar, this message translates to:
  /// **'أوسمتك'**
  String get discoveryMsg075;

  /// No description provided for @discoveryMsg076.
  ///
  /// In ar, this message translates to:
  /// **'كل تسجيل بيقرّبك من وسام جديد. حدد هدف المياه عشان تتابع تقدّمك فيه.'**
  String get discoveryMsg076;

  /// No description provided for @discoveryMsg077.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get discoveryMsg077;

  /// No description provided for @discoveryMsg078.
  ///
  /// In ar, this message translates to:
  /// **'لسه مش معروف'**
  String get discoveryMsg078;

  /// No description provided for @discoveryMsg079.
  ///
  /// In ar, this message translates to:
  /// **'محتاجين تسجيلات أكتر عشان نعرض تقدمك.'**
  String get discoveryMsg079;

  /// No description provided for @discoveryMsg080.
  ///
  /// In ar, this message translates to:
  /// **'وقت تسجيل الإنجاز لأول مرة مش معروف.'**
  String get discoveryMsg080;

  /// No description provided for @discoveryMsg081.
  ///
  /// In ar, this message translates to:
  /// **'أول مرة سفرة سجّل فيها الإنجاز، مش بالضرورة وقت تحقيقه'**
  String get discoveryMsg081;

  /// No description provided for @discoveryMsg082.
  ///
  /// In ar, this message translates to:
  /// **'فانوس الإنجازات'**
  String get discoveryMsg082;

  /// No description provided for @discoveryCloudFavoritesNote.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ متزامن مع حسابك.'**
  String get discoveryCloudFavoritesNote;

  /// No description provided for @discoveryLocalFavoritesNote.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ على هذا الجهاز لحسابك الحالي.'**
  String get discoveryLocalFavoritesNote;

  /// No description provided for @discoverySaved.
  ///
  /// In ar, this message translates to:
  /// **'محفوظة'**
  String get discoverySaved;

  /// No description provided for @discoverySave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get discoverySave;

  /// No description provided for @discoveryBreakfast.
  ///
  /// In ar, this message translates to:
  /// **'فطار'**
  String get discoveryBreakfast;

  /// No description provided for @discoveryLunch.
  ///
  /// In ar, this message translates to:
  /// **'غدا'**
  String get discoveryLunch;

  /// No description provided for @discoveryDinner.
  ///
  /// In ar, this message translates to:
  /// **'عشا'**
  String get discoveryDinner;

  /// No description provided for @discoveryWeekday1.
  ///
  /// In ar, this message translates to:
  /// **'ن'**
  String get discoveryWeekday1;

  /// No description provided for @discoveryWeekday2.
  ///
  /// In ar, this message translates to:
  /// **'ث'**
  String get discoveryWeekday2;

  /// No description provided for @discoveryWeekday3.
  ///
  /// In ar, this message translates to:
  /// **'ر'**
  String get discoveryWeekday3;

  /// No description provided for @discoveryWeekday4.
  ///
  /// In ar, this message translates to:
  /// **'خ'**
  String get discoveryWeekday4;

  /// No description provided for @discoveryWeekday5.
  ///
  /// In ar, this message translates to:
  /// **'ج'**
  String get discoveryWeekday5;

  /// No description provided for @discoveryWeekday6.
  ///
  /// In ar, this message translates to:
  /// **'س'**
  String get discoveryWeekday6;

  /// No description provided for @discoveryWeekday7.
  ///
  /// In ar, this message translates to:
  /// **'ح'**
  String get discoveryWeekday7;

  /// No description provided for @mealIngredientAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مكوّن'**
  String get mealIngredientAdd;

  /// No description provided for @mealIngredientEdit.
  ///
  /// In ar, this message translates to:
  /// **'تغيير المكوّن'**
  String get mealIngredientEdit;

  /// No description provided for @mealIngredientRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة المكوّن'**
  String get mealIngredientRemove;

  /// No description provided for @mealDraftIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'اختار مكوّن ببيانات سعرات معروفة ومصدر واضح، وراجع الكميات واسم الوجبة.'**
  String get mealDraftIncomplete;

  /// No description provided for @mealReviewCatalogHint.
  ///
  /// In ar, this message translates to:
  /// **'راجع المكوّنات والكميات قبل الحفظ.'**
  String get mealReviewCatalogHint;

  /// No description provided for @progressNavHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get progressNavHome;

  /// No description provided for @progressNavDiary.
  ///
  /// In ar, this message translates to:
  /// **'اليومية'**
  String get progressNavDiary;

  /// No description provided for @progressNavProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدمي'**
  String get progressNavProgress;

  /// No description provided for @progressNavAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get progressNavAccount;

  /// No description provided for @statsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقدمي'**
  String get statsTitle;

  /// No description provided for @statsTabWeek.
  ///
  /// In ar, this message translates to:
  /// **'أسبوع'**
  String get statsTabWeek;

  /// No description provided for @statsTabMonth.
  ///
  /// In ar, this message translates to:
  /// **'شهر'**
  String get statsTabMonth;

  /// No description provided for @statsStreakDays.
  ///
  /// In ar, this message translates to:
  /// **'{count} أيام ورا بعض'**
  String statsStreakDays(Object count);

  /// No description provided for @statsStreakCheer.
  ///
  /// In ar, this message translates to:
  /// **'عاش! كمّل'**
  String get statsStreakCheer;

  /// No description provided for @statsCaloriesTitle.
  ///
  /// In ar, this message translates to:
  /// **'السعرات'**
  String get statsCaloriesTitle;

  /// No description provided for @statsCaloriesAverage.
  ///
  /// In ar, this message translates to:
  /// **'المتوسط {avg} / {target}'**
  String statsCaloriesAverage(Object avg, Object target);

  /// No description provided for @statsWeightTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوزن'**
  String get statsWeightTitle;

  /// No description provided for @statsWeightDown.
  ///
  /// In ar, this message translates to:
  /// **'▼ {kg} كجم'**
  String statsWeightDown(Object kg);

  /// No description provided for @statsWeightUp.
  ///
  /// In ar, this message translates to:
  /// **'▲ {kg} كجم'**
  String statsWeightUp(Object kg);

  /// No description provided for @statsBadgesTitle.
  ///
  /// In ar, this message translates to:
  /// **'شارات'**
  String get statsBadgesTitle;

  /// No description provided for @statsNoTrackedDays.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش أيام متسجلة الفترة دي'**
  String get statsNoTrackedDays;

  /// No description provided for @statsNoWeightData.
  ///
  /// In ar, this message translates to:
  /// **'سجّل وزنك عشان تشوف تقدمك'**
  String get statsNoWeightData;

  /// No description provided for @reportTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقرير'**
  String get reportTitle;

  /// No description provided for @reportSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعك في صورة واحدة'**
  String get reportSubtitle;

  /// No description provided for @reportAverageCalories.
  ///
  /// In ar, this message translates to:
  /// **'متوسط السعرات'**
  String get reportAverageCalories;

  /// No description provided for @reportRingCalories.
  ///
  /// In ar, this message translates to:
  /// **'السعرات: {pct}٪ من الهدف'**
  String reportRingCalories(Object pct);

  /// No description provided for @reportRingProtein.
  ///
  /// In ar, this message translates to:
  /// **'البروتين: {pct}٪ من الهدف'**
  String reportRingProtein(Object pct);

  /// No description provided for @reportRingFiber.
  ///
  /// In ar, this message translates to:
  /// **'ألياف {pct}٪'**
  String reportRingFiber(Object pct);

  /// No description provided for @reportDailyCommitment.
  ///
  /// In ar, this message translates to:
  /// **'الأيام اللي سجلت فيها أكلك'**
  String get reportDailyCommitment;

  /// No description provided for @reportWaterTitle.
  ///
  /// In ar, this message translates to:
  /// **'المياه'**
  String get reportWaterTitle;

  /// No description provided for @reportWaterCupsOf.
  ///
  /// In ar, this message translates to:
  /// **'{have} من {goal} أكواب'**
  String reportWaterCupsOf(Object goal, Object have);

  /// No description provided for @reportMealDistribution.
  ///
  /// In ar, this message translates to:
  /// **'الوجبات المتسجلة'**
  String get reportMealDistribution;

  /// No description provided for @reportSugarAlertTitle.
  ///
  /// In ar, this message translates to:
  /// **'انتبه: سكر {day}'**
  String reportSugarAlertTitle(Object day);

  /// No description provided for @reportSugarAlertBody.
  ///
  /// In ar, this message translates to:
  /// **'زاد {pct}٪ عن المعتاد، غالبًا من الحلو بعد الغدا'**
  String reportSugarAlertBody(Object pct);

  /// No description provided for @waterScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'مية النهاردة'**
  String get waterScreenTitle;

  /// No description provided for @waterCupsOf.
  ///
  /// In ar, this message translates to:
  /// **'{have} من {goal} أكواب'**
  String waterCupsOf(Object goal, Object have);

  /// No description provided for @waterMlOf.
  ///
  /// In ar, this message translates to:
  /// **'{have} من {goal} مل'**
  String waterMlOf(Object goal, Object have);

  /// No description provided for @waterAdd250.
  ///
  /// In ar, this message translates to:
  /// **'+ ٢٥٠ مل'**
  String get waterAdd250;

  /// No description provided for @waterAdd500.
  ///
  /// In ar, this message translates to:
  /// **'+ ٥٠٠ مل'**
  String get waterAdd500;

  /// No description provided for @waterAddCustom.
  ///
  /// In ar, this message translates to:
  /// **'مخصص'**
  String get waterAddCustom;

  /// No description provided for @waterAddConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أضف'**
  String get waterAddConfirm;

  /// No description provided for @waterMlValue.
  ///
  /// In ar, this message translates to:
  /// **'{value} مل'**
  String waterMlValue(Object value);

  /// No description provided for @weightScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'وزنك'**
  String get weightScreenTitle;

  /// No description provided for @weightSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'رحلتك ماشية، وكل خطوة صغيرة بتتحسب'**
  String get weightSubtitle;

  /// No description provided for @weightCurrent.
  ///
  /// In ar, this message translates to:
  /// **'وزنك دلوقتي'**
  String get weightCurrent;

  /// No description provided for @weightKg.
  ///
  /// In ar, this message translates to:
  /// **'كجم'**
  String get weightKg;

  /// No description provided for @weightOfYourGoal.
  ///
  /// In ar, this message translates to:
  /// **'من هدفك'**
  String get weightOfYourGoal;

  /// No description provided for @weightLighterBy.
  ///
  /// In ar, this message translates to:
  /// **'▼ أخف بـ {kg} كجم'**
  String weightLighterBy(Object kg);

  /// No description provided for @weightHeavierBy.
  ///
  /// In ar, this message translates to:
  /// **'▲ أتقل بـ {kg} كجم'**
  String weightHeavierBy(Object kg);

  /// No description provided for @weightYouAreHere.
  ///
  /// In ar, this message translates to:
  /// **'إنت هنا'**
  String get weightYouAreHere;

  /// No description provided for @weightGoalLabel.
  ///
  /// In ar, this message translates to:
  /// **'الهدف {kg}'**
  String weightGoalLabel(Object kg);

  /// No description provided for @weightGreatWork.
  ///
  /// In ar, this message translates to:
  /// **'شغل ممتاز يا بطل!'**
  String get weightGreatWork;

  /// No description provided for @weightToNextMilestone.
  ///
  /// In ar, this message translates to:
  /// **'باقي {kg} كجم على هدفك. وزنك ممكن يطلع وينزل يوميًا، فتابع الاتجاه مع الوقت.'**
  String weightToNextMilestone(Object kg);

  /// No description provided for @weightLogCta.
  ///
  /// In ar, this message translates to:
  /// **'+ سجّل وزن اليوم'**
  String get weightLogCta;

  /// No description provided for @weightLogTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل وزنك'**
  String get weightLogTitle;

  /// No description provided for @weightLogHint.
  ///
  /// In ar, this message translates to:
  /// **'الوزن بالكيلو'**
  String get weightLogHint;

  /// No description provided for @weightLogSave.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get weightLogSave;

  /// No description provided for @weightLogInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب وزن صحيح أكبر من صفر'**
  String get weightLogInvalid;

  /// No description provided for @exportTitle.
  ///
  /// In ar, this message translates to:
  /// **'سفرة · تقرير التغذية'**
  String get exportTitle;

  /// No description provided for @exportSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الفترة اللي اخترتها'**
  String get exportSubtitle;

  /// No description provided for @exportPdfBadge.
  ///
  /// In ar, this message translates to:
  /// **'PDF'**
  String get exportPdfBadge;

  /// No description provided for @exportAdherenceLabel.
  ///
  /// In ar, this message translates to:
  /// **'الالتزام'**
  String get exportAdherenceLabel;

  /// No description provided for @exportMacrosTitle.
  ///
  /// In ar, this message translates to:
  /// **'المغذيات: المسجّل مقارنة بأهدافك المحفوظة'**
  String get exportMacrosTitle;

  /// No description provided for @exportMacrosHint.
  ///
  /// In ar, this message translates to:
  /// **'(الخط الأسود = الهدف)'**
  String get exportMacrosHint;

  /// No description provided for @exportProteinLabel.
  ///
  /// In ar, this message translates to:
  /// **'بروتين'**
  String get exportProteinLabel;

  /// No description provided for @exportCarbsLabel.
  ///
  /// In ar, this message translates to:
  /// **'كربوهيدرات'**
  String get exportCarbsLabel;

  /// No description provided for @exportFatLabel.
  ///
  /// In ar, this message translates to:
  /// **'دهون'**
  String get exportFatLabel;

  /// No description provided for @exportAdherenceMapTitle.
  ///
  /// In ar, this message translates to:
  /// **'خريطة الالتزام (٢ أسابيع)'**
  String get exportAdherenceMapTitle;

  /// No description provided for @exportReviewPointsTitle.
  ///
  /// In ar, this message translates to:
  /// **'نقاط تحتاج مراجعتك'**
  String get exportReviewPointsTitle;

  /// No description provided for @exportReviewSodium.
  ///
  /// In ar, this message translates to:
  /// **'الصوديوم المسجّل أعلى من متوسط الفترة ٣ أيام ورا بعض'**
  String get exportReviewSodium;

  /// No description provided for @exportReviewFiber.
  ///
  /// In ar, this message translates to:
  /// **'ألياف أقل من الموصى به ({pct}٪)'**
  String exportReviewFiber(Object pct);

  /// No description provided for @exportReviewWaterOk.
  ///
  /// In ar, this message translates to:
  /// **'الميّه في آخر يوم وصلت لهدفك المحفوظ'**
  String get exportReviewWaterOk;

  /// No description provided for @exportPdfButton.
  ///
  /// In ar, this message translates to:
  /// **'تصدير PDF'**
  String get exportPdfButton;

  /// No description provided for @exportSendToDoctor.
  ///
  /// In ar, this message translates to:
  /// **'إرسال للدكتور'**
  String get exportSendToDoctor;

  /// No description provided for @exportGoalLoss.
  ///
  /// In ar, this message translates to:
  /// **'الهدف: خفض وزن {kg} كجم'**
  String exportGoalLoss(Object kg);

  /// No description provided for @exportBmiLabel.
  ///
  /// In ar, this message translates to:
  /// **'BMI {bmi}'**
  String exportBmiLabel(Object bmi);

  /// No description provided for @exportYearsOld.
  ///
  /// In ar, this message translates to:
  /// **'{age} سنة'**
  String exportYearsOld(Object age);

  /// No description provided for @exportCmLabel.
  ///
  /// In ar, this message translates to:
  /// **'{height} سم'**
  String exportCmLabel(Object height);

  /// Note that the 2000 ml water goal is a non-personalized design default
  ///
  /// In ar, this message translates to:
  /// **'هدف استرشادي غير مخصّص'**
  String get waterGoalDefaultNote;

  /// Caption under neutral badges when earned state is unknown
  ///
  /// In ar, this message translates to:
  /// **'حالة الشارات لم تُحمَّل بعد'**
  String get statsBadgesUnknown;

  /// No description provided for @weekdayLetter1.
  ///
  /// In ar, this message translates to:
  /// **'س'**
  String get weekdayLetter1;

  /// No description provided for @weekdayLetter2.
  ///
  /// In ar, this message translates to:
  /// **'ح'**
  String get weekdayLetter2;

  /// No description provided for @weekdayLetter3.
  ///
  /// In ar, this message translates to:
  /// **'ن'**
  String get weekdayLetter3;

  /// No description provided for @weekdayLetter4.
  ///
  /// In ar, this message translates to:
  /// **'ث'**
  String get weekdayLetter4;

  /// No description provided for @weekdayLetter5.
  ///
  /// In ar, this message translates to:
  /// **'ر'**
  String get weekdayLetter5;

  /// No description provided for @weekdayLetter6.
  ///
  /// In ar, this message translates to:
  /// **'خ'**
  String get weekdayLetter6;

  /// No description provided for @weekdayLetter7.
  ///
  /// In ar, this message translates to:
  /// **'ج'**
  String get weekdayLetter7;

  /// No description provided for @weekdayName1.
  ///
  /// In ar, this message translates to:
  /// **'سبت'**
  String get weekdayName1;

  /// No description provided for @weekdayName2.
  ///
  /// In ar, this message translates to:
  /// **'حد'**
  String get weekdayName2;

  /// No description provided for @weekdayName3.
  ///
  /// In ar, this message translates to:
  /// **'اتنين'**
  String get weekdayName3;

  /// No description provided for @weekdayName4.
  ///
  /// In ar, this message translates to:
  /// **'تلات'**
  String get weekdayName4;

  /// No description provided for @weekdayName5.
  ///
  /// In ar, this message translates to:
  /// **'أربع'**
  String get weekdayName5;

  /// No description provided for @weekdayName6.
  ///
  /// In ar, this message translates to:
  /// **'خميس'**
  String get weekdayName6;

  /// No description provided for @weekdayName7.
  ///
  /// In ar, this message translates to:
  /// **'جمعة'**
  String get weekdayName7;

  /// No description provided for @cameraTitle.
  ///
  /// In ar, this message translates to:
  /// **'صوّر وجبتك'**
  String get cameraTitle;

  /// No description provided for @cameraClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get cameraClose;

  /// No description provided for @cameraFlash.
  ///
  /// In ar, this message translates to:
  /// **'الفلاش'**
  String get cameraFlash;

  /// No description provided for @cameraFlashUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الفلاش مش متاح على الكاميرا دي'**
  String get cameraFlashUnavailable;

  /// No description provided for @cameraDenied.
  ///
  /// In ar, this message translates to:
  /// **'محتاجين إذن الكاميرا. تقدر تجرّب تاني أو تدخل الوجبة بإيدك.'**
  String get cameraDenied;

  /// No description provided for @cameraRestricted.
  ///
  /// In ar, this message translates to:
  /// **'افتح إعدادات الجهاز واسمح للتطبيق يستخدم الكاميرا، أو دخل الوجبة بإيدك.'**
  String get cameraRestricted;

  /// No description provided for @cameraMissing.
  ///
  /// In ar, this message translates to:
  /// **'مفيش كاميرا متاحة على الجهاز ده'**
  String get cameraMissing;

  /// No description provided for @cameraFailed.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا مش جاهزة. جرّب تاني أو استخدم الإدخال اليدوي.'**
  String get cameraFailed;

  /// No description provided for @cameraPaused.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا متوقفة'**
  String get cameraPaused;

  /// No description provided for @cameraStarting.
  ///
  /// In ar, this message translates to:
  /// **'بنجهّز الكاميرا'**
  String get cameraStarting;

  /// No description provided for @cameraRetry.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تاني'**
  String get cameraRetry;

  /// No description provided for @cameraTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'الصورة كبيرة قوي. استخدم صورة أصغر.'**
  String get cameraTooLarge;

  /// No description provided for @cameraBadImage.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نقرأ الصورة دي. جرّب صورة تانية.'**
  String get cameraBadImage;

  /// No description provided for @cameraAiUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تحليل الصور مش متاح حالياً. اختار الأكل من القاعدة وراجع الكميات بنفسك.'**
  String get cameraAiUnavailable;

  /// No description provided for @cameraEmpty.
  ///
  /// In ar, this message translates to:
  /// **'ملقيناش أكل واضح. جرّب صورة تانية أو اختار من القاعدة.'**
  String get cameraEmpty;

  /// No description provided for @cameraInvalidResponse.
  ///
  /// In ar, this message translates to:
  /// **'نتيجة التحليل مش صالحة. جرّب تاني أو اختار من القاعدة.'**
  String get cameraInvalidResponse;

  /// No description provided for @cameraNetwork.
  ///
  /// In ar, this message translates to:
  /// **'التحليل موصلش. جرّب تاني أو اختار من القاعدة.'**
  String get cameraNetwork;

  /// No description provided for @cameraFrameHint.
  ///
  /// In ar, this message translates to:
  /// **'حط الطبق كله جوه الإطار'**
  String get cameraFrameHint;

  /// No description provided for @cameraLightHint.
  ///
  /// In ar, this message translates to:
  /// **'إضاءة كويسة · ثبّت الموبايل · الطبق كامل'**
  String get cameraLightHint;

  /// No description provided for @cameraCapture.
  ///
  /// In ar, this message translates to:
  /// **'التقاط الصورة'**
  String get cameraCapture;

  /// No description provided for @cameraRetake.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التصوير'**
  String get cameraRetake;

  /// No description provided for @cameraMealType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الوجبة'**
  String get cameraMealType;

  /// No description provided for @cameraNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات تساعد التحليل (اختياري)'**
  String get cameraNotes;

  /// No description provided for @cameraNotesHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب طريقة التحضير أو أي تفاصيل مهمة'**
  String get cameraNotesHint;

  /// No description provided for @cameraNoOil.
  ///
  /// In ar, this message translates to:
  /// **'بدون زيت'**
  String get cameraNoOil;

  /// No description provided for @cameraLarge.
  ///
  /// In ar, this message translates to:
  /// **'كمية كبيرة'**
  String get cameraLarge;

  /// No description provided for @cameraSmall.
  ///
  /// In ar, this message translates to:
  /// **'كمية صغيرة'**
  String get cameraSmall;

  /// No description provided for @cameraSugar.
  ///
  /// In ar, this message translates to:
  /// **'سكر زيادة'**
  String get cameraSugar;

  /// No description provided for @cameraGhee.
  ///
  /// In ar, this message translates to:
  /// **'مقلي بالسمن'**
  String get cameraGhee;

  /// No description provided for @cameraPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'الصورة بتتبعت بعد موافقتك في كل مرة. نوع الوجبة والملاحظات مش بيتبعتوا للتحليل. راجع النتيجة والكميات قبل الحفظ.'**
  String get cameraPrivacy;

  /// No description provided for @cameraNoUpload.
  ///
  /// In ar, this message translates to:
  /// **'تحليل الصور غير مفعّل. الصورة بتفضل مؤقتاً على جهازك ومش بتتبعت لأي خدمة.'**
  String get cameraNoUpload;

  /// No description provided for @cameraAnalyzing.
  ///
  /// In ar, this message translates to:
  /// **'بنحلّل وجبتك'**
  String get cameraAnalyzing;

  /// No description provided for @cameraAnalyze.
  ///
  /// In ar, this message translates to:
  /// **'حلّل الصورة'**
  String get cameraAnalyze;

  /// No description provided for @cameraReviewWarning.
  ///
  /// In ar, this message translates to:
  /// **'دي اقتراحات مش قياسات. اختار الأكل والكميات من القاعدة قبل الحفظ.'**
  String get cameraReviewWarning;

  /// No description provided for @cameraManual.
  ///
  /// In ar, this message translates to:
  /// **'اختار الأكل من القاعدة'**
  String get cameraManual;

  /// No description provided for @cameraSkip.
  ///
  /// In ar, this message translates to:
  /// **'استبعاد الاقتراح'**
  String get cameraSkip;

  /// No description provided for @cameraSkipped.
  ///
  /// In ar, this message translates to:
  /// **'مستبعد'**
  String get cameraSkipped;

  /// Kilogram unit abbreviation
  ///
  /// In ar, this message translates to:
  /// **'كجم'**
  String get exportKgUnit;

  /// No description provided for @progressUnknownNote.
  ///
  /// In ar, this message translates to:
  /// **'الشرطة (—) معناها إن البيانات أو الأهداف وقت التسجيل مش متاحة، مش صفر.'**
  String get progressUnknownNote;

  /// No description provided for @reportUnknownCalories.
  ///
  /// In ar, this message translates to:
  /// **'السعرات: غير متاحة'**
  String get reportUnknownCalories;

  /// No description provided for @reportUnknownProtein.
  ///
  /// In ar, this message translates to:
  /// **'البروتين: غير متاح'**
  String get reportUnknownProtein;

  /// No description provided for @reportUnknownFiber.
  ///
  /// In ar, this message translates to:
  /// **'الألياف: غير متاحة'**
  String get reportUnknownFiber;

  /// No description provided for @voiceListening.
  ///
  /// In ar, this message translates to:
  /// **'سامعينك… قول وصف وجبتك'**
  String get voiceListening;

  /// No description provided for @voiceStarting.
  ///
  /// In ar, this message translates to:
  /// **'بنجهّز الميكروفون'**
  String get voiceStarting;

  /// No description provided for @voiceReady.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على الميكروفون أو اكتب وصف وجبتك'**
  String get voiceReady;

  /// No description provided for @voiceDenied.
  ///
  /// In ar, this message translates to:
  /// **'إذن الميكروفون مش متاح. راجع إعدادات الجهاز أو اكتب الوصف.'**
  String get voiceDenied;

  /// No description provided for @voiceUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'التعرف على الصوت مش متاح على الجهاز ده. تقدر تكتب الوصف.'**
  String get voiceUnavailable;

  /// No description provided for @voiceLanguageUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'لغة التطبيق مش متاحة للتعرف على الصوت على الجهاز ده. اكتب الوصف.'**
  String get voiceLanguageUnavailable;

  /// No description provided for @voiceNoSpeech.
  ///
  /// In ar, this message translates to:
  /// **'مسمعناش كلام واضح. جرّب تاني أو اكتب الوصف.'**
  String get voiceNoSpeech;

  /// No description provided for @voiceFailed.
  ///
  /// In ar, this message translates to:
  /// **'التعرف على الصوت موصلش. جرّب تاني أو اكتب الوصف.'**
  String get voiceFailed;

  /// No description provided for @voiceStop.
  ///
  /// In ar, this message translates to:
  /// **'وقف التسجيل'**
  String get voiceStop;

  /// No description provided for @voiceStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ وصف بالصوت'**
  String get voiceStart;

  /// No description provided for @voicePrivacy.
  ///
  /// In ar, this message translates to:
  /// **'الميكروفون بيشتغل لما تضغط بس. خدمة التعرف على الصوت في جهازك ممكن تبعت الصوت لمقدمها. سفرة مش بتحفظ تسجيل صوتي.'**
  String get voicePrivacy;

  /// No description provided for @voiceTextHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: فول وعيش وخيار'**
  String get voiceTextHint;

  /// No description provided for @voiceDescription.
  ///
  /// In ar, this message translates to:
  /// **'وصف الوجبة، قابل للتعديل'**
  String get voiceDescription;

  /// No description provided for @voiceFindFoods.
  ///
  /// In ar, this message translates to:
  /// **'دوّر على الأكل في القاعدة'**
  String get voiceFindFoods;

  /// No description provided for @voicePortionWarning.
  ///
  /// In ar, this message translates to:
  /// **'البحث بيقترح أصناف من القاعدة، مش بيحسب وزن من الكلام. اختار الأصناف وراجع الجرامات قبل الحفظ.'**
  String get voicePortionWarning;

  /// No description provided for @voiceNoFoods.
  ///
  /// In ar, this message translates to:
  /// **'ملقيناش أصناف مطابقة. دوّر باسم الأكلة أو اختارها من القاعدة.'**
  String get voiceNoFoods;

  /// No description provided for @waterWeekRecordedTitle.
  ///
  /// In ar, this message translates to:
  /// **'المية المسجلة آخر ٧ أيام'**
  String get waterWeekRecordedTitle;

  /// No description provided for @barcodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'امسح الباركود'**
  String get barcodeTitle;

  /// No description provided for @barcodeClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get barcodeClose;

  /// No description provided for @barcodeFlash.
  ///
  /// In ar, this message translates to:
  /// **'فلاش'**
  String get barcodeFlash;

  /// No description provided for @barcodeFlashUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الفلاش مش متاح على الجهاز ده'**
  String get barcodeFlashUnavailable;

  /// No description provided for @barcodeStartCamera.
  ///
  /// In ar, this message translates to:
  /// **'شغّل الكاميرا'**
  String get barcodeStartCamera;

  /// No description provided for @barcodeAim.
  ///
  /// In ar, this message translates to:
  /// **'وجّه الكاميرا ناحية الباركود'**
  String get barcodeAim;

  /// No description provided for @barcodeSearching.
  ///
  /// In ar, this message translates to:
  /// **'بيدوّر على الباركود…'**
  String get barcodeSearching;

  /// No description provided for @barcodeManualLabel.
  ///
  /// In ar, this message translates to:
  /// **'أو اكتب الرقم اللي تحت الباركود'**
  String get barcodeManualLabel;

  /// No description provided for @barcodeManualField.
  ///
  /// In ar, this message translates to:
  /// **'رقم الباركود'**
  String get barcodeManualField;

  /// No description provided for @barcodeLookup.
  ///
  /// In ar, this message translates to:
  /// **'دوّر'**
  String get barcodeLookup;

  /// No description provided for @barcodePhotoFallback.
  ///
  /// In ar, this message translates to:
  /// **'صوّر الجدول الغذائي'**
  String get barcodePhotoFallback;

  /// No description provided for @barcodeSearchFallback.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الأكلات'**
  String get barcodeSearchFallback;

  /// No description provided for @barcodeCameraDenied.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا مش مسموحة للتطبيق. اكتب الرقم تحت، أو فعّل إذن الكاميرا من إعدادات الجهاز.'**
  String get barcodeCameraDenied;

  /// No description provided for @barcodeCameraUnsupported.
  ///
  /// In ar, this message translates to:
  /// **'الجهاز ده مفيهوش كاميرا متاحة. اكتب الرقم تحت.'**
  String get barcodeCameraUnsupported;

  /// No description provided for @barcodeCameraError.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا مش شغالة دلوقتي. اكتب الرقم تحت أو جرّب تاني.'**
  String get barcodeCameraError;

  /// No description provided for @barcodeRetryCamera.
  ///
  /// In ar, this message translates to:
  /// **'جرّب الكاميرا تاني'**
  String get barcodeRetryCamera;

  /// No description provided for @barcodeLooking.
  ///
  /// In ar, this message translates to:
  /// **'بنجيب بيانات {code}'**
  String barcodeLooking(String code);

  /// No description provided for @barcodeInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الرقم غلط. لازم يكون ٨ أو ١٢ أو ١٣ أو ١٤ رقم وصحيح حسب رقم التحقق.'**
  String get barcodeInvalid;

  /// No description provided for @barcodeNotFound.
  ///
  /// In ar, this message translates to:
  /// **'ملقيناش المنتج {code}. اتأكد من الرقم أو دوّر باسمه.'**
  String barcodeNotFound(String code);

  /// No description provided for @barcodeNotFoundHelp.
  ///
  /// In ar, this message translates to:
  /// **'ممكن تدوّر عليه بالاسم أو تصوّر الجدول الغذائي. مش هنسجّل أرقام من عندنا.'**
  String get barcodeNotFoundHelp;

  /// No description provided for @barcodeRetry.
  ///
  /// In ar, this message translates to:
  /// **'حاول تاني'**
  String get barcodeRetry;

  /// No description provided for @barcodeOffline.
  ///
  /// In ar, this message translates to:
  /// **'مفيش اتصال بالإنترنت أو الاتصال بطيء. اتأكد وحاول تاني، أو اكتب الأكلة يدوي.'**
  String get barcodeOffline;

  /// No description provided for @barcodeRateLimited.
  ///
  /// In ar, this message translates to:
  /// **'طلبات كتير في وقت قصير. جرّب بعد {seconds} ثانية.'**
  String barcodeRateLimited(int seconds);

  /// No description provided for @barcodeUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'خدمة Open Food Facts مش متاحة دلوقتي. حاول بعد شوية.'**
  String get barcodeUnavailable;

  /// No description provided for @barcodeBadResponse.
  ///
  /// In ar, this message translates to:
  /// **'الرد من المصدر مش مفهوم. حاول تاني بعد شوية.'**
  String get barcodeBadResponse;

  /// No description provided for @barcodeNotConfigured.
  ///
  /// In ar, this message translates to:
  /// **'البحث بالباركود مش متاح في النسخة دي لسه.'**
  String get barcodeNotConfigured;

  /// No description provided for @productTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيانات المنتج'**
  String get productTitle;

  /// No description provided for @productBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get productBack;

  /// No description provided for @productNoImage.
  ///
  /// In ar, this message translates to:
  /// **'مفيش صورة للمنتج في المصدر'**
  String get productNoImage;

  /// No description provided for @productNutritionPer100g.
  ///
  /// In ar, this message translates to:
  /// **'القيم الغذائية لكل ١٠٠ جم'**
  String get productNutritionPer100g;

  /// No description provided for @productNutritionPer100ml.
  ///
  /// In ar, this message translates to:
  /// **'القيم الغذائية لكل ١٠٠ مل'**
  String get productNutritionPer100ml;

  /// No description provided for @productNotProvided.
  ///
  /// In ar, this message translates to:
  /// **'غير مذكور'**
  String get productNotProvided;

  /// No description provided for @productCalories.
  ///
  /// In ar, this message translates to:
  /// **'السعرات'**
  String get productCalories;

  /// No description provided for @productProtein.
  ///
  /// In ar, this message translates to:
  /// **'بروتين'**
  String get productProtein;

  /// No description provided for @productCarbs.
  ///
  /// In ar, this message translates to:
  /// **'كربوهيدرات'**
  String get productCarbs;

  /// No description provided for @productFat.
  ///
  /// In ar, this message translates to:
  /// **'دهون'**
  String get productFat;

  /// No description provided for @productFiber.
  ///
  /// In ar, this message translates to:
  /// **'ألياف'**
  String get productFiber;

  /// No description provided for @productSugars.
  ///
  /// In ar, this message translates to:
  /// **'سكر'**
  String get productSugars;

  /// No description provided for @productSodium.
  ///
  /// In ar, this message translates to:
  /// **'صوديوم'**
  String get productSodium;

  /// No description provided for @productKcalUnit.
  ///
  /// In ar, this message translates to:
  /// **'سعرة'**
  String get productKcalUnit;

  /// No description provided for @productGramUnit.
  ///
  /// In ar, this message translates to:
  /// **'جم'**
  String get productGramUnit;

  /// No description provided for @productMgUnit.
  ///
  /// In ar, this message translates to:
  /// **'ملليجرام'**
  String get productMgUnit;

  /// No description provided for @productServing.
  ///
  /// In ar, this message translates to:
  /// **'حجم الحصة المذكور: {serving}'**
  String productServing(String serving);

  /// No description provided for @productQuantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية في العبوة: {quantity}'**
  String productQuantity(String quantity);

  /// No description provided for @productIngredients.
  ///
  /// In ar, this message translates to:
  /// **'المكوّنات (كما في المصدر)'**
  String get productIngredients;

  /// No description provided for @productAllergens.
  ///
  /// In ar, this message translates to:
  /// **'مسببات الحساسية المذكورة في المصدر'**
  String get productAllergens;

  /// No description provided for @productAllergensNone.
  ///
  /// In ar, this message translates to:
  /// **'المصدر مذكرش مسببات حساسية. ده مش معناه إن المنتج خالٍ منها.'**
  String get productAllergensNone;

  /// No description provided for @productAllergensUnknown.
  ///
  /// In ar, this message translates to:
  /// **'المصدر ملوش بيانات عن مسببات الحساسية. اقرأ العبوة.'**
  String get productAllergensUnknown;

  /// No description provided for @productAllergensCaveat.
  ///
  /// In ar, this message translates to:
  /// **'البيانات من مساهمين وقد تكون ناقصة. اقرأ العبوة دايمًا لو عندك حساسية.'**
  String get productAllergensCaveat;

  /// No description provided for @productNutriScore.
  ///
  /// In ar, this message translates to:
  /// **'نوتري سكور'**
  String get productNutriScore;

  /// No description provided for @productNutriScoreFromSource.
  ///
  /// In ar, this message translates to:
  /// **'كما ورد في المصدر'**
  String get productNutriScoreFromSource;

  /// No description provided for @productAttribution.
  ///
  /// In ar, this message translates to:
  /// **'المصدر: Open Food Facts. البيانات من مساهمين ومرخّصة بترخيص ODbL وقد تكون ناقصة أو قديمة.'**
  String get productAttribution;

  /// No description provided for @productFromCache.
  ///
  /// In ar, this message translates to:
  /// **'نسخة محفوظة على الجهاز'**
  String get productFromCache;

  /// No description provided for @productPortionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكمية بالجرام'**
  String get productPortionLabel;

  /// No description provided for @productUseServing.
  ///
  /// In ar, this message translates to:
  /// **'حصة {grams} جم'**
  String productUseServing(String grams);

  /// No description provided for @productAddToDiary.
  ///
  /// In ar, this message translates to:
  /// **'أضف لليومية'**
  String get productAddToDiary;

  /// No description provided for @productGramsInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كمية بالجرام أكبر من صفر وحتى ١٠٠٠٠.'**
  String get productGramsInvalid;

  /// No description provided for @productCannotLogMl.
  ///
  /// In ar, this message translates to:
  /// **'القيم دي لكل ١٠٠ مل. مش هنحوّلها لجرامات لأن كثافة المنتج مش معروفة، فمفيش تسجيل بالجرام.'**
  String get productCannotLogMl;

  /// No description provided for @productCannotLogNoEnergy.
  ///
  /// In ar, this message translates to:
  /// **'السعرات مش مذكورة في المصدر، فمش هينفع نسجّل المنتج ده.'**
  String get productCannotLogNoEnergy;

  /// No description provided for @productNutritionBasisUnknown.
  ///
  /// In ar, this message translates to:
  /// **'القيم كما وردت، وحدة الأساس غير مؤكدة'**
  String get productNutritionBasisUnknown;

  /// No description provided for @productCannotLogUnknownBasis.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة الأساسية مش واضحة أو متعارضة في المصدر. مش هنحوّل القيم لجرامات. راجع الملصق أو اختار أكلة من القاعدة.'**
  String get productCannotLogUnknownBasis;

  /// No description provided for @favoritesTitle.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get favoritesTitle;

  /// No description provided for @favoritesTabMeals.
  ///
  /// In ar, this message translates to:
  /// **'وجبات مفضلة'**
  String get favoritesTabMeals;

  /// No description provided for @favoritesTabRecipes.
  ///
  /// In ar, this message translates to:
  /// **'وصفات محفوظة'**
  String get favoritesTabRecipes;

  /// No description provided for @favoritesTabFrequent.
  ///
  /// In ar, this message translates to:
  /// **'الأكتر تسجيلًا'**
  String get favoritesTabFrequent;

  /// No description provided for @favoritesHeroChip.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر تسجيلًا'**
  String get favoritesHeroChip;

  /// No description provided for @favoritesHeroCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{سجّلتها مرة في آخر ٣٠ يوم} =2{سجّلتها مرتين في آخر ٣٠ يوم} few{سجّلتها {count} مرات في آخر ٣٠ يوم} other{عدد مرات تسجيلها في آخر ٣٠ يوم: {count}}}'**
  String favoritesHeroCount(int count);

  /// No description provided for @favoritesSortLabel.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب'**
  String get favoritesSortLabel;

  /// No description provided for @favoritesSortRecent.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث'**
  String get favoritesSortRecent;

  /// No description provided for @favoritesSortName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get favoritesSortName;

  /// No description provided for @favoritesSortCalories.
  ///
  /// In ar, this message translates to:
  /// **'السعرات'**
  String get favoritesSortCalories;

  /// No description provided for @favoritesRemove.
  ///
  /// In ar, this message translates to:
  /// **'شيل من المفضلة'**
  String get favoritesRemove;

  /// No description provided for @favoritesRemoved.
  ///
  /// In ar, this message translates to:
  /// **'اتشالت من المفضلة'**
  String get favoritesRemoved;

  /// No description provided for @favoritesRemoveFailed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نشيلها. جرّب تاني.'**
  String get favoritesRemoveFailed;

  /// No description provided for @favoritesAddToDiary.
  ///
  /// In ar, this message translates to:
  /// **'أضف لليومية'**
  String get favoritesAddToDiary;

  /// No description provided for @favoritesAdded.
  ///
  /// In ar, this message translates to:
  /// **'اتضافت لليومية'**
  String get favoritesAdded;

  /// No description provided for @favoritesAddFailed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نضيفها. جرّب تاني.'**
  String get favoritesAddFailed;

  /// No description provided for @favoritesSaved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظت في المفضلة'**
  String get favoritesSaved;

  /// No description provided for @favoritesSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحفظها في المفضلة. جرّب تاني.'**
  String get favoritesSaveFailed;

  /// No description provided for @favoritesPickMealType.
  ///
  /// In ar, this message translates to:
  /// **'تضيفها كـ'**
  String get favoritesPickMealType;

  /// No description provided for @favoritesUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الوجبة الأصلية اتمسحت'**
  String get favoritesUnavailable;

  /// No description provided for @favoritesUnavailableHint.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تشيلها من المفضلة بس.'**
  String get favoritesUnavailableHint;

  /// No description provided for @favoritesMealMeta.
  ///
  /// In ar, this message translates to:
  /// **'{kcal} سعرة'**
  String favoritesMealMeta(String kcal);

  /// No description provided for @favoritesMealMetaProtein.
  ///
  /// In ar, this message translates to:
  /// **'{kcal} سعرة · {protein} جم بروتين'**
  String favoritesMealMetaProtein(String kcal, String protein);

  /// No description provided for @favoritesFrequentCount.
  ///
  /// In ar, this message translates to:
  /// **'اتسجّل {count} مرات'**
  String favoritesFrequentCount(int count);

  /// No description provided for @favoritesFrequentNote.
  ///
  /// In ar, this message translates to:
  /// **'من وجباتك المسجّلة آخر ٣٠ يوم.'**
  String get favoritesFrequentNote;

  /// No description provided for @favoritesEmptyMealsTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش وجبات مفضلة'**
  String get favoritesEmptyMealsTitle;

  /// No description provided for @favoritesEmptyMealsBody.
  ///
  /// In ar, this message translates to:
  /// **'افتح وجبة اتسجلت واضغط القلب عشان تلاقيها هنا.'**
  String get favoritesEmptyMealsBody;

  /// No description provided for @favoritesEmptyRecipesTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش وصفات محفوظة'**
  String get favoritesEmptyRecipesTitle;

  /// No description provided for @favoritesEmptyRecipesBody.
  ///
  /// In ar, this message translates to:
  /// **'احفظ وصفة من اقتراحات الوصفات وهتظهر هنا.'**
  String get favoritesEmptyRecipesBody;

  /// No description provided for @favoritesEmptyFrequentTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أكل متكرر لسه'**
  String get favoritesEmptyFrequentTitle;

  /// No description provided for @favoritesEmptyFrequentBody.
  ///
  /// In ar, this message translates to:
  /// **'لما تسجّل أكلك كذا مرة هيظهر الأكتر تكرارًا هنا.'**
  String get favoritesEmptyFrequentBody;

  /// No description provided for @favoritesLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحمّل المفضلة.'**
  String get favoritesLoadFailed;

  /// No description provided for @favoritesRetry.
  ///
  /// In ar, this message translates to:
  /// **'حاول تاني'**
  String get favoritesRetry;

  /// No description provided for @favoritesExpired.
  ///
  /// In ar, this message translates to:
  /// **'الجلسة خلصت. ادخل تاني.'**
  String get favoritesExpired;

  /// No description provided for @premiumTitle.
  ///
  /// In ar, this message translates to:
  /// **'سفرة بريميوم'**
  String get premiumTitle;

  /// No description provided for @premiumSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ميزات إضافية جاية قريب'**
  String get premiumSubtitle;

  /// No description provided for @premiumComingSoonChip.
  ///
  /// In ar, this message translates to:
  /// **'قريبًا'**
  String get premiumComingSoonChip;

  /// No description provided for @premiumFeatureCoachTitle.
  ///
  /// In ar, this message translates to:
  /// **'مدرّب ذكي'**
  String get premiumFeatureCoachTitle;

  /// No description provided for @premiumFeatureCoachBody.
  ///
  /// In ar, this message translates to:
  /// **'نصايح مبنية على أكلك'**
  String get premiumFeatureCoachBody;

  /// No description provided for @premiumFeatureReportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقارير أسبوعية'**
  String get premiumFeatureReportsTitle;

  /// No description provided for @premiumFeatureReportsBody.
  ///
  /// In ar, this message translates to:
  /// **'ملخص لتقدمك كل أسبوع'**
  String get premiumFeatureReportsBody;

  /// No description provided for @premiumFeaturePlanTitle.
  ///
  /// In ar, this message translates to:
  /// **'تخطيط وجبات'**
  String get premiumFeaturePlanTitle;

  /// No description provided for @premiumFeaturePlanBody.
  ///
  /// In ar, this message translates to:
  /// **'خطة أسبوع على مقاسك'**
  String get premiumFeaturePlanBody;

  /// No description provided for @premiumNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك مش متاح دلوقتي'**
  String get premiumNotAvailable;

  /// No description provided for @premiumBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get premiumBack;

  /// No description provided for @plannerTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطة الأسبوع'**
  String get plannerTitle;

  /// No description provided for @plannerEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش خطة للأسبوع ده. اضغط ولّد خطة جديدة عشان تبدأ.'**
  String get plannerEmpty;

  /// No description provided for @plannerDayEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش وجبات في اليوم ده. ضيف وجبة من الأزرار تحت.'**
  String get plannerDayEmpty;

  /// No description provided for @plannerTotal.
  ///
  /// In ar, this message translates to:
  /// **'المجموع'**
  String get plannerTotal;

  /// No description provided for @plannerMissingTarget.
  ///
  /// In ar, this message translates to:
  /// **'كمّل إعدادك الشخصي عشان نعرف هدفك اليومي ونجهّز خطة مناسبة.'**
  String get plannerMissingTarget;

  /// No description provided for @plannerGenerate.
  ///
  /// In ar, this message translates to:
  /// **'ولّد خطة جديدة'**
  String get plannerGenerate;

  /// No description provided for @plannerShoppingCta.
  ///
  /// In ar, this message translates to:
  /// **'قائمة التسوق'**
  String get plannerShoppingCta;

  /// No description provided for @plannerReplace.
  ///
  /// In ar, this message translates to:
  /// **'استبدال'**
  String get plannerReplace;

  /// No description provided for @plannerAddMeal.
  ///
  /// In ar, this message translates to:
  /// **'ضيف'**
  String get plannerAddMeal;

  /// No description provided for @weekdaySat.
  ///
  /// In ar, this message translates to:
  /// **'س'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In ar, this message translates to:
  /// **'ح'**
  String get weekdaySun;

  /// No description provided for @weekdayMon.
  ///
  /// In ar, this message translates to:
  /// **'ن'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In ar, this message translates to:
  /// **'ث'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In ar, this message translates to:
  /// **'ر'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In ar, this message translates to:
  /// **'خ'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In ar, this message translates to:
  /// **'ج'**
  String get weekdayFri;

  /// No description provided for @shoppingTitle.
  ///
  /// In ar, this message translates to:
  /// **'قايمة التسوق'**
  String get shoppingTitle;

  /// No description provided for @shoppingEmpty.
  ///
  /// In ar, this message translates to:
  /// **'القايمة فاضية. ولّدها من خطة الأسبوع أو ضيف صنف بنفسك.'**
  String get shoppingEmpty;

  /// No description provided for @shoppingGenerateFromPlan.
  ///
  /// In ar, this message translates to:
  /// **'ولّد من خطة الأسبوع'**
  String get shoppingGenerateFromPlan;

  /// No description provided for @shoppingRegenerate.
  ///
  /// In ar, this message translates to:
  /// **'حدّث من خطة الأسبوع'**
  String get shoppingRegenerate;

  /// No description provided for @shoppingNoPlan.
  ///
  /// In ar, this message translates to:
  /// **'ولّد واحفظ خطة الأسبوع الأول عشان تقدر تولّد القايمة منها.'**
  String get shoppingNoPlan;

  /// No description provided for @shoppingSkipped.
  ///
  /// In ar, this message translates to:
  /// **'{count} صنف محتاجين تراجع كميتهم في الخطة قبل إضافتهم.'**
  String shoppingSkipped(int count);

  /// No description provided for @shoppingItemCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{٠ أصناف} one{صنف واحد} two{صنفين} few{{count} أصناف} many{{count} صنف} other{{count} صنف}}'**
  String shoppingItemCount(int count);

  /// No description provided for @shoppingGroupProduce.
  ///
  /// In ar, this message translates to:
  /// **'خضار وفاكهة'**
  String get shoppingGroupProduce;

  /// No description provided for @shoppingGroupProtein.
  ///
  /// In ar, this message translates to:
  /// **'بروتين'**
  String get shoppingGroupProtein;

  /// No description provided for @shoppingGroupDairy.
  ///
  /// In ar, this message translates to:
  /// **'ألبان'**
  String get shoppingGroupDairy;

  /// No description provided for @shoppingGroupGrains.
  ///
  /// In ar, this message translates to:
  /// **'حبوب ونشويات'**
  String get shoppingGroupGrains;

  /// No description provided for @shoppingGroupOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get shoppingGroupOther;

  /// No description provided for @shoppingAddTitle.
  ///
  /// In ar, this message translates to:
  /// **'ضيف صنف بنفسك'**
  String get shoppingAddTitle;

  /// No description provided for @shoppingAddName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الصنف'**
  String get shoppingAddName;

  /// No description provided for @shoppingAddInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم الصنف وكمية أكبر من صفر'**
  String get shoppingAddInvalid;

  /// No description provided for @coachTitle.
  ///
  /// In ar, this message translates to:
  /// **'مدرّب سفرة'**
  String get coachTitle;

  /// No description provided for @coachStatusReviewing.
  ///
  /// In ar, this message translates to:
  /// **'بيراجع سجلات وجباتك المحفوظة'**
  String get coachStatusReviewing;

  /// No description provided for @coachStatusIdle.
  ///
  /// In ar, this message translates to:
  /// **'مستني أول تسجيل منك'**
  String get coachStatusIdle;

  /// No description provided for @coachRuleBadge.
  ///
  /// In ar, this message translates to:
  /// **'من سجلاتك'**
  String get coachRuleBadge;

  /// No description provided for @coachRuleBadgeShort.
  ///
  /// In ar, this message translates to:
  /// **'سجلاتك'**
  String get coachRuleBadgeShort;

  /// No description provided for @coachToday.
  ///
  /// In ar, this message translates to:
  /// **'النهاردة'**
  String get coachToday;

  /// No description provided for @coachReviewNote.
  ///
  /// In ar, this message translates to:
  /// **'المدرّب بيراجع وجباتك آخر ٧ أيام'**
  String get coachReviewNote;

  /// No description provided for @coachNoRecordsNote.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش سجلات كفاية — سجّل وجبتك الأولى'**
  String get coachNoRecordsNote;

  /// No description provided for @coachSendFailed.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة متسجلتش. حاول تاني.'**
  String get coachSendFailed;

  /// No description provided for @coachInputHint.
  ///
  /// In ar, this message translates to:
  /// **'اسأل مدرّب سفرة...'**
  String get coachInputHint;

  /// No description provided for @coachAdviceLabel.
  ///
  /// In ar, this message translates to:
  /// **'نصيحة'**
  String get coachAdviceLabel;

  /// No description provided for @coachQuickPlan.
  ///
  /// In ar, this message translates to:
  /// **'اعمل لي خطة غدا'**
  String get coachQuickPlan;

  /// No description provided for @coachQuickWeek.
  ///
  /// In ar, this message translates to:
  /// **'حلل أسبوعي'**
  String get coachQuickWeek;

  /// No description provided for @coachQuickWater.
  ///
  /// In ar, this message translates to:
  /// **'أشرب كام مية؟'**
  String get coachQuickWater;

  /// No description provided for @ramadanGreeting.
  ///
  /// In ar, this message translates to:
  /// **'رمضان كريم'**
  String get ramadanGreeting;

  /// No description provided for @ramadanUntilIftar.
  ///
  /// In ar, this message translates to:
  /// **'فاضل على الإفطار'**
  String get ramadanUntilIftar;

  /// No description provided for @ramadanUntilTaraweeh.
  ///
  /// In ar, this message translates to:
  /// **'فاضل على بعد التراويح'**
  String get ramadanUntilTaraweeh;

  /// No description provided for @ramadanUntilSuhoor.
  ///
  /// In ar, this message translates to:
  /// **'فاضل على آخر السحور'**
  String get ramadanUntilSuhoor;

  /// No description provided for @ramadanSeconds.
  ///
  /// In ar, this message translates to:
  /// **'ثانية'**
  String get ramadanSeconds;

  /// No description provided for @ramadanMinutes.
  ///
  /// In ar, this message translates to:
  /// **'دقيقة'**
  String get ramadanMinutes;

  /// No description provided for @ramadanHours.
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get ramadanHours;

  /// No description provided for @ramadanSuhoorEnd.
  ///
  /// In ar, this message translates to:
  /// **'آخر السحور'**
  String get ramadanSuhoorEnd;

  /// No description provided for @ramadanIftarAt.
  ///
  /// In ar, this message translates to:
  /// **'الإفطار'**
  String get ramadanIftarAt;

  /// No description provided for @ramadanTaraweeh.
  ///
  /// In ar, this message translates to:
  /// **'بعد التراويح'**
  String get ramadanTaraweeh;

  /// No description provided for @ramadanCups.
  ///
  /// In ar, this message translates to:
  /// **'أكواب'**
  String get ramadanCups;

  /// No description provided for @ramadanCupsUserNote.
  ///
  /// In ar, this message translates to:
  /// **'هدف الأكواب ده انت اللي ظبطه'**
  String get ramadanCupsUserNote;

  /// No description provided for @ramadanCupsDefaultNote.
  ///
  /// In ar, this message translates to:
  /// **'٨ أكواب عرض افتراضي من التصميم، مش هدف صحي شخصي — تقدر تظبطه'**
  String get ramadanCupsDefaultNote;

  /// No description provided for @ramadanEditTimes.
  ///
  /// In ar, this message translates to:
  /// **'ظبط مواعيدك'**
  String get ramadanEditTimes;

  /// No description provided for @ramadanDisclaimer.
  ///
  /// In ar, this message translates to:
  /// **'للتوعية فقط، استشر طبيبك لو عندك سكر أو حمل'**
  String get ramadanDisclaimer;

  /// No description provided for @ramadanSetupBody.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق مش بيخترع مواعيد صلاة. ظبط مواعيد الإفطار والسحور على حسب بلدك وجدولك، وهنكمل العد والتنظيم عليها.'**
  String get ramadanSetupBody;

  /// No description provided for @ramadanSetupCta.
  ///
  /// In ar, this message translates to:
  /// **'ظبط مواعيد رمضان'**
  String get ramadanSetupCta;

  /// No description provided for @ramadanChooseTime.
  ///
  /// In ar, this message translates to:
  /// **'اختار الوقت'**
  String get ramadanChooseTime;

  /// No description provided for @ramadanTimesTitle.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد رمضان بتاعتك'**
  String get ramadanTimesTitle;

  /// No description provided for @ramadanTimesNote.
  ///
  /// In ar, this message translates to:
  /// **'اختار كل وقت حسب مدينتك ومواعيدك. التطبيق مش بيحسب مواقيت الصلاة هنا، وتقدر تغيّرها في أي وقت.'**
  String get ramadanTimesNote;

  /// Warning that allergy filtering is name-level only, shown wherever a plan is generated.
  ///
  /// In ar, this message translates to:
  /// **'لو عندك حساسية، راجع مكونات كل وجبة وعبوتها قبل الأكل. الخطة مش ضمان لخلو الوجبة من مسببات الحساسية.'**
  String get plannerAllergyWarning;

  /// No description provided for @coachVoicePrivacy.
  ///
  /// In ar, this message translates to:
  /// **'الإملاء الصوتي ممكن يبعت الصوت لمزوّد التعرف على الكلام في جهازك. سفرة مش بيحفظ الصوت؛ الكلام هيظهر هنا عشان تراجعه وتعدّله قبل الإرسال.'**
  String get coachVoicePrivacy;

  /// No description provided for @coachVoiceCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get coachVoiceCancel;

  /// No description provided for @coachVoiceStart.
  ///
  /// In ar, this message translates to:
  /// **'إملاء صوتي'**
  String get coachVoiceStart;

  /// No description provided for @coachVoiceListening.
  ///
  /// In ar, this message translates to:
  /// **'جاري الاستماع. راجع الكلام قبل ما تبعته.'**
  String get coachVoiceListening;

  /// No description provided for @coachVoiceUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الإملاء غير متاح أو لم يسمع كلاماً. راجع إذن الميكروفون واللغة، أو اكتب رسالتك.'**
  String get coachVoiceUnavailable;

  /// No description provided for @statsBadgesEarned.
  ///
  /// In ar, this message translates to:
  /// **'{earned} من {total} شارات متحققة'**
  String statsBadgesEarned(String earned, String total);

  /// No description provided for @plannerWeekTotal.
  ///
  /// In ar, this message translates to:
  /// **'مجموع الأسبوع: {calories} سعرة'**
  String plannerWeekTotal(String calories);

  /// No description provided for @avatarLocalNote.
  ///
  /// In ar, this message translates to:
  /// **'اختار صورة لحسابك، هتتحفظ على الجهاز ده بس ومش هتترفع لأي خدمة.'**
  String get avatarLocalNote;

  /// No description provided for @avatarChoose.
  ///
  /// In ar, this message translates to:
  /// **'اختار صورة البروفايل'**
  String get avatarChoose;

  /// No description provided for @avatarFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحفظ الصورة. جرب صورة تانية.'**
  String get avatarFailed;

  /// No description provided for @appLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get appLanguage;

  /// No description provided for @cameraGallery.
  ///
  /// In ar, this message translates to:
  /// **'اختار صورة من المعرض'**
  String get cameraGallery;

  /// No description provided for @exportSelectRange.
  ///
  /// In ar, this message translates to:
  /// **'اختار فترة التقرير'**
  String get exportSelectRange;

  /// No description provided for @exportRangeLimit.
  ///
  /// In ar, this message translates to:
  /// **'اختار فترة لحد سنة واحدة لكل تقرير.'**
  String get exportRangeLimit;

  /// No description provided for @exportLoggedWater.
  ///
  /// In ar, this message translates to:
  /// **'المية المسجلة حسب اليوم (مل)'**
  String get exportLoggedWater;

  /// No description provided for @exportWeightHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل الوزن المسجل (كجم)'**
  String get exportWeightHistory;

  /// No description provided for @exportNoWeightHistory.
  ///
  /// In ar, this message translates to:
  /// **'مفيش تسجيلات وزن خلال الفترة المختارة.'**
  String get exportNoWeightHistory;

  /// No description provided for @exportNoWaterRecord.
  ///
  /// In ar, this message translates to:
  /// **'مفيش كمية مية مسجلة'**
  String get exportNoWaterRecord;

  /// No description provided for @exportTrackingDays.
  ///
  /// In ar, this message translates to:
  /// **'خريطة التسجيل (عدد أيام الفترة: {days})'**
  String exportTrackingDays(String days);

  /// No description provided for @themeAccentPicker.
  ///
  /// In ar, this message translates to:
  /// **'ألوان المظهر الحالي'**
  String get themeAccentPicker;

  /// No description provided for @remindersTitle.
  ///
  /// In ar, this message translates to:
  /// **'التذكيرات'**
  String get remindersTitle;

  /// No description provided for @remindersWaterTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير المية'**
  String get remindersWaterTitle;

  /// No description provided for @remindersWaterAdd.
  ///
  /// In ar, this message translates to:
  /// **'أضف ميعاد'**
  String get remindersWaterAdd;

  /// No description provided for @remindersWaterRemove.
  ///
  /// In ar, this message translates to:
  /// **'شيل الميعاد'**
  String get remindersWaterRemove;

  /// No description provided for @remindersWaterFull.
  ///
  /// In ar, this message translates to:
  /// **'وصلت لأقصى عدد مواعيد للمية.'**
  String get remindersWaterFull;

  /// No description provided for @remindersMealsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الوجبات'**
  String get remindersMealsTitle;

  /// No description provided for @remindersWeightTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الوزن'**
  String get remindersWeightTitle;

  /// No description provided for @remindersWeightEvery.
  ///
  /// In ar, this message translates to:
  /// **'كل أسبوع يوم {day}'**
  String remindersWeightEvery(String day);

  /// No description provided for @remindersPickDay.
  ///
  /// In ar, this message translates to:
  /// **'اختار اليوم'**
  String get remindersPickDay;

  /// No description provided for @remindersNotSet.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش ميعاد'**
  String get remindersNotSet;

  /// No description provided for @remindersPermissionOff.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات سفرة مقفولة من إعدادات الجهاز. افتحها من هناك عشان التذكيرات توصلك.'**
  String get remindersPermissionOff;

  /// No description provided for @remindersPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'من غير إذن الإشعارات مش هنقدر نبعتلك تذكير.'**
  String get remindersPermissionDenied;

  /// No description provided for @remindersScheduleFailed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نظبط التذكير على الجهاز. جرّب تاني.'**
  String get remindersScheduleFailed;

  /// No description provided for @remindersTimezoneUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحدد توقيت الجهاز، فالتذكيرات متظبطتش.'**
  String get remindersTimezoneUnavailable;

  /// No description provided for @remindersSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحفظ التغيير. جرّب تاني.'**
  String get remindersSaveFailed;

  /// No description provided for @remindersInexactNote.
  ///
  /// In ar, this message translates to:
  /// **'التذكيرات مش بتتحدد بالدقيقة بالظبط. ممكن توصل متأخرة شوية، خصوصًا لو الموبايل في وضع توفير الطاقة.'**
  String get remindersInexactNote;

  /// No description provided for @remindersPrivacyNote.
  ///
  /// In ar, this message translates to:
  /// **'التذكيرات محفوظة على جهازك بس، وبتشتغل لحسابك الحالي.'**
  String get remindersPrivacyNote;

  /// No description provided for @remindersNotifTitle.
  ///
  /// In ar, this message translates to:
  /// **'سفرة'**
  String get remindersNotifTitle;

  /// No description provided for @remindersNotifWater.
  ///
  /// In ar, this message translates to:
  /// **'لو مناسب ليك، خد لحظة للمية. افتح سفرة وسجّل اللي شربته.'**
  String get remindersNotifWater;

  /// No description provided for @remindersNotifMeal.
  ///
  /// In ar, this message translates to:
  /// **'جاهز تسجّل {meal}؟ افتح سفرة وراجع أكلك وكميته.'**
  String remindersNotifMeal(String meal);

  /// No description provided for @remindersNotifWeight.
  ///
  /// In ar, this message translates to:
  /// **'لو ده وقت مناسب، سجّل وزنك. ركّز على الاتجاه مش رقم يوم واحد.'**
  String get remindersNotifWeight;

  /// No description provided for @remindersChannelWater.
  ///
  /// In ar, this message translates to:
  /// **'تذكير المية'**
  String get remindersChannelWater;

  /// No description provided for @remindersChannelMeals.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الوجبات'**
  String get remindersChannelMeals;

  /// No description provided for @remindersChannelWeight.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الوزن'**
  String get remindersChannelWeight;

  /// No description provided for @reminderCleanupFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تأكيد إلغاء التذكيرات. ممكن تفضل تظهر على الجهاز لحد فتح التطبيق ومحاولة الإلغاء تاني.'**
  String get reminderCleanupFailed;

  /// No description provided for @reportMeasuredAverages.
  ///
  /// In ar, this message translates to:
  /// **'متوسط القيم المسجّلة'**
  String get reportMeasuredAverages;

  /// No description provided for @reportMetricCoverage.
  ///
  /// In ar, this message translates to:
  /// **'{measured} من {total} يوم فيه قيمة مسجّلة'**
  String reportMetricCoverage(String measured, String total);

  /// No description provided for @reportRangeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الفترة: {start} لحد {end}'**
  String reportRangeLabel(String start, String end);

  /// No description provided for @waterGoalChoose.
  ///
  /// In ar, this message translates to:
  /// **'غيّر هدف الميّه'**
  String get waterGoalChoose;

  /// No description provided for @waterGoalChosenNote.
  ///
  /// In ar, this message translates to:
  /// **'هدفك اللي اخترته، محفوظ على الجهاز للحساب ده'**
  String get waterGoalChosenNote;

  /// No description provided for @waterGoalLocalHint.
  ///
  /// In ar, this message translates to:
  /// **'اختار هدفك بالملليلتر. مش توصية طبية، ومش بيتزامن بين الأجهزة.'**
  String get waterGoalLocalHint;

  /// No description provided for @waterGoalInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كمية أكبر من صفر ولحد ٢٠٠٠٠ مل'**
  String get waterGoalInvalid;

  /// No description provided for @alternativesPreferenceNote.
  ///
  /// In ar, this message translates to:
  /// **'البدائل بتراعي حساسية وتفضيلات ملفك بمطابقة الأسماء والفئات فقط، مش فحص أمان للحساسية. راجع المكونات والملصق. لو عندك قيد غذائي مش مدعوم، مش هنعرض بديل على إنه مناسب.'**
  String get alternativesPreferenceNote;

  /// No description provided for @cameraConsentTitle.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الصورة إلى {provider}؟'**
  String cameraConsentTitle(String provider);

  /// No description provided for @cameraConsentDetail.
  ///
  /// In ar, this message translates to:
  /// **'الإرسال للصورة دي بس حسب الشرح أعلاه. نوع الوجبة والملاحظات مش بيتبعتوا للتحليل، وبيفضلوا للوجبة اللي تراجعها وتحفظها. تقدر تلغي وتختار الأكل يدوي.'**
  String get cameraConsentDetail;

  /// No description provided for @cameraConsentSend.
  ///
  /// In ar, this message translates to:
  /// **'وافق وابعت المرة دي'**
  String get cameraConsentSend;

  /// No description provided for @recipeCalorieLimit.
  ///
  /// In ar, this message translates to:
  /// **'حد أقصى للسعرات للحصة'**
  String get recipeCalorieLimit;

  /// No description provided for @recipeTimeLimit.
  ///
  /// In ar, this message translates to:
  /// **'وقت الطبخ بحد أقصى'**
  String get recipeTimeLimit;

  /// No description provided for @recipeNoLimit.
  ///
  /// In ar, this message translates to:
  /// **'من غير حد'**
  String get recipeNoLimit;

  /// No description provided for @recipeStrictConstraints.
  ///
  /// In ar, this message translates to:
  /// **'الاقتراح بيحتاج نوع وجبة موثّق، ومع الحدود كمان وقت وسعرات موثّقة. الوصفات اللي بياناتها ناقصة مش هنعتبرها مطابقة. تقدر تتصفحها من غير اقتراح مقيّد.'**
  String get recipeStrictConstraints;

  /// No description provided for @recipeYourVersion.
  ///
  /// In ar, this message translates to:
  /// **'نسختك بالكميات اللي راجعتها'**
  String get recipeYourVersion;

  /// No description provided for @recipeQuantifiedNotice.
  ///
  /// In ar, this message translates to:
  /// **'دي نسخة من اختيارك مش قيم المصدر. طابق كل مكوّن بصنف وحالة التحضير من القاعدة، واكتب جرامات الوصفة كلها والعائد. أي مكوّن مستبعد لازم يكون مش موجود فعلاً. القيم هتتحسب من الجرامات دي بس، ومش هنسجّل حاجة قبل المراجعة.'**
  String get recipeQuantifiedNotice;

  /// No description provided for @recipeExcludeIngredient.
  ///
  /// In ar, this message translates to:
  /// **'مش مستخدم في نسختي'**
  String get recipeExcludeIngredient;

  /// No description provided for @recipeYield.
  ///
  /// In ar, this message translates to:
  /// **'عدد الحصص الناتجة من الوصفة'**
  String get recipeYield;

  /// No description provided for @recipeServingsToLog.
  ///
  /// In ar, this message translates to:
  /// **'الحصص اللي هتسجّلها'**
  String get recipeServingsToLog;

  /// No description provided for @recipeMatchEveryIngredient.
  ///
  /// In ar, this message translates to:
  /// **'راجع كل مكوّن: طابقه وادخل جراماته، أو أكّد إنه مش مستخدم.'**
  String get recipeMatchEveryIngredient;

  /// No description provided for @recipeBuildQuantified.
  ///
  /// In ar, this message translates to:
  /// **'راجع كمياتي وسجّل'**
  String get recipeBuildQuantified;

  /// No description provided for @recipeExcludedCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد المكونات المستبعدة'**
  String get recipeExcludedCount;

  /// No description provided for @foodCategoryAll.
  ///
  /// In ar, this message translates to:
  /// **'كل الأصناف'**
  String get foodCategoryAll;

  /// No description provided for @foodCategoryEgyptian.
  ///
  /// In ar, this message translates to:
  /// **'أساسيات الأكل المصري'**
  String get foodCategoryEgyptian;

  /// No description provided for @foodCategoryGrains.
  ///
  /// In ar, this message translates to:
  /// **'حبوب'**
  String get foodCategoryGrains;

  /// No description provided for @foodCategoryLegumes.
  ///
  /// In ar, this message translates to:
  /// **'بقوليات'**
  String get foodCategoryLegumes;

  /// No description provided for @foodCategoryVegetables.
  ///
  /// In ar, this message translates to:
  /// **'خضار'**
  String get foodCategoryVegetables;

  /// No description provided for @foodCategoryDairy.
  ///
  /// In ar, this message translates to:
  /// **'ألبان'**
  String get foodCategoryDairy;

  /// No description provided for @foodCategoryPoultry.
  ///
  /// In ar, this message translates to:
  /// **'فراخ'**
  String get foodCategoryPoultry;

  /// No description provided for @foodCategoryProducts.
  ///
  /// In ar, this message translates to:
  /// **'منتجات بالباركود'**
  String get foodCategoryProducts;

  /// No description provided for @foodManualTitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف صنف يدوي'**
  String get foodManualTitle;

  /// No description provided for @foodManualNote.
  ///
  /// In ar, this message translates to:
  /// **'اكتب قيم كل ١٠٠ جرام من الملصق أو مصدرك. دي قيم من إدخالك مش موثّقة من سفرة. البيانات الناقصة هتفضل غير معروفة.'**
  String get foodManualNote;

  /// No description provided for @foodManualSource.
  ///
  /// In ar, this message translates to:
  /// **'اسم العبوة'**
  String get foodManualSource;

  /// No description provided for @foodManualRequired.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get foodManualRequired;

  /// No description provided for @foodManualConfirm.
  ///
  /// In ar, this message translates to:
  /// **'راجعت إن القيم لكل ١٠٠ جرام ونقلتها صح'**
  String get foodManualConfirm;

  /// No description provided for @foodManualInvalid.
  ///
  /// In ar, this message translates to:
  /// **'راجع الاسم والمصدر والسعرات والقيم وأكّد المراجعة'**
  String get foodManualInvalid;

  /// No description provided for @registrationPolicyUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل الجديد متوقف لحد ما سياسة الخصوصية والشروط المعتمدة تتضاف. تسجيل الدخول للحسابات الموجودة متاح.'**
  String get registrationPolicyUnavailable;

  /// No description provided for @statsMacroPerformance.
  ///
  /// In ar, this message translates to:
  /// **'متوسط أداء الماكروز'**
  String get statsMacroPerformance;

  /// No description provided for @statsMacroCoverage.
  ///
  /// In ar, this message translates to:
  /// **'{count} من {total} يوم فيه قيمة مسجّلة. متوسط الهدف: {goal} جم'**
  String statsMacroCoverage(String count, String total, String goal);

  /// No description provided for @ownerTerms.
  ///
  /// In ar, this message translates to:
  /// **'شروط الاستخدام'**
  String get ownerTerms;

  /// No description provided for @ownerPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get ownerPrivacy;

  /// No description provided for @cameraCandidateSafetyNote.
  ///
  /// In ar, this message translates to:
  /// **'ده اقتراح من الصورة بس. أكد المكونات ووزن الكمية بنفسك.'**
  String get cameraCandidateSafetyNote;

  /// No description provided for @cameraNutritionSafetyNote.
  ///
  /// In ar, this message translates to:
  /// **'التعرّف من الصورة مش بيقيس الوزن بالجرام ومش بيدي قيم غذائية مؤكدة.'**
  String get cameraNutritionSafetyNote;

  /// No description provided for @homeBrowseMeals.
  ///
  /// In ar, this message translates to:
  /// **'قسّم سفرتك'**
  String get homeBrowseMeals;

  /// No description provided for @homeMealSuggestions.
  ///
  /// In ar, this message translates to:
  /// **'أطباق سفرتك'**
  String get homeMealSuggestions;

  /// No description provided for @homeRecipeNutritionUnknown.
  ///
  /// In ar, this message translates to:
  /// **'التغذية محتاجة كميات المكونات'**
  String get homeRecipeNutritionUnknown;

  /// No description provided for @homeRecipeSourceNote.
  ///
  /// In ar, this message translates to:
  /// **'TheMealDB · كتالوج تعليمي للتطوير'**
  String get homeRecipeSourceNote;

  /// No description provided for @homeRecipeUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات الوصفات مش متاحة في النسخة دي.'**
  String get homeRecipeUnavailable;

  /// No description provided for @homeOpenRecipes.
  ///
  /// In ar, this message translates to:
  /// **'تصفّح الوصفات'**
  String get homeOpenRecipes;

  /// No description provided for @homeFeaturedRecipe.
  ///
  /// In ar, this message translates to:
  /// **'من أطباق سفرة'**
  String get homeFeaturedRecipe;

  /// No description provided for @homeSourceCategoryNote.
  ///
  /// In ar, this message translates to:
  /// **'التقسيم حسب فئات المصدر، مش توصية غذائية.'**
  String get homeSourceCategoryNote;

  /// No description provided for @homeCategoryVegetarian.
  ///
  /// In ar, this message translates to:
  /// **'نباتي · تصنيف المصدر'**
  String get homeCategoryVegetarian;

  /// No description provided for @homeCategoryChicken.
  ///
  /// In ar, this message translates to:
  /// **'فراخ'**
  String get homeCategoryChicken;

  /// No description provided for @homeCategoryBeef.
  ///
  /// In ar, this message translates to:
  /// **'لحوم بقري'**
  String get homeCategoryBeef;

  /// No description provided for @homeCategorySide.
  ///
  /// In ar, this message translates to:
  /// **'أطباق جانبية'**
  String get homeCategorySide;

  /// No description provided for @unitMinutesShort.
  ///
  /// In ar, this message translates to:
  /// **'دقيقة'**
  String get unitMinutesShort;

  /// No description provided for @plannerPortionNote.
  ///
  /// In ar, this message translates to:
  /// **'دي بداية لترتيب وجباتك، مش نظام كامل. عدّل الكميات حسب احتياجك؛ المجموع قد يختلف عن هدفك.'**
  String get plannerPortionNote;

  /// No description provided for @reportLoggedCoverage.
  ///
  /// In ar, this message translates to:
  /// **'المتوسط من الأيام اللي سجلت فيها: {count} من {total}'**
  String reportLoggedCoverage(int count, int total);

  /// No description provided for @reportWaterToday.
  ///
  /// In ar, this message translates to:
  /// **'ميّه النهارده'**
  String get reportWaterToday;

  /// No description provided for @reportNoMeals.
  ///
  /// In ar, this message translates to:
  /// **'مفيش تفاصيل وجبات نعرض توزيعها'**
  String get reportNoMeals;

  /// No description provided for @reportOtherMeals.
  ///
  /// In ar, this message translates to:
  /// **'وجبات تانية'**
  String get reportOtherMeals;

  /// No description provided for @reportRecordedFiber.
  ///
  /// In ar, this message translates to:
  /// **'الألياف المسجّلة'**
  String get reportRecordedFiber;

  /// No description provided for @weightHistoryNeeded.
  ///
  /// In ar, this message translates to:
  /// **'التقدم مش متاح بالبيانات الحالية. محتاج هدف مختلف عن وزن البداية وتسجيلين في وقتين مختلفين. الوزن الواحد مش كفاية عشان نعرف الاتجاه.'**
  String get weightHistoryNeeded;

  /// No description provided for @weightLoadedProgress.
  ///
  /// In ar, this message translates to:
  /// **'التقدم من أقدم وزن ظاهر في السجل الحالي، مش من بداية استخدام التطبيق.'**
  String get weightLoadedProgress;

  /// No description provided for @weightBaselineDetail.
  ///
  /// In ar, this message translates to:
  /// **'بداية السجل الظاهر: {kg} كجم، {date}'**
  String weightBaselineDetail(String kg, String date);

  /// No description provided for @weightCurrentDetail.
  ///
  /// In ar, this message translates to:
  /// **'الوزن الحالي: {kg} كجم'**
  String weightCurrentDetail(String kg);

  /// No description provided for @weightTargetDetail.
  ///
  /// In ar, this message translates to:
  /// **'هدفك المحفوظ: {kg} كجم'**
  String weightTargetDetail(String kg);

  /// No description provided for @weightProgressBaselineLabel.
  ///
  /// In ar, this message translates to:
  /// **'من بداية السجل'**
  String get weightProgressBaselineLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

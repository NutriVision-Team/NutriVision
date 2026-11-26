// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sufra';

  @override
  String get appTagline => 'Your health at your table';

  @override
  String get splashBlessing => 'Bon appétit';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Let\'s start';

  @override
  String onboardingCounter(int current, int total) {
    return '$current / $total';
  }

  @override
  String get onboarding1Title => 'Log your food by voice';

  @override
  String get onboarding1Body =>
      'Say what you ate in your own dialect and we understand in seconds';

  @override
  String get onboarding2Title => 'Numbers you can trust';

  @override
  String get onboarding2Body =>
      'We calculate from the dish\'s ingredients, not guesses';

  @override
  String get onboarding3Title => 'All your Egyptian food';

  @override
  String get onboarding3Body =>
      'Koshari, foul, molokhia, mahshi... all in Sufra';

  @override
  String get loginTitleA => 'Don\'t eat less,';

  @override
  String get loginTitleB => 'eat right';

  @override
  String get loginSubtitle => 'Sign in and continue your healthy journey';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'Sign in';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get googleProvider => 'Google';

  @override
  String get phoneProvider => 'Phone number';

  @override
  String get providerNotConfigured =>
      'This sign-in method is not available right now.';

  @override
  String get phoneComingToast =>
      'We will send a verification code to your phone';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get createAccountLink => 'Create a new account';

  @override
  String get resetEmailSent => 'We sent a password reset link to your email';

  @override
  String get registerTitleA => 'Start your sufra,';

  @override
  String get registerTitleB => 'eat for real';

  @override
  String get nameHint => 'Name';

  @override
  String get passwordRegisterHint => 'Password (at least 8 characters)';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthMedium => 'Medium';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get interestHealthyFasting => 'Healthy fasting';

  @override
  String get interestWeightLoss => 'Weight loss';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get agreeTermsPrefix => 'I agree to the ';

  @override
  String get agreeTermsLink => 'Terms & Privacy';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get haveAccount => 'Have an account?';

  @override
  String get signInLink => 'Sign in';

  @override
  String welcomeTitle(String name) {
    return 'Welcome, $name';
  }

  @override
  String get welcomeSubtitle =>
      'Your account is ready and your sufra is set. Bon appétit';

  @override
  String get welcomePoint1 => 'Log your food by voice in your dialect';

  @override
  String get welcomePoint2 => 'Numbers from the dish\'s real ingredients';

  @override
  String get welcomePoint3 => 'Koshari, foul, molokhia and more';

  @override
  String get welcomeCta => 'Let\'s start';

  @override
  String wizardStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get wizardBack => 'Back';

  @override
  String get wizardNext => 'Next';

  @override
  String get wizardFinish => 'Calculate my plan';

  @override
  String get wizardGenderTitle => 'Introduce yourself';

  @override
  String get wizardGenderBody =>
      'This information helps us calculate your needs accurately';

  @override
  String get wizardGenderMale => 'Male';

  @override
  String get wizardGenderFemale => 'Female';

  @override
  String get wizardDobTitle => 'Your date of birth';

  @override
  String get wizardDobBody => 'Your age affects your basal metabolic rate';

  @override
  String get wizardHeightTitle => 'How tall are you?';

  @override
  String get wizardHeightBody => 'In centimeters';

  @override
  String get wizardWeightTitle => 'Your current weight';

  @override
  String get wizardWeightBody => 'In kilograms';

  @override
  String get wizardTargetTitle => 'Your target weight';

  @override
  String get wizardTargetBody => 'A realistic goal beats an impossible one';

  @override
  String get wizardActivityTitle => 'Your daily activity level';

  @override
  String get wizardActivityBody => 'Pick the closest to your routine';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activitySedentaryBody => 'Desk job and little movement';

  @override
  String get activityLight => 'Light';

  @override
  String get activityLightBody => 'Walking or light exercise 1-3 days';

  @override
  String get activityModerate => 'Moderate';

  @override
  String get activityModerateBody => 'Exercise 3-5 days a week';

  @override
  String get activityActive => 'Very active';

  @override
  String get activityActiveBody => 'Hard exercise 6-7 days';

  @override
  String get wizardGoalTitle => 'What is your goal?';

  @override
  String get wizardGoalBody =>
      'Choose, and Sufra will tailor everything to you';

  @override
  String get goalLose => 'Lose weight';

  @override
  String get goalLoseBody => 'Fewer calories and filling food';

  @override
  String get goalMaintain => 'Maintain weight';

  @override
  String get goalMaintainBody => 'Balance that keeps your weight';

  @override
  String get goalGain => 'Gain weight';

  @override
  String get goalGainBody => 'More calories and more protein';

  @override
  String get unitCm => 'cm';

  @override
  String get unitKg => 'kg';

  @override
  String get planTitleUnnamed => 'Your plan is ready!';

  @override
  String get welcomeTitleUnnamed => 'Welcome';

  @override
  String planTitle(String name) {
    return 'Your plan is ready, $name!';
  }

  @override
  String get planDailyCalories => 'Your daily calories';

  @override
  String get planProtein => 'Protein · g';

  @override
  String get planCarbs => 'Carbs · g';

  @override
  String get planFat => 'Fat · g';

  @override
  String planTimeline(int weeks) {
    return 'A rough estimate is around $weeks weeks. Your actual progress may take a different time.';
  }

  @override
  String get planTimelineMaintain =>
      'Your goal is to maintain your current weight';

  @override
  String get planDisclaimer => 'Indicative numbers for awareness';

  @override
  String get planCta => 'Start my journey';

  @override
  String get homeGreetingMorning => 'Good morning,';

  @override
  String get homeGreetingEvening => 'Good evening,';

  @override
  String get homeSearchHint => 'Search for a dish or product…';

  @override
  String get homeHeroChip => 'Sufra · smarter choices';

  @override
  String get homeHeroTitleA => 'Food you love,';

  @override
  String get homeHeroTitleB => 'balance that fits you';

  @override
  String get homeHeroBody =>
      'Organize your meals and health without deprivation.';

  @override
  String get homeHeroCta => 'Plan your meals';

  @override
  String get homeEatenToday => 'What you ate today';

  @override
  String get unitKcal => 'kcal';

  @override
  String homeGoalRemaining(int target, int remaining) {
    return 'Goal $target · $remaining left';
  }

  @override
  String get homeNoGoalYet =>
      'Finish your personal setup so we can calculate your goal';

  @override
  String get homeStreakDays => 'Days in a row';

  @override
  String get homeStreakCta => 'Keep going, champ';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroFat => 'Fat';

  @override
  String get homeMealsToday => 'Today\'s meals';

  @override
  String get homeNoMeals => 'You have not logged any meals today';

  @override
  String get homeAddFirstMeal => 'Log your first meal';

  @override
  String get homeTipsTitle => 'Sufra tips';

  @override
  String get tipWaterTitle => 'Drink a glass of water';

  @override
  String tipWaterBody(int count, int goal) {
    return '$count of $goal cups';
  }

  @override
  String get tipProteinTitle => 'Review your daily protein';

  @override
  String get tipProteinBody =>
      'Review your remaining target and choose a portion that works for you';

  @override
  String get tipLogTitle => 'Log your food as you go';

  @override
  String get tipLogBody => 'Consistent logging is the secret to results';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnack => 'Snack';

  @override
  String get navHome => 'Home';

  @override
  String get navDiary => 'Diary';

  @override
  String get navProgress => 'Progress';

  @override
  String get navAccount => 'Account';

  @override
  String get comingSoonTitle => 'Coming soon to Sufra';

  @override
  String get comingSoonBody => 'This feature is not available yet.';

  @override
  String get stateLoading => 'Loading…';

  @override
  String get stateError => 'Something went wrong while loading. Try again';

  @override
  String get stateRetry => 'Try again';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationEmail => 'Enter a valid email';

  @override
  String get validationPassword => 'Password must be at least 8 characters';

  @override
  String get validationName => 'Enter your name';

  @override
  String get validationTerms => 'You must accept the Terms & Privacy';

  @override
  String get validationNumber => 'Enter a valid number';

  @override
  String get validationStep => 'Complete this step first';

  @override
  String get authInvalidCredentials => 'Wrong email or password';

  @override
  String get authEmailInUse =>
      'This email is already registered. Try signing in';

  @override
  String get authWeakPassword => 'Weak password. Use at least 8 characters';

  @override
  String get authUserNotFound => 'No account exists with this email';

  @override
  String get authNetworkError =>
      'No internet connection. Check your network and try again';

  @override
  String get authGenericError => 'Something went wrong. Try again in a moment';

  @override
  String get signOut => 'Sign out';

  @override
  String get logHubTitle => 'How will you log your food?';

  @override
  String get logHubSubtitle =>
      'Pick the easiest way - each one is a single tap';

  @override
  String get logHubChipPhoto => 'Photo';

  @override
  String get logHubChipBarcode => 'Barcode';

  @override
  String get logHubChipVoice => 'Voice';

  @override
  String get logHubChipSearch => 'Search';

  @override
  String get logHubVoiceTitle => 'By voice or text';

  @override
  String get logHubVoiceSubtitle => 'Describe food, then check foods and grams';

  @override
  String get logHubFastest => 'Fastest';

  @override
  String get logHubPhotoTitle => 'Snap your meal';

  @override
  String get logHubPhotoSubtitle => 'Capture and review manually';

  @override
  String get logHubBarcodeTitle => 'Scan a barcode';

  @override
  String get logHubBarcodeSubtitle => 'Packaged product';

  @override
  String get logHubSearchTitle => 'Search manually';

  @override
  String get logHubSearchSubtitle => 'Browse the food catalog';

  @override
  String get logHubFavoritesTitle => 'From favorites';

  @override
  String get logHubFavoritesSubtitle => 'One tap';

  @override
  String get logHubRecentTitle => 'Your recent meals';

  @override
  String logHubRecentMeal(String name, int calories) {
    return '$name · $calories kcal';
  }

  @override
  String get logHubRelog => 'Log again';

  @override
  String get logHubRelogDone => 'Meal added to your day';

  @override
  String get foodSearchHint => 'Search for a food...';

  @override
  String get foodCatalogTitle => 'Find food';

  @override
  String get foodSearchStart => 'Type a food name to search';

  @override
  String get foodSearchEmpty => 'No results. Try another name';

  @override
  String foodPer100g(String value) {
    return '100 g · $value kcal';
  }

  @override
  String get foodNutritionUnknown => 'Nutrition not available';

  @override
  String get foodGrams => 'Portion in grams';

  @override
  String get foodInvalidGrams => 'Enter a portion above 0 and up to 10,000 g';

  @override
  String get foodUnknown => 'Unknown';

  @override
  String get foodKcal => 'kcal';

  @override
  String get foodMg => 'mg';

  @override
  String get foodGramUnit => 'g';

  @override
  String foodSource(String source) {
    return 'Data source: $source';
  }

  @override
  String get foodIncompleteWarning =>
      'Nutrition or source data is missing. Unknown values will not be saved as zero.';

  @override
  String get foodCalories => 'Calories';

  @override
  String get foodProtein => 'Protein';

  @override
  String get foodCarbs => 'Carbohydrates';

  @override
  String get foodFat => 'Fat';

  @override
  String get foodFiber => 'Fiber';

  @override
  String get foodSugar => 'Sugar';

  @override
  String get foodSodium => 'Sodium';

  @override
  String get mealReviewTitle => 'Review your meal';

  @override
  String get mealReviewTotal => 'Total from source data';

  @override
  String get mealTypeLabel => 'Meal type';

  @override
  String get mealSessionExpired =>
      'Your session changed. Go back and sign in again';

  @override
  String get mealSave => 'Save your meal';

  @override
  String get diaryTitle => 'Diary';

  @override
  String get diaryEmpty => 'No meals logged on this day';

  @override
  String get diaryPrevious => 'Previous day';

  @override
  String get diaryNext => 'Next day';

  @override
  String get artRotateHint => 'Drag to rotate';

  @override
  String get diaryChooseDate => 'Choose date';

  @override
  String get diaryEmptySlot => 'Not logged yet';

  @override
  String get diaryAddMeal => '+ Add a meal';

  @override
  String get diaryOtherMeals => 'Other meals';

  @override
  String get foodRecipes => 'Recipes';

  @override
  String get foodAlternatives => 'Alternatives';

  @override
  String get mealEdit => 'Edit';

  @override
  String get mealDelete => 'Delete';

  @override
  String get mealDeleteConfirm =>
      'Delete this logged meal? Your daily totals will be updated.';

  @override
  String get mealName => 'Meal name';

  @override
  String get mealNotes => 'Notes';

  @override
  String get mealEditInvalid => 'Check the meal name and ingredient amounts.';

  @override
  String get mealNotFound =>
      'This meal is no longer available for this account and date.';

  @override
  String get actionSave => 'Save changes';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get mealSuhoor => 'Suhoor';

  @override
  String get mealIftar => 'Iftar';

  @override
  String get discoveryMsg001 => 'Save failed. Please retry.';

  @override
  String get discoveryMsg002 => 'Recipe blocked pending release licensing.';

  @override
  String get discoveryMsg003 => 'Recipe not found.';

  @override
  String get discoveryMsg004 => 'Back';

  @override
  String get discoveryMsg005 => 'Time not set';

  @override
  String get discoveryMsg006 => 'Calories unknown';

  @override
  String get discoveryMsg007 => 'Servings unknown';

  @override
  String get discoveryMsg008 =>
      'Measures and steps are preserved as published, without estimated gram conversions.';

  @override
  String get discoveryMsg009 =>
      'Accurate nutrition logging needs verified ingredient weights and servings.';

  @override
  String get discoveryMsg010 => 'Source and license';

  @override
  String get discoveryMsg011 => 'Source and license · development only';

  @override
  String get discoveryMsg012 =>
      'Ingredient weights, servings and nutrients are unverified';

  @override
  String get discoveryMsg013 => 'Log as a meal';

  @override
  String get discoveryMsg014 => 'Suggestion failed';

  @override
  String get discoveryMsg015 => 'We could not load recipes. Try again.';

  @override
  String get discoveryMsg016 => 'Add your ingredients';

  @override
  String get discoveryMsg017 =>
      'Add at least one ingredient to match against the published recipe ingredients.';

  @override
  String get discoveryMsg018 =>
      'These recipes are not available in this version yet.';

  @override
  String get discoveryMsg019 => 'Suggest a meal';

  @override
  String get discoveryMsg020 => 'I have';

  @override
  String get discoveryMsg021 => '+ Add';

  @override
  String get discoveryMsg022 => 'Calories';

  @override
  String get discoveryMsg023 => 'Time';

  @override
  String get discoveryMsg024 => 'Not set';

  @override
  String get discoveryMsg025 =>
      'Recipe calories and most times are unavailable. Time filters accept only recipes with a sourced total time.';

  @override
  String get discoveryMsg026 => 'Suggest';

  @override
  String get discoveryMsg027 => 'Local ingredient matching';

  @override
  String get discoveryMsg028 => 'About suggestions';

  @override
  String get discoveryMsg029 => 'Source and matching';

  @override
  String get discoveryMsg030 =>
      'Literal ingredient matching. Meal type is a preference, not a source classification. Review missing ingredients and allergies. TheMealDB is development/education only. Optional AI is unavailable unless a verified service is configured.';

  @override
  String get discoveryMsg031 => 'Suggest for me';

  @override
  String get discoveryMsg032 => 'Show all recipes';

  @override
  String get discoveryMsg033 => 'Search local recipes';

  @override
  String get discoveryMsg034 => 'Clear';

  @override
  String get discoveryMsg035 => 'Saved only';

  @override
  String get discoveryMsg036 => 'TheMealDB · development and education only';

  @override
  String get discoveryMsg037 => 'No matching recipes.';

  @override
  String get discoveryMsg038 => 'Calories unknown';

  @override
  String get discoveryMsg039 => 'Add an ingredient';

  @override
  String get discoveryMsg040 => 'Ingredient name';

  @override
  String get discoveryMsg041 => 'Cancel';

  @override
  String get discoveryMsg042 => 'Add';

  @override
  String get discoveryMsg043 => 'Home';

  @override
  String get discoveryMsg044 => 'Diary';

  @override
  String get discoveryMsg045 => 'Progress';

  @override
  String get discoveryMsg046 => 'Account';

  @override
  String get discoveryMsg047 => 'Could not load the data. Try again.';

  @override
  String get discoveryMsg048 => 'Retry';

  @override
  String get discoveryMsg049 => 'OK';

  @override
  String get discoveryMsg050 => 'Current progress';

  @override
  String get discoveryMsg051 => 'Target';

  @override
  String get discoveryMsg052 => 'Alternatives for what?';

  @override
  String get discoveryMsg053 => 'Search the original food';

  @override
  String get discoveryMsg054 =>
      'No verified comparison for this food in the current catalog. Try milk, rice or bread.';

  @override
  String get discoveryMsg055 => 'Alternatives from sourced data';

  @override
  String get discoveryMsg056 =>
      'Per 100 g comparisons from recorded food data, not medical advice.';

  @override
  String get discoveryMsg057 => 'Packaged products';

  @override
  String get discoveryMsg058 =>
      'No verified packaged products in the local catalog.';

  @override
  String get discoveryMsg059 =>
      'Product search is not connected yet. No sample prices or nutrition grades are shown.';

  @override
  String get discoveryMsg060 => 'Energy per 100 g';

  @override
  String get discoveryMsg061 => 'USDA · source and comparison details';

  @override
  String get discoveryMsg062 => 'Comparison per 100 g';

  @override
  String get discoveryMsg063 => 'Original';

  @override
  String get discoveryMsg064 => 'Alternative';

  @override
  String get discoveryMsg065 =>
      'Food state and preparation matter. Portions are not automatically equivalent.';

  @override
  String get discoveryMsg066 => 'Energy (kcal)';

  @override
  String get discoveryMsg067 => 'Fiber (g)';

  @override
  String get discoveryMsg068 => 'Fat (g)';

  @override
  String get discoveryMsg069 => 'Protein (g)';

  @override
  String get discoveryMsg070 => 'Days in a row';

  @override
  String get discoveryMsg071 => 'Logged';

  @override
  String get discoveryMsg072 => 'Not logged';

  @override
  String get discoveryMsg073 => 'Golden lantern';

  @override
  String get discoveryMsg074 => 'days';

  @override
  String get discoveryMsg075 => 'Your badges';

  @override
  String get discoveryMsg076 =>
      'Each log brings you closer to a new badge. Set a water goal to track your progress.';

  @override
  String get discoveryMsg077 => 'Earned';

  @override
  String get discoveryMsg078 => 'Not yet known';

  @override
  String get discoveryMsg079 => 'More logs are needed to show your progress.';

  @override
  String get discoveryMsg080 =>
      'The time this badge was first recorded is unknown.';

  @override
  String get discoveryMsg081 =>
      'First recorded by Sufra, not necessarily when earned';

  @override
  String get discoveryMsg082 => 'Achievement lantern';

  @override
  String get discoveryCloudFavoritesNote => 'Favorites sync with your account.';

  @override
  String get discoveryLocalFavoritesNote =>
      'Favorites are saved on this device for your current account.';

  @override
  String get discoverySaved => 'Saved';

  @override
  String get discoverySave => 'Save';

  @override
  String get discoveryBreakfast => 'Breakfast';

  @override
  String get discoveryLunch => 'Lunch';

  @override
  String get discoveryDinner => 'Dinner';

  @override
  String get discoveryWeekday1 => 'M';

  @override
  String get discoveryWeekday2 => 'T';

  @override
  String get discoveryWeekday3 => 'W';

  @override
  String get discoveryWeekday4 => 'T';

  @override
  String get discoveryWeekday5 => 'F';

  @override
  String get discoveryWeekday6 => 'S';

  @override
  String get discoveryWeekday7 => 'S';

  @override
  String get mealIngredientAdd => 'Add ingredient';

  @override
  String get mealIngredientEdit => 'Change ingredient';

  @override
  String get mealIngredientRemove => 'Remove ingredient';

  @override
  String get mealDraftIncomplete =>
      'Choose an ingredient with measured calories and a source, then check quantities and meal name.';

  @override
  String get mealReviewCatalogHint =>
      'Review ingredients and quantities before saving.';

  @override
  String get progressNavHome => 'Home';

  @override
  String get progressNavDiary => 'Diary';

  @override
  String get progressNavProgress => 'Progress';

  @override
  String get progressNavAccount => 'Account';

  @override
  String get statsTitle => 'My progress';

  @override
  String get statsTabWeek => 'Week';

  @override
  String get statsTabMonth => 'Month';

  @override
  String statsStreakDays(Object count) {
    return '$count days in a row';
  }

  @override
  String get statsStreakCheer => 'Keep it up!';

  @override
  String get statsCaloriesTitle => 'Calories';

  @override
  String statsCaloriesAverage(Object avg, Object target) {
    return 'Average $avg / $target';
  }

  @override
  String get statsWeightTitle => 'Weight';

  @override
  String statsWeightDown(Object kg) {
    return '▼ $kg kg';
  }

  @override
  String statsWeightUp(Object kg) {
    return '▲ $kg kg';
  }

  @override
  String get statsBadgesTitle => 'Badges';

  @override
  String get statsNoTrackedDays => 'No tracked days in this period yet';

  @override
  String get statsNoWeightData => 'Log your weight to see progress';

  @override
  String get reportTitle => 'Report';

  @override
  String get reportSubtitle => 'Your week at a glance';

  @override
  String get reportAverageCalories => 'Average calories';

  @override
  String reportRingCalories(Object pct) {
    return 'Calories: $pct% of target';
  }

  @override
  String reportRingProtein(Object pct) {
    return 'Protein: $pct% of target';
  }

  @override
  String reportRingFiber(Object pct) {
    return 'Fiber $pct%';
  }

  @override
  String get reportDailyCommitment => 'Days with food logged';

  @override
  String get reportWaterTitle => 'Water';

  @override
  String reportWaterCupsOf(Object goal, Object have) {
    return '$have of $goal cups';
  }

  @override
  String get reportMealDistribution => 'Meals logged';

  @override
  String reportSugarAlertTitle(Object day) {
    return 'Watch: $day sugar';
  }

  @override
  String reportSugarAlertBody(Object pct) {
    return 'Up $pct% vs usual, likely dessert after lunch';
  }

  @override
  String get waterScreenTitle => 'Today\'s water';

  @override
  String waterCupsOf(Object goal, Object have) {
    return '$have of $goal cups';
  }

  @override
  String waterMlOf(Object goal, Object have) {
    return '$have of $goal ml';
  }

  @override
  String get waterAdd250 => '+ 250 ml';

  @override
  String get waterAdd500 => '+ 500 ml';

  @override
  String get waterAddCustom => 'Custom';

  @override
  String get waterAddConfirm => 'Add';

  @override
  String waterMlValue(Object value) {
    return '$value ml';
  }

  @override
  String get weightScreenTitle => 'Your weight';

  @override
  String get weightSubtitle => 'Your journey counts, every small step';

  @override
  String get weightCurrent => 'Current weight';

  @override
  String get weightKg => 'kg';

  @override
  String get weightOfYourGoal => 'of your goal';

  @override
  String weightLighterBy(Object kg) {
    return '▼ $kg kg lighter';
  }

  @override
  String weightHeavierBy(Object kg) {
    return '▲ $kg kg heavier';
  }

  @override
  String get weightYouAreHere => 'You are here';

  @override
  String weightGoalLabel(Object kg) {
    return 'Goal $kg';
  }

  @override
  String get weightGreatWork => 'Great work, champ!';

  @override
  String weightToNextMilestone(Object kg) {
    return '$kg kg from your target. Daily weight can vary, so follow the trend over time.';
  }

  @override
  String get weightLogCta => '+ Log today\'s weight';

  @override
  String get weightLogTitle => 'Log your weight';

  @override
  String get weightLogHint => 'Weight in kg';

  @override
  String get weightLogSave => 'Save';

  @override
  String get weightLogInvalid => 'Enter a valid weight above zero';

  @override
  String get exportTitle => 'Sufra · Nutrition report';

  @override
  String get exportSubtitle => 'Your selected date range';

  @override
  String get exportPdfBadge => 'PDF';

  @override
  String get exportAdherenceLabel => 'Adherence';

  @override
  String get exportMacrosTitle => 'Macros: recorded vs saved targets';

  @override
  String get exportMacrosHint => '(black tick = target)';

  @override
  String get exportProteinLabel => 'Protein';

  @override
  String get exportCarbsLabel => 'Carbs';

  @override
  String get exportFatLabel => 'Fat';

  @override
  String get exportAdherenceMapTitle => 'Adherence map (2 weeks)';

  @override
  String get exportReviewPointsTitle => 'Points to review';

  @override
  String get exportReviewSodium =>
      'Recorded sodium was above your period average for 3 days in a row';

  @override
  String exportReviewFiber(Object pct) {
    return 'Fiber below recommendation ($pct%)';
  }

  @override
  String get exportReviewWaterOk =>
      'Latest day\'s water reached your saved goal';

  @override
  String get exportPdfButton => 'Export PDF';

  @override
  String get exportSendToDoctor => 'Send to doctor';

  @override
  String exportGoalLoss(Object kg) {
    return 'Goal: lose $kg kg';
  }

  @override
  String exportBmiLabel(Object bmi) {
    return 'BMI $bmi';
  }

  @override
  String exportYearsOld(Object age) {
    return '$age years';
  }

  @override
  String exportCmLabel(Object height) {
    return '$height cm';
  }

  @override
  String get waterGoalDefaultNote =>
      'Indicative default goal, not personalized';

  @override
  String get statsBadgesUnknown => 'Badge status not loaded yet';

  @override
  String get weekdayLetter1 => 'Sa';

  @override
  String get weekdayLetter2 => 'Su';

  @override
  String get weekdayLetter3 => 'Mo';

  @override
  String get weekdayLetter4 => 'Tu';

  @override
  String get weekdayLetter5 => 'We';

  @override
  String get weekdayLetter6 => 'Th';

  @override
  String get weekdayLetter7 => 'Fr';

  @override
  String get weekdayName1 => 'Saturday';

  @override
  String get weekdayName2 => 'Sunday';

  @override
  String get weekdayName3 => 'Monday';

  @override
  String get weekdayName4 => 'Tuesday';

  @override
  String get weekdayName5 => 'Wednesday';

  @override
  String get weekdayName6 => 'Thursday';

  @override
  String get weekdayName7 => 'Friday';

  @override
  String get cameraTitle => 'Photograph your meal';

  @override
  String get cameraClose => 'Close';

  @override
  String get cameraFlash => 'Flash';

  @override
  String get cameraFlashUnavailable => 'Flash is not available on this camera';

  @override
  String get cameraDenied =>
      'Camera permission is needed. Retry or enter your meal manually.';

  @override
  String get cameraRestricted =>
      'Allow camera access in device settings, or enter your meal manually.';

  @override
  String get cameraMissing => 'No camera is available on this device';

  @override
  String get cameraFailed =>
      'The camera is not ready. Retry or enter manually.';

  @override
  String get cameraPaused => 'Camera paused';

  @override
  String get cameraStarting => 'Starting the camera';

  @override
  String get cameraRetry => 'Retry';

  @override
  String get cameraTooLarge => 'The image is too large. Use a smaller image.';

  @override
  String get cameraBadImage =>
      'This image could not be read. Try another image.';

  @override
  String get cameraAiUnavailable =>
      'Image recognition is not available. Choose catalog foods and check their portions yourself.';

  @override
  String get cameraEmpty =>
      'No clear food was found. Retake or choose from the catalog.';

  @override
  String get cameraInvalidResponse =>
      'The recognition response was invalid. Retry or choose from the catalog.';

  @override
  String get cameraNetwork =>
      'Recognition could not be completed. Retry or choose from the catalog.';

  @override
  String get cameraFrameHint => 'Keep the whole plate inside the frame';

  @override
  String get cameraLightHint => 'Good light · Keep steady · Whole plate';

  @override
  String get cameraCapture => 'Capture photo';

  @override
  String get cameraRetake => 'Retake photo';

  @override
  String get cameraMealType => 'Meal type';

  @override
  String get cameraNotes => 'Notes to help recognition (optional)';

  @override
  String get cameraNotesHint =>
      'Describe preparation or other important details';

  @override
  String get cameraNoOil => 'No oil';

  @override
  String get cameraLarge => 'Large portion';

  @override
  String get cameraSmall => 'Small portion';

  @override
  String get cameraSugar => 'Extra sugar';

  @override
  String get cameraGhee => 'Fried in ghee';

  @override
  String get cameraPrivacy =>
      'The image is sent only after permission for each request. Meal type and notes are not sent for analysis. Review foods and quantities before saving.';

  @override
  String get cameraNoUpload =>
      'Image recognition is not enabled. The photo stays temporarily on your device and is not uploaded.';

  @override
  String get cameraAnalyzing => 'Recognizing your meal';

  @override
  String get cameraAnalyze => 'Analyze photo';

  @override
  String get cameraReviewWarning =>
      'These are suggestions, not measurements. Confirm catalog foods and portions before saving.';

  @override
  String get cameraManual => 'Choose food from the catalog';

  @override
  String get cameraSkip => 'Exclude suggestion';

  @override
  String get cameraSkipped => 'Excluded';

  @override
  String get exportKgUnit => 'kg';

  @override
  String get progressUnknownNote =>
      'A dash (—) means the data or target at the time of logging is unavailable, not zero.';

  @override
  String get reportUnknownCalories => 'Calories: unavailable';

  @override
  String get reportUnknownProtein => 'Protein: unavailable';

  @override
  String get reportUnknownFiber => 'Fiber: unavailable';

  @override
  String get voiceListening => 'Listening… describe your meal';

  @override
  String get voiceStarting => 'Starting the microphone';

  @override
  String get voiceReady => 'Tap the microphone or type your meal description';

  @override
  String get voiceDenied =>
      'Microphone access is unavailable. Check device settings or type your description.';

  @override
  String get voiceUnavailable =>
      'Speech recognition is not available on this device. You can type instead.';

  @override
  String get voiceLanguageUnavailable =>
      'This device does not offer speech recognition in the app language. Type instead.';

  @override
  String get voiceNoSpeech =>
      'No clear speech was heard. Retry or type instead.';

  @override
  String get voiceFailed =>
      'Speech recognition did not complete. Retry or type instead.';

  @override
  String get voiceStop => 'Stop listening';

  @override
  String get voiceStart => 'Start dictation';

  @override
  String get voicePrivacy =>
      'The microphone starts only when you tap. Your device speech service may send audio to its provider. Sufra does not save an audio recording.';

  @override
  String get voiceTextHint => 'Example: beans, bread and cucumber';

  @override
  String get voiceDescription => 'Meal description, editable';

  @override
  String get voiceFindFoods => 'Find catalog foods';

  @override
  String get voicePortionWarning =>
      'Search suggests catalog foods, not weights from speech. Select the foods and check grams before saving.';

  @override
  String get voiceNoFoods =>
      'No matching foods were found. Search by food name or choose from the catalog.';

  @override
  String get waterWeekRecordedTitle => 'Recorded water over the last 7 days';

  @override
  String get barcodeTitle => 'Scan a barcode';

  @override
  String get barcodeClose => 'Close';

  @override
  String get barcodeFlash => 'Flash';

  @override
  String get barcodeFlashUnavailable => 'Flash is not available on this device';

  @override
  String get barcodeStartCamera => 'Start camera';

  @override
  String get barcodeAim => 'Point the camera at the barcode';

  @override
  String get barcodeSearching => 'Looking for a barcode…';

  @override
  String get barcodeManualLabel => 'Or type the number under the barcode';

  @override
  String get barcodeManualField => 'Barcode number';

  @override
  String get barcodeLookup => 'Look up';

  @override
  String get barcodePhotoFallback => 'Photograph the nutrition label';

  @override
  String get barcodeSearchFallback => 'Search foods';

  @override
  String get barcodeCameraDenied =>
      'Camera access is off for this app. Type the number below, or enable camera permission in device settings.';

  @override
  String get barcodeCameraUnsupported =>
      'No usable camera on this device. Type the number below.';

  @override
  String get barcodeCameraError =>
      'The camera is not working right now. Type the number below or try again.';

  @override
  String get barcodeRetryCamera => 'Try the camera again';

  @override
  String barcodeLooking(String code) {
    return 'Looking up $code';
  }

  @override
  String get barcodeInvalid =>
      'Invalid number. It must be 8, 12, 13 or 14 digits with a correct check digit.';

  @override
  String barcodeNotFound(String code) {
    return 'Product $code was not found. Check the number or search by name.';
  }

  @override
  String get barcodeNotFoundHelp =>
      'You can search by name or photograph the label. We never make up numbers.';

  @override
  String get barcodeRetry => 'Try again';

  @override
  String get barcodeOffline =>
      'No internet, or the connection is too slow. Check it and try again, or log the food manually.';

  @override
  String barcodeRateLimited(int seconds) {
    return 'Too many lookups in a short time. Try again in $seconds seconds.';
  }

  @override
  String get barcodeUnavailable =>
      'Open Food Facts is not available right now. Try again later.';

  @override
  String get barcodeBadResponse =>
      'The source sent a response we could not read. Try again later.';

  @override
  String get barcodeNotConfigured =>
      'Barcode lookup is not enabled in this build yet.';

  @override
  String get productTitle => 'Product details';

  @override
  String get productBack => 'Back';

  @override
  String get productNoImage => 'The source has no product image';

  @override
  String get productNutritionPer100g => 'Nutrition per 100 g';

  @override
  String get productNutritionPer100ml => 'Nutrition per 100 ml';

  @override
  String get productNotProvided => 'Not provided';

  @override
  String get productCalories => 'Calories';

  @override
  String get productProtein => 'Protein';

  @override
  String get productCarbs => 'Carbohydrates';

  @override
  String get productFat => 'Fat';

  @override
  String get productFiber => 'Fiber';

  @override
  String get productSugars => 'Sugars';

  @override
  String get productSodium => 'Sodium';

  @override
  String get productKcalUnit => 'kcal';

  @override
  String get productGramUnit => 'g';

  @override
  String get productMgUnit => 'mg';

  @override
  String productServing(String serving) {
    return 'Listed serving: $serving';
  }

  @override
  String productQuantity(String quantity) {
    return 'Package size: $quantity';
  }

  @override
  String get productIngredients => 'Ingredients (as listed by the source)';

  @override
  String get productAllergens => 'Allergens listed by the source';

  @override
  String get productAllergensNone =>
      'The source lists no allergens. That does not mean the product is free of them.';

  @override
  String get productAllergensUnknown =>
      'The source has no allergen data. Read the package.';

  @override
  String get productAllergensCaveat =>
      'Data is contributed by users and may be incomplete. If you have an allergy, always read the package.';

  @override
  String get productNutriScore => 'Nutri-Score';

  @override
  String get productNutriScoreFromSource => 'As given by the source';

  @override
  String get productAttribution =>
      'Source: Open Food Facts. Data is contributed by users, licensed under ODbL, and may be incomplete or out of date.';

  @override
  String get productFromCache => 'Copy saved on this device';

  @override
  String get productPortionLabel => 'Amount in grams';

  @override
  String productUseServing(String grams) {
    return 'Serving $grams g';
  }

  @override
  String get productAddToDiary => 'Add to diary';

  @override
  String get productGramsInvalid =>
      'Enter an amount in grams above 0 and up to 10000.';

  @override
  String get productCannotLogMl =>
      'These values are per 100 ml. We do not convert to grams because the product density is unknown, so logging by grams is unavailable.';

  @override
  String get productCannotLogNoEnergy =>
      'The source gives no calories, so this product cannot be logged.';

  @override
  String get productNutritionBasisUnknown =>
      'Source values, basis unit unconfirmed';

  @override
  String get productCannotLogUnknownBasis =>
      'The source basis is missing or conflicting. We will not convert these values to grams. Check the label or choose a catalog food.';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesTabMeals => 'Favorite meals';

  @override
  String get favoritesTabRecipes => 'Saved recipes';

  @override
  String get favoritesTabFrequent => 'Most logged';

  @override
  String get favoritesHeroChip => 'Most logged';

  @override
  String favoritesHeroCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Logged $count times in the last 30 days',
      one: 'Logged once in the last 30 days',
    );
    return '$_temp0';
  }

  @override
  String get favoritesSortLabel => 'Sort';

  @override
  String get favoritesSortRecent => 'Newest';

  @override
  String get favoritesSortName => 'Name';

  @override
  String get favoritesSortCalories => 'Calories';

  @override
  String get favoritesRemove => 'Remove from favorites';

  @override
  String get favoritesRemoved => 'Removed from favorites';

  @override
  String get favoritesRemoveFailed => 'Could not remove it. Try again.';

  @override
  String get favoritesAddToDiary => 'Add to diary';

  @override
  String get favoritesAdded => 'Added to your diary';

  @override
  String get favoritesAddFailed => 'Could not add it. Try again.';

  @override
  String get favoritesSaved => 'Saved to favorites';

  @override
  String get favoritesSaveFailed =>
      'Could not save it to favorites. Try again.';

  @override
  String get favoritesPickMealType => 'Add it as';

  @override
  String get favoritesUnavailable => 'The original meal was deleted';

  @override
  String get favoritesUnavailableHint =>
      'You can only remove it from favorites.';

  @override
  String favoritesMealMeta(String kcal) {
    return '$kcal kcal';
  }

  @override
  String favoritesMealMetaProtein(String kcal, String protein) {
    return '$kcal kcal · $protein g protein';
  }

  @override
  String favoritesFrequentCount(int count) {
    return 'Logged $count times';
  }

  @override
  String get favoritesFrequentNote =>
      'From your logged meals in the last 30 days.';

  @override
  String get favoritesEmptyMealsTitle => 'No favorite meals yet';

  @override
  String get favoritesEmptyMealsBody =>
      'Open a logged meal and tap the heart to find it here.';

  @override
  String get favoritesEmptyRecipesTitle => 'No saved recipes yet';

  @override
  String get favoritesEmptyRecipesBody =>
      'Save a recipe from the recipe suggestions and it will show up here.';

  @override
  String get favoritesEmptyFrequentTitle => 'No frequent foods yet';

  @override
  String get favoritesEmptyFrequentBody =>
      'Once you log foods a few times, the most repeated ones appear here.';

  @override
  String get favoritesLoadFailed => 'Could not load favorites.';

  @override
  String get favoritesRetry => 'Try again';

  @override
  String get favoritesExpired => 'Your session ended. Sign in again.';

  @override
  String get premiumTitle => 'Sufra Premium';

  @override
  String get premiumSubtitle => 'Extra features coming soon';

  @override
  String get premiumComingSoonChip => 'Coming soon';

  @override
  String get premiumFeatureCoachTitle => 'Smart coach';

  @override
  String get premiumFeatureCoachBody => 'Tips based on what you eat';

  @override
  String get premiumFeatureReportsTitle => 'Weekly reports';

  @override
  String get premiumFeatureReportsBody =>
      'A summary of your progress each week';

  @override
  String get premiumFeaturePlanTitle => 'Meal planning';

  @override
  String get premiumFeaturePlanBody => 'A weekly plan that fits you';

  @override
  String get premiumNotAvailable => 'Subscriptions are not available right now';

  @override
  String get premiumBack => 'Back';

  @override
  String get plannerTitle => 'Weekly plan';

  @override
  String get plannerEmpty =>
      'No plan for this week yet. Tap Generate new plan to start.';

  @override
  String get plannerDayEmpty =>
      'No meals on this day. Add one with the buttons below.';

  @override
  String get plannerTotal => 'Total';

  @override
  String get plannerMissingTarget =>
      'Finish your personal setup so we know your daily target and can generate an honest plan.';

  @override
  String get plannerGenerate => 'Generate new plan';

  @override
  String get plannerShoppingCta => 'Shopping list';

  @override
  String get plannerReplace => 'Replace';

  @override
  String get plannerAddMeal => 'Add';

  @override
  String get weekdaySat => 'Sa';

  @override
  String get weekdaySun => 'Su';

  @override
  String get weekdayMon => 'Mo';

  @override
  String get weekdayTue => 'Tu';

  @override
  String get weekdayWed => 'We';

  @override
  String get weekdayThu => 'Th';

  @override
  String get weekdayFri => 'Fr';

  @override
  String get shoppingTitle => 'Shopping list';

  @override
  String get shoppingEmpty =>
      'The list is empty. Generate it from the weekly plan or add an item yourself.';

  @override
  String get shoppingGenerateFromPlan => 'Generate from weekly plan';

  @override
  String get shoppingRegenerate => 'Update from weekly plan';

  @override
  String get shoppingNoPlan =>
      'Generate and save a weekly plan first to build the list from it.';

  @override
  String shoppingSkipped(int count) {
    return 'Review amounts for $count plan items before adding them.';
  }

  @override
  String shoppingItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get shoppingGroupProduce => 'Produce';

  @override
  String get shoppingGroupProtein => 'Protein';

  @override
  String get shoppingGroupDairy => 'Dairy';

  @override
  String get shoppingGroupGrains => 'Grains & starches';

  @override
  String get shoppingGroupOther => 'Other';

  @override
  String get shoppingAddTitle => 'Add an item yourself';

  @override
  String get shoppingAddName => 'Item name';

  @override
  String get shoppingAddInvalid =>
      'Enter an item name and a quantity above zero';

  @override
  String get coachTitle => 'Sufra Coach';

  @override
  String get coachStatusReviewing => 'Reviewing saved meal records';

  @override
  String get coachStatusIdle => 'Waiting for your first log';

  @override
  String get coachRuleBadge => 'From your records';

  @override
  String get coachRuleBadgeShort => 'Your records';

  @override
  String get coachToday => 'Today';

  @override
  String get coachReviewNote => 'The coach reviewed your last 7 days of meals';

  @override
  String get coachNoRecordsNote =>
      'Not enough records yet — log your first meal';

  @override
  String get coachSendFailed => 'The message was not saved. Try again.';

  @override
  String get coachInputHint => 'Ask Sufra Coach...';

  @override
  String get coachAdviceLabel => 'Tip';

  @override
  String get coachQuickPlan => 'Make me a plan for tomorrow';

  @override
  String get coachQuickWeek => 'Analyze my week';

  @override
  String get coachQuickWater => 'How much water should I drink?';

  @override
  String get ramadanGreeting => 'Ramadan Kareem';

  @override
  String get ramadanUntilIftar => 'Until Iftar';

  @override
  String get ramadanUntilTaraweeh => 'Until after Taraweeh';

  @override
  String get ramadanUntilSuhoor => 'Until Suhoor ends';

  @override
  String get ramadanSeconds => 'seconds';

  @override
  String get ramadanMinutes => 'minutes';

  @override
  String get ramadanHours => 'hours';

  @override
  String get ramadanSuhoorEnd => 'Suhoor ends';

  @override
  String get ramadanIftarAt => 'Iftar';

  @override
  String get ramadanTaraweeh => 'After Taraweeh';

  @override
  String get ramadanCups => 'cups';

  @override
  String get ramadanCupsUserNote => 'You set this cups goal yourself';

  @override
  String get ramadanCupsDefaultNote =>
      '8 cups is a design default display, not a personal health goal — you can change it';

  @override
  String get ramadanEditTimes => 'Set your times';

  @override
  String get ramadanDisclaimer =>
      'Educational only; consult your doctor if you have diabetes or are pregnant';

  @override
  String get ramadanSetupBody =>
      'The app never invents prayer times. Set your Iftar and Suhoor times for your city and schedule, and we will run the countdown and organization on them.';

  @override
  String get ramadanSetupCta => 'Set Ramadan times';

  @override
  String get ramadanChooseTime => 'Choose time';

  @override
  String get ramadanTimesTitle => 'Your Ramadan times';

  @override
  String get ramadanTimesNote =>
      'Choose each time for your city and schedule. No prayer times are calculated here. You can change them anytime.';

  @override
  String get plannerAllergyWarning =>
      'If you have an allergy, check every meal’s ingredients and packaging before eating. The plan does not guarantee an allergen-free meal.';

  @override
  String get coachVoicePrivacy =>
      'Platform speech recognition may send audio to its provider. Sufra does not store audio. Text appears here for you to review and edit before sending.';

  @override
  String get coachVoiceCancel => 'Cancel';

  @override
  String get coachVoiceStart => 'Dictate message';

  @override
  String get coachVoiceListening =>
      'Listening. Review the text before sending.';

  @override
  String get coachVoiceUnavailable =>
      'Dictation is unavailable or no speech was heard. Check microphone permission and language, or type your message.';

  @override
  String statsBadgesEarned(String earned, String total) {
    return '$earned of $total badges earned';
  }

  @override
  String plannerWeekTotal(String calories) {
    return 'Week total: $calories kcal';
  }

  @override
  String get avatarLocalNote =>
      'Choose a profile picture saved only on this device for this account. It will not be uploaded.';

  @override
  String get avatarChoose => 'Choose profile picture';

  @override
  String get avatarFailed =>
      'Could not save that image. Try a different photo.';

  @override
  String get appLanguage => 'Language';

  @override
  String get cameraGallery => 'Choose image from gallery';

  @override
  String get exportSelectRange => 'Select report dates';

  @override
  String get exportRangeLimit => 'Choose up to one year per report.';

  @override
  String get exportLoggedWater => 'Logged water by day (ml)';

  @override
  String get exportWeightHistory => 'Recorded weight history (kg)';

  @override
  String get exportNoWeightHistory => 'No weight records in this range';

  @override
  String get exportNoWaterRecord => 'No water amount recorded';

  @override
  String exportTrackingDays(String days) {
    return 'Tracking map (days in range: $days)';
  }

  @override
  String get themeAccentPicker => 'Current theme colors';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersWaterTitle => 'Water reminders';

  @override
  String get remindersWaterAdd => 'Add a time';

  @override
  String get remindersWaterRemove => 'Remove time';

  @override
  String get remindersWaterFull =>
      'You reached the maximum number of water times.';

  @override
  String get remindersMealsTitle => 'Meal reminders';

  @override
  String get remindersWeightTitle => 'Weight reminder';

  @override
  String remindersWeightEvery(String day) {
    return 'Every week on $day';
  }

  @override
  String get remindersPickDay => 'Choose the day';

  @override
  String get remindersNotSet => 'No time set yet';

  @override
  String get remindersPermissionOff =>
      'Sufra notifications are off in your device settings. Turn them on there so reminders reach you.';

  @override
  String get remindersPermissionDenied =>
      'Without notification permission we cannot send you a reminder.';

  @override
  String get remindersScheduleFailed =>
      'Could not set the reminder on this device. Try again.';

  @override
  String get remindersTimezoneUnavailable =>
      'Could not read the device timezone, so reminders were not set.';

  @override
  String get remindersSaveFailed => 'Could not save the change. Try again.';

  @override
  String get remindersInexactNote =>
      'Reminder times are approximate. A reminder can arrive a few minutes late, especially when the phone is saving power.';

  @override
  String get remindersPrivacyNote =>
      'Reminders are stored on this device only and run for your current account.';

  @override
  String get remindersNotifTitle => 'Sufra';

  @override
  String get remindersNotifWater =>
      'If it works for you, take a water break. Open Sufra to log what you drank.';

  @override
  String remindersNotifMeal(String meal) {
    return 'Ready to log $meal? Open Sufra to review your food and portion.';
  }

  @override
  String get remindersNotifWeight =>
      'If now is a good time, log your weight. Focus on the trend, not one reading.';

  @override
  String get remindersChannelWater => 'Water reminders';

  @override
  String get remindersChannelMeals => 'Meal reminders';

  @override
  String get remindersChannelWeight => 'Weight reminders';

  @override
  String get reminderCleanupFailed =>
      'Could not confirm reminder cleanup. Reminders may still appear until the app opens and retries.';

  @override
  String get reportMeasuredAverages => 'Averages of recorded values';

  @override
  String reportMetricCoverage(String measured, String total) {
    return 'Value recorded on $measured of $total days';
  }

  @override
  String reportRangeLabel(String start, String end) {
    return 'Period: $start to $end';
  }

  @override
  String get waterGoalChoose => 'Change water goal';

  @override
  String get waterGoalChosenNote =>
      'Your chosen goal, saved on this device for this account';

  @override
  String get waterGoalLocalHint =>
      'Choose your goal in ml. Not medical advice. Does not sync across devices.';

  @override
  String get waterGoalInvalid =>
      'Enter an amount above zero and up to 20,000 ml';

  @override
  String get alternativesPreferenceNote =>
      'Profile allergies and dietary preferences use name/category exclusions only, not allergy-safety checks. Check ingredients and labels. Unsupported dietary constraints do not receive a claimed matching alternative.';

  @override
  String cameraConsentTitle(String provider) {
    return 'Send image to $provider?';
  }

  @override
  String get cameraConsentDetail =>
      'This permission covers this image only as described above. Meal type and notes are not sent for analysis; they stay with the meal you review and save. You can cancel and choose foods manually.';

  @override
  String get cameraConsentSend => 'Agree and send once';

  @override
  String get recipeCalorieLimit => 'Maximum calories per serving';

  @override
  String get recipeTimeLimit => 'Maximum cooking time';

  @override
  String get recipeNoLimit => 'No limit';

  @override
  String get recipeStrictConstraints =>
      'Suggestions require a verified meal type and, when limited, verified calories and cooking time. Missing values never count as a match. You can still browse recipes without constrained suggestions.';

  @override
  String get recipeYourVersion => 'Your reviewed quantified version';

  @override
  String get recipeQuantifiedNotice =>
      'This is your version, not source nutrition. Match every ingredient and preparation state to the catalog. Enter grams for the whole recipe and the yield. Exclude only ingredients you did not use. Values use only your reviewed grams. Nothing is saved before meal review.';

  @override
  String get recipeExcludeIngredient => 'Not used in my version';

  @override
  String get recipeYield => 'Recipe yield in servings';

  @override
  String get recipeServingsToLog => 'Servings to log';

  @override
  String get recipeMatchEveryIngredient =>
      'Review every ingredient: match it and enter grams, or confirm it was not used.';

  @override
  String get recipeBuildQuantified => 'Review my amounts and log';

  @override
  String get recipeExcludedCount => 'Excluded ingredient count';

  @override
  String get foodCategoryAll => 'All foods';

  @override
  String get foodCategoryEgyptian => 'Egyptian cooking staples';

  @override
  String get foodCategoryGrains => 'Grains';

  @override
  String get foodCategoryLegumes => 'Legumes';

  @override
  String get foodCategoryVegetables => 'Vegetables';

  @override
  String get foodCategoryDairy => 'Dairy';

  @override
  String get foodCategoryPoultry => 'Poultry';

  @override
  String get foodCategoryProducts => 'Barcode products';

  @override
  String get foodManualTitle => 'Add food manually';

  @override
  String get foodManualNote =>
      'Enter per 100 g values from your label or source. These are user-entered, not verified by Sufra. Missing values remain unknown.';

  @override
  String get foodManualSource => 'Pack name';

  @override
  String get foodManualRequired => 'Required';

  @override
  String get foodManualConfirm =>
      'I checked that these values are per 100 g and copied correctly';

  @override
  String get foodManualInvalid =>
      'Check name, source, calories and values, then confirm review';

  @override
  String get registrationPolicyUnavailable =>
      'New registration is paused until approved terms and privacy policy are provided. Existing account sign-in is available.';

  @override
  String get statsMacroPerformance => 'Average macro performance';

  @override
  String statsMacroCoverage(String count, String total, String goal) {
    return '$count of $total days have a recorded value. Average target: $goal g';
  }

  @override
  String get ownerTerms => 'Terms';

  @override
  String get ownerPrivacy => 'Privacy policy';

  @override
  String get cameraCandidateSafetyNote =>
      'Visual candidate only. Confirm ingredients and weighed portion.';

  @override
  String get cameraNutritionSafetyNote =>
      'Image recognition cannot measure grams or provide verified nutrition.';

  @override
  String get homeBrowseMeals => 'Explore your table';

  @override
  String get homeMealSuggestions => 'Meal ideas';

  @override
  String get homeRecipeNutritionUnknown =>
      'Nutrition needs ingredient quantities';

  @override
  String get homeRecipeSourceNote =>
      'TheMealDB · educational development catalog';

  @override
  String get homeRecipeUnavailable =>
      'Recipe suggestions are unavailable in this build.';

  @override
  String get homeOpenRecipes => 'Browse recipes';

  @override
  String get homeFeaturedRecipe => 'A Sufra dish';

  @override
  String get homeSourceCategoryNote =>
      'Categories follow the source, not dietary advice.';

  @override
  String get homeCategoryVegetarian => 'Vegetarian · source category';

  @override
  String get homeCategoryChicken => 'Chicken';

  @override
  String get homeCategoryBeef => 'Beef';

  @override
  String get homeCategorySide => 'Side dishes';

  @override
  String get unitMinutesShort => 'min';

  @override
  String get plannerPortionNote =>
      'A starting point for your meals, not a complete diet. Adjust portions to your needs; the total may differ from your target.';

  @override
  String reportLoggedCoverage(int count, int total) {
    return 'Average based on $count of $total days with food logged';
  }

  @override
  String get reportWaterToday => 'Today\'s water';

  @override
  String get reportNoMeals => 'No meal details to show a breakdown';

  @override
  String get reportOtherMeals => 'Other meals';

  @override
  String get reportRecordedFiber => 'Recorded fiber';

  @override
  String get weightHistoryNeeded =>
      'Progress is unavailable with the current data. It needs a target different from the starting weight and two entries at different times. A single weight cannot show a trend.';

  @override
  String get weightLoadedProgress =>
      'Progress from the oldest entry in the loaded history, not from when you first used the app.';

  @override
  String weightBaselineDetail(String kg, String date) {
    return 'Loaded history starts at $kg kg on $date';
  }

  @override
  String weightCurrentDetail(String kg) {
    return 'Current weight: $kg kg';
  }

  @override
  String weightTargetDetail(String kg) {
    return 'Saved target: $kg kg';
  }

  @override
  String get weightProgressBaselineLabel => 'from loaded start';
}

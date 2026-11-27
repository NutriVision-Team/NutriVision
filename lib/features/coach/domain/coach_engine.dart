import 'weekly_personal_review.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/daily_log_model.dart';
import '../../../data/models/meal_entry_model.dart';

/// One numeric fact shown inside a coach answer card.
class CoachStat {
  const CoachStat({required this.label, required this.value});

  /// Localized label, e.g. "أيام مسجلة".
  final String label;

  /// Already localized display value; numbers only from real records.
  final String value;
}

class CoachAnswer {
  const CoachAnswer({required this.text, this.stats = const [], this.advice});

  final String text;
  final List<CoachStat> stats;
  final String? advice;
}

/// The records a coach answer may use. Everything here comes from the
/// user's own repositories; the engine never invents meals or values.
class CoachData {
  const CoachData({
    required this.todayKey,
    required this.locale,
    this.meals = const [],
    this.dailyLogs = const [],
    this.calorieTarget,
    this.waterTargetMl,
    this.goals = const [],
  });

  final String todayKey;

  /// 'ar' or 'en'; answers are authored in both, never machine-translated.
  final String locale;
  final List<MealEntryModel> meals;
  final List<DailyLogModel> dailyLogs;
  final double? calorieTarget;
  final List<String> goals;

  /// The water goal the user actually configured; null when unknown, in
  /// which case water answers say so instead of quoting an invented goal.
  final double? waterTargetMl;

  bool get isArabic => locale == 'ar';
}

/// Deterministic, rule-based Smart Coach (screen 27 baseline).
///
/// Every number in an answer is computed from [CoachData]. Missing records
/// are reported as missing, never as zero consumption, and the coach gives
/// no medical diagnoses or treatment. This class is the documented
/// fallback; an optional AI provider may replace it behind the same
/// interface but is never required.
class RuleBasedCoach {
  const RuleBasedCoach();

  static const _waterWords = ['مية', 'مياه', 'اشرب', 'أشرب', 'شرب', 'water'];
  static const _weekWords = ['أسبوع', 'اسبوع', 'حلل', 'تحليل', 'week'];
  static const _planWords = ['خطة', 'خطط', 'غدا', 'بكرة', 'plan', 'tomorrow'];
  static const _todayWords = ['النهاردة', 'اليوم', 'سعرات', 'today', 'calor'];
  static const _proteinWords = ['بروتين', 'protein'];
  static const _greetWords = ['اهلا', 'أهلا', 'هاي', 'hello', 'hi', 'سلام'];

  CoachAnswer answer(String rawQuestion, CoachData data) {
    final q = _normalize(rawQuestion);
    if (q.isEmpty) return _fallback(data);
    if (_hits(q, _waterWords)) return _water(data);
    if (_hits(q, _weekWords)) return _week(data);
    if (_hits(q, _planWords)) return _tomorrowPlan(data);
    if (_hits(q, _proteinWords)) return _protein(data);
    if (_hits(q, _todayWords)) return _today(data);
    if (_hits(q, _greetWords)) return _fallback(data);
    return _fallback(data);
  }

  /// The three quick prompts from the design, keyed for the UI.
  static const quickPrompts = ['plan_tomorrow', 'analyze_week', 'water'];

  CoachAnswer quick(String id, CoachData data) {
    switch (id) {
      case 'plan_tomorrow':
        return _tomorrowPlan(data);
      case 'analyze_week':
        return _week(data);
      case 'water':
        return _water(data);
      default:
        return _fallback(data);
    }
  }

  static String _normalize(String input) {
    var out = input.trim().toLowerCase();
    out = out
        .replaceAll(RegExp(r'[ً-ْٰ]'), '')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
    return out;
  }

  static bool _hits(String q, List<String> words) {
    final normalized = words.map(_normalize);
    return normalized.any(q.contains);
  }

  List<MealEntryModel> _last7Meals(CoachData data) {
    final today = DateTime.parse('${data.todayKey}T00:00:00');
    final start = SufraDateUtils.toDateKey(
      today.subtract(const Duration(days: 6)),
    );
    return data.meals
        .where(
          (m) =>
              m.dateKey.compareTo(start) >= 0 &&
              m.dateKey.compareTo(data.todayKey) <= 0,
        )
        .toList(growable: false);
  }

  CoachAnswer _today(CoachData data) {
    final ar = data.isArabic;
    final todayMeals = data.meals
        .where((m) => m.dateKey == data.todayKey)
        .toList(growable: false);
    if (todayMeals.isEmpty) {
      return CoachAnswer(
        text: ar
            ? 'لسه مسجلتش أي وجبة النهاردة، فمش هقدر أقولك رقم. سجّل أول أكلة وهحسبهالك فورًا.'
            : 'No meals are logged for today yet, so there is no number to report. Log your first meal and I will total it for you.',
        advice: ar ? 'التسجيل المنتظم هو أساس أي تحليل صادق.' : null,
      );
    }
    final calories = todayMeals.fold<double>(
      0,
      (sum, m) => sum + m.totalCalories,
    );
    final target = data.calorieTarget;
    return CoachAnswer(
      text: ar
          ? 'النهاردة سجلت ${todayMeals.length} ${todayMeals.length == 1 ? 'وجبة' : 'وجبات'} بإجمالي محسوب من مكوناتها.'
          : 'Today you logged ${todayMeals.length} meal(s), totaled from their ingredients.',
      stats: [
        CoachStat(
          label: ar ? 'سعرات النهاردة' : 'Calories today',
          value: calories.round().toString(),
        ),
        CoachStat(
          label: ar ? 'هدفك' : 'Your target',
          value: target != null
              ? target.round().toString()
              : (ar ? 'غير محدد' : 'Not set'),
        ),
      ],
      advice: target != null && calories > target
          ? (ar
                ? 'الرقم ده من المسجّل بس، مش حكم على يومك. مش محتاج تعوّض بحرمان أو تفويت وجبات.'
                : 'This total reflects logged meals only, not a judgment of your day. Do not compensate by skipping meals or restricting food.')
          : null,
    );
  }

  CoachAnswer _week(CoachData data) {
    final ar = data.isArabic;
    final meals = _last7Meals(data);
    final days = meals.map((m) => m.dateKey).toSet();
    if (meals.isEmpty) {
      return CoachAnswer(
        text: ar
            ? 'مفيش وجبات مسجلة في آخر ٧ أيام، فمفيش تحليل أقدر أعمله من غير ما أخترع أرقام. سجّل يومين وهتشوف تحليل حقيقي هنا.'
            : 'No meals were logged in the last 7 days, so there is nothing honest to analyze. Log two days and a real analysis will appear here.',
      );
    }
    final review = WeeklyPersonalReview(
      todayKey: data.todayKey,
      meals: data.meals,
    );
    final energy = review.measuredAverage((m) => m.totalCalories);
    final protein = review.measuredAverage((m) => m.totalProtein);
    final fiber = review.measuredAverage((m) => m.totalFiber);
    final average = energy.average;
    final missingDays = 7 - days.length;
    final varietyGoal = data.goals.any(
      (g) => const [
        'food_variety',
        'تنويع الأكل',
        'food variety',
      ].contains(g.trim().toLowerCase()),
    );
    final regularGoal = data.goals.any(
      (g) => const [
        'meal_routine',
        'تنظيم الوجبات',
        'meal routine',
      ].contains(g.trim().toLowerCase()),
    );
    final goalAdvice = varietyGoal
        ? (review.ingredientMeals < meals.length
              ? (ar
                    ? 'لهدف تنويع الأكل: ابدأ بإضافة مكونات وجبة واحدة، عشان نقدر نلاحظ التنوع من غير تخمين.'
                    : 'For your food-variety goal, add ingredients to one meal so variety can be described without guessing.')
              : (ar
                    ? 'لهدف تنويع الأكل: جرّب مكوّن مختلف في وجبة جاية لو يناسب اختياراتك. عدد المكونات مش تقييم لتوازن النظام.'
                    : 'For your food-variety goal, try a different ingredient in a coming meal if it fits your choices. Ingredient count is not a balanced-diet score.'))
        : regularGoal
        ? (ar
              ? 'لهدف تنظيم الوجبات: اختار وجبة واحدة في يومك وسجّلها لما تخلص. أيام التسجيل مش دليل إن باقي الأيام كانت من غير أكل.'
              : 'For your meal-routine goal, choose one meal in your day and log it afterward. Unlogged days do not mean no food was eaten.')
        : null;

    return CoachAnswer(
      text: ar
          ? 'راجعت سجلات آخر ٧ أيام: عندك ${days.length} ${days.length == 1 ? 'يوم مسجّل' : 'أيام مسجلة'}${missingDays > 0 ? ' و$missingDays بدون تسجيل (مش صفر أكل، بس بيانات ناقصة)' : ''}.'
          : 'I reviewed the last 7 days: ${days.length} day(s) logged${missingDays > 0 ? ' and $missingDays without records (missing data, not zero food)' : ''}.',
      stats: [
        CoachStat(
          label: ar ? 'أيام مسجلة' : 'Days logged',
          value: days.length.toString(),
        ),
        CoachStat(
          label: ar ? 'أيام الأسبوع اللي قبله' : 'Previous week logged days',
          value: review.previousDays.toString(),
        ),
        CoachStat(
          label: ar ? 'مكونات مختلفة مسجلة' : 'Different logged ingredients',
          value: review.ingredientMeals == 0
              ? (ar ? 'غير معروف' : 'Unknown')
              : review.ingredientFoods.toString(),
        ),
        CoachStat(
          label: ar
              ? 'وجبات بتفاصيل المكونات'
              : 'Meals with ingredient details',
          value: '${review.ingredientMeals} / ${meals.length}',
        ),
        CoachStat(
          label: ar ? 'متوسط البروتين (جم)' : 'Average protein (g)',
          value:
              protein.average?.toStringAsFixed(0) ??
              (ar ? 'غير معروف' : 'Unknown'),
        ),
        CoachStat(
          label: ar
              ? 'أيام البروتين المكتملة'
              : 'Days with complete protein values',
          value: '${protein.days} / ${days.length}',
        ),
        CoachStat(
          label: ar ? 'متوسط الألياف (جم)' : 'Average fiber (g)',
          value:
              fiber.average?.toStringAsFixed(0) ??
              (ar ? 'غير معروف' : 'Unknown'),
        ),
        CoachStat(
          label: ar
              ? 'أيام الألياف المكتملة'
              : 'Days with complete fiber values',
          value: '${fiber.days} / ${days.length}',
        ),
        CoachStat(
          label: ar ? 'متوسط السعرات' : 'Average calories',
          value: average != null
              ? average.round().toString()
              : (ar ? 'غير معروف' : 'Unknown'),
        ),
      ],
      advice:
          goalAdvice ??
          (review.ingredientMeals < meals.length
              ? (ar
                    ? 'بعض الوجبات من غير تفاصيل مكونات، فعدد المكونات مش مقياس لتوازن أكلك. جرّب تضيف مكونات وجبة واحدة بكمياتها المرة الجاية.'
                    : 'Some meals lack ingredient details, so ingredient counts do not measure diet balance. Add ingredients and quantities for one meal next time.')
              : fiber.days < days.length
              ? (ar
                    ? 'الألياف ناقصة في بعض القيم، فمش هنعتبرها صفر. راجع مصدر مكونات وجبة واحدة عشان المتابعة تبقى أوضح.'
                    : 'Some fiber values are missing, not zero. Review one meal ingredient source to improve coverage.')
              : (ar
                    ? 'المتابعة هنا للأكل اللي سجلته بس، مش حكم على الأسبوع كله. جرّب تختار مكوّن مختلف لوجبة جاية لو يناسبك.'
                    : 'This describes logged food, not your whole week. Consider a different ingredient in a coming meal if it suits you.')),
    );
  }

  CoachAnswer _water(CoachData data) {
    final ar = data.isArabic;
    DailyLogModel? todayLog;
    for (final log in data.dailyLogs) {
      if (log.dateKey == data.todayKey) todayLog = log;
    }
    final value = todayLog?.waterIntakeMl;
    final intake = value != null && value.isFinite && value >= 0 ? value : null;
    final configured = data.waterTargetMl;
    final target = configured != null && configured.isFinite && configured > 0
        ? configured
        : null;
    final caution = ar
        ? 'الهدف للمراجعة، مش وصفة شخصية أو أمر إنك تشرب الباقي. لو عندك قيود للسوائل، اتبع تعليمات مختصك.'
        : 'The goal is a reference, not a personal prescription or an instruction to drink the difference. Follow professional guidance if you have a fluid limit.';
    if (intake == null) {
      return CoachAnswer(
        text: ar
            ? 'مفيش قيمة مية صالحة في سجل النهاردة. الاستهلاك غير معروف، مش صفر. افتح سجل المية وضيف اللي شربته فعلًا.'
            : 'There is no valid water value in today\'s record. Intake is unknown, not zero. Open the water log and add what you actually drank.',
        stats: [
          CoachStat(
            label: ar ? 'المية في السجل (مل)' : 'Water in record (ml)',
            value: ar ? 'غير معروف' : 'Unknown',
          ),
          if (target != null)
            CoachStat(
              label: ar ? 'الهدف المحدد (مل)' : 'Configured goal (ml)',
              value: target.round().toString(),
            ),
        ],
        advice: caution,
      );
    }
    return CoachAnswer(
      text: ar
          ? 'قيمة المية في سجل النهاردة ${intake.round()} مل. ده وصف للمسجل بس، مش قياس لكل اللي شربته.${target == null ? ' هدف المية غير محدد، ومش هفترض رقم.' : ''}'
          : 'Today\'s water record contains ${intake.round()} ml. This describes the record, not a measurement of everything you drank.${target == null ? ' No water goal is configured; I will not invent one.' : ''}',
      stats: [
        CoachStat(
          label: ar ? 'المية في السجل (مل)' : 'Water in record (ml)',
          value: intake.round().toString(),
        ),
        if (target != null) ...[
          CoachStat(
            label: ar ? 'الهدف المحدد (مل)' : 'Configured goal (ml)',
            value: target.round().toString(),
          ),
          CoachStat(
            label: ar ? 'الفرق عن الهدف (مل)' : 'Difference below goal (ml)',
            value: (target - intake)
                .clamp(0, double.infinity)
                .round()
                .toString(),
          ),
        ],
      ],
      advice: caution,
    );
  }

  CoachAnswer _protein(CoachData data) {
    final ar = data.isArabic;
    final todayMeals = data.meals
        .where((m) => m.dateKey == data.todayKey)
        .toList(growable: false);
    if (todayMeals.isEmpty) {
      return CoachAnswer(
        text: ar
            ? 'مفيش وجبات النهاردة لحد دلوقتي، فمفيش بروتين أحسبه. سجّل وجبتك وهقولك فين واقف.'
            : 'No meals logged today yet, so there is no protein to compute. Log a meal and I will tell you where you stand.',
      );
    }
    final allKnown = todayMeals.every((m) => m.totalProtein != null);
    if (!allKnown) {
      final partial = todayMeals.fold<double?>(
        0,
        (sum, m) => sum == null || m.totalProtein == null
            ? null
            : sum + m.totalProtein!,
      );
      return CoachAnswer(
        text: ar
            ? 'بروتين بعض الوجبات مش متاح، فإجمالي اليوم لسه مش كامل.'
            : 'Some of today\'s items have no protein value, so the full total is unknown rather than zero.',
        stats: [
          CoachStat(
            label: ar ? 'بروتين متاح (جم)' : 'Verified protein (g)',
            value: partial != null
                ? partial.round().toString()
                : (ar ? 'غير معروف' : 'Unknown'),
          ),
        ],
      );
    }
    final protein = todayMeals.fold<double>(
      0,
      (sum, m) => sum + (m.totalProtein ?? 0),
    );
    return CoachAnswer(
      text: ar ? 'بروتين وجباتك النهاردة:' : 'Today\'s recorded protein:',
      stats: [
        CoachStat(
          label: ar ? 'بروتين (جم)' : 'Protein (g)',
          value: protein.round().toString(),
        ),
      ],
    );
  }

  CoachAnswer _tomorrowPlan(CoachData data) {
    final ar = data.isArabic;
    final target = data.calorieTarget;
    if (target == null) {
      return CoachAnswer(
        text: ar
            ? 'محتاج هدفك اليومي الأول. كمّل إعدادك الشخصي، وبعدها شاشة خطة الأسبوع تولّدلك خطة محفوظة من الأكلات المتاحة.'
            : 'I need your daily target first. Finish your personal setup, then the weekly planner can help you plan your meals.',
      );
    }
    return CoachAnswer(
      text: ar
          ? 'هدفك اليومي ${target.round()} سعرة. افتح خطة الأسبوع وهتلاقي زرار "ولّد خطة جديدة" بيبني ٧ أيام من الأكلات المتاحة وبيحفظها، وبعدها قائمة التسوق بتتولّد من نفس الكميات.'
          : 'Your daily target is ${target.round()} kcal. Open the weekly planner and tap "Generate new plan": it builds a 7-day plan and saves it, and the shopping list is generated from the same quantities.',
      stats: [
        CoachStat(
          label: ar ? 'هدفك اليومي' : 'Daily target',
          value: target.round().toString(),
        ),
      ],
      advice: ar
          ? 'الخطة بتتحفظ فورًا — اللي بتشوفه هو اللي اتسجل فعلًا.'
          : 'The plan is saved immediately: what you see is what was stored.',
    );
  }

  CoachAnswer _fallback(CoachData data) {
    final ar = data.isArabic;
    final hasData = data.meals.isNotEmpty;
    return CoachAnswer(
      text: ar
          ? 'أنا مدرّب سفرة. هنراجع يومك خطوة بخطوة حسب اللي سجّلته والهدف اللي اخترته. أقدر ألخّص سعرات يومك وبروتينك ونشاط تسجيلك والمية، وأساعدك تفتح الأداة المناسبة. لو معلومة ناقصة هقولك، ومش هقدّم تشخيص أو خطة علاج.'
          : 'I am your Sufra coach. We can review your day step by step using your logs and chosen target. I can summarize logged calories, protein, activity and water, and help you open the right tool. I will say when information is missing. I do not diagnose or provide treatment plans.',
      advice: hasData
          ? null
          : (ar
                ? 'سجّل أول وجبة عشان أبدأ أساعدك بأرقام حقيقية.'
                : 'Log your first meal so I can help with real numbers.'),
    );
  }
}

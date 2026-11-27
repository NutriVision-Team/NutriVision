import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import '../../domain/coach_learn_content.dart';
import 'coach_learn_article_screen.dart';
import 'dart:async';
import 'coach_daily_checkin_screen.dart';
import '../../domain/coach_daily_checkin.dart';
import '../../domain/coach_progress_comparison.dart';
import '../../../health_coach/domain/health_coach_profile.dart';
import '../../../progress/export/coach_report_snapshot.dart';
import '../../../../core/widgets/sufra_lustre.dart';
import '../../../../core/theme/app_colors.dart';
import 'coach_storage_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/weekly_personal_review.dart';
import '../../../../data/models/meal_entry_model.dart';
import '../../../planner/domain/planner_food_choices.dart';
import '../../domain/coach_engine.dart';
import '../cubit/coach_cubit.dart';
import 'coach_habits_screen.dart';

/// Local workspace over existing owned records. No new persistence or AI call.
class CoachWorkspacePanel extends StatefulWidget {
  const CoachWorkspacePanel({
    super.key,
    required this.cubit,
    required this.section,
    required this.onChat,
  });
  final CoachCubit cubit;
  final int section;
  final VoidCallback onChat;
  @override
  State<CoachWorkspacePanel> createState() => _CoachWorkspacePanelState();
}

class _CoachWorkspacePanelState extends State<CoachWorkspacePanel> {
  late Future<CoachData> data;
  int period = 7;
  Timer? dayTimer;
  late String shownDay;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String t(String a, String e) => ar ? a : e;
  @override
  void initState() {
    super.initState();
    shownDay = widget.cubit.habitTodayKey;
    dayTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && shownDay != widget.cubit.habitTodayKey) {
        setState(() {
          shownDay = widget.cubit.habitTodayKey;
          data = widget.cubit.readLocalReview();
        });
      }
    });
    data = widget.section == 4
        ? Future.value(const CoachData(todayKey: '', locale: 'en'))
        : widget.cubit.readLocalReview();
  }

  @override
  void dispose() {
    dayTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CoachWorkspacePanel old) {
    super.didUpdateWidget(old);
    if (old.section != widget.section) {
      data = widget.section == 4
          ? Future.value(const CoachData(todayKey: '', locale: 'en'))
          : widget.cubit.readLocalReview();
    }
  }

  Widget card(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: GlassCard(
      borderColor: AppColors.purpleLight.withValues(alpha: .36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 25,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ),
  );
  Widget text(String a, String e) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t(a, e)));
  Future<void> habits() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CoachHabitsScreen(cubit: widget.cubit)),
    );
    if (mounted) {
      setState(() {
        data = widget.cubit.readLocalReview();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.section == 4) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
        children: [
          text(
            'معلومات عامة من المصادر، مش خطة علاج. المحتوى المختصر هنا لسه ما اتراجعش من مختص للتطبيق.',
            'General source-based information, not treatment. These app summaries have not yet had specialist review.',
          ),
          for (final topic in coachLearnTopics)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(ar ? topic.titleAr : topic.titleEn),
                  subtitle: Text(topic.sourceName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CoachLearnArticleScreen(topic: topic),
                    ),
                  ),
                ),
              ),
            ),
          OutlinedButton(
            onPressed: () => context.push('/recipes'),
            child: Text(t('استكشف وصفات سُفرة', 'Explore Sufra recipes')),
          ),
        ],
      );
    }
    return FutureBuilder<CoachData>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || widget.cubit.inactive) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() {
                data = widget.cubit.readLocalReview();
              }),
              child: Text(
                t(
                  'تعذر تحميل السجل. جرّب تاني',
                  'Could not load records. Retry',
                ),
              ),
            ),
          );
        }
        final d = snapshot.requireData;
        final p = widget.cubit.healthProfile;
        final today = d.meals.where((m) => m.dateKey == d.todayKey).length;
        final chosen = widget.cubit.chosenHabits;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
          children: [
            if (widget.section == 0) ...[
              dashboard(
                today,
                chosen.length,
                chosen.where(widget.cubit.habitDone).length,
                d,
              ),
              card(t('يومك في سُفرة', 'Your day in Sufra'), [
                Text(
                  t(
                    'وجبات مسجلة النهاردة: $today',
                    'Meals logged today: $today',
                  ),
                ),
                text(
                  'عدم التسجيل مش معناه إنك ما أكلتش.',
                  'No log does not mean you did not eat.',
                ),
                OutlinedButton(
                  onPressed: () => context.push('/diary'),
                  child: Text(t('افتح يوميتي', 'Open my diary')),
                ),
              ]),
              card(t('تركيزك الحالي', 'Your current focus'), [
                Text(
                  p.goals.isEmpty
                      ? t(
                          'لسه ما اخترتش هدف. تقدر تختار من اختيارات المدرب.',
                          'No focus selected. You can choose one in Coach choices.',
                        )
                      : p.goals
                            .map((g) => CoachGoalLabels.label(g, ar))
                            .join(ar ? '، ' : ', '),
                ),
                text(
                  'الاختيار مش إثبات لتحقيق الهدف. بنقترح خطوة صغيرة تراجعها بنفسك.',
                  'A selection is not evidence a goal was achieved. Choose a small step and check it yourself.',
                ),
              ]),
              card(t('خطوتك النهاردة', 'Your step today'), [
                Text(
                  t(
                    'خطوات اخترتها: ${chosen.length}، أكدت منها: ${chosen.where(widget.cubit.habitDone).length}',
                    'Steps chosen: ${chosen.length}. Checked in: ${chosen.where(widget.cubit.habitDone).length}',
                  ),
                ),
                text(
                  'التأكيد للجلسة لحد ما تحفظه بنفسك في حسابك.',
                  'A check-in is session-only until you explicitly save it in your account.',
                ),
                OutlinedButton(
                  onPressed: habits,
                  child: Text(
                    t('اختار أو راجع خطوتك', 'Choose or review your step'),
                  ),
                ),
              ]),
              card(t('خطوة جاية من سجلك', 'Next step from your records'), [
                Text(
                  const RuleBasedCoach().quick('analyze_week', d).advice ??
                      t(
                        'سجّل وجبة بمكوناتها عشان نبدأ مراجعة مبنية على بيانات.',
                        'Log a meal with ingredients to start a record-based review.',
                      ),
                ),
              ]),
            ],
            if (widget.section == 0) dailyCard(),
            if (widget.section == 2) ...[
              planSteps(),
              card(t('خطة قابلة للتعديل', 'An editable plan'), [
                text(
                  'المكونات والكميات من قاعدة الأكل. قرب السعرات مش ضمان للتوازن الغذائي.',
                  'Ingredients and quantities use the food catalog. Calorie matching does not guarantee nutritional adequacy.',
                ),
                text(
                  'الأسعار ووقت التحضير مش بيتطبقوا في المطابقة. الحالات الصحية تحتاج مراجعة مختص.',
                  'Price and preparation time are not matched. Disclosed conditions require professional review.',
                ),
                FilledButton(
                  onPressed: openPlan,
                  child: Text(t('افتح خطتي', 'Open my plan')),
                ),
                OutlinedButton(
                  onPressed: () => context.push('/recipes'),
                  child: Text(t('اختار وصفة', 'Browse recipes')),
                ),
              ]),
            ],
            if (widget.section == 3) ...[
              Wrap(
                spacing: 8,
                children: [
                  for (final n in [1, 7, 30])
                    ChoiceChip(
                      label: Text(
                        n == 1
                            ? t('اليوم', 'Today')
                            : n == 7
                            ? t('٧ أيام', '7 days')
                            : t('٣٠ يوم', '30 days'),
                      ),
                      selected: period == n,
                      onSelected: (_) => setState(() => period = n),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              ...review(d),
              if (period > 1) comparison(d),
              card(t('متابعة خطوتك', 'Your step check-in'), [
                text(
                  'المتابعة بتأكيدك أنت، من الجلسة أو الأيام اللي اخترت تحفظها. اليوم الناقص مش فشل، ومش بنستنتج تحقيق هدف من الوجبات.',
                  'Check-ins are confirmed by you, from this session or days you chose to save. Missing days are not failures. Meals do not establish goal completion.',
                ),
                ...habitReview(),
                OutlinedButton(
                  onPressed: habits,
                  child: Text(t('راجع خطوة النهاردة', 'Review today\'s step')),
                ),
              ]),
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () => context.push(
                  '/report/export',
                  extra: CoachReportSnapshot(
                    ownerUid: widget.cubit.userId,
                    goals: widget.cubit.healthProfile.goals,
                    habits: widget.cubit.chosenHabits.toList(),
                    checkins: widget.cubit.habitHistory(366),
                  ),
                ),
                label: Text(
                  t('تقرير التغذية والخطوات PDF', 'Nutrition and steps PDF'),
                ),
              ),
            ],
            OutlinedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CoachStorageScreen(cubit: widget.cubit),
                  ),
                );
                if (mounted) {
                  setState(() {
                    data = widget.cubit.readLocalReview();
                  });
                }
              },
              child: Text(
                t(
                  'حفظ الملف والخطوات في حسابي',
                  'Save profile and steps to my account',
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => setState(() {
                data = widget.cubit.readLocalReview();
              }),
              child: Text(t('حدّث من السجل', 'Refresh records')),
            ),
          ],
        );
      },
    );
  }

  Widget planSteps() => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: GlassCard(
      gradient: LinearGradient(
        colors: [
          AppColors.primaryBlue.withValues(alpha: .28),
          AppColors.aiPurple.withValues(alpha: .24),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cyanLight
                : const Color(0xFF006A80),
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t('سفرتك على مزاجك', 'Your table, your choices'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );

  Widget dashboard(int meals, int selected, int completed, CoachData d) {
    final logged = d.meals
        .map((m) => m.dateKey)
        .toSet()
        .where((date) => date.compareTo(d.todayKey) <= 0)
        .length;
    Widget metric(String label, String value, IconData icon, Color color) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: .28)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(
                  value,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SufraLustre(
        color: AppColors.cyanLight,
        child: GlassCard(
          gradient: LinearGradient(
            colors: [
              AppColors.aiPurple.withValues(alpha: .30),
              AppColors.primaryBlue.withValues(alpha: .18),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.cyanLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('ملخص يومك', 'Your day at a glance'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  metric(
                    t('وجبات النهاردة', 'Meals today'),
                    '$meals',
                    Icons.restaurant_rounded,
                    AppColors.cyanLight,
                  ),
                  const SizedBox(width: 8),
                  metric(
                    t('خطوات مؤكدة', 'Confirmed steps'),
                    '$completed / $selected',
                    Icons.check_circle_outline,
                    AppColors.greenLight,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                t(
                  '\u2066$logged\u2069 يوم ظاهر في سجل الوجبات',
                  'Meal records visible for $logged days',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dailyCard() {
    final v = widget.cubit.dailyCheckin;
    return card(t('ملاحظاتك عن النهاردة', 'Your notes for today'), [
      Text(
        t(
          'نشاط مسجل: ${v.activityMinutes == null ? 'مش مسجل' : '${v.activityMinutes} دقيقة'}',
          'Recorded activity: ${v.activityMinutes == null ? 'Not recorded' : '${v.activityMinutes} minutes'}',
        ),
      ),
      Text(
        t(
          'النوم: ${v.sleepHours == null ? 'مش مسجل' : '${v.sleepHours} ساعة'}',
          'Sleep: ${v.sleepHours == null ? 'Not recorded' : '${v.sleepHours} hours'}',
        ),
      ),
      Text(
        t('شعورك العام: ', 'General feeling: ') +
            CoachDailyCheckin.feelingLabel(v.feeling ?? '', ar),
      ),
      text(
        'للجلسة فقط. مش تقييم للصحة ولا بيانات من جهاز.',
        'Session-only. Not a health assessment or device data.',
      ),
      OutlinedButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CoachDailyCheckinScreen(cubit: widget.cubit),
            ),
          );
          if (mounted) setState(() {});
        },
        child: Text(t('سجّل أو عدّل ملاحظاتك', 'Add or edit your notes')),
      ),
      TextButton(
        onPressed: () => context.push('/reminders'),
        child: Text(t('اختار تذكيراتك ومواعيدها', 'Choose reminder times')),
      ),
    ]);
  }

  void openPlan() {
    final p = widget.cubit.healthProfile;
    context.push(
      '/planner',
      extra: PlannerFoodChoices(
        ownerUid: widget.cubit.userId,
        mealsPerDay: p.mealsPerDay,
        preferred: p.preferredFoods,
        excluded: p.excludedFoods,
        allergens: p.allergens,
        dietaryPreferences: p.dietaryRestrictions,
        requiresProfessionalReview:
            p.disclosedConditions.isNotEmpty ||
            (p.specialistGuidance?.trim().isNotEmpty ?? false) ||
            (p.age != null && p.age! < 18),
      ),
    );
  }

  Widget comparison(CoachData d) {
    final c = CoachProgressComparison(
      todayKey: d.todayKey,
      meals: d.meals,
      checkins: widget.cubit.habitHistory(period * 2),
      days: period,
    );
    Widget window(bool prior) {
      final r = prior ? c.previous : c.current;
      final checks = prior ? c.previousConfirmations : c.currentConfirmations;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              prior
                  ? t('الفترة اللي قبلها', 'Previous period')
                  : t('الفترة الحالية', 'Current period'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(c.range(prior), textDirection: TextDirection.ltr),
            Text(
              t(
                '${r.loggedDays} يوم فيه وجبات مسجلة، ${r.records.length} وجبة',
                '${r.loggedDays} ${r.loggedDays == 1 ? 'day' : 'days'} with meal records, ${r.records.length} ${r.records.length == 1 ? 'meal' : 'meals'}',
              ),
            ),
            Text(
              r.ingredientMeals == 0
                  ? t(
                      'تفاصيل المكونات غير متاحة',
                      'Ingredient details unavailable',
                    )
                  : t(
                      '${r.ingredientFoods} مكون مختلف، تفاصيل ${r.ingredientMeals} من ${r.records.length} وجبة',
                      '${r.ingredientFoods} distinct ingredients, details for ${r.ingredientMeals} of ${r.records.length} meals',
                    ),
            ),
            Text(
              t(
                '$checks تأكيد خطوة مسجل',
                '$checks recorded step ${checks == 1 ? 'check-in' : 'check-ins'}',
              ),
            ),
          ],
        ),
      );
    }

    final action = c.nextAction;
    final message = switch (action) {
      'diary' => t(
        'مفيش وجبات ظاهرة في الفترة دي. لو حابب، ابدأ بسجل وجبة.',
        'No meals are visible in this period. If you want, start with one meal record.',
      ),
      'ingredients' => t(
        'بعض الوجبات من غير تفاصيل مكونات. راجع وجبة وأضف التفاصيل اللي تعرفها بدل التخمين.',
        'Some meals lack ingredient details. Review one and add only the details you know.',
      ),
      'checkin' => t(
        'فيه وجبات مسجلة، لكن مفيش تأكيد خطوة ظاهر. اختار خطوة بسيطة وراجعها بنفسك.',
        'Meal records are present, but no step check-in is visible. Choose a small step and check it yourself.',
      ),
      _ => t(
        'فيه وجبات وتأكيدات مسجلة. لو ظروفك اتغيرت، راجع خطة الوجبات وعدّل اللي يناسبك.',
        'Meal records and check-ins are present. If your circumstances changed, review and edit your meal plan.',
      ),
    };
    return card(t('المسجل عبر فترتين', 'Records across two periods'), [
      window(false),
      window(true),
      text(
        'أرقام السجل مش تقييم للصحة أو تحقيق الأهداف. الناقص غير معروف. المتاح من تأكيداتك المحفوظة آخر ٦٢ سجل.',
        'Recorded counts, not health or goal achievement. Missing entries are unknown. Saved check-ins: latest 62 records.',
      ),
      Text(
        t('خطوة ممكنة بعد كده', 'A possible next step'),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      Text(message),
      TextButton(
        onPressed: action == 'checkin'
            ? habits
            : action == 'plan'
            ? openPlan
            : () => context.push('/diary'),
        child: Text(
          action == 'checkin'
              ? t('راجع خطوتك', 'Review your step')
              : action == 'plan'
              ? t('راجع خطتك', 'Review your plan')
              : t('افتح اليومية', 'Open diary'),
        ),
      ),
    ]);
  }

  List<Widget> habitReview() {
    final history = widget.cubit.habitHistory(period);
    final days = history.values.where((v) => v.isNotEmpty).length;
    final count = history.values.fold<int>(0, (n, v) => n + v.length);
    final labels = {
      'log_meal': t('تسجيل وجبة', 'Log one meal'),
      'prepare_meal': t('تجهيز وجبة', 'Prepare for a meal'),
      'review_ingredients': t('مراجعة المكونات', 'Review ingredients'),
    };
    final dates = history.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      Text(
        t(
          '$count تأكيد على $days يوم في الفترة',
          '$count ${count == 1 ? 'check-in' : 'check-ins'} across $days ${days == 1 ? 'day' : 'days'} in this period',
        ),
      ),
      for (final date in dates.where((d) => history[d]!.isNotEmpty))
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            children: [
              Text(date, textDirection: TextDirection.ltr),
              Text(history[date]!.map((id) => labels[id]!).join('، ')),
            ],
          ),
        ),
    ];
  }

  List<Widget> review(CoachData d) {
    final review = WeeklyPersonalReview(
      todayKey: d.todayKey,
      meals: d.meals,
      windowDays: period,
    );
    final records = review.records;
    final days = review.loggedDays;
    final details = review.ingredientMeals;
    final foods = review.ingredientFoods;
    final metrics = <Widget>[];
    for (final item in <(String, double? Function(MealEntryModel))>[
      (t('البروتين', 'Protein'), (m) => m.totalProtein),
      (t('الألياف', 'Fiber'), (m) => m.totalFiber),
    ]) {
      final measured = review.measuredAverage(item.$2);
      metrics.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${item.$1}: ${measured.average == null ? t('غير معروف', 'Unknown') : '${measured.average!.toStringAsFixed(1)} ${t('جم/يوم مسجل', 'g/logged day')}'} (${measured.days}/$days ${t('أيام بقيم كاملة', 'days with complete values')})',
          ),
        ),
      );
    }
    return [
      card(t('تغطية السجل', 'Record coverage'), [
        Text(
          t(
            '$days يوم مسجل من $period، بعدد ${records.length} وجبة',
            '$days of $period days logged, ${records.length} meals',
          ),
        ),
        text(
          'الأيام الناقصة مش صفر أكل، والمراجعة مش حكم على الالتزام بالخطة.',
          'Missing days do not mean zero food. This is not a plan-adherence score.',
        ),
        Text(
          t(
            'تنوّع المكونات: ${details == 0 ? 'غير معروف' : foods}، تفاصيل متاحة لـ $details من ${records.length} وجبة',
            'Ingredient variety: ${details == 0 ? 'Unknown' : foods}. Details for $details of ${records.length} meals.',
          ),
        ),
      ]),
      card(t('متوسط المسجل فقط', 'Recorded averages only'), [
        ...metrics,
        text(
          'اليوم اللي فيه قيمة ناقصة مستبعد من متوسط العنصر ده. مفيش استنتاج إن أكلك متوازن من الأرقام دي.',
          'A day with a missing value is excluded from that nutrient average. These values do not establish dietary adequacy.',
        ),
      ]),
    ];
  }

  Widget source(String label, String url) => TextButton(
    onPressed: () async {
      try {
        final ok = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SufraSnackBar(
              content: Text(t('تعذر فتح المصدر', 'Could not open source')),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SufraSnackBar(
              content: Text(t('تعذر فتح المصدر', 'Could not open source')),
            ),
          );
        }
      }
    },
    child: Text(label),
  );
}

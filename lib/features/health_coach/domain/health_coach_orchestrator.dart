import 'coach_history_summary.dart';
import '../../meal_log/domain/catalog_meal_draft.dart';
import 'coach_conversation_tools.dart';
import 'health_coach_profile.dart';
import 'coach_output_safety.dart';

enum CoachReplyOrigin { ai, safety, unavailable }

enum CoachActionKind { previewMealPlan, previewFoodLog, previewMemory }

/// A model can propose a preview, never commit a side effect.
class CoachActionProposal {
  const CoachActionProposal({required this.kind, required this.payload});
  final CoachActionKind kind;
  final Map<String, Object?> payload;
}

class HealthCoachReply {
  const HealthCoachReply({
    required this.text,
    required this.origin,
    this.sourceIds = const [],
    this.proposals = const [],
    this.trustedToolStats = const {},
    this.calculationValues,
  });
  final String text;
  final CoachReplyOrigin origin;
  final List<String> sourceIds;
  final List<CoachActionProposal> proposals;
  final Map<String, String> trustedToolStats;
  final List<double?>? calculationValues;
}

class HealthCoachRequest {
  const HealthCoachRequest({
    required this.question,
    required this.locale,
    required this.context,
  });
  final String question;
  final String locale;
  final Map<String, Object> context;
}

abstract interface class HealthCoachProvider {
  /// Implementations call a trusted backend, never a model API with a client key.
  Future<HealthCoachReply> generate(HealthCoachRequest request);
}

/// Cancels in-flight transport without granting any tool or storage access.
abstract interface class CancellableCoachProvider {
  void cancelPending();
}

/// A conservative local preflight, not a medical classifier or safety guarantee.
/// Further server input/output checks and specialist-reviewed test cases are
/// required before a live provider is enabled.
class CoachSafetyPreflight {
  const CoachSafetyPreflight();
  String? refusal(String question, HealthCoachProfile profile, String locale) {
    final ar = locale == 'ar';
    final q = question
        .toLowerCase()
        .replaceAll(RegExp('[أإآ]'), 'ا')
        .replaceAll(RegExp(r'[ً-ْ]'), '');
    const emergencies = [
      'chest pain',
      'cannot breathe',
      "can't breathe",
      'trouble breathing',
      'anaphylaxis',
      'suicid',
      'الم في الصدر',
      'مش قادر اتنفس',
      'اختناق',
      'اغماء',
      'انتحار',
    ];
    if (emergencies.any(q.contains)) {
      return ar
          ? 'الأعراض اللي وصفتها ممكن تحتاج مساعدة عاجلة. اتصل بالطوارئ المحلية أو اطلب من شخص قريب يساعدك دلوقتي. ما تستناش رد المدرب، وما تستخدمش خطة أكل لعلاج الحالة.'
          : 'The symptoms you describe may need urgent help. Contact local emergency services or ask someone nearby for help now. Do not wait for this coach or use a meal plan to treat this.';
    }
    const clinical = [
      'insulin dose',
      'change my dose',
      'diagnose',
      'stop medication',
      'جرعة',
      'جرعه',
      'شخص مرض',
      'تشخيص',
      'اوقف الدواء',
      'وقف الدوا',
    ];
    const extreme = [
      'starve',
      'purge',
      '500 calorie',
      '500 سعرة',
      '500 سعره',
      'تجويع',
      'تقيؤ',
      'تجويع',
    ];
    if ([...clinical, ...extreme].any(q.contains)) {
      return ar
          ? 'مش هقدر أشخّص مرض أو أحدد جرعة دواء أو أساعد في حمية قاسية. راجع طبيبك أو مختص تغذية مؤهل. أقدر أساعدك بأسئلة عامة أو تنظيم سجل تعرضه عليهم.'
          : 'I cannot diagnose, set medication doses, or help with extreme diets. Consult your clinician or a qualified dietitian. I can help with general questions or organizing records to discuss with them.';
    }
    final severeAllergy = RegExp(
      r'(?:severe|serious).{0,35}allerg|(?:allerg).{0,35}(?:severe|serious)|حساسي[ةه].{0,40}(?:شديد|مفرط)',
    ).hasMatch(q);
    if (severeAllergy) {
      return ar
          ? 'مش هقدر أأكد إن الوجبة آمنة لحساسية شديدة. اتأكد من المكونات واحتمال التلامس مع مسبب الحساسية مع مقدم الأكل، ولو مش متأكد بلاش تعتمد على الرد ده أو الصورة. اتبع خطة طبيبك، ولو فيه أعراض طارئة اطلب الطوارئ فورًا.'
          : "I cannot confirm a meal is safe for a severe allergy. Check ingredients and possible cross-contact with whoever prepared it. If unsure, do not rely on this chat or a photo. Follow your clinician's plan; for emergency symptoms seek emergency help now.";
    }
    // Known high-risk status is applied outside model discretion.
    final needsClinicalPlan = [
      'plan',
      'diet',
      'weight loss',
      'خطة',
      'خس',
      'رجيم',
    ].any(q.contains);
    if (needsClinicalPlan &&
        (profile.disclosedConditions.isNotEmpty ||
            [
              'pregnan',
              'breastfeed',
              'kidney disease',
              'diabet',
              'eating disorder',
              'حامل',
              'رضاعة',
              'رضاعه',
              'كلى',
              'سكري',
              'سكر',
              'اضطراب اكل',
            ].any(q.contains) ||
            (profile.age != null && profile.age! < 18))) {
      return ar
          ? 'بسبب المعلومات الصحية اللي شاركتها، مش هولّد خطة وزن أو علاج مستقلة. لازم الخطة تتراجع مع مختص. نقدر نشتغل على تنظيم الوجبات والسجلات بدون تغيير تعليمات المختص.'
          : 'Given the health information you shared, I will not generate an independent weight or treatment plan. A qualified professional should review it. We can organize meals and records without changing their guidance.';
    }
    return null;
  }
}

class HealthCoachOrchestrator {
  HealthCoachOrchestrator({
    required this.provider,
    this.safety = const CoachSafetyPreflight(),
    this.outputSafety = const CoachOutputSafety(),
    this.conversationTools,
  });
  final HealthCoachProvider provider;
  final CoachSafetyPreflight safety;
  final CoachOutputSafety outputSafety;
  final CoachConversationTools? conversationTools;

  int _requestGeneration = 0;

  void cancelPending() {
    _requestGeneration++;
    final p = provider;
    if (p is CancellableCoachProvider) {
      (p as CancellableCoachProvider).cancelPending();
    }
  }

  Future<HealthCoachReply> ask({
    required String question,
    required String locale,
    required HealthCoachConsent consent,
    required HealthCoachProfile profile,
    List<CoachRecordFact> facts = const [],
    List<String> history = const [],
    List<String> approvedMemories = const [],
    CatalogMealDraft? reviewedCalculation,
    CoachHistorySummary? reviewedHistory,
  }) async {
    final myGeneration = _requestGeneration;
    void active() {
      if (myGeneration != _requestGeneration) {
        throw StateError('Request cancelled');
      }
    }

    final ar = locale == 'ar';
    final trimmed = question.trim();
    if (trimmed.isEmpty || trimmed.length > 2000) {
      throw ArgumentError('Question length');
    }
    final blocked = safety.refusal(trimmed, profile, locale);
    if (blocked != null) {
      return HealthCoachReply(text: blocked, origin: CoachReplyOrigin.safety);
    }
    if (!consent.externalAi) {
      return HealthCoachReply(
        text: ar
            ? 'فعّل المحادثة من إعدادات المدرب عشان تسألني. تقدر تتابع يومك وخطتك من غير تفعيلها.'
            : 'The online Coach is off. You can use local records and planning tools, or review context-sharing choices first.',
        origin: CoachReplyOrigin.unavailable,
      );
    }
    final context = const CoachContextBuilder().build(
      consent: consent,
      profile: profile,
      facts: facts,
      recentConversation: history,
      approvedMemories: approvedMemories,
    );
    if (reviewedCalculation != null) {
      if (!reviewedCalculation.canSave ||
          reviewedCalculation.portions.length > 8) {
        throw StateError('Invalid reviewed calculation');
      }
      context['reviewedCalculation'] = [
        for (final p in reviewedCalculation.portions)
          {'foodId': p.food.foodId, 'grams': p.grams},
      ];
    }
    if (reviewedHistory != null) {
      context['reviewedHistory'] = reviewedHistory.toContext();
    }
    try {
      CoachGroundedCalculation? calculation = reviewedCalculation == null
          ? null
          : CoachGroundedCalculation(
              reviewedCalculation.totals!.energyKcal,
              reviewedCalculation.totals!.proteinG,
              reviewedCalculation.portions
                  .map((p) => p.food.source ?? '')
                  .toList(),
            );
      final tools = conversationTools;
      final planner = provider;
      if (tools != null && planner is CoachToolPlanner) {
        final request = await (planner as CoachToolPlanner).selectCalculation(
          trimmed,
        );
        active();
        if (request != null) calculation = await tools.execute(request);
        active();
      }
      active();
      final reply = await provider.generate(
        HealthCoachRequest(question: trimmed, locale: locale, context: context),
      );
      active();
      if (reviewedCalculation != null &&
          reply.origin == CoachReplyOrigin.ai &&
          (reply.calculationValues == null ||
              (reply.calculationValues![0]! - calculation!.energyKcal).abs() >
                  0.000001 ||
              (reply.calculationValues![1] == null) !=
                  (calculation.proteinG == null) ||
              (calculation.proteinG != null &&
                  (reply.calculationValues![1]! - calculation.proteinG!).abs() >
                      0.000001))) {
        throw StateError('Catalog calculation mismatch');
      }
      if (!const {
            CoachReplyOrigin.ai,
            CoachReplyOrigin.safety,
          }.contains(reply.origin) ||
          reply.text.trim().isEmpty ||
          !outputSafety.accepts(reply.text) ||
          reply.proposals.isNotEmpty) {
        throw StateError('Invalid provider reply');
      }
      return HealthCoachReply(
        text: reply.text,
        origin: reply.origin,
        sourceIds: reply.sourceIds,
        proposals: reply.proposals,
        trustedToolStats:
            reviewedHistory?.display(ar) ??
            calculation?.display(ar) ??
            const {},
      );
    } catch (_) {
      return HealthCoachReply(
        text: ar
            ? 'مش قادر أرد دلوقتي. جرّب بعد شوية؛ يومياتك وخطتك لسه متاحين.'
            : 'The Coach is unavailable or the free allowance has been reached. No generated answer is available. Your local records and tools still work.',
        origin: CoachReplyOrigin.unavailable,
      );
    }
  }
}

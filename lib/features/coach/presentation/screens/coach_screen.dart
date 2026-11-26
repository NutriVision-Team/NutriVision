import '../../../meal_log/domain/catalog_meal_draft.dart';
import '../../../camera_analysis/presentation/camera_analysis_screen.dart';
import '../../../health_coach/domain/coach_reviewed_explanation.dart';
import '../../../../core/widgets/sufra_lustre.dart';
import 'coach_workspace_panel.dart';
import 'coach_recipe_panel.dart';
import 'coach_food_calculator_panel.dart';
import 'coach_habits_screen.dart';
import '../../../planner/domain/planner_food_choices.dart';
import 'package:go_router/go_router.dart';
import 'coach_tools_sheet.dart';
import '../../../health_coach/presentation/screens/coach_health_settings_screen.dart';
import '../../../home/presentation/widgets/local_profile_avatar.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import '../../../../core/theme/app_theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';
import '../../../voice_logging/data/dictation_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../planning_shared/presentation/planning_widgets.dart';
import '../../domain/coach_engine.dart';
import '../cubit/coach_cubit.dart';

/// Screen 27 — Smart Coach (مدرّب سفرة), rule-based baseline.
class CoachScreen extends StatefulWidget {
  const CoachScreen({
    super.key,
    required this.cubit,
    this.dictation,
    this.initialReviewedDraft,
  });

  static const routePath = '/coach';

  final CoachCubit cubit;
  final DictationService? dictation;
  final CatalogMealDraft? initialReviewedDraft;

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.cubit.state.status == CoachStatus.loading) {
      widget.cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: PlanningScaffold(
        currentNavIndex: -1,
        avoidNavigationOverlap: true,
        child: BlocBuilder<CoachCubit, CoachState>(
          builder: (context, state) {
            switch (state.status) {
              case CoachStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case CoachStatus.error:
                return PlanningError(
                  onRetry: () => context.read<CoachCubit>().load(),
                );
              case CoachStatus.ready:
                return _CoachBody(
                  state: state,
                  dictation: widget.dictation,
                  initialReviewedDraft: widget.initialReviewedDraft,
                );
            }
          },
        ),
      ),
    );
  }
}

class _CoachBody extends StatefulWidget {
  const _CoachBody({
    required this.state,
    this.dictation,
    this.initialReviewedDraft,
  });

  final CoachState state;
  final DictationService? dictation;
  final CatalogMealDraft? initialReviewedDraft;

  @override
  State<_CoachBody> createState() => _CoachBodyState();
}

class _CoachBodyState extends State<_CoachBody> with WidgetsBindingObserver {
  Future<void> _explainReviewed(CatalogMealDraft draft) async {
    final c = context.read<CoachCubit>();
    c.assertActive();
    final ar = c.locale == 'ar';
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          ar ? 'شارك الوجبة مع المدرّب؟' : 'Share this meal with Coach?',
        ),
        content: SingleChildScrollView(
          child: Text(
            '${draft.portions.map((p) => '${p.food.name} (${p.food.foodState}) \u2066${p.grams} g\u2069').join('\n')}\n\n${ar ? 'هيتبعت الأكل والجرامات اللي راجعتها بس للشرح. من غير الصورة أو حفظ الوجبة.' : 'Only reviewed foods and grams are sent for explanation. No image or meal save.'}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ar ? 'رجوع' : 'Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ar ? 'شارك واشرح' : 'Share and explain'),
          ),
        ],
      ),
    );
    c.assertActive();
    if (approved == true &&
        c.externalQuestionEnabled &&
        !c.state.thinking &&
        !c.state.sendFailure) {
      await c.send(
        reviewedCalculationQuestion(draft, c.locale),
        reviewedCalculation: draft,
      );
    }
  }

  int _section = 1;
  bool _showChatActions = false;
  int _lastEntryCount = 0;
  final _input = TextEditingController();
  final _scroll = ScrollController();

  late final DictationService _dictation;
  late final int _lease;
  bool _acceptTranscript = false;
  bool _active = true;
  String _beforeDictation = '';
  String _lastApplied = '';

  @override
  void initState() {
    super.initState();
    _dictation = widget.dictation ?? PlatformDictationService.shared;
    _lease = _dictation.acquire();
    _dictation.addListener(_onDictation);
    WidgetsBinding.instance.addObserver(this);
  }

  void _stopDictation() {
    _acceptTranscript = false;
    unawaited(_dictation.stop(_lease));
  }

  void _onDictation() {
    if (!mounted || !_active) return;
    if (_acceptTranscript && _dictation.text.isNotEmpty) {
      if (_input.text != _lastApplied) {
        // A manual edit wins over every late recognizer result.
        _stopDictation();
      } else {
        final words = _dictation.text;
        final next = _beforeDictation.trim().isEmpty
            ? words
            : '${_beforeDictation.trimRight()} $words';
        _lastApplied = next;
        _input.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    }
    setState(() {});
  }

  Future<void> _toggleDictation() async {
    if (_dictation.status == DictationStatus.starting ||
        _dictation.status == DictationStatus.listening) {
      _stopDictation();
      return;
    }
    final l10n = context.l10n;
    final approved = await showSufraDialog<bool>(
      context: context,
      builder: (context) => SufraAlertDialog(
        content: Text(l10n.coachVoicePrivacy),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.coachVoiceCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.coachVoiceStart),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    _beforeDictation = _input.text;
    _lastApplied = _input.text;
    _acceptTranscript = true;
    await _dictation.start(
      _lease,
      Localizations.localeOf(context).languageCode,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stopDictation();
  }

  @override
  void deactivate() {
    _active = false;
    _stopDictation();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  @override
  void dispose() {
    _acceptTranscript = false;
    WidgetsBinding.instance.removeObserver(this);
    _dictation.removeListener(_onDictation);
    _dictation.release(_lease);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = widget.state;
    final coachForCalculation = context.read<CoachCubit>();
    if (state.thinking || state.entries.length != _lastEntryCount) {
      _lastEntryCount = state.entries.length;
      _scrollToEnd();
    }
    final large = MediaQuery.textScalerOf(context).scale(11) > 15;
    Widget messageArea(Widget child) => large ? child : Expanded(child: child);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final sections = ar
        ? ['نظرة عامة', 'المحادثة', 'خطتي', 'تقدمي', 'اتعلم']
        : ['Overview', 'Chat', 'My plan', 'Progress', 'Learn'];
    final sectionPicker = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<int>(
        key: ValueKey('coach_section_selector_$_section'),
        initialValue: _section,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: ar ? 'أقسام مدربك' : 'Coach sections',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        items: [
          for (var i = 0; i < sections.length; i++)
            DropdownMenuItem(
              value: i,
              child: Text(sections[i], key: ValueKey('coach_section_$i')),
            ),
        ],
        onChanged: (value) {
          if (value == null) return;
          _stopDictation();
          setState(() => _section = value);
        },
      ),
    );
    if (_section != 1) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
            child: _CoachHeader(hasRecords: state.hasRecords),
          ),
          sectionPicker,
          const SizedBox(height: 12),
          Expanded(
            child: CoachWorkspacePanel(
              cubit: context.read<CoachCubit>(),
              section: _section,
              onChat: () => setState(() => _section = 1),
            ),
          ),
        ],
      );
    }
    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: _CoachHeader(hasRecords: state.hasRecords),
        ),
        sectionPicker,
        const SizedBox(height: 8),
        messageArea(
          ListView(
            controller: large ? null : _scroll,
            shrinkWrap: large,
            physics: large ? const NeverScrollableScrollPhysics() : null,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            children: [
              TextButton.icon(
                key: const ValueKey('coach_local_tools'),
                onPressed: state.thinking
                    ? null
                    : () {
                        _stopDictation();
                        final profile = context
                            .read<CoachCubit>()
                            .healthProfile;
                        showCoachTools(
                          context,
                          onHabits: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CoachHabitsScreen(
                                cubit: context.read<CoachCubit>(),
                              ),
                            ),
                          ),
                          foodChoices: PlannerFoodChoices(
                            ownerUid: context.read<CoachCubit>().userId,
                            mealsPerDay: profile.mealsPerDay,
                            allergens: List.unmodifiable(profile.allergens),
                            dietaryPreferences: List.unmodifiable(
                              profile.dietaryRestrictions,
                            ),
                            requiresProfessionalReview:
                                profile.disclosedConditions.isNotEmpty ||
                                (profile.specialistGuidance
                                        ?.trim()
                                        .isNotEmpty ??
                                    false) ||
                                (profile.age != null && profile.age! < 18),
                            preferred: List.unmodifiable(
                              profile.preferredFoods,
                            ),
                            excluded: List.unmodifiable(profile.excludedFoods),
                          ),
                        );
                      },
                icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
                label: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'يومك وخطتك'
                      : 'Your day and plan',
                ),
              ),
              if (coachForCalculation.externalQuestionEnabled)
                OutlinedButton.icon(
                  key: const ValueKey('coach_review_history'),
                  icon: const Icon(Icons.history),
                  label: Text(
                    ar
                        ? 'راجع سجلي مع المدرّب'
                        : 'Review my records with Coach',
                  ),
                  onPressed: state.thinking || state.sendFailure
                      ? null
                      : () async {
                          final c = coachForCalculation;
                          final days = await showDialog<int>(
                            context: context,
                            builder: (ctx) => SimpleDialog(
                              title: Text(
                                ar ? 'اختار الفترة' : 'Choose recorded period',
                              ),
                              children: [
                                for (final d in [7, 30, 0])
                                  SimpleDialogOption(
                                    onPressed: () => Navigator.pop(ctx, d),
                                    child: Text(
                                      d == 0
                                          ? (ar
                                                ? 'كل السجل المتاح'
                                                : 'All available records')
                                          : (ar
                                                ? 'آخر $d يوم'
                                                : 'Last $d days'),
                                    ),
                                  ),
                              ],
                            ),
                          );
                          if (days == null || !context.mounted) return;
                          try {
                            final summary = await c.previewHistory(days);
                            if (!context.mounted) return;
                            final approved = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                  ar
                                      ? 'شارك الملخص ده؟'
                                      : 'Share this summary?',
                                ),
                                content: SingleChildScrollView(
                                  child: Text(
                                    '${summary.display(ar).entries.map((e) => '${e.key}: \u2066${e.value}\u2069').join('\n')}\n\n${ar ? 'دي الوجبات المؤكدة المسجلة بس. الأيام الناقصة مش صفر أكل. هيتبعت الملخص للذكاء الاصطناعي للشرح، من غير أسماء وجبات أو معرفات أو حفظ جديد.' : 'Only confirmed recorded meals. Missing days are unknown, not zero intake. This summary is sent to AI for explanation, without meal names, IDs or new writes.'}',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(ar ? 'رجوع' : 'Back'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(
                                      ar ? 'شارك وراجع' : 'Share and review',
                                    ),
                                  ),
                                ],
                              ),
                            );
                            c.assertActive();
                            if (approved != true ||
                                !c.externalQuestionEnabled ||
                                c.state.thinking ||
                                c.state.sendFailure) {
                              return;
                            }
                            await c.send(
                              ar
                                  ? 'راجع ملخص سجلاتي للفترة المختارة. وضح حدود البيانات واقترح خطوة عامة، من غير أرقام في الشرح أو افتراض إن الأيام الناقصة أصفار.'
                                  : 'Review my selected record summary. Explain the coverage and suggest a general next step without numbers in prose or assuming missing days are zero.',
                              reviewedHistory: summary,
                            );
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ar
                                        ? 'مش قادر أقرأ السجل دلوقتي. مفيش بيانات اتبعتت.'
                                        : 'Cannot read records now. No data sent.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                ),
              if (coachForCalculation.externalQuestionEnabled)
                OutlinedButton.icon(
                  key: const ValueKey('coach_review_photo'),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    ar
                        ? 'حلّل صورة وجبة وراجعها مع المدرّب'
                        : 'Review a meal photo with Coach',
                  ),
                  onPressed: state.thinking || state.sendFailure
                      ? null
                      : () async {
                          final c = coachForCalculation;
                          final draft = await context.push<CatalogMealDraft>(
                            CameraAnalysisScreen.routePath,
                            extra: 'coach-reviewed-draft',
                          );
                          if (draft == null || !context.mounted) return;
                          c.assertActive();
                          if (!c.externalQuestionEnabled ||
                              c.state.thinking ||
                              c.state.sendFailure) {
                            return;
                          }
                          final approved = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                ar
                                    ? 'راجع الأكل مع المدرّب؟'
                                    : 'Review these foods with Coach?',
                              ),
                              content: SingleChildScrollView(
                                child: Text(
                                  '${draft.portions.map((p) => '${p.food.name} (${p.food.foodState}) \u2066${p.grams} g\u2069').join('\n')}\n\n${ar ? 'هيتبعت اختيار الأصناف والأوزان فقط للحساب والشرح. الصورة نفسها مش هتتبعت للشات. مفيش حفظ وجبة.' : 'Only reviewed foods and weights are sent for source calculation and explanation. The photo is not sent to chat. No meal is saved.'}',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(ar ? 'رجوع' : 'Back'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(
                                    ar ? 'شارك وراجع' : 'Share and review',
                                  ),
                                ),
                              ],
                            ),
                          );
                          c.assertActive();
                          if (approved == true &&
                              c.externalQuestionEnabled &&
                              !c.state.thinking &&
                              !c.state.sendFailure) {
                            await c.send(
                              reviewedCalculationQuestion(draft, c.locale),
                              reviewedCalculation: draft,
                            );
                          }
                        },
                ),
              if (widget.initialReviewedDraft case final CatalogMealDraft draft)
                OutlinedButton.icon(
                  key: const ValueKey('coach_explain_reviewed_meal'),
                  icon: const Icon(Icons.restaurant_menu),
                  label: Text(
                    ar
                        ? 'اشرح الوجبة اللي راجعتها'
                        : 'Explain the reviewed meal',
                  ),
                  onPressed:
                      coachForCalculation.externalQuestionEnabled &&
                          !state.thinking &&
                          !state.sendFailure
                      ? () => _explainReviewed(draft)
                      : null,
                ),
              const CoachRecipePanel(),
              CoachFoodCalculatorPanel(
                key: ValueKey(coachForCalculation.userId),
                onExplain:
                    coachForCalculation.externalQuestionEnabled &&
                        !state.thinking &&
                        !state.sendFailure
                    ? (draft) async {
                        final cubit = coachForCalculation;
                        cubit.assertActive();
                        if (!cubit.externalQuestionEnabled ||
                            cubit.state.thinking ||
                            cubit.state.sendFailure) {
                          throw StateError('Coach unavailable');
                        }
                        final question = reviewedCalculationQuestion(
                          draft,
                          cubit.locale,
                        );
                        await cubit.send(question, reviewedCalculation: draft);
                      }
                    : null,
              ),
              Center(child: _Pill(label: l10n.coachToday, dashed: false)),
              const SizedBox(height: 6),
              Center(
                child: _Pill(
                  label: state.hasRecords
                      ? (context.read<CoachCubit>().externalQuestionEnabled
                            ? (Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? 'اسألني عن الأكل، أو افتح ملخص يومك.'
                                  : 'Ask about food or open your daily summary.')
                            : l10n.coachReviewNote)
                      : l10n.coachNoRecordsNote,
                  dashed: true,
                ),
              ),
              const SizedBox(height: 12),
              if (state.entries.isEmpty)
                _CoachBubble(
                  entry: CoachEntry(
                    id: 'local-welcome',
                    isUser: false,
                    text: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'أهلاً بيك في سفرة. اسألني عن أكلك، أو نراجع يومك من سجلاتك. لو معلومة ناقصة هقولك. المدرب مش بديل للطبيب.'
                        : 'Welcome to Sufra. Ask about food or review your daily logs. I will flag missing information. Your coach does not replace medical care.',
                  ),
                ),
              for (final entry in state.entries)
                entry.isUser
                    ? _UserBubble(entry: entry)
                    : _CoachBubble(entry: entry),
              if (state.thinking)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('coach_expand_actions'),
            onPressed: () =>
                setState(() => _showChatActions = !_showChatActions),
            icon: Icon(
              _showChatActions ? Icons.expand_less : Icons.add_circle_outline,
              size: 18,
            ),
            label: Text(ar ? 'تسجيل وخطوات سريعة' : 'Log and quick prompts'),
          ),
        ),
        if (_showChatActions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final action in <(IconData, String, String)>[
                  (
                    Icons.restaurant_outlined,
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'سجّل وجبتك'
                        : 'Log a meal',
                    '/log',
                  ),
                  (
                    Icons.water_drop_outlined,
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'سجّل المية'
                        : 'Log water',
                    '/water',
                  ),
                  (
                    Icons.today_outlined,
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'راجع يومك'
                        : 'Review your day',
                    '/diary',
                  ),
                ])
                  ActionChip(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .3),
                    ),
                    avatar: Icon(action.$1, size: 16),
                    label: Text(action.$2),
                    onPressed: state.thinking
                        ? null
                        : () => context.push(action.$3),
                  ),
              ],
            ),
          ),
        if (state.sendFailure)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.coachSendFailed,
                  style: const TextStyle(
                    color: AppColors.orangeLight,
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: state.thinking
                      ? null
                      : () => context.read<CoachCubit>().retryPending(),
                  child: Text(l10n.stateRetry),
                ),
              ],
            ),
          ),
        if (_showChatActions && large)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final prompt in RuleBasedCoach.quickPrompts)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: _QuickChip(
                      label: _quickLabel(context, prompt),
                      onTap: state.thinking
                          ? null
                          : () {
                              _stopDictation();
                              _scrollToEnd();
                              context.read<CoachCubit>().send(
                                '',
                                quickId: prompt,
                              );
                            },
                    ),
                  ),
              ],
            ),
          )
        else if (_showChatActions)
          SizedBox(
            height: large ? 82 : 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final prompt in RuleBasedCoach.quickPrompts)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: _QuickChip(
                      label: _quickLabel(context, prompt),
                      onTap: state.thinking
                          ? null
                          : () {
                              _stopDictation();
                              _scrollToEnd();
                              context.read<CoachCubit>().send(
                                '',
                                quickId: prompt,
                              );
                            },
                    ),
                  ),
              ],
            ),
          ),
        if (_dictation.status != DictationStatus.idle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _dictation.status == DictationStatus.listening ||
                      _dictation.status == DictationStatus.starting
                  ? l10n.coachVoiceListening
                  : l10n.coachVoiceUnavailable,
              style: TextStyle(color: context.planningMuted, fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            padding: const EdgeInsetsDirectional.only(start: 6, end: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.coachVoiceStart,
                  onPressed: state.thinking ? null : _toggleDictation,
                  icon: Icon(
                    _dictation.status == DictationStatus.listening ||
                            _dictation.status == DictationStatus.starting
                        ? Icons.stop_circle_outlined
                        : Icons.mic_none,
                    color: AppColors.orangeLight,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    onChanged: (_) => _stopDictation(),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: l10n.coachInputHint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                SufraControlFeedback(
                  radius: 20,
                  overlay: true,
                  child: GestureDetector(
                    onTap: state.thinking ? null : _send,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.aiPurple, AppColors.turquoise],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x807C3AED),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return large
        ? SingleChildScrollView(controller: _scroll, child: body)
        : body;
  }

  void _send() {
    _stopDictation();
    final text = _input.text;
    if (text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    _input.clear();
    _scrollToEnd();
    context.read<CoachCubit>().send(text);
  }

  static String _quickLabel(BuildContext context, String id) {
    final l10n = context.l10n;
    switch (id) {
      case 'plan_tomorrow':
        return l10n.coachQuickPlan;
      case 'analyze_week':
        return l10n.coachQuickWeek;
      default:
        return l10n.coachQuickWater;
    }
  }
}

class _CoachHeader extends StatelessWidget {
  const _CoachHeader({required this.hasRecords});

  final bool hasRecords;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CoachCubit>();
    final externalEnabled = cubit.externalQuestionEnabled;
    final large =
        MediaQuery.textScalerOf(context).scale(12) > 17 ||
        MediaQuery.sizeOf(context).width < 370;
    Widget flexible(Widget child) => Expanded(child: child);
    return SufraLustre(
      radius: 22,
      color: AppColors.purpleLight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              AppColors.aiPurple.withValues(alpha: 0.3),
              AppColors.turquoise.withValues(alpha: 0.12),
            ],
          ),
          border: Border.all(
            color: AppColors.purpleLight.withValues(alpha: 0.35),
          ),
        ),
        child: Flex(
          direction: Axis.horizontal,
          crossAxisAlignment: large
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            IconButton(
              tooltip: Localizations.localeOf(context).languageCode == 'ar'
                  ? 'إعدادات المدرب والخصوصية'
                  : 'Coach settings and privacy',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () {
                final cubit = context.read<CoachCubit>();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CoachHealthSettingsScreen(
                      profile: cubit.healthProfile,
                      contextSharingAvailable: cubit.contextSharingAvailable,
                      providerAvailable: cubit.healthOrchestrator != null,
                      consent: cubit.healthConsent,
                      onSave: (p, c) {
                        if (!cubit.inactive) cubit.updateHealthChoices(c, p);
                      },
                    ),
                  ),
                );
              },
            ),
            if (!large) const _CoachAvatar(size: 46, online: true),
            SizedBox(width: large ? 0 : 12, height: large ? 8 : 0),
            flexible(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.coachTitle,
                    style: TextStyle(
                      fontFamily:
                          Localizations.localeOf(context).languageCode == 'ar'
                          ? 'Cairo'
                          : AppTheme.displayFontFamily,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    externalEnabled
                        ? (Localizations.localeOf(context).languageCode == 'ar'
                              ? (cubit.healthConsent.profileContext ||
                                        cubit.healthConsent.recordContext ||
                                        cubit.healthConsent.conversationContext
                                    ? 'بالبيانات اللي اخترت تشاركها'
                                    : 'سؤالك بس، من غير مشاركة سجلاتك')
                              : (cubit.healthConsent.profileContext ||
                                        cubit.healthConsent.recordContext ||
                                        cubit.healthConsent.conversationContext
                                    ? 'Using the data you chose to share'
                                    : 'Your question only, no records shared'))
                        : (cubit.healthOrchestrator != null
                              ? (Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'المحادثة مقفولة من الإعدادات'
                                    : 'Chat is turned off in settings')
                              : (hasRecords
                                    ? l10n.coachStatusReviewing
                                    : l10n.coachStatusIdle)),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.greenLight
                          : const Color(0xFF166534),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Daily tools are already labeled below the compact large-type header.
            // The badge follows active consent, not provider capability alone.
            if (!large)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.orangeLight.withValues(alpha: 0.16),
                  border: Border.all(
                    color: AppColors.orangeLight.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  externalEnabled
                      ? (Localizations.localeOf(context).languageCode == 'ar'
                            ? 'محادثتك'
                            : 'Your chat')
                      : (Localizations.localeOf(context).languageCode == 'ar'
                            ? 'أدوات يومك'
                            : 'Daily tools'),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.orangeLight
                        : AppColors.primaryBlue,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({this.size = 38, this.online = false});

  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.4),
                colors: [Color(0xFFC4B5FD), Color(0xFF5B21B6)],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.aiPurple.withValues(alpha: 0.65),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
          ),
          if (online)
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: -1,
              bottom: 0,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.greenLight,
                  border: Border.all(color: AppColors.darkBackground, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.dashed});

  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: dashed ? null : Colors.white.withValues(alpha: 0.08),
        border: dashed
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                style: BorderStyle.solid,
              )
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(color: context.planningMuted, fontSize: 11.5),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.entry});

  final CoachEntry entry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: Directionality.of(context) == TextDirection.rtl
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: LocalProfileAvatar(
                  uid: context.read<CoachCubit>().userId,
                  editable: false,
                  size: 34,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(6),
                ),
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, Color(0xFF2F8CF0)],
                ),
                border: Border.all(color: const Color(0xFFFDBA74), width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                entry.text,
                style: context.messageStyle(size: 14, color: Colors.white),
              ),
            ),
            const SizedBox(height: 3),
            Icon(
              entry.failed
                  ? Icons.error_outline
                  : entry.persisted
                  ? Icons.done_all
                  : Icons.schedule,
              size: 16,
              color: entry.failed
                  ? AppColors.orangeLight
                  : AppColors.greenLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({required this.entry});

  final CoachEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CoachCubit>();
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (cubit.replyFlagged(entry.id)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ar
                  ? 'الإجابة مخفية ومعلّمة للمراجعة في الجلسة دي فقط. مفيش بلاغ اتبعت لفريق أو مختص.'
                  : 'Answer hidden and flagged for this session only. No report was sent to a team or clinician.',
            ),
            TextButton(
              onPressed: () => cubit.restoreReply(entry.id),
              child: Text(ar ? 'عرض الإجابة تاني' : 'Show answer again'),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(22),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.aiPurple.withValues(alpha: 0.26),
                      AppColors.turquoise.withValues(alpha: 0.09),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFB8C00),
                    width: 1.6,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.coachTitle,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.purpleLight
                                : AppColors.aiPurple,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            color: AppColors.purpleLight.withValues(
                              alpha: 0.25,
                            ),
                          ),
                          child: Text(
                            switch (entry.origin) {
                              'ai' =>
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'رد المدرب'
                                    : 'Coach reply',
                              'safety' =>
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'أمان'
                                    : 'Safety',
                              'unavailable' =>
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'غير متاح'
                                    : 'Unavailable',
                              _ => l10n.coachRuleBadgeShort,
                            },
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFFDDD6FE)
                                  : AppColors.aiPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(entry.text, style: context.messageStyle(size: 14)),
                    if (entry.localRecordSummary && entry.stats.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Divider(),
                      ),
                    if (entry.stats.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final stat in entry.stats)
                              SizedBox(
                                width: 126,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _statValue(context, stat.value),
                                        textDirection: TextDirection.ltr,
                                        style: const TextStyle(
                                          color: AppColors.cyanLight,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          fontFamily:
                                              AppTheme.displayFontFamily,
                                        ),
                                      ),
                                      Text(
                                        stat.label,
                                        style: TextStyle(
                                          color: context.planningMuted,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (entry.id != 'local-welcome')
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          key: ValueKey('flag_${entry.id}'),
                          icon: const Icon(Icons.flag_outlined, size: 16),
                          label: Text(
                            ar
                                ? 'فيه مشكلة في الإجابة؟'
                                : 'Problem with this answer?',
                          ),
                          onPressed: () async {
                            final reason = await showSufraDialog<String>(
                              context: context,
                              builder: (dialog) => SufraAlertDialog(
                                title: Text(
                                  ar
                                      ? 'علّم الإجابة للمراجعة'
                                      : 'Flag answer for review',
                                  style: context.readableDisplayStyle(size: 20),
                                ),
                                content: Text(
                                  ar
                                      ? 'هتتخفى وتتعلّم للجلسة بس، من غير إرسال محتوى لحد. ده مش بلاغ لمختص ولا قناة طوارئ. لو فيه خطر اطلب مساعدة طبية فورًا.'
                                      : 'Hide and flag for this session only, without sending content to anyone. This is not a report to a clinician or an emergency channel. Seek urgent medical help if needed.',
                                ),
                                actions: [
                                  for (final item in <(String, String)>[
                                    ('unsafe', ar ? 'غير آمنة' : 'Unsafe'),
                                    (
                                      'incorrect',
                                      ar ? 'معلومة غير صحيحة' : 'Incorrect',
                                    ),
                                    ('other', ar ? 'سبب تاني' : 'Other'),
                                  ])
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialog, item.$1),
                                      child: Text(item.$2),
                                    ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialog),
                                    child: Text(ar ? 'إلغاء' : 'Cancel'),
                                  ),
                                ],
                              ),
                            );
                            if (reason != null && !cubit.inactive) {
                              cubit.flagReply(entry.id, reason);
                            }
                          },
                        ),
                      ),
                    if (entry.advice != null)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1FFBBF24),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x59FBBF24)),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${l10n.coachAdviceLabel}: ',
                                style: const TextStyle(
                                  color: Color(0xFFFCD34D),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(text: entry.advice),
                            ],
                          ),
                          style: const TextStyle(fontSize: 13, height: 1.7),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            const _CoachAvatar(),
          ],
        ),
      ),
    );
  }

  /// Stat values are stored as plain strings; numeric ones get the active
  /// locale's digits at render time.
  static String _statValue(BuildContext context, String value) {
    final parsed = num.tryParse(value);
    if (parsed == null) return value;
    return planningNumber(context, parsed);
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SufraControlFeedback(
      radius: 99,
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: LinearGradient(
              colors: [
                AppColors.aiPurple.withValues(alpha: 0.45),
                AppColors.turquoise.withValues(alpha: 0.35),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

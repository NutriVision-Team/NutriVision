import '../../../../core/widgets/sufra_button_response.dart';
import '../../../../core/widgets/dish_float.dart';
import '../widgets/meal_budget_card.dart';
import '../widgets/meal_portion_alternatives.dart';
import '../../domain/meal_budget_preview.dart';
import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../core/widgets/catalog_food_art.dart';
import '../../../../data/models/food_catalog_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../domain/catalog_meal_draft.dart';
import '../../domain/food_portion.dart';
import '../cubit/meal_save_cubit.dart';
import 'food_search_screen.dart';

class MealReviewScreen extends StatefulWidget {
  const MealReviewScreen({
    super.key,
    this.portion,
    this.draft,
    this.initialMealType = 'lunch',
    this.initialNotes = '',
    this.initialTitle,
    this.inputMethod = 'catalog',
  }) : assert((portion == null) != (draft == null));
  static const routePath = '/meal-review';
  final FoodPortion? portion;
  final CatalogMealDraft? draft;
  final String initialMealType, initialNotes;
  final String? initialTitle;
  final String inputMethod;
  @override
  State<MealReviewScreen> createState() => _MealReviewScreenState();
}

class _MealReviewScreenState extends State<MealReviewScreen> {
  late CatalogMealDraft _draft;
  late String _title;
  String _notes = '', _mealType = 'lunch';
  String? _owner;
  MealSaveCubit? _writer;
  @override
  void initState() {
    super.initState();
    _draft = widget.draft ?? CatalogMealDraft([widget.portion!]);
    _title =
        widget.initialTitle ??
        (_draft.portions.isEmpty ? '' : _draft.portions.first.food.name);
    _notes = widget.initialNotes;
    _mealType = widget.initialMealType;
  }

  @override
  void dispose() {
    _writer?.close();
    super.dispose();
  }

  void _invalidate() {
    _writer?.close();
    _writer = null;
  }

  MealSaveCubit _getWriter() {
    final session = context.read<SessionCubit>();
    String? uid() {
      final s = session.state;
      return s is SessionAuthenticated ? s.user.uid : null;
    }

    return _writer ??= MealSaveCubit(
      draft: _draft,
      title: _title,
      notes: _notes,
      inputMethod: widget.inputMethod,
      repository: context.read<NutritionRepository>(),
      uid: uid() ?? '',
      currentUid: uid,
      mealType: _mealType,
    );
  }

  Future<void> _choose([int? index]) async {
    final food = await context.push<FoodCatalogModel>(
      FoodSearchScreen.pickRoutePath,
    );
    if (!mounted || food == null) return;
    setState(() {
      _invalidate();
      final values = [..._draft.portions];
      if (index == null) {
        values.add(FoodPortion(food, 100));
      } else {
        values[index] = FoodPortion(food, values[index].grams);
      }
      _draft = CatalogMealDraft(values);
    });
  }

  Future<void> _quantity(int index) async {
    final result = await showSufraBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _QuantitySheet(_draft.portions[index]),
    );
    if (!mounted || result == null) return;
    setState(() {
      _invalidate();
      final values = [..._draft.portions];
      values[index] = FoodPortion(values[index].food, result);
      _draft = CatalogMealDraft(values, imageUrl: _draft.imageUrl);
    });
  }

  Future<void> _metadata() async {
    final result = await showSufraBottomSheet<({String title, String notes})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _MetadataSheet(title: _title, notes: _notes),
    );
    if (!mounted || result == null) return;
    setState(() {
      _invalidate();
      _title = result.title;
      _notes = result.notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        session = context.watch<SessionCubit>().state;
    if (session is! SessionAuthenticated) {
      return const Scaffold(body: SizedBox.shrink());
    }
    _owner ??= session.user.uid;
    if (_owner != session.user.uid) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.mealSessionExpired),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(l.wizardBack),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return BlocProvider.value(
      value: _getWriter(),
      child: BlocConsumer<MealSaveCubit, MealSaveStatus>(
        listener: (context, status) {
          if (status == MealSaveStatus.saved) {
            final s = context.read<SessionCubit>().state;
            if (s is SessionAuthenticated) {
              context.read<HomeCubit>().load(s.user.uid);
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SufraSnackBar(content: Text(l.logHubRelogDone)));
            context.go('/diary');
          }
        },
        builder: (context, status) {
          final locked = status != MealSaveStatus.ready, total = _draft.totals;
          final large = MediaQuery.textScalerOf(context).scale(14) > 20;
          final valid = total != null && _title.trim().isNotEmpty;
          return Scaffold(
            body: NebulaBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        children: [
                          Flex(
                            direction: large ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: large
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.center,
                            children: [
                              if (large)
                                Text(
                                  l.mealReviewTitle,
                                  style: context.readableDisplayStyle(size: 28),
                                )
                              else
                                Expanded(
                                  child: Text(
                                    l.mealReviewTitle,
                                    style: context.readableDisplayStyle(
                                      size: 28,
                                    ),
                                  ),
                                ),
                              GlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _mealType,
                                    items: [
                                      for (final p in [
                                        ('breakfast', l.mealBreakfast),
                                        ('lunch', l.mealLunch),
                                        ('dinner', l.mealDinner),
                                        ('snack', l.mealSnack),
                                        ('suhoor', l.mealSuhoor),
                                        ('iftar', l.mealIftar),
                                      ])
                                        DropdownMenuItem(
                                          value: p.$1,
                                          child: Text(p.$2),
                                        ),
                                    ],
                                    onChanged: locked
                                        ? null
                                        : (v) {
                                            if (v != null) {
                                              setState(() {
                                                _invalidate();
                                                _mealType = v;
                                              });
                                            }
                                          },
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: l.actionCancel,
                                onPressed: status == MealSaveStatus.saving
                                    ? null
                                    : () => context.pop(),
                                icon: const BackButtonIcon(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l.mealReviewCatalogHint,
                            style: context.mutedStyle(size: 14),
                          ),
                          if (widget.inputMethod == 'photo')
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'تقدير من صورة، مش قياس. الكمية والزيت والإضافات ممكن يغيّروا النتيجة. الحفظ مش تأكيد لدقة التقدير.'
                                    : 'Image estimate, not a measurement. Portions, oil and additions may change the result. Saving does not confirm estimate accuracy.',
                                style: const TextStyle(color: Colors.amber),
                              ),
                            ),
                          const SizedBox(height: 18),
                          for (var i = 0; i < _draft.portions.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SufraControlFeedback(
                                radius: 24,
                                intensity: .18,
                                enabled: !locked,
                                child: GlassCard(
                                  borderColor: const Color(0x77D99A35),
                                  onTap: locked ? null : () => _quantity(i),
                                  padding: const EdgeInsets.all(12),
                                  child: Flex(
                                    direction: large
                                        ? Axis.vertical
                                        : Axis.horizontal,
                                    crossAxisAlignment: large
                                        ? CrossAxisAlignment.start
                                        : CrossAxisAlignment.center,
                                    children: [
                                      i == 0
                                          ? DishFloat(
                                              child: _ReviewFoodArt(
                                                _draft.portions[i].food,
                                              ),
                                            )
                                          : _ReviewFoodArt(
                                              _draft.portions[i].food,
                                            ),
                                      SizedBox(
                                        width: large ? 0 : 10,
                                        height: large ? 10 : 0,
                                      ),
                                      _FlexibleReviewItem(
                                        vertical: large,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _foodName(
                                                context,
                                                _draft.portions[i].food,
                                              ),
                                              style: context
                                                  .readableDisplayStyle(
                                                    size: 20,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_draft.portions[i].grams.toStringAsFixed(1)} ${l.foodGramUnit}',
                                              textDirection: TextDirection.ltr,
                                              style: context.mutedStyle(
                                                size: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _draft.portions[i]
                                                .amount('calories')
                                                ?.toStringAsFixed(0) ??
                                            l.foodUnknown,
                                        style: context.readableDisplayStyle(
                                          size: 22,
                                        ),
                                        textDirection: TextDirection.ltr,
                                      ),
                                      PopupMenuButton<String>(
                                        enabled: !locked,
                                        tooltip: l.mealEdit,
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            value: 'quantity',
                                            child: Text(l.foodGrams),
                                          ),
                                          PopupMenuItem(
                                            value: 'change',
                                            child: Text(l.mealIngredientEdit),
                                          ),
                                          PopupMenuItem(
                                            value: 'remove',
                                            child: Text(l.mealIngredientRemove),
                                          ),
                                        ],
                                        onSelected: (v) {
                                          if (v == 'quantity') {
                                            _quantity(i);
                                          } else if (v == 'change') {
                                            _choose(i);
                                          } else {
                                            setState(() {
                                              _invalidate();
                                              _draft = CatalogMealDraft(
                                                [..._draft.portions]
                                                  ..removeAt(i),
                                              );
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Wrap(
                            spacing: 10,
                            children: [
                              TextButton.icon(
                                onPressed:
                                    locked || _draft.portions.length >= 50
                                    ? null
                                    : () => _choose(),
                                icon: const Icon(Icons.add),
                                label: Text(l.mealIngredientAdd),
                              ),
                              TextButton.icon(
                                onPressed: locked ? null : _metadata,
                                icon: const Icon(Icons.edit_note),
                                label: Text(l.mealNotes),
                              ),
                            ],
                          ),
                          GlassCard(
                            borderColor: const Color(0x77D99A35),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    Text(
                                      l.mealReviewTotal,
                                      style: context.mutedStyle(),
                                    ),
                                    Text(
                                      '${total?.energyKcal.toStringAsFixed(0) ?? l.foodUnknown} ${l.foodKcal}',
                                      style: context.readableDisplayStyle(
                                        size: 27,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 14,
                                  children: [
                                    for (final p in [
                                      (l.foodProtein, total?.proteinG),
                                      (l.foodCarbs, total?.carbohydrateG),
                                      (l.foodFat, total?.fatG),
                                    ])
                                      Text(
                                        '${p.$1}: ${p.$2?.toStringAsFixed(1) ?? l.foodUnknown} ${l.foodGramUnit}',
                                        style: context.mutedStyle(size: 12),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          BlocBuilder<HomeCubit, HomeState>(
                            builder: (context, home) {
                              if (status == MealSaveStatus.saved) {
                                return const SizedBox.shrink();
                              }
                              final ar =
                                  Localizations.localeOf(
                                    context,
                                  ).languageCode ==
                                  'ar';
                              final preview = home is HomeLoaded
                                  ? MealBudgetPreview.calculate(
                                      target: home
                                          .nutritionProfile
                                          ?.dailyCalorieTarget,
                                      consumed: home.eatenCalories,
                                      meal: total?.energyKcal,
                                    )
                                  : null;
                              if (preview == null) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    ar
                                        ? 'كمّل هدفك اليومي عشان نقارن الوجبة بيه. المقارنة مش حكم طبي على الأكل.'
                                        : 'Set your daily target to compare this meal. This is not a medical assessment.',
                                    style: context.mutedStyle(size: 12),
                                  ),
                                );
                              }
                              return MealBudgetCard(
                                preview: preview,
                                onAlternatives: () async {
                                  final next =
                                      await showSufraBottomSheet<
                                        CatalogMealDraft
                                      >(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (c) => FractionallySizedBox(
                                          heightFactor: .9,
                                          child: MealPortionAlternatives(
                                            draft: _draft,
                                            remaining: preview.before,
                                            allergies:
                                                (home as HomeLoaded)
                                                    .nutritionProfile
                                                    ?.allergies ??
                                                const [],
                                            dietaryPreferences:
                                                home
                                                    .nutritionProfile
                                                    ?.dietaryPreferences ??
                                                const [],
                                          ),
                                        ),
                                      );
                                  if (next != null && mounted) {
                                    setState(() {
                                      _invalidate();
                                      _draft = next;
                                    });
                                  }
                                },
                              );
                            },
                          ),
                          if (valid && status != MealSaveStatus.expired)
                            OutlinedButton.icon(
                              key: const ValueKey('meal_review_coach'),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text(
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'راجع الشرح مع المدرّب'
                                    : 'Review explanation with Coach',
                              ),
                              onPressed: status == MealSaveStatus.saving
                                  ? null
                                  : () => context.push(
                                      '/coach',
                                      extra: OwnedReviewedMeal(
                                        session.user.uid,
                                        _draft,
                                      ),
                                    ),
                            ),
                          if (_notes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(_notes),
                            ),
                          if (!valid)
                            Text(
                              l.mealDraftIncomplete,
                              style: const TextStyle(color: Colors.orange),
                            ),
                          if (status == MealSaveStatus.failure)
                            Text(
                              l.stateError,
                              style: const TextStyle(color: Colors.orange),
                            ),
                          if (status == MealSaveStatus.expired)
                            Text(
                              l.mealSessionExpired,
                              style: const TextStyle(color: Colors.orange),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: GradientButton(
                        height: large ? 144 : 54,
                        labelPadding: large
                            ? const EdgeInsets.symmetric(horizontal: 12)
                            : EdgeInsets.zero,
                        labelAlign: large ? TextAlign.center : null,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF16A34A), Color(0xFF4ADE80)],
                        ),
                        textColor: const Color(0xFF052E16),
                        label: status == MealSaveStatus.failure
                            ? l.stateRetry
                            : l.mealSave,
                        isLoading: status == MealSaveStatus.saving,
                        onPressed:
                            !valid ||
                                status == MealSaveStatus.saving ||
                                status == MealSaveStatus.saved ||
                                status == MealSaveStatus.expired
                            ? null
                            : _writer!.save,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet(this.portion);
  final FoodPortion portion;
  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late final _value = TextEditingController(
    text: widget.portion.grams.toStringAsFixed(1),
  );
  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _setGrams(double grams) {
    _value.value = TextEditingValue(
      text: grams.toStringAsFixed(1),
      selection: TextSelection.collapsed(
        offset: grams.toStringAsFixed(1).length,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), g = parseDecimalInput(_value.text);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final valid = g != null && g > 0 && g <= 10000;
    final p = valid ? FoodPortion(widget.portion.food, g) : null;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedInk = dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    TextStyle muted(double size) =>
        context.mutedStyle(size: size).copyWith(color: mutedInk);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    Widget amount(String value, String unit, {double size = 16}) =>
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: context.readableDisplayStyle(size: size)),
              const SizedBox(width: 5),
              Text(unit, style: muted(12)),
            ],
          ),
        );
    return SingleChildScrollView(
      key: const ValueKey('portion-editor'),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DishFloat(child: _ReviewFoodArt(widget.portion.food)),
                Text(
                  ar ? 'ظبّط الكمية على قد أكلك' : 'Make this portion yours',
                  style: context.readableDisplayStyle(size: 22),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_foodName(context, widget.portion.food), style: muted(15)),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('portion-grams'),
              controller: _value,
              textDirection: TextDirection.ltr,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l.foodGrams,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFD99A35)),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(l.foodGramUnit, style: muted(13)),
                ),
                errorText: valid ? null : l.foodInvalidGrams,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ar
                  ? 'اختار كمية أو اكتبها بنفسك'
                  : 'Choose a weight or enter your own',
              style: muted(12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final grams in [50, 100, 150, 200])
                  ChoiceChip(
                    key: ValueKey('portion-preset-$grams'),
                    side: const BorderSide(color: Color(0xFFD99A35)),
                    selected: valid && g == grams,
                    onSelected: (_) => _setGrams(grams.toDouble()),
                    label: amount('$grams', l.foodGramUnit, size: 15),
                    checkmarkColor: dark
                        ? Colors.white
                        : const Color(0xFF0F5263),
                    selectedColor: const Color(
                      0xFF22D3EE,
                    ).withValues(alpha: dark ? .22 : .15),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedContainer(
              duration: duration,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: dark
                      ? const [Color(0x3022D3EE), Color(0x1816A34A)]
                      : const [Color(0x2022D3EE), Color(0x1616A34A)],
                ),
                border: Border.all(
                  color: const Color(0xFF22D3EE).withValues(alpha: .3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ar ? 'الكمية دي تساوي' : 'For this portion',
                    style: muted(13),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: amount(
                      p?.amount('calories')?.toStringAsFixed(0) ??
                          l.foodUnknown,
                      l.foodKcal,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 18,
                    runSpacing: 12,
                    children: [
                      for (final macro in [
                        (l.foodProtein, 'protein'),
                        (l.foodCarbs, 'carbohydrates'),
                        (l.foodFat, 'fat'),
                      ])
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(macro.$1, style: muted(12)),
                            amount(
                              p?.amount(macro.$2)?.toStringAsFixed(1) ??
                                  l.foodUnknown,
                              l.foodGramUnit,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ar
                  ? 'التعديل هيتطبق لما تضغط حفظ. الوجبة نفسها لسه ما اتحفظتش.'
                  : 'Apply to update your review. The meal is not logged yet.',
              style: muted(12),
            ),
            const SizedBox(height: 16),
            GradientButton(
              key: const ValueKey('portion-apply'),
              label: l.actionSave,
              onPressed: valid ? () => Navigator.pop(context, g) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataSheet extends StatefulWidget {
  const _MetadataSheet({required this.title, required this.notes});
  final String title, notes;
  @override
  State<_MetadataSheet> createState() => _MetadataSheetState();
}

class _MetadataSheetState extends State<_MetadataSheet> {
  late final _title = TextEditingController(text: widget.title),
      _notes = TextEditingController(text: widget.notes);
  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              maxLength: 120,
              decoration: InputDecoration(labelText: l.mealName),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _notes,
              maxLength: 1000,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.mealNotes),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: l.actionSave,
              onPressed: _title.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, (
                      title: _title.text.trim(),
                      notes: _notes.text.trim(),
                    )),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewFoodArt extends StatelessWidget {
  const _ReviewFoodArt(this.food);
  final FoodCatalogModel food;
  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(child: CatalogFoodArt(size: 56, id: food.foodId)),
    );
  }
}

class _FlexibleReviewItem extends StatelessWidget {
  const _FlexibleReviewItem({required this.vertical, required this.child});
  final bool vertical;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      vertical ? child : Expanded(child: child);
}

String _foodName(BuildContext context, FoodCatalogModel food) {
  final name =
      food.localizedNames?[Localizations.localeOf(context).languageCode];
  return name is String && name.trim().isNotEmpty ? name : food.name;
}

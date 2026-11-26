import '../../../../core/widgets/saved_catalog_label.dart';
import '../../../../core/widgets/catalog_food_art.dart';
import '../../../../core/widgets/catalog_photo.dart';
import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../favorites/data/favorites_repository.dart';
import '../../../favorites/domain/favorites_logic.dart';
import '../../../../data/models/favorite_model.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/utils/decimal_input.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../data/models/meal_entry_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../domain/edit_logged_meal.dart';
import '../cubit/meal_detail_cubit.dart';

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({
    super.key,
    required this.mealId,
    required this.dateKey,
  });
  final String mealId, dateKey;
  static const routePath = '/meal/:id';
  static String locationFor(MealEntryModel meal) => Uri(
    pathSegments: ['', 'meal', meal.mealId],
    queryParameters: {'date': meal.dateKey},
  ).toString();
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>();
    final current = session.state;
    if (current is! SessionAuthenticated) {
      return const Scaffold(body: AppLoadingView());
    }
    return BlocProvider(
      key: ValueKey('${current.user.uid}/$mealId'),
      create: (context) => MealDetailCubit(
        repository: context.read<NutritionRepository>(),
        uid: current.user.uid,
        mealId: mealId,
        dateKey: dateKey,
        currentUid: () {
          final s = session.state;
          return s is SessionAuthenticated ? s.user.uid : null;
        },
      )..load(),
      child: const _DetailBody(),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocConsumer<MealDetailCubit, MealDetailState>(
      listener: (context, state) {
        if (state.status == MealDetailStatus.saved ||
            state.status == MealDetailStatus.deleted) {
          final s = context.read<SessionCubit>().state;
          if (s is SessionAuthenticated) {
            context.read<HomeCubit>().load(s.user.uid);
          }
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go('/diary');
          }
        }
      },
      builder: (context, state) {
        final c = context.read<MealDetailCubit>();
        final meal = state.meal;
        Widget body;
        if (state.status == MealDetailStatus.loading) {
          body = const AppLoadingView();
        } else if (state.status == MealDetailStatus.failure) {
          body = AppErrorView(onRetry: c.load);
        } else if (meal == null) {
          body = AppEmptyView(message: l.mealNotFound);
        } else {
          final locale = Localizations.localeOf(context).languageCode;
          final grams = [meal.totalProtein, meal.totalCarbs, meal.totalFat];
          final energy = [
            meal.totalProtein == null ? null : meal.totalProtein! * 4,
            meal.totalCarbs == null ? null : meal.totalCarbs! * 4,
            meal.totalFat == null ? null : meal.totalFat! * 9,
          ];
          final complete = energy.every((v) => v != null);
          final sum = complete ? energy.fold<double>(0, (s, v) => s + v!) : 0.0;
          final fractions = complete && sum > 0
              ? energy.map((v) => v! / sum).toList()
              : <double>[];
          final names = [l.foodProtein, l.foodCarbs, l.foodFat];
          const colors = [
            AppColors.turquoise,
            AppColors.copper,
            AppColors.aiPurple,
          ];
          body = ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: l.wizardBack,
                    onPressed: state.busy
                        ? null
                        : () => context.canPop()
                              ? context.pop()
                              : context.go('/diary'),
                    icon: const BackButtonIcon(),
                  ),
                  _MealFavoriteButton(meal: meal),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.yMMMd(
                            locale,
                          ).add_jm().format(meal.consumedAt),
                          style: context.mutedStyle(size: 12),
                        ),
                        if (meal.inputMethod == 'catalog' &&
                            meal.items.length == 1 &&
                            meal.title == meal.items.single.foodName)
                          SavedCatalogLabel(
                            item: meal.items.single,
                            style: context
                                .readableDisplayStyle(size: 26)
                                .copyWith(fontFamily: 'Cairo'),
                          )
                        else
                          Text(
                            meal.title,
                            style: context
                                .readableDisplayStyle(size: 26)
                                .copyWith(fontFamily: 'Cairo'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (meal.inputMethod == 'photo')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    locale.startsWith('ar')
                        ? 'تقدير من صورة، مش قياس. الزيت والإضافات غير المعروفة مش محسوبة.'
                        : 'Image estimate, not a measurement. Unknown oil and additions are not included.',
                    style: const TextStyle(color: Colors.amber),
                  ),
                ),
              const SizedBox(height: 12),
              GlassCard(
                padding: EdgeInsets.zero,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x66FB8C00), Color(0x4D7C3AED)],
                ),
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      Center(
                        child: meal.imageUrl == null && meal.items.length == 1
                            ? CatalogFoodArt(
                                id: meal.items.single.foodId,
                                size: 136,
                              )
                            : _LoggedMealImage(url: meal.imageUrl),
                      ),
                      PositionedDirectional(
                        top: 14,
                        start: 14,
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${meal.totalCalories.round()}',
                                style: context.readableDisplayStyle(size: 26),
                              ),
                              Text(
                                l.foodKcal,
                                style: context.mutedStyle(size: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        bottom: 14,
                        end: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '\u2066${meal.totalProtein?.toStringAsFixed(1) ?? l.foodUnknown} ${l.foodGramUnit}\u2069 ${l.foodProtein}',
                            style: const TextStyle(
                              color: AppColors.darkBackground,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (meal.imageUrl == null && meal.items.length == 1)
                CatalogImageCredit(foodId: meal.items.single.foodId),
              const SizedBox(height: 12),
              GlassCard(
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CustomPaint(
                        painter: _MacroDonut(fractions),
                        child: fractions.isEmpty
                            ? Center(
                                child: Text(
                                  l.foodUnknown,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colors[i],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      '${names[i]} ${fractions.isEmpty ? (grams[i]?.toStringAsFixed(1) ?? l.foodUnknown) : '${(fractions[i] * 100).round()}%'}${fractions.isEmpty ? ' ${l.foodGramUnit}' : ''}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: [
                    for (final field in [
                      (l.foodFiber, meal.totalFiber, l.foodGramUnit),
                      (l.foodSugar, meal.totalSugar, l.foodGramUnit),
                      (l.foodSodium, meal.totalSodium, l.foodMg),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(field.$1),
                            Text(
                              '${field.$2?.toStringAsFixed(1) ?? l.foodUnknown} ${field.$3}',
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (meal.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in meal.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: SavedCatalogLabel(item: item, amount: true),
                        ),
                    ],
                  ),
                ),
              ],
              if (meal.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(meal.notes!),
              ],
              if (state.mutationFailed) ...[
                const SizedBox(height: 12),
                Text(
                  l.stateError,
                  style: const TextStyle(color: AppColors.orangeLight),
                ),
              ],
              const SizedBox(height: 18),
              if (state.busy)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: l.mealEdit,
                        onPressed: () async {
                          final updated =
                              await showSufraBottomSheet<MealEntryModel>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _EditMealForm(meal),
                              );
                          if (updated != null && context.mounted) {
                            c.save(updated);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GradientButton(
                        label: l.mealDelete,
                        gradient: const LinearGradient(
                          colors: [AppColors.error, Color(0xFFFB7185)],
                        ),
                        onPressed: () async {
                          final approved = await showSufraDialog<bool>(
                            context: context,
                            builder: (dialog) => SufraAlertDialog(
                              title: Text(l.mealDelete),
                              content: Text(l.mealDeleteConfirm),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialog, false),
                                  child: Text(l.actionCancel),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialog, true),
                                  child: Text(l.mealDelete),
                                ),
                              ],
                            ),
                          );
                          if (approved == true && context.mounted) {
                            c.delete();
                          }
                        },
                      ),
                    ),
                  ],
                ),
            ],
          );
        }
        return Scaffold(
          body: NebulaBackground(child: SafeArea(child: body)),
        );
      },
    );
  }
}

class _MacroDonut extends CustomPainter {
  const _MacroDonut(this.values);
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawOval(rect.deflate(8), paint..color = Colors.white12);
    var start = -math.pi / 2;
    const colors = [AppColors.turquoise, AppColors.copper, AppColors.aiPurple];
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] * math.pi * 2;
      canvas.drawArc(
        rect.deflate(8),
        start,
        sweep,
        false,
        paint..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_MacroDonut old) =>
      old.values.toString() != values.toString();
}

class _EditMealForm extends StatefulWidget {
  const _EditMealForm(this.meal);
  final MealEntryModel meal;
  @override
  State<_EditMealForm> createState() => _EditMealFormState();
}

class _EditMealFormState extends State<_EditMealForm> {
  late final _title = TextEditingController(text: widget.meal.title);
  late final _notes = TextEditingController(text: widget.meal.notes ?? '');
  late final _weights = [
    for (final item in widget.meal.items)
      TextEditingController(text: item.weightInGrams.toStringAsFixed(1)),
  ];
  late String _type = widget.meal.mealType;
  bool _invalid = false;
  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    for (final c in _weights) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.mealEdit, style: context.readableDisplayStyle(size: 24)),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              maxLength: 120,
              decoration: InputDecoration(labelText: l.mealName),
            ),
            DropdownButtonFormField<String>(
              initialValue:
                  const [
                    'breakfast',
                    'lunch',
                    'dinner',
                    'snack',
                    'suhoor',
                    'iftar',
                  ].contains(_type)
                  ? _type
                  : null,
              decoration: InputDecoration(labelText: l.mealTypeLabel),
              items: [
                for (final pair in [
                  ('breakfast', l.mealBreakfast),
                  ('lunch', l.mealLunch),
                  ('dinner', l.mealDinner),
                  ('snack', l.mealSnack),
                  ('suhoor', l.mealSuhoor),
                  ('iftar', l.mealIftar),
                ])
                  DropdownMenuItem(value: pair.$1, child: Text(pair.$2)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            for (var i = 0; i < _weights.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  controller: _weights[i],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        '${widget.meal.items[i].foodName} (${l.foodGramUnit})',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLength: 1000,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.mealNotes),
            ),
            if (_invalid)
              Text(
                l.mealEditInvalid,
                style: const TextStyle(color: AppColors.orangeLight),
              ),
            const SizedBox(height: 12),
            GradientButton(
              label: l.actionSave,
              onPressed: () {
                try {
                  final weights = _weights
                      .map((c) => parseDecimalInput(c.text))
                      .toList();
                  if (weights.any((v) => v == null)) {
                    throw const FormatException();
                  }
                  final edited = editLoggedMeal(
                    widget.meal,
                    title: _title.text,
                    mealType: _type,
                    notes: _notes.text,
                    weightsInGrams: weights.cast<double>(),
                  );
                  Navigator.pop(context, edited);
                } catch (_) {
                  setState(() => _invalid = true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MealFavoriteButton extends StatefulWidget {
  const _MealFavoriteButton({required this.meal});
  final MealEntryModel meal;
  @override
  State<_MealFavoriteButton> createState() => _MealFavoriteButtonState();
}

class _MealFavoriteButtonState extends State<_MealFavoriteButton> {
  bool _busy = false, _saved = false;
  String? _uid() {
    final session = context.read<SessionCubit>().state;
    return session is SessionAuthenticated ? session.user.uid : null;
  }

  Future<void> _save() async {
    final meal = widget.meal;
    if (_busy || _saved || _uid() != meal.userId) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    try {
      await FirestoreFavoritesBackend(
        FirebaseFirestore.instance,
        assertActive: (uid) {
          if (!mounted || _uid() != uid) {
            throw StateError('Account no longer active');
          }
        },
      ).saveIfAbsent(
        meal.userId,
        FavoriteModel(
          favoriteId: mealFavoriteId(meal.mealId),
          targetId: meal.mealId,
          targetType: favoriteTypeMeal,
          title: meal.title,
          imageUrl: meal.imageUrl,
        ),
      );
      if (!mounted || _uid() != meal.userId) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SufraSnackBar(content: Text(l.favoritesSaved)));
    } catch (_) {
      if (mounted && _uid() == meal.userId) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SufraSnackBar(content: Text(l.favoritesSaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context).favoritesTitle,
    onPressed: _busy || _saved ? null : _save,
    icon: _busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(
            _saved ? Icons.favorite : Icons.favorite_border,
            color: const Color(0xFFFB7185),
          ),
  );
}

class _LoggedMealImage extends StatelessWidget {
  const _LoggedMealImage({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url ?? '');
    const fallback = Icon(
      Icons.restaurant_outlined,
      size: 100,
      color: Color(0x88FFFFFF),
    );
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return fallback;
    }
    return ClipOval(
      child: Image.network(
        uri.toString(),
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

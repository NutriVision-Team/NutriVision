import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'dart:ui' as ui;
import '../recipe_arabic.dart';
import '../../../../core/widgets/egyptian_dish_art.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/datasources/local_recipe_data_source.dart';
import '../../domain/recipe_catalog_repository.dart';
import '../widgets/discovery_widgets.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.repository,
    this.favorites,
    this.onLogRequested,
  });
  static const routeBase = '/recipe';
  final String recipeId;
  final RecipeCatalogRepository? repository;
  final RecipeFavorites? favorites;

  /// Reserved for a verified portion flow, never called with unknown nutrition.
  final Future<void> Function(LocalRecipeRecord recipe)? onLogRequested;
  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<LocalRecipeRecord?> _load;
  final _checked = <int>{};
  bool _saving = false;
  bool _saved = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _generation++;
    _checked.clear();
    _saving = false;
    _saved = false;
    _load = _loadRecipeAndFavorites();
  }

  Future<LocalRecipeRecord?> _loadRecipeAndFavorites() async {
    final id = widget.recipeId;
    final favorites = widget.favorites;
    final results = await Future.wait<Object?>([
      (widget.repository ?? RecipeCatalogRepository()).getById(id),
      if (favorites != null) favorites.refresh(),
    ]);
    if (mounted && widget.recipeId == id && widget.favorites == favorites) {
      _saved = favorites?.read().contains(id) ?? false;
    }
    return results.first as LocalRecipeRecord?;
  }

  @override
  void didUpdateWidget(covariant RecipeDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipeId != widget.recipeId ||
        oldWidget.repository != widget.repository ||
        oldWidget.favorites != widget.favorites) {
      _reset();
    }
  }

  Future<void> _toggleSaved() async {
    final store = widget.favorites;
    if (store == null) return;
    final generation = _generation;
    final next = !_saved;
    setState(() => _saving = true);
    try {
      await store.setSaved(widget.recipeId, next);
      if (mounted && generation == _generation) setState(() => _saved = next);
    } catch (_) {
      if (mounted && generation == _generation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SufraSnackBar(
            content: Text(AppLocalizations.of(context).discoveryMsg001),
          ),
        );
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DiscoveryScaffold(
    showNavigation: false,
    child: FutureBuilder<LocalRecipeRecord?>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: snapshot.error is RecipeLicenseException
                ? Text(AppLocalizations.of(context).discoveryMsg002)
                : DiscoveryError(onRetry: () => setState(_reset)),
          );
        }
        final recipe = snapshot.data;
        if (recipe == null) {
          return Center(
            child: Text(AppLocalizations.of(context).discoveryMsg003),
          );
        }
        final name = discoveryArabic(context)
            ? recipe.nameAr ?? recipe.nameEn
            : recipe.nameEn;
        return Column(
          children: [
            Expanded(
              child: DiscoveryList(
                bottom: 18,
                children: [
                  GlassCard(
                    padding: EdgeInsets.zero,
                    borderColor: AppColors.orangeLight.withValues(alpha: .6),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x73FB8C00), Color(0x404ADE80)],
                    ),
                    child: SizedBox(
                      height: 242,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Positioned.fill(
                            child: CustomPaint(painter: _RecipeRingPainter()),
                          ),
                          DiscoveryFloat(
                            child: RecipeSourceImage(recipe: recipe, size: 160),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                discoveryArabic(context) &&
                                        recipe.area == 'Egyptian'
                                    ? 'مصري'
                                    : recipe.area ?? '',
                                style: const TextStyle(
                                  color: AppColors.darkBackground,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: IconButton(
                              tooltip: AppLocalizations.of(
                                context,
                              ).discoveryMsg004,
                              onPressed: () => Navigator.maybePop(context),
                              icon: const BackButtonIcon(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DiscoveryTitle(name, size: 26),
                  if (recipe.id == 'themealdb_53027')
                    GlassCard(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            discoveryArabic(context)
                                ? 'الوصفة المنقولة ناقصة'
                                : 'Imported recipe is incomplete',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            discoveryArabic(context)
                                ? 'المصدر بيستخدم دقيق وفلفل مش موجودين في قائمة المكونات، وناقصه جزء الصلصة والتقديم من الوصفة الأصلية. متعتمدش عليها كطريقة كاملة. راجع الأصل قبل الطبخ؛ مضفناش مقادير من عندنا.'
                                : 'The provider method uses flour and pepper missing from its ingredient list, and omits the original sauce and serving steps. Do not rely on this as a complete method. Check the original before cooking. We have not filled in quantities.',
                          ),
                          if (recipe.sourceUrl != null)
                            SelectableText(recipe.sourceUrl!),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _detailChip(
                        AppLocalizations.of(context).discoveryMsg005,
                        AppColors.cyanLight,
                      ),
                      _detailChip(
                        AppLocalizations.of(context).discoveryMsg006,
                        AppColors.orangeLight,
                      ),
                      _detailChip(
                        AppLocalizations.of(context).discoveryMsg007,
                        AppColors.purpleLight,
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (index, ingredient)
                          in recipe.ingredients.indexed)
                        Semantics(
                          checked: _checked.contains(index),
                          child: FilterChip(
                            shape: const StadiumBorder(),
                            backgroundColor: Colors.white.withValues(alpha: .1),
                            side: BorderSide(
                              color: AppColors.orangeLight.withValues(
                                alpha: .5,
                              ),
                            ),
                            selected: _checked.contains(index),
                            showCheckmark: true,
                            avatar: _checked.contains(index)
                                ? null
                                : const Icon(
                                    Icons.check_box_outline_blank,
                                    size: 18,
                                  ),
                            selectedColor: AppColors.greenLight.withValues(
                              alpha: .3,
                            ),
                            label: Text(
                              '${discoveryArabic(context) ? RecipeArabic.ingredients[ingredient.name] ?? ingredient.name : ingredient.name}${ingredient.measure?.isNotEmpty == true ? ' · ${discoveryArabic(context) ? RecipeArabic.measure(ingredient.measure!) : ingredient.measure}' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                decoration: _checked.contains(index)
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            onSelected: (value) => setState(() {
                              if (value) {
                                _checked.add(index);
                              } else {
                                _checked.remove(index);
                              }
                            }),
                          ),
                        ),
                    ],
                  ),
                  DiscoveryNotice(AppLocalizations.of(context).discoveryMsg008),
                  GlassCard(
                    borderColor: AppColors.orangeLight.withValues(alpha: .5),
                    child: Column(
                      children: [
                        for (final (index, step) in recipe.instructions.indexed)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == recipe.instructions.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.success,
                                        AppColors.turquoise,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x6606B6D4),
                                        blurRadius: 14,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    discoveryNumber(context, index + 1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Directionality(
                                      textDirection: discoveryArabic(context)
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                      child: Text(
                                        discoveryArabic(context)
                                            ? (RecipeArabic.steps[recipe
                                                      .id]?[index] ??
                                                  step)
                                            : step,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  DiscoveryNotice(
                    AppLocalizations.of(context).discoveryMsg009,
                    warning: true,
                  ),
                  if (widget.favorites != null)
                    DiscoveryNotice(
                      widget.favorites!.isCloudBacked
                          ? AppLocalizations.of(
                              context,
                            ).discoveryCloudFavoritesNote
                          : AppLocalizations.of(
                              context,
                            ).discoveryLocalFavoritesNote,
                    ),
                ],
              ),
            ),
            if (MediaQuery.textScalerOf(context).scale(11) > 15)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _saving || widget.favorites == null
                            ? null
                            : _toggleSaved,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _saved ? Icons.favorite : Icons.favorite_border,
                                color: AppColors.pinkLight,
                                size: 18,
                              ),
                        label: Text(
                          _saved
                              ? AppLocalizations.of(context).discoverySaved
                              : AppLocalizations.of(context).discoverySave,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Tooltip(
                      message: AppLocalizations.of(context).discoveryMsg012,
                      child: FilledButton(
                        onPressed: recipe.ingredients.isEmpty
                            ? null
                            : () => context.push(
                                '/recipe-quantify',
                                extra: recipe,
                              ),
                        child: Text(
                          AppLocalizations.of(context).recipeBuildQuantified,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    SizedBox(
                      width: 108,
                      child: OutlinedButton.icon(
                        onPressed: _saving || widget.favorites == null
                            ? null
                            : _toggleSaved,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _saved ? Icons.favorite : Icons.favorite_border,
                                color: AppColors.pinkLight,
                                size: 18,
                              ),
                        label: Text(
                          _saved
                              ? AppLocalizations.of(context).discoverySaved
                              : AppLocalizations.of(context).discoverySave,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Tooltip(
                        message: AppLocalizations.of(context).discoveryMsg012,
                        child: FilledButton(
                          onPressed: recipe.ingredients.isEmpty
                              ? null
                              : () => context.push(
                                  '/recipe-quantify',
                                  extra: recipe,
                                ),
                          child: Text(
                            AppLocalizations.of(context).recipeBuildQuantified,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _detailChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.darkBackground,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class RecipeSourceImage extends StatelessWidget {
  const RecipeSourceImage({super.key, required this.recipe, this.size = 54});
  final LocalRecipeRecord recipe;
  final double size;
  @override
  Widget build(BuildContext context) {
    // Three original HTML cutouts and five generated, composition-checked illustrations.
    const supplied = <String, String>{
      'themealdb_53025': 'ful',
      'themealdb_53026': 'taameya',
      'themealdb_53027': 'koshari',
      'themealdb_52963': 'shakshuka',
      'themealdb_53028': 'shawarma',
      'themealdb_53029': 'molokhia',
      'themealdb_53030': 'feteer',
      'themealdb_53031': 'fatta',
    };
    final suppliedName = supplied[recipe.id];
    if (suppliedName != null) {
      final image = Image.asset(
        'assets/images/${const {'koshari', 'ful', 'taameya'}.contains(suppliedName) ? 'reference_food' : 'generated_food'}/$suppliedName.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: const Offset(0, 8),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Color(0x8C000000),
                      BlendMode.srcIn,
                    ),
                    child: image,
                  ),
                ),
              ),
            ),
            image,
          ],
        ),
      );
    }
    final url = Uri.tryParse(recipe.imageUrl ?? '');
    final fallback = SizedBox(
      width: size,
      height: size,
      child: const Icon(Icons.restaurant_outlined),
    );
    final illustration = EgyptianDishArt.ids.contains(recipe.id)
        ? EgyptianDishArt(dishId: recipe.id, size: size)
        : fallback;
    if (url == null || url.scheme != 'https') return illustration;
    // Photo pilot: these source-page bindings were rechecked 2026-11-23.
    // Remaining imagery stays unchanged until the in-app pilot is reviewed.
    const verifiedPhotoPilot = {
      'themealdb_52963',
      'themealdb_53025',
      'themealdb_53026',
      'themealdb_53027',
    };
    if (verifiedPhotoPilot.contains(recipe.id)) {
      return Semantics(
        image: true,
        label: Localizations.localeOf(context).languageCode == 'ar'
            ? 'صورة توضيحية للطبق، مش قياس للحصة'
            : 'Dish photograph, not a portion measurement',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size > 100 ? 24 : 12),
          child: Image.network(
            url.toString(),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : fallback,
          ),
        ),
      );
    }
    return illustration;
  }
}

class _RecipeRingPainter extends CustomPainter {
  const _RecipeRingPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: 92);
    for (var i = 0; i < 36; i++) {
      canvas.drawArc(rect, i * math.pi / 18, math.pi / 30, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RecipeRingPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../recipes/presentation/screens/recipe_detail_screen.dart';
import '../../../recipes/data/datasources/local_recipe_data_source.dart';
import '../../../recipes/domain/ingredient_recipe_matcher.dart';
import '../../../recipes/domain/recipe_catalog_repository.dart';

/// Explicit local lookup. Typed chat and private health data are not inputs.
class CoachRecipePanel extends StatefulWidget {
  const CoachRecipePanel({super.key, this.repository});
  final RecipeCatalogRepository? repository;
  @override
  State<CoachRecipePanel> createState() => _CoachRecipePanelState();
}

class _CoachRecipePanelState extends State<CoachRecipePanel> {
  final _input = TextEditingController();
  List<IngredientRecipeMatch>? _matches;
  List<String> _inputs = const [];
  double? _maxMinutes;
  bool _busy = false;
  bool _failed = false;
  bool _licenseBlocked = false;
  int _generation = 0;

  @override
  void dispose() {
    _generation++;
    _input.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final inputs = _input.text
        .split(RegExp('[,،\n]'))
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    if (_busy || (inputs.isEmpty && _maxMinutes == null)) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _failed = false;
      _licenseBlocked = false;
      _matches = null;
    });
    try {
      final records = await (widget.repository ?? RecipeCatalogRepository())
          .getAll();
      final matches = IngredientRecipeMatcher.match(
        records,
        RecipeRequest(
          mealType: '',
          ingredients: inputs,
          maxCookingMinutes: _maxMinutes,
        ),
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _matches = matches.take(3).toList();
        _inputs = inputs;
      });
    } on RecipeLicenseException {
      if (mounted && generation == _generation) {
        setState(() => _licenseBlocked = true);
      }
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _failed = true);
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String t(String a, String e) => ar ? a : e;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          minTileHeight: 64,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          shape: const Border(),
          collapsedShape: const Border(),
          key: const ValueKey('coach_recipe_lookup'),
          leading: const Icon(Icons.soup_kitchen_outlined),
          title: Text(t('نطبخ إيه بالموجود؟', 'What can we cook?')),
          childrenPadding: const EdgeInsets.all(14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(
                'افصل المكونات بفاصلة، زي رز، عدس. البحث على جهازك، من غير إرسال المكونات للمحادثة.',
                'Separate ingredients with commas, like rice, lentils. Local search only. Ingredients are not sent with chat.',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('coach_recipe_ingredients'),
              controller: _input,
              maxLength: 300,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: t('المكونات المتاحة', 'Available ingredients'),
              ),
              onChanged: (_) => setState(() {
                _matches = null;
                _failed = false;
                _licenseBlocked = false;
              }),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final minutes in <double?>[null, 30, 60, 90])
                  ChoiceChip(
                    shape: const StadiumBorder(),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .3),
                    ),
                    label: Text(
                      minutes == null
                          ? t('أي وقت', 'Any time')
                          : '${minutes.toInt()} ${t('دقيقة', 'min')}',
                    ),
                    selected: _maxMinutes == minutes,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() {
                            _maxMinutes = minutes;
                            _matches = null;
                          }),
                  ),
              ],
            ),
            Text(
              t(
                'فلتر الوقت للوصفات اللي ليها وقت كلي موثق بس. أغلب الكتالوج وقته غير متاح.',
                'Time filters include only recipes with a sourced total time. Most catalog times are unknown.',
              ),
            ),
            FilledButton.icon(
              key: const ValueKey('coach_recipe_search'),
              onPressed:
                  _busy || (_input.text.trim().isEmpty && _maxMinutes == null)
                  ? null
                  : _search,
              icon: const Icon(Icons.search),
              label: Text(
                _busy
                    ? t('بندور…', 'Searching...')
                    : t('دور في الوصفات', 'Find recipes'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t(
                'مطابقة مكونات بس، مش توصية صحية. راجع الحساسية وباقي المكونات. الأسعار والتغذية مش متاحة. الوقت بيظهر بس لما يكون موثق.',
                'Ingredient matches, not health advice. Check allergies and all ingredients. Prices and nutrition are unavailable. Time is shown only when sourced.',
              ),
            ),
            if (_matches != null && _matches!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  t(
                    'كتالوج تجريبي. النشر محتاج ترخيص الوصفات.',
                    'Development catalog. Distribution licensing is still needed.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (_failed)
              Text(
                t(
                  'الوصفات مش متاحة دلوقتي. جرب تاني.',
                  'Could not load recipes. Try again.',
                ),
              ),
            if (_licenseBlocked)
              Text(
                t(
                  'الوصفات دي متاحة لنسخة التطوير بس لحد استكمال الترخيص.',
                  'These recipes are development-only until distribution licensing is settled.',
                ),
              ),
            if (_matches != null && _matches!.isEmpty)
              Text(
                t(
                  'ملقيناش مطابقة للمكونات دي في الوصفات المتاحة. جرب اسم مكون واحد.',
                  'No matching ingredients in the available recipes. Try one ingredient name.',
                ),
              ),
            for (final match in _matches ?? <IngredientRecipeMatch>[])
              _recipeCard(match, ar),
          ],
        ),
      ),
    );
  }

  Widget _recipeCard(IngredientRecipeMatch match, bool ar) {
    final LocalRecipeRecord recipe = match.recipe;
    final unmatched = _inputs
        .where((v) => !match.matchedInputs.contains(v))
        .toList();
    return GlassCard(
      key: ValueKey('coach_recipe_card_${recipe.id}'),
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: .35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: RecipeSourceImage(recipe: recipe, size: 112)),
          const SizedBox(height: 8),
          Text(
            ar ? (recipe.nameAr ?? recipe.nameEn) : recipe.nameEn,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (recipe.cookingMinutes != null)
            Text(
              ar
                  ? 'الوقت الكلي حسب المصدر: ${recipe.cookingMinutes!.toInt()} دقيقة، شامل التجهيز والراحة.'
                  : 'Source total: ${recipe.cookingMinutes!.toInt()} minutes, including preparation and resting.',
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final input in match.matchedInputs)
                Chip(
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .3),
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .08),
                  avatar: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(input),
                ),
            ],
          ),
          if (unmatched.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                ar
                    ? 'مش مطابق: ${unmatched.join('، ')}'
                    : 'Not matched: ${unmatched.join(', ')}',
              ),
            ),
          const SizedBox(height: 6),
          Text(
            ar
                ? 'المصدر مسجّل ${recipe.ingredients.length} مكونات. راجع اللي ناقصك.'
                : '${recipe.ingredients.length} listed ingredients. Check what else you need.',
          ),
          if (recipe.id == 'themealdb_53027')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                ar
                    ? 'الوصفة المنقولة ناقصة. راجع تنبيه المصدر قبل الطبخ.'
                    : 'Imported recipe is incomplete. Read the source warning before cooking.',
              ),
            ),
          TextButton.icon(
            key: ValueKey('coach_recipe_open_${recipe.id}'),
            onPressed: () =>
                context.push('/recipe/${Uri.encodeComponent(recipe.id)}'),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(ar ? 'شوف الوصفة' : 'View recipe'),
          ),
        ],
      ),
    );
  }
}

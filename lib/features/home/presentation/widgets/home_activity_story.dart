import '../../../../core/widgets/catalog_food_art.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/viewport_reveal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../cubit/home_cubit.dart';

/// Read-only story of recorded activity. No reward or health claim is inferred.
class HomeActivityStory extends StatelessWidget {
  const HomeActivityStory({super.key, required this.data, required this.now});
  final HomeLoaded data;
  final DateTime now;
  Widget _favoriteArt(String mealId) {
    // Only a matching recorded meal establishes food identity. Never infer a
    // dish from a favorite title or replace an unknown composite with a photo.
    final matches = data.todaysMeals.where((m) => m.mealId == mealId);
    if (matches.isNotEmpty && matches.first.items.length == 1) {
      return CatalogFoodArt(id: matches.first.items.single.foodId, size: 54);
    }
    return const Icon(Icons.restaurant_outlined, color: AppColors.pinkLight);
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final reduced = MediaQuery.disableAnimationsOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - 6 + i),
    );
    final active = {
      for (final log in data.recentLogs)
        if (log.mealCount > 0) log.dateKey,
    };
    final count = days
        .where((d) => active.contains(SufraDateUtils.toDateKey(d)))
        .length;
    final meals = data.todaysMeals.length;
    final favoriteMeals = data.favorites
        .where((f) => f.targetType == 'meal')
        .take(6)
        .toList();
    final title = ar
        ? (meals == 0 ? 'يومك لسه قدامه حكاية' : 'كل تسجيل بيوضح يومك أكتر')
        : (meals == 0
              ? 'Your day is still unfolding'
              : 'Each log tells more of your day');
    return ViewportReveal(
      builder: (context, visible) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            onTap: () => context.push('/stats'),
            gradient: LinearGradient(
              colors: dark
                  ? const [Color(0xAA163F60), Color(0xAA372858)]
                  : const [Color(0xF0E6F5FC), Color(0xE8F0E9FA)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 450),
                  child: Text(
                    title,
                    key: ValueKey(title),
                    style: context.readableDisplayStyle(size: 19),
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: reduced ? count.toDouble() : 0,
                    end: visible ? count.toDouble() : 0,
                  ),
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 1100),
                  builder: (context, value, _) => Text(
                    ar
                        ? 'سجّلت وجبات في ${value.round()} من آخر 7 أيام'
                        : '${value.round()} days with logged meals in the last 7 days',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    for (final pair in days.indexed)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: reduced ? 1 : 0,
                              end: visible ? 1 : 0,
                            ),
                            duration: Duration(
                              milliseconds: reduced ? 0 : 500 + pair.$1 * 90,
                            ),
                            builder: (context, v, _) => Column(
                              children: [
                                Transform.scale(
                                  scale: .6 + .4 * v,
                                  child: Container(
                                    height:
                                        active.contains(
                                          SufraDateUtils.toDateKey(pair.$2),
                                        )
                                        ? 34
                                        : 12,
                                    decoration: BoxDecoration(
                                      color:
                                          active.contains(
                                            SufraDateUtils.toDateKey(pair.$2),
                                          )
                                          ? AppColors.turquoise
                                          : (dark
                                                ? Colors.white24
                                                : AppColors.primaryBlue
                                                      .withValues(alpha: .15)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${pair.$2.day}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ar
                      ? 'الأقدم شمال، والأحدث يمين. ده سجل وجبات، مش تقييم ليومك.'
                      : 'Oldest left, latest right. Meal records, not a score for your day.',
                  style: context.mutedStyle(size: 11),
                ),
                const SizedBox(height: 12),
                Text(
                  ar
                      ? 'وجبات النهاردة: $meals · اعرض نشاطك'
                      : 'Meals logged today: $meals · View activity',
                  style: TextStyle(
                    fontSize: 12,
                    color: dark ? AppColors.cyanLight : AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ar ? 'أكلات بتحب ترجع لها' : 'Meals you like coming back to',
            style: context.readableDisplayStyle(size: 19),
          ),
          const SizedBox(height: 8),
          if (favoriteMeals.isEmpty)
            GlassCard(
              onTap: () async {
                await context.push('/favorites');
                if (context.mounted && data.profile != null) {
                  await context.read<HomeCubit>().load(data.profile!.uid);
                }
              },
              child: Text(
                ar
                    ? (data.favoritesAvailable
                          ? 'احفظ وجباتك في المفضلة عشان تلاقيها هنا.'
                          : 'مش قادرين نحمّل المفضلة دلوقتي. افتحها للمحاولة تاني.')
                    : (data.favoritesAvailable
                          ? 'Save meals to favorites to see them here.'
                          : 'Favorites could not be loaded. Open them to try again.'),
              ),
            )
          else
            SizedBox(
              height:
                  108 +
                  (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(
                        0,
                        42,
                      ) *
                      3,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: favoriteMeals.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => AnimatedSlide(
                  offset: visible || reduced
                      ? Offset.zero
                      : const Offset(.15, 0),
                  duration: Duration(milliseconds: reduced ? 0 : 550 + i * 120),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: visible || reduced ? 1 : 0,
                    duration: Duration(
                      milliseconds: reduced ? 0 : 450 + i * 100,
                    ),
                    child: SizedBox(
                      width:
                          (210 +
                                  (MediaQuery.textScalerOf(context).scale(14) -
                                          14) *
                                      8)
                              .clamp(
                                210,
                                (MediaQuery.sizeOf(context).width - 32).clamp(
                                  210,
                                  double.infinity,
                                ),
                              ),
                      child: GlassCard(
                        onTap: () async {
                          await context.push('/favorites');
                          if (context.mounted && data.profile != null) {
                            await context.read<HomeCubit>().load(
                              data.profile!.uid,
                            );
                          }
                        },
                        gradient: LinearGradient(
                          colors: [
                            (i.isEven
                                    ? AppColors.aiPurple
                                    : AppColors.primaryBlue)
                                .withValues(alpha: dark ? .5 : .10),
                            dark
                                ? const Color(0x6622D3EE)
                                : const Color(0xE8E7F9FC),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 54,
                                height: 54,
                                child:
                                    favoriteMeals[i].imageUrl != null &&
                                        Uri.tryParse(
                                              favoriteMeals[i].imageUrl!,
                                            )?.scheme ==
                                            'https'
                                    ? Image.network(
                                        favoriteMeals[i].imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.image_not_supported_outlined,
                                        ),
                                      )
                                    : _favoriteArt(favoriteMeals[i].targetId),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                favoriteMeals[i].title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/home/presentation/widgets/home_activity_story.dart';
import 'package:sufradepi/features/home/presentation/cubit/home_cubit.dart';
import 'package:sufradepi/data/models/favorite_model.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets(
      'record-only activity/favorites renders with reduced=$reduced',
      (t) async {
        await t.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: HomeActivityStory(
                    now: DateTime(2026, 11, 24),
                    data: const HomeLoaded(
                      profile: null,
                      nutritionProfile: null,
                      todaysMeals: [],
                      dailyLog: null,
                      streakDays: 0,
                      favorites: [
                        FavoriteModel(
                          favoriteId: 'm',
                          targetId: 'x',
                          targetType: 'meal',
                          title: 'Saved meal',
                        ),
                        FavoriteModel(
                          favoriteId: 'r',
                          targetId: 'y',
                          targetType: 'recipe',
                          title: 'Recipe not meal',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pump(const Duration(seconds: 2));
        expect(find.text('Saved meal'), findsOneWidget);
        expect(find.text('Recipe not meal'), findsNothing);
        expect(
          find.text('0 days with logged meals in the last 7 days'),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}

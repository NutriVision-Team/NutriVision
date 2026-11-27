import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'package:sufradepi/features/alternatives/domain/alternatives_repository.dart';
import 'package:sufradepi/features/alternatives/domain/food_preference_filter.dart';
import 'package:sufradepi/features/alternatives/presentation/screens/alternatives_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../planning/plan_generator_test.dart' show food;

class FixedAlternatives extends AlternativesRepository {
  @override
  Future<List<FoodAlternative>> getAll() async => [
    for (final (id, cat) in [
      ('chicken', 'poultry'),
      ('milk', 'dairy'),
      ('rice', 'grains'),
    ])
      FoodAlternative(
        id: id,
        original: food('original', 'grains', 100),
        alternative: food(id, cat, 90),
        reasonAr: 'fixture',
        reasonEn: 'fixture',
        comparisons: const {},
      ),
  ];
}

NutritionProfileModel profile(String preference) => NutritionProfileModel(
  profileId: 'p',
  gender: 'male',
  dateOfBirth: DateTime(2000),
  heightCm: 180,
  currentWeightKg: 80,
  targetWeightKg: 75,
  activityLevel: 'sedentary',
  nutritionGoal: 'lose',
  dailyCalorieTarget: 2000,
  proteinTarget: 100,
  carbsTarget: 250,
  fatTarget: 70,
  dietaryPreferences: [preference],
);
void main() {
  test(
    'allergy synonyms and dietary categories exclude incompatible alternatives',
    () {
      expect(
        FoodPreferenceFilter.allows(
          food('yogurt', 'dairy', 60),
          allergies: ['حليب'],
        ),
        isFalse,
      );
      expect(
        FoodPreferenceFilter.allows(
          food('chicken', 'poultry', 165),
          dietaryPreferences: ['vegetarian'],
        ),
        isFalse,
      );
      expect(
        FoodPreferenceFilter.allows(
          food('egg', 'eggs', 100),
          dietaryPreferences: ['vegan'],
        ),
        isFalse,
      );
      expect(
        FoodPreferenceFilter.allows(
          food('rice', 'grains', 100),
          dietaryPreferences: ['vegan'],
        ),
        isTrue,
      );
      expect(
        FoodPreferenceFilter.allows(
          food('rice', 'grains', 100),
          dietaryPreferences: ['unknown medical diet'],
        ),
        isFalse,
      );
      expect(
        FoodPreferenceFilter.allows(
          food('tuna', 'fish', 100),
          allergies: ['سمك'],
        ),
        isFalse,
      );
    },
  );
  testWidgets('stale preference load cannot replace current-account results', (
    t,
  ) async {
    final old = Completer<NutritionProfileModel?>();
    final repo = FixedAlternatives();
    Widget host(Future<NutritionProfileModel?> Function() load) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AlternativesScreen(repository: repo, loadProfile: load),
    );
    await t.pumpWidget(host(() => old.future));
    await t.pump();
    await t.pumpWidget(host(() async => profile('vegan')));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.text('rice'), findsOneWidget);
    expect(find.text('chicken'), findsNothing);
    expect(find.text('milk'), findsNothing);
    old.complete(profile('vegetarian'));
    await t.pump();
    expect(find.text('milk'), findsNothing);
    await t.pumpWidget(const SizedBox.shrink());
  });
}

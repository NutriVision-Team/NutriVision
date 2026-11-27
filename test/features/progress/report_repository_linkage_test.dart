import 'package:sufradepi/features/progress/export/coach_report_snapshot.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/features/food_catalog/data/local_food_repository.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/progress/presentation/cubit/progress_cubit.dart';
import 'package:sufradepi/features/progress/presentation/cubit/weight_cubit.dart';
import 'package:sufradepi/features/progress/export/nutrition_pdf_document.dart';
import '../../support/memory_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'catalog save to real repository aggregate to selected range to extracted PDF',
    () async {
      final store = MemoryFirestore();
      final repo = FirestoreNutritionRepository(store);
      final food = (await LocalFoodRepository().getFoodById('usda_sr_168878'));
      expect(food, isNotNull);
      final draft = CatalogMealDraft([FoodPortion(food!, 225)]);
      final meal = draft.toMeal(
        uid: 'report-qa',
        id: 'rice',
        at: DateTime(2026, 11, 20),
        mealType: 'lunch',
      );
      await repo.saveMealEntry('report-qa', meal);
      final c = ProgressCubit(
        nutritionRepository: repo,
        uid: 'report-qa',
        currentUid: () => 'report-qa',
      );
      await c.loadRange(DateTime(2026, 11, 19), DateTime(2026, 11, 21));
      expect(c.state.failed, isFalse);
      expect(c.state.days.map((d) => d.tracked), [false, true, false]);
      expect(c.state.days[1].calories, meal.totalCalories);
      expect(c.state.days[1].protein, meal.totalProtein);
      expect(c.state.averages.calories, meal.totalCalories);
      for (final lang in ['en', 'ar']) {
        final data = NutritionReportData(
          days: c.state.days,
          coach: CoachReportSnapshot(
            ownerUid: 'report-qa',
            goals: [lang == 'ar' ? 'تنويع الأكل' : 'My selected goal'],
            habits: ['log_meal', 'prepare_meal'],
            checkins: {
              '2026-11-20': {'log_meal', 'prepare_meal'},
              '2026-10-01': {'prepare_meal'},
            },
          ),
          weight: WeightState(
            activeProfile: NutritionProfileModel(
              profileId: 'qa',
              gender: 'male',
              dateOfBirth: DateTime(2000, 12, 1),
              heightCm: 175,
              currentWeightKg: 90,
              targetWeightKg: 80,
              activityLevel: 'moderate',
              nutritionGoal: 'lose',
              dailyCalorieTarget: 2000,
              proteinTarget: 100,
              carbsTarget: 200,
              fatTarget: 60,
            ),
          ),
          l10n: await AppLocalizations.delegate.load(Locale(lang)),
          displayName: lang == 'ar' ? 'بيانات اختبار' : 'QA example',
        );
        final bytes = await NutritionPdfDocument.generate(data);
        final file = File(
          '/downloads/sufra/verification/repository_report_$lang.pdf',
        );
        await file.writeAsBytes(bytes);
        final extracted = await Process.run('pdftotext', [
          '-layout',
          file.path,
          '-',
        ]);
        expect(extracted.exitCode, 0);
        final text = extracted.stdout as String;
        if (lang == 'en') {
          expect(text, contains('My selected goal'));
          expect(text, contains('Log one meal, Prepare for a meal'));
          expect(text, isNot(contains('،')));
        }
        expect(text, isNot(contains('2026-10-01')));
        expect(text, contains('175'));
        expect(text, contains('29.4'));
        expect(text, contains('2026-11-19'));
        expect(text, contains('2026-11-21'));
        expect(text, contains(NutritionPdfDocument.num(meal.totalCalories)));
      }
      await c.close();
    },
  );
}

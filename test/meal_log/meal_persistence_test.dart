import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import '../support/memory_firestore.dart';

MealEntryModel record({
  String id = 'm1',
  int day = 20,
  double calories = 200,
  double? protein = 10,
  String uid = 'u1',
}) => FoodPortion(
  FoodCatalogModel(
    foodId: 'f1',
    name: 'Fixture food',
    source: 'test fixture',
    nutritionPer100g: {'calories': calories, 'protein': protein},
  ),
  100,
).toMeal(uid: uid, id: id, at: DateTime(2026, 11, day), mealType: 'lunch');
Map<String, dynamic> stored(MealEntryModel m) => {
  ...m.toMap(),
  'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 1)),
  'updatedAt': null,
};
String mealPath(String id) => 'users/u1/meal_entries/$id';
String logPath(int day) => 'users/u1/daily_logs/2026-11-$day';
void main() {
  late MemoryFirestore store;
  late FirestoreNutritionRepository repository;
  setUp(() {
    store = MemoryFirestore();
    repository = FirestoreNutritionRepository(store);
  });
  test(
    'save rebuilds stale legacy totals and preserves water and target',
    () async {
      store.seed(mealPath('old'), stored(record(id: 'old', calories: 400)));
      store.seed(logPath(20), {
        'dateKey': '2026-11-20',
        'totalCalories': 999,
        'waterIntakeMl': 750,
        'calorieTarget': 1850,
        'timezone': 'Africa/Cairo',
      });
      await repository.saveMealEntry('u1', record());
      final daily = store.documents[logPath(20)]!;
      expect(daily['totalCalories'], 600);
      expect(daily['mealCount'], 2);
      expect(daily['waterIntakeMl'], 750);
      expect(daily['calorieTarget'], 1850);
      expect(daily['timezone'], 'Africa/Cairo');
      expect(daily['totalFiber'], isNull);
    },
  );
  test(
    'same-ID save retry replaces rather than double counting and keeps creation timestamp',
    () async {
      await repository.saveMealEntry('u1', record());
      final created = store.documents[mealPath('m1')]!['createdAt'];
      await repository.saveMealEntry('u1', record(calories: 350));
      await repository.saveMealEntry('u1', record(calories: 350));
      expect(store.documents[logPath(20)]!['mealCount'], 1);
      expect(store.documents[logPath(20)]!['totalCalories'], 350);
      expect(store.documents[mealPath('m1')]!['createdAt'], created);
    },
  );
  test(
    'deleting the last meal clears nutritional aggregate without clearing water; repeat is safe',
    () async {
      store.seed(logPath(20), {'waterIntakeMl': 500});
      await repository.saveMealEntry('u1', record());
      await repository.deleteMealEntry('u1', 'm1');
      await repository.deleteMealEntry('u1', 'm1');
      expect(store.documents.containsKey(mealPath('m1')), isFalse);
      expect(store.documents[logPath(20)]!['mealCount'], 0);
      expect(store.documents[logPath(20)]!['totalCalories'], 0);
      expect(store.documents[logPath(20)]!['waterIntakeMl'], 500);
    },
  );
  test(
    'changing a meal date updates both date aggregates atomically',
    () async {
      await repository.saveMealEntry('u1', record());
      await repository.saveMealEntry('u1', record(day: 21));
      expect(store.documents[logPath(20)]!['mealCount'], 0);
      expect(store.documents[logPath(21)]!['mealCount'], 1);
      expect(store.documents[logPath(21)]!['totalCalories'], 200);
    },
  );
  test(
    'transport failure before commit leaves neither partial meal nor partial daily total',
    () async {
      store.failNextCommit = true;
      await expectLater(
        repository.saveMealEntry('u1', record()),
        throwsStateError,
      );
      expect(store.documents, isEmpty);
    },
  );
  test(
    'concurrent app commit causes retry and latest complete aggregate',
    () async {
      store.seed(logPath(20), {'waterIntakeMl': 250});
      store.beforeCommit = () {
        store.seed(
          mealPath('other'),
          stored(record(id: 'other', calories: 100)),
        );
        store.seed(logPath(20), {
          'waterIntakeMl': 500,
          'totalCalories': 100,
          'mealCount': 1,
        });
      };
      await repository.saveMealEntry('u1', record());
      expect(store.attempts, 2);
      expect(store.documents[logPath(20)]!['totalCalories'], 300);
      expect(store.documents[logPath(20)]!['mealCount'], 2);
      expect(store.documents[logPath(20)]!['waterIntakeMl'], 500);
    },
  );
  test(
    'wrong ownership and malformed IDs are rejected before writes',
    () async {
      await expectLater(
        repository.saveMealEntry('u1', record(uid: 'other')),
        throwsArgumentError,
      );
      await expectLater(
        repository.deleteMealEntry('u1', 'bad/path'),
        throwsArgumentError,
      );
      expect(store.documents, isEmpty);
      store.seed(mealPath('m1'), stored(record(uid: 'other')));
      await expectLater(
        repository.deleteMealEntry('u1', 'm1'),
        throwsStateError,
      );
      expect(store.documents[mealPath('m1')]!['userId'], 'other');
    },
  );
  test(
    'unknown optional nutrients survive persistence and daily totals',
    () async {
      await repository.saveMealEntry('u1', record(protein: null));
      final meal = MealEntryModel.fromMap(
        'm1',
        store.documents[mealPath('m1')]!,
      );
      expect(meal.totalProtein, isNull);
      expect(meal.items.single.fiber, isNull);
      final daily = DailyLogModel.fromMap(store.documents[logPath(20)]!);
      expect(daily.totalProtein, isNull);
      expect(daily.totalCalories, 200);
    },
  );
  test(
    'water-only daily records do not invent calorie or macro measurements',
    () {
      final daily = DailyLogModel.fromMap({
        'dateKey': '2026-11-20',
        'waterIntakeMl': 250,
      });
      expect(daily.totalCalories, isNull);
      expect(daily.totalProtein, isNull);
      expect(daily.waterIntakeMl, 250);
    },
  );
  test(
    'missing primary energy fails parsing instead of silently becoming zero',
    () {
      final map = stored(record())..remove('totalCalories');
      expect(() => MealEntryModel.fromMap('m1', map), throwsFormatException);
    },
  );
}

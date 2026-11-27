import 'support/persistence_fixtures.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/favorite_model.dart';
import 'package:sufradepi/data/models/achievement_model.dart';
import 'package:sufradepi/features/recipes/data/persistence/cloud_recipe_favorites.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';
import 'package:sufradepi/features/achievements/domain/achievement_activity.dart';
import 'package:sufradepi/features/achievements/data/persistence/achievement_progress_store.dart';

AchievementActivity sample(String uid, {int mealCount = 0}) =>
    AchievementActivity(
      userId: uid,
      loggedDays: const {},
      mealCount: mealCount,
      distinctFoods: const {},
      mealTypesByDay: const {},
      categoriesByDay: const {},
    );
AchievementRule rule({
  String id = 'first',
  int target = 1,
  String condition = 'meal_log_count',
}) => AchievementRule(
  id: id,
  titleAr: 'fixture',
  titleEn: 'fixture',
  descriptionAr: 'fixture',
  descriptionEn: 'fixture',
  condition: condition,
  target: target,
  parameters: const {},
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'cloud favorites persist recipe metadata and repeated saves are idempotent',
    () async {
      final backend = MemoryFavoritesBackend();
      final store = CloudRecipeFavorites(
        userId: 'a',
        activeUserId: () => 'a',
        backend: backend,
        catalog: RecipeCatalogRepository(),
      );
      await Future.wait([
        store.setSaved('themealdb_52963', true),
        store.setSaved('themealdb_52963', true),
      ]);
      expect(backend.operations.length, 1);
      expect(store.read(), {'themealdb_52963'});
      expect(backend.values.single.targetType, 'recipe');
      expect(backend.values.single.title, isNotEmpty);
      final reopened = CloudRecipeFavorites(
        userId: 'a',
        activeUserId: () => 'a',
        backend: backend,
        catalog: RecipeCatalogRepository(),
      );
      await reopened.load();
      expect(reopened.read(), {'themealdb_52963'});
      await reopened.setSaved('themealdb_52963', false);
      await reopened.setSaved('themealdb_52963', false);
      expect(backend.operations.length, 2);
      expect(reopened.read(), isEmpty);
    },
  );
  test(
    'cloud favorites delete existing legacy IDs rather than a guessed path',
    () async {
      final backend = MemoryFavoritesBackend()
        ..values = [
          const FavoriteModel(
            favoriteId: 'old-generated-id',
            targetId: 'themealdb_52963',
            targetType: 'recipe',
            title: 'fixture',
          ),
          const FavoriteModel(
            favoriteId: 'duplicate-generated-id',
            targetId: 'themealdb_52963',
            targetType: 'recipe',
            title: 'fixture',
          ),
        ];
      final store = CloudRecipeFavorites(
        userId: 'a',
        activeUserId: () => 'a',
        backend: backend,
        catalog: RecipeCatalogRepository(),
      );
      await store.setSaved('themealdb_52963', false);
      expect(backend.operations, [
        'a:delete:old-generated-id',
        'a:delete:duplicate-generated-id',
      ]);
      expect(backend.values, isEmpty);
    },
  );
  test(
    'failed favorite writes do not show success or contaminate saved cache',
    () async {
      final backend = MemoryFavoritesBackend()..fail = true;
      final store = CloudRecipeFavorites(
        userId: 'a',
        activeUserId: () => 'a',
        backend: backend,
        catalog: RecipeCatalogRepository(),
      );
      await expectLater(
        store.setSaved('themealdb_52963', true),
        throwsStateError,
      );
      expect(store.read(), isEmpty);
      expect(backend.operations, isEmpty);
      backend.fail = false;
      await store.setSaved('themealdb_52963', true);
      expect(store.read(), {'themealdb_52963'});
    },
  );
  test(
    'active-UID change rejects late favorite load before any write',
    () async {
      var active = 'a';
      final backend = MemoryFavoritesBackend()
        ..pending = Completer<List<FavoriteModel>>();
      final store = CloudRecipeFavorites(
        userId: 'a',
        activeUserId: () => active,
        backend: backend,
        catalog: RecipeCatalogRepository(),
      );
      final loading = store.setSaved('themealdb_52963', true);
      await Future<void>.delayed(Duration.zero);
      active = 'b';
      backend.pending!.complete([]);
      await expectLater(loading, throwsStateError);
      expect(backend.operations, isEmpty);
      expect(store.read, throwsStateError);
    },
  );
  test(
    'first historical earned threshold keeps unknown unlock time and persists observation time',
    () async {
      final backend = MemoryAchievementsBackend();
      final store = AchievementProgressStore(
        userId: 'a',
        activeUserId: () => 'a',
        backend: backend,
      );
      final result = await store.synchronize(sample('a', mealCount: 2), [
        rule(),
      ]);
      expect(result.records.single.isUnlocked, isTrue);
      expect(result.records.single.unlockedAt, isNull);
      expect(result.records.single.createdAt, backend.observedTime);
      expect(result.newUnlockIds, isEmpty);
      await store.synchronize(sample('a', mealCount: 2), [rule()]);
      expect(backend.writes, 1);
    },
  );
  test(
    'genuine observed transition unlocks once and preserves timestamp across visits',
    () async {
      final backend = MemoryAchievementsBackend();
      final store = AchievementProgressStore(
        userId: 'a',
        activeUserId: () => 'a',
        backend: backend,
      );
      await store.synchronize(sample('a'), [rule()]);
      final result = await store.synchronize(sample('a', mealCount: 1), [
        rule(),
      ]);
      expect(result.newUnlockIds, {'first'});
      expect(result.records.single.unlockedAt, backend.observedTime);
      final repeated = await store.synchronize(sample('a', mealCount: 1), [
        rule(),
      ]);
      expect(repeated.newUnlockIds, isEmpty);
      expect(repeated.records.single.unlockedAt, backend.observedTime);
      expect(backend.writes, 2);
      final afterDeletion = await store.synchronize(sample('a'), [rule()]);
      expect(afterDeletion.records.single.isUnlocked, isTrue);
      expect(afterDeletion.records.single.progress, 1);
    },
  );
  test(
    'unverified rules never create earned state or fabricated progress',
    () async {
      final backend = MemoryAchievementsBackend();
      final store = AchievementProgressStore(
        userId: 'a',
        activeUserId: () => 'a',
        backend: backend,
      );
      final result = await store.synchronize(sample('a'), [
        rule(condition: 'water_goal_reached_days'),
      ]);
      expect(result.records, isEmpty);
      expect(backend.writes, 0);
    },
  );
  test(
    'achievement store rejects wrong activity UID and late old-account results',
    () async {
      var active = 'a';
      final backend = MemoryAchievementsBackend();
      final store = AchievementProgressStore(
        userId: 'a',
        activeUserId: () => active,
        backend: backend,
      );
      await expectLater(
        store.synchronize(sample('b'), [rule()]),
        throwsStateError,
      );
      expect(backend.writes, 0);
      backend.pending = Completer<void>();
      final future = store.synchronize(sample('a'), [rule()]);
      active = 'b';
      backend.pending!.complete();
      await expectLater(future, throwsStateError);
    },
  );
  test(
    'reconciliation preserves prior timestamps and malformed baselines cannot invent unlock dates',
    () {
      final stamp = DateTime.utc(2026, 1, 1);
      final old = AchievementModel(
        achievementId: 'first',
        achievementType: 'meal_log_count',
        title: 'fixture',
        description: 'fixture',
        progress: 0,
        target: 1,
        isUnlocked: false,
        createdAt: stamp,
        unlockedAt: stamp,
      );
      final plan = planAchievement(
        old,
        AchievementObservation(rule: rule(), progress: 1),
      );
      expect(plan.model.createdAt, stamp);
      expect(plan.model.unlockedAt, stamp);
      final unknownBaseline = planAchievement(
        old,
        AchievementObservation(rule: rule(), progress: 1),
        verifiedLockedBaseline: false,
      );
      expect(unknownBaseline.observedUnlock, isFalse);
    },
  );
  test(
    'changed criteria or an already-met historical baseline never invent a new unlock time',
    () {
      final old = AchievementModel(
        achievementId: 'first',
        achievementType: 'meal_log_count',
        title: 'fixture',
        description: 'fixture',
        progress: 2,
        target: 5,
        isUnlocked: false,
      );
      final changed = planAchievement(
        old,
        AchievementObservation(rule: rule(), progress: 2),
      );
      expect(changed.model.isUnlocked, isTrue);
      expect(changed.observedUnlock, isFalse);
      expect(changed.model.unlockedAt, isNull);
      final inconsistent = AchievementModel(
        achievementId: 'first',
        achievementType: 'meal_log_count',
        title: 'fixture',
        description: 'fixture',
        progress: 1,
        target: 1,
        isUnlocked: false,
      );
      expect(
        planAchievement(
          inconsistent,
          AchievementObservation(rule: rule(), progress: 1),
        ).observedUnlock,
        isFalse,
      );
    },
  );
}

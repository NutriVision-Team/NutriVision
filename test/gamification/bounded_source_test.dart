import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/data/models/meal_plan_model.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';
import 'package:sufradepi/features/gamification/data/bounded_firestore_progression.dart';
import 'production_dataflow_test.dart' show meal;

void main() {
  test(
    'bounded live cache no repeated subscriptions/queries during recalculation',
    () async {
      final meals = StreamController<List<MealEntryModel>>(),
          plans = StreamController<List<MealPlanModel>>(),
          profile = StreamController<UserProfileModel?>();
      var reads = 0;
      final source = BoundedProgressionSource(
        uid: 'u',
        currentUid: () => 'u',
        mealStream: () {
          reads++;
          return meals.stream;
        },
        planStream: () {
          reads++;
          return plans.stream;
        },
        profileStream: () {
          reads++;
          return profile.stream;
        },
      );
      final changes = source.watch().listen((_) {});
      meals.add([meal('m')]);
      plans.add([]);
      profile.add(null);
      expect((await source.meals()).length, 1);
      for (var i = 0; i < 20; i++) {
        await source.meals();
        await source.plans();
        await source.profile();
      }
      expect(reads, 3);
      meals.add([meal('m'), meal('n')]);
      await Future<void>.delayed(Duration.zero);
      expect((await source.meals()).length, 2);
      expect(reads, 3);
      await changes.cancel();
      expect(meals.hasListener, isFalse);
      await meals.close();
      await plans.close();
      await profile.close();
    },
  );
  test(
    'overflow cannot silently return partial history; recovery clears only its source error',
    () async {
      final meals = StreamController<List<MealEntryModel>>(),
          plans = StreamController<List<MealPlanModel>>(),
          profile = StreamController<UserProfileModel?>();
      final source = BoundedProgressionSource(
        uid: 'u',
        currentUid: () => 'u',
        mealStream: () => meals.stream,
        planStream: () => plans.stream,
        profileStream: () => profile.stream,
      );
      final changes = source.watch().listen((_) {});
      plans.add([]);
      profile.add(null);
      meals.add(List.generate(501, (i) => meal('m$i')));
      await expectLater(
        source.meals(),
        throwsA(isA<ProgressionHistoryTooLarge>()),
      );
      profile.add(null);
      await Future<void>.delayed(Duration.zero);
      await expectLater(
        source.meals(),
        throwsA(isA<ProgressionHistoryTooLarge>()),
      );
      meals.add([meal('m')]);
      await Future<void>.delayed(Duration.zero);
      expect((await source.meals()).length, 1);
      await changes.cancel();
      await meals.close();
      await plans.close();
      await profile.close();
    },
  );
  test('cache cannot expose former owner after account changes', () async {
    String uid = 'u';
    final source = BoundedProgressionSource(
      uid: 'u',
      currentUid: () => uid,
      mealStream: () => Stream.value([meal('m')]),
      planStream: () => Stream.value([]),
      profileStream: () => Stream.value(null),
    );
    final changes = source.watch().listen((_) {});
    expect((await source.meals()).length, 1);
    uid = 'v';
    await expectLater(source.meals(), throwsStateError);
    await changes.cancel();
  });
}

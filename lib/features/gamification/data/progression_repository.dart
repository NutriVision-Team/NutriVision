import '../../../data/models/meal_entry_model.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/meal_plan_model.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../domain/progression_engine.dart';

abstract interface class ProgressionConfigSource {
  Future<ProgressionConfig> load();
}

/// Bundled rules are versioned data, not widget constants. A future approved
/// remote source must validate through the same parser before use.
class BundledProgressionConfigSource implements ProgressionConfigSource {
  @override
  Future<ProgressionConfig> load() async => ProgressionConfig.fromJson(
    jsonDecode(await rootBundle.loadString('assets/data/progression.json'))
        as Map<String, dynamic>,
  );
}

class ProgressionSnapshot {
  const ProgressionSnapshot(
    this.profile,
    this.config,
    this.events, {
    this.authoritative = false,
    this.activeDayCount,
    this.pendingCount = 0,
    this.draftPolicy = false,
    this.hasLedger = true,
  });
  final bool authoritative, draftPolicy, hasLedger;
  final int? activeDayCount;
  final int pendingCount;
  final ProgressionProfile profile;
  final ProgressionConfig config;
  final List<ProgressionEvent> events;
}

abstract interface class LiveProgressionRepository {
  Stream<void> watchChanges(String uid);
}

abstract interface class ProgressionRepository {
  Future<ProgressionSnapshot> load(String uid, String todayKey);
}

/// Read-only projection from owned records. There is no XP write API here.
/// Existing client-written achievement records are never trusted award input.
class ReadOnlyProgressionRepository
    implements ProgressionRepository, LiveProgressionRepository {
  ReadOnlyProgressionRepository({
    required this.nutrition,
    required this.currentUid,
    required this.profile,
    this.loadPlans,
    this.loadProfile,
    this.loadMeals,
    this.changes,
    ProgressionConfigSource? configSource,
  }) : configSource = configSource ?? BundledProgressionConfigSource();
  final Stream<void> Function(String uid)? changes;
  @override
  Stream<void> watchChanges(String uid) {
    _check(uid);
    return changes?.call(uid) ?? const Stream.empty();
  }

  final Future<UserProfileModel?> Function()? loadProfile;
  final Future<List<MealEntryModel>> Function()? loadMeals;
  final NutritionRepository nutrition;
  final String? Function() currentUid;
  final UserProfileModel? Function() profile;
  final Future<List<MealPlanModel>> Function(String uid)? loadPlans;
  final ProgressionConfigSource configSource;
  void _check(String uid) {
    if (uid.isEmpty || uid.contains('/') || currentUid() != uid) {
      throw StateError('Inactive progression owner');
    }
  }

  @override
  Future<ProgressionSnapshot> load(String uid, String todayKey) async {
    _check(uid);
    ProgressionEngine.date(todayKey);
    final config = await configSource.load();
    _check(uid);
    final meals = loadMeals == null
        ? await nutrition.getMealEntries(uid)
        : await loadMeals!();
    _check(uid);
    final owner = loadProfile == null ? profile() : await loadProfile!();
    _check(uid);
    if (owner != null && owner.uid != uid) {
      throw StateError('Profile owner mismatch');
    }
    final events = <ProgressionEvent>[
      if (owner?.onboardingCompleted ?? false)
        ProgressionEvent(
          uid: uid,
          sourceId: 'setup',
          kind: 'profile',
          dayKey: '',
        ),
    ];
    for (final meal in meals) {
      if (meal.userId != uid) throw StateError('Meal owner mismatch');
      if (meal.mealId.isEmpty ||
          meal.title.trim().isEmpty ||
          meal.analysisStatus != 'confirmed') {
        continue;
      }
      events.add(
        ProgressionEvent(
          uid: uid,
          sourceId: meal.mealId,
          kind: 'meal',
          dayKey: meal.dateKey,
        ),
      );
    }
    final plans = await loadPlans?.call(uid) ?? <MealPlanModel>[];
    _check(uid);
    for (final plan in plans) {
      if (plan.createdAt == null ||
          plan.meals.isEmpty ||
          plan.status != 'active') {
        continue;
      }
      // Created date is recorded; never infer it from a planned future meal.
      events.add(
        ProgressionEvent(
          uid: uid,
          sourceId: plan.planId,
          kind: 'plan',
          dayKey: ProgressionEngine.keyOf(plan.createdAt!),
        ),
      );
    }
    final result = ProgressionEngine(config).project(uid, todayKey, events);
    _check(uid);
    return ProgressionSnapshot(result, config, List.unmodifiable(events));
  }
}

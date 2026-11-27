import 'dart:async';
import 'package:sufradepi/data/models/favorite_model.dart';
import 'package:sufradepi/data/models/achievement_model.dart';
import 'package:sufradepi/features/recipes/data/persistence/cloud_recipe_favorites.dart';
import 'package:sufradepi/features/achievements/data/persistence/achievement_progress_store.dart';

class MemoryFavoritesBackend implements RecipeFavoritesBackend {
  List<FavoriteModel> values = [];
  final operations = <String>[];
  Completer<List<FavoriteModel>>? pending;
  bool fail = false;
  @override
  Future<List<FavoriteModel>> load(String uid) async =>
      pending == null ? values.toList() : pending!.future;
  @override
  Future<void> save(String uid, FavoriteModel model) async {
    if (fail) throw StateError('fixture write failure');
    operations.add('$uid:save:${model.favoriteId}');
    if (!values.any((v) => v.favoriteId == model.favoriteId)) values.add(model);
  }

  @override
  Future<void> remove(String uid, String favoriteId) async {
    if (fail) throw StateError('fixture write failure');
    operations.add('$uid:delete:$favoriteId');
    values.removeWhere((v) => v.favoriteId == favoriteId);
  }
}

class MemoryAchievementsBackend implements AchievementProgressBackend {
  final values = <String, AchievementModel>{};
  int writes = 0;
  final DateTime observedTime = DateTime.utc(2026, 11, 22, 18);
  Completer<void>? pending;
  @override
  Future<AchievementSyncResult> reconcile(
    String uid,
    List<AchievementObservation> observations,
  ) async {
    if (pending != null) await pending!.future;
    final unlocked = <String>{};
    for (final observation in observations) {
      final old = values[observation.rule.id];
      final plan = planAchievement(old, observation);
      if (!plan.changed) continue;
      writes++;
      final m = plan.model;
      values[m.achievementId] = AchievementModel(
        achievementId: m.achievementId,
        achievementType: m.achievementType,
        title: m.title,
        description: m.description,
        progress: m.progress,
        target: m.target,
        isUnlocked: m.isUnlocked,
        createdAt: old?.createdAt ?? observedTime,
        unlockedAt:
            old?.unlockedAt ?? (plan.observedUnlock ? observedTime : null),
      );
      if (plan.observedUnlock) unlocked.add(m.achievementId);
    }
    return AchievementSyncResult(
      records: values.values.toList(),
      newUnlockIds: unlocked,
    );
  }
}

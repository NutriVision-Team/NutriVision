import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../data/models/achievement_model.dart';
import '../../domain/achievement_activity.dart';

class AchievementObservation {
  const AchievementObservation({required this.rule, required this.progress});
  final AchievementRule rule;
  final int progress;
}

class AchievementWritePlan {
  const AchievementWritePlan({
    required this.model,
    required this.changed,
    required this.observedUnlock,
  });
  final AchievementModel model;
  final bool changed, observedUnlock;
}

/// Pure reconciliation. A first-seen historical threshold has no unlock date.
AchievementWritePlan planAchievement(
  AchievementModel? old,
  AchievementObservation observation, {
  bool verifiedLockedBaseline = true,
}) {
  final rule = observation.rule;
  if (rule.target <= 0 || observation.progress < 0) {
    throw ArgumentError('Invalid achievement progress');
  }
  if (old != null && old.achievementId != rule.id) {
    throw StateError('Achievement identity mismatch');
  }
  if (old != null &&
      (!old.progress.isFinite || old.progress < 0 || !old.target.isFinite)) {
    throw StateError('Malformed stored achievement progress');
  }
  final progress = math.max(
    old?.progress ?? 0,
    observation.progress.toDouble(),
  );
  final earned = (old?.isUnlocked ?? false) || progress >= rule.target;
  final transition =
      verifiedLockedBaseline &&
      old != null &&
      !old.isUnlocked &&
      old.progress < old.target &&
      old.target == rule.target &&
      old.achievementType == rule.condition &&
      observation.progress >= rule.target;
  final model = AchievementModel(
    achievementId: rule.id,
    achievementType: rule.condition,
    title: rule.titleAr,
    description: rule.descriptionAr,
    progress: progress,
    target: rule.target.toDouble(),
    isUnlocked: earned,
    unlockedAt: old?.unlockedAt,
    createdAt: old?.createdAt,
  );
  final changed =
      old == null ||
      old.progress != model.progress ||
      old.target != model.target ||
      old.isUnlocked != model.isUnlocked ||
      old.title != model.title ||
      old.description != model.description ||
      old.achievementType != model.achievementType;
  return AchievementWritePlan(
    model: model,
    changed: changed,
    observedUnlock: transition,
  );
}

class AchievementSyncResult {
  const AchievementSyncResult({
    required this.records,
    this.newUnlockIds = const {},
  });
  final List<AchievementModel> records;
  final Set<String> newUnlockIds;
}

abstract interface class AchievementProgressBackend {
  Future<AchievementSyncResult> reconcile(
    String uid,
    List<AchievementObservation> observations,
  );
}

class FirestoreAchievementProgressBackend
    implements AchievementProgressBackend {
  FirestoreAchievementProgressBackend(
    this.firestore, {
    required this.assertActive,
  });
  final FirebaseFirestore firestore;
  final void Function(String uid) assertActive;
  @override
  Future<AchievementSyncResult> reconcile(
    String uid,
    List<AchievementObservation> observations,
  ) async {
    assertActive(uid);
    final newlyUnlocked = <String>{};
    for (final observation in observations) {
      final ref = firestore.doc(
        FirestoreCollections.achievementDocument(uid, observation.rule.id),
      );
      final transitioned = await firestore.runTransaction<bool>((
        transaction,
      ) async {
        assertActive(uid);
        final existing = await transaction.get(ref);
        assertActive(uid);
        final old = existing.exists
            ? AchievementModel.fromMap(existing.id, existing.data()!)
            : null;
        final plan = planAchievement(
          old,
          observation,
          verifiedLockedBaseline:
              existing.data()?['isUnlocked'] is bool &&
              existing.data()?['progress'] is num,
        );
        if (!plan.changed) return false;
        final data = plan.model.toMap();
        if (existing.exists) data.remove('createdAt');
        if (plan.observedUnlock && old?.unlockedAt == null) {
          data['unlockedAt'] = FieldValue.serverTimestamp();
        }
        transaction.set(ref, data, SetOptions(merge: true));
        return plan.observedUnlock;
      });
      assertActive(uid);
      if (transitioned) newlyUnlocked.add(observation.rule.id);
    }
    final records = await firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.achievements)
        .get();
    assertActive(uid);
    return AchievementSyncResult(
      records: records.docs
          .map((d) => AchievementModel.fromMap(d.id, d.data()))
          .toList(growable: false),
      newUnlockIds: Set.unmodifiable(newlyUnlocked),
    );
  }
}

class AchievementProgressStore {
  AchievementProgressStore({
    required this.userId,
    required this.activeUserId,
    required this.backend,
  }) {
    if (userId.trim().isEmpty) throw ArgumentError.value(userId, 'userId');
  }
  final String userId;
  final String? Function() activeUserId;
  final AchievementProgressBackend backend;
  void _guard() {
    if (activeUserId() != userId) {
      throw StateError('Achievement account is no longer active');
    }
  }

  Future<AchievementSyncResult> synchronize(
    AchievementActivity activity,
    List<AchievementRule> rules,
  ) async {
    _guard();
    if (activity.userId != userId) {
      throw StateError('Achievement activity account mismatch');
    }
    final observations = <AchievementObservation>[];
    for (final rule in rules) {
      final progress = activity.progress(rule);
      if (progress != null) {
        observations.add(
          AchievementObservation(rule: rule, progress: progress),
        );
      }
    }
    final result = await backend.reconcile(userId, observations);
    _guard();
    return result;
  }
}

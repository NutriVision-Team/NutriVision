import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/meal_entry_model.dart';
import '../../../data/models/meal_plan_model.dart';
import '../../../data/models/user_profile_model.dart';

class ProgressionHistoryTooLarge implements Exception {}

/// Bounded snapshot cache. UI recalculation never launches a second query.
/// Oversized history fails visibly, never masquerades as a lifetime total.
class BoundedProgressionSource {
  BoundedProgressionSource({
    required this.uid,
    required this.currentUid,
    required this.mealStream,
    required this.planStream,
    required this.profileStream,
  });
  final String uid;
  final String? Function() currentUid;
  final Stream<List<MealEntryModel>> Function() mealStream;
  final Stream<List<MealPlanModel>> Function() planStream;
  final Stream<UserProfileModel?> Function() profileStream;
  static const maxRecords = 500;
  List<MealEntryModel>? _meals;
  List<MealPlanModel>? _plans;
  UserProfileModel? _profile;
  bool _profileLoaded = false;
  final Map<String, Object> _errors = {};
  Completer<void>? _ready;
  int _generation = 0;
  void _check() {
    if (uid.isEmpty || uid.contains('/') || currentUid() != uid) {
      throw StateError('Inactive progression source');
    }
  }

  Stream<void> watch() {
    _check();
    final generation = ++_generation;
    late StreamController<void> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    final ready = Completer<void>();
    _ready = ready;
    _meals = null;
    _plans = null;
    _profileLoaded = false;
    _errors.clear();
    bool active() => generation == _generation && !controller.isClosed;
    void emit(String channel) {
      if (!active()) return;
      _errors.remove(channel);
      if (_meals != null &&
          _plans != null &&
          _profileLoaded &&
          !ready.isCompleted) {
        ready.complete();
      }
      controller.add(null);
    }

    void fail(String channel, Object error, StackTrace stack) {
      if (!active()) return;
      _errors[channel] = error;
      if (!ready.isCompleted) ready.complete();
      controller.add(null);
    }

    controller = StreamController<void>(
      onListen: () {
        subscriptions.add(
          profileStream().listen((profile) {
            try {
              if (!active()) return;
              _check();
              if (profile != null && profile.uid != uid) {
                throw StateError('Profile owner mismatch');
              }
              _profile = profile;
              _profileLoaded = true;
              emit('profile');
            } catch (e, s) {
              fail('profile', e, s);
            }
          }, onError: (Object e, StackTrace s) => fail('profile', e, s)),
        );
        subscriptions.add(
          mealStream().listen((meals) {
            try {
              if (!active()) return;
              _check();
              if (meals.length > maxRecords) throw ProgressionHistoryTooLarge();
              if (meals.any((m) => m.userId != uid)) {
                throw StateError('Meal owner mismatch');
              }
              _meals = List.unmodifiable(meals);
              emit('meals');
            } catch (e, s) {
              fail('meals', e, s);
            }
          }, onError: (Object e, StackTrace s) => fail('meals', e, s)),
        );
        subscriptions.add(
          planStream().listen((plans) {
            try {
              if (!active()) return;
              _check();
              if (plans.length > maxRecords) throw ProgressionHistoryTooLarge();
              _plans = List.unmodifiable(plans);
              emit('plans');
            } catch (e, s) {
              fail('plans', e, s);
            }
          }, onError: (Object e, StackTrace s) => fail('plans', e, s)),
        );
      },
      onCancel: () async {
        if (generation == _generation) {
          _generation++;
          if (!ready.isCompleted) ready.complete();
        }
        for (final s in subscriptions) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }

  Future<void> _awaitReady() async {
    _check();
    final generation = _generation;
    if (_ready == null) throw StateError('Source not listening');
    await _ready!.future.timeout(const Duration(seconds: 15));
    _check();
    if (generation != _generation) throw StateError('Stale progression source');
    if (_errors.isNotEmpty) throw _errors.values.first;
    if (_meals == null || _plans == null || !_profileLoaded) {
      throw StateError('Source not ready');
    }
  }

  Future<List<MealEntryModel>> meals() async {
    await _awaitReady();
    return _meals!;
  }

  Future<List<MealPlanModel>> plans() async {
    await _awaitReady();
    return _plans!;
  }

  Future<UserProfileModel?> profile() async {
    await _awaitReady();
    return _profile;
  }
}

BoundedProgressionSource firestoreProgressionSource(
  FirebaseFirestore firestore,
  String uid,
  String? Function() currentUid,
) {
  if (uid.isEmpty || uid.contains('/')) throw ArgumentError('Invalid owner');
  final user = firestore.collection('users').doc(uid);
  return BoundedProgressionSource(
    uid: uid,
    currentUid: currentUid,
    profileStream: () => user.snapshots().map(
      (snapshot) => snapshot.data() == null
          ? null
          : UserProfileModel.fromMap(snapshot.data()!),
    ),
    mealStream: () => user
        .collection('meal_entries')
        .limit(BoundedProgressionSource.maxRecords + 1)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => MealEntryModel.fromMap(d.id, d.data()))
              .toList(),
        ),
    planStream: () => user
        .collection('meal_plans')
        .limit(BoundedProgressionSource.maxRecords + 1)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => MealPlanModel.fromMap(d.id, d.data())).toList(),
        ),
  );
}

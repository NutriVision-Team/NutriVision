import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/operation_id.dart';
import '../../../data/models/water_log_model.dart';
import '../../../data/models/weight_log_model.dart';

abstract class WaterWeightRepository {
  Future<List<WaterLogModel>> getWaterLogs(String uid, String dateKey);
  Future<List<WeightLogModel>> getWeightLogs(String uid, {int limit = 60});
  Future<void> addWaterLog(
    String uid,
    double amountMl,
    DateTime consumedAt, {
    String? operationId,
  });
  Future<void> addWeightLog(
    String uid,
    double weightKg,
    DateTime recordedAt, {
    String? note,
    String? operationId,
  });
}

/// Account-bound, idempotent appends. A caller retains operationId and the
/// original payload until its outcome is confirmed. A new user action gets a
/// new ID. Hydration patches only its own fields on the shared daily lock.
abstract class WeightRecordEditor {
  Future<void> updateWeightRecord(String uid, WeightLogModel log);
  Future<void> deleteWeightRecord(String uid, String id);
}

abstract class WeightHistoryRangeReader {
  Future<List<WeightLogModel>> getWeightHistoryRange(
    String uid,
    DateTime start,
    DateTime end,
  );
}

class FirestoreWaterWeightRepository
    implements
        WaterWeightRepository,
        WeightHistoryRangeReader,
        WeightRecordEditor {
  FirestoreWaterWeightRepository(
    this._firestore, {
    String? Function()? activeUserId,
  }) : _activeUserId =
           activeUserId ?? (() => FirebaseAuth.instance.currentUser?.uid);
  final FirebaseFirestore _firestore;
  final String? Function() _activeUserId;
  void _guard(String uid) {
    if (uid.isEmpty || _activeUserId() != uid) {
      throw StateError('Account is no longer active');
    }
  }

  CollectionReference<Map<String, dynamic>> _water(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.waterLogs);
  CollectionReference<Map<String, dynamic>> _weight(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.weightLogs);
  String _id(String? id, String prefix) {
    final value = id ?? newOperationId(prefix);
    if (!RegExp(r'^[A-Za-z0-9_-]{1,120}$').hasMatch(value)) {
      throw ArgumentError('Invalid operation ID');
    }
    return value;
  }

  @override
  Future<List<WaterLogModel>> getWaterLogs(String uid, String dateKey) async {
    _guard(uid);
    final snapshot = await _water(
      uid,
    ).where('dateKey', isEqualTo: dateKey).get();
    _guard(uid);
    final result =
        snapshot.docs.map((d) => WaterLogModel.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
    return result;
  }

  @override
  Future<List<WeightLogModel>> getWeightLogs(
    String uid, {
    int limit = 60,
  }) async {
    _guard(uid);
    final snapshot = await _weight(
      uid,
    ).orderBy('recordedAt', descending: true).limit(limit).get();
    _guard(uid);
    return snapshot.docs
        .map((d) => WeightLogModel.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<List<WeightLogModel>> getWeightHistoryRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    _guard(uid);
    final after = DateTime(start.year, start.month, start.day),
        before = DateTime(end.year, end.month, end.day + 1);
    final snapshot = await _weight(uid)
        .where('recordedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(after))
        .where('recordedAt', isLessThan: Timestamp.fromDate(before))
        .orderBy('recordedAt', descending: true)
        .get();
    _guard(uid);
    return snapshot.docs
        .map((d) => WeightLogModel.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<void> addWaterLog(
    String uid,
    double amountMl,
    DateTime consumedAt, {
    String? operationId,
  }) async {
    _guard(uid);
    if (!amountMl.isFinite || amountMl <= 0) {
      throw ArgumentError('Invalid water amount');
    }
    final dateKey = SufraDateUtils.toDateKey(consumedAt);
    final waterRef = _water(uid).doc(_id(operationId, 'water'));
    final dailyRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.dailyLogs)
        .doc(dateKey);
    await _firestore.runTransaction((tx) async {
      _guard(uid);
      final existing = await tx.get(waterRef);
      _guard(uid);
      if (existing.exists) {
        final old = WaterLogModel.fromMap(existing.id, existing.data()!);
        if (old.amountMl != amountMl ||
            !old.consumedAt.isAtSameMomentAs(consumedAt) ||
            old.dateKey != dateKey) {
          throw StateError('Water operation payload changed');
        }
        return;
      }
      final daily = await tx.get(dailyRef);
      _guard(uid);
      final raw = daily.data()?['waterIntakeMl'];
      if (raw != null && (raw is! num || !raw.isFinite || raw < 0)) {
        throw StateError('Invalid stored water total');
      }
      final next = (raw as num?)?.toDouble() ?? 0;
      if (!(next + amountMl).isFinite) {
        throw StateError('Water total overflow');
      }
      tx.set(
        waterRef,
        WaterLogModel(
          waterId: waterRef.id,
          amountMl: amountMl,
          consumedAt: consumedAt,
          dateKey: dateKey,
        ).toMap(),
      );
      tx.set(dailyRef, {
        'dateKey': dateKey,
        'waterIntakeMl': next + amountMl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    _guard(uid);
  }

  @override
  Future<void> addWeightLog(
    String uid,
    double weightKg,
    DateTime recordedAt, {
    String? note,
    String? operationId,
  }) async {
    _guard(uid);
    if (!weightKg.isFinite || weightKg <= 0 || (note?.length ?? 0) > 1000) {
      throw ArgumentError('Invalid weight record');
    }
    final dateKey = SufraDateUtils.toDateKey(recordedAt),
        ref = _weight(uid).doc(_id(operationId, 'weight'));
    await _firestore.runTransaction((tx) async {
      _guard(uid);
      final existing = await tx.get(ref);
      _guard(uid);
      if (existing.exists) {
        final old = WeightLogModel.fromMap(existing.id, existing.data()!);
        if (old.weightKg != weightKg ||
            !old.recordedAt.isAtSameMomentAs(recordedAt) ||
            old.note != note) {
          throw StateError('Weight operation payload changed');
        }
        return;
      }
      tx.set(
        ref,
        WeightLogModel(
          weightId: ref.id,
          weightKg: weightKg,
          recordedAt: recordedAt,
          dateKey: dateKey,
          note: note,
        ).toMap(),
      );
    });
    _guard(uid);
  }

  @override
  Future<void> updateWeightRecord(String uid, WeightLogModel log) async {
    _guard(uid);
    if (!log.weightKg.isFinite ||
        log.weightKg <= 0 ||
        log.weightKg > 1000 ||
        log.dateKey != SufraDateUtils.toDateKey(log.recordedAt) ||
        (log.note?.length ?? 0) > 1000) {
      throw ArgumentError('Invalid weight record');
    }
    final ref = _weight(uid).doc(_id(log.weightId, 'weight'));
    await _firestore.runTransaction((tx) async {
      _guard(uid);
      final old = await tx.get(ref);
      _guard(uid);
      if (!old.exists) throw StateError('Weight record no longer exists');
      tx.update(ref, {
        'weightKg': log.weightKg,
        'recordedAt': Timestamp.fromDate(log.recordedAt),
        'dateKey': log.dateKey,
        'note': log.note,
      });
    });
    _guard(uid);
  }

  @override
  Future<void> deleteWeightRecord(String uid, String id) async {
    _guard(uid);
    final ref = _weight(uid).doc(_id(id, 'weight'));
    await _firestore.runTransaction((tx) async {
      _guard(uid);
      await tx.get(ref);
      _guard(uid);
      tx.delete(ref);
    });
    _guard(uid);
  }
}

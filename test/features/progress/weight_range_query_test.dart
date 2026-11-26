// ignore_for_file: subtype_of_sealed_class
// SDK query-boundary fake, not a substitute for Firestore emulator/device checks.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/progress/data/water_weight_repository.dart';
import '../../support/memory_firestore.dart';

class RangeFirestore extends MemoryFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      RangeCollection(this, path);
}

class RangeCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  RangeCollection(
    this.store,
    this.path, {
    this.start,
    this.end,
    this.desc = false,
  });
  final MemoryFirestore store;
  @override
  final String path;
  final Timestamp? start, end;
  final bool desc;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      RangeDocument(store, '$path/$id');
  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #where) {
      expect(i.positionalArguments.first, 'recordedAt');
      return RangeCollection(
        store,
        path,
        start: i.namedArguments[#isGreaterThanOrEqualTo] as Timestamp? ?? start,
        end: i.namedArguments[#isLessThan] as Timestamp? ?? end,
        desc: desc,
      );
    }
    if (i.memberName == #orderBy) {
      expect(i.positionalArguments.first, 'recordedAt');
      return RangeCollection(
        store,
        path,
        start: start,
        end: end,
        desc: i.namedArguments[#descending] as bool? ?? false,
      );
    }
    return super.noSuchMethod(i);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final found =
        store.documents.entries
            .where(
              (e) =>
                  e.key.startsWith('$path/') &&
                  e.value['recordedAt'] is Timestamp,
            )
            .where((e) {
              final at = e.value['recordedAt'] as Timestamp;
              return (start == null || at.compareTo(start!) >= 0) &&
                  (end == null || at.compareTo(end!) < 0);
            })
            .toList()
          ..sort(
            (a, b) =>
                (a.value['recordedAt'] as Timestamp).compareTo(
                  b.value['recordedAt'] as Timestamp,
                ) *
                (desc ? -1 : 1),
          );
    return MemoryQuerySnapshot([
      for (final e in found)
        MemoryQueryDocument(MemoryDocument(store, e.key), e.value),
    ]);
  }
}

class RangeDocument extends MemoryDocument<Map<String, dynamic>> {
  RangeDocument(super.store, super.path);
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      RangeCollection(store, '$path/$name');
}

void main() {
  test(
    'real weight range query includes both selected days, excludes adjacent days, newest first',
    () async {
      final db = RangeFirestore();
      for (final (id, at) in [
        ('before', DateTime(2026, 11, 9, 23, 59)),
        ('start', DateTime(2026, 11, 10)),
        ('end', DateTime(2026, 11, 12, 23, 59, 59)),
        ('after', DateTime(2026, 11, 13)),
      ]) {
        db.seed('users/u/weight_logs/$id', {
          'recordedAt': Timestamp.fromDate(at),
          'weightKg': 90.0,
          'dateKey': at.toIso8601String().substring(0, 10),
        });
      }
      db.seed('users/other/weight_logs/foreign', {
        'recordedAt': Timestamp.fromDate(DateTime(2026, 11, 11)),
        'weightKg': 99.0,
        'dateKey': '2026-11-11',
      });
      final r = FirestoreWaterWeightRepository(db, activeUserId: () => 'u');
      final logs = await r.getWeightHistoryRange(
        'u',
        DateTime(2026, 11, 10, 18),
        DateTime(2026, 11, 12, 1),
      );
      expect(logs.map((w) => w.weightId), ['end', 'start']);
    },
  );
}

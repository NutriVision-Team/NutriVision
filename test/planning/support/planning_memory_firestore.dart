// SDK-boundary fakes for the planning features' repositories. Extends the
// shared in-memory fake with document set/delete, batches and orderBy,
// which the shopping and coach stores use.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_firestore.dart';

class PlanningMemoryFirestore extends MemoryFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      PlanningMemoryCollection(this, path);

  @override
  WriteBatch batch() => PlanningMemoryBatch(this);
}

class PlanningMemoryCollection extends MemoryCollection {
  PlanningMemoryCollection(
    super.store,
    super.path, {
    super.field,
    super.equal,
    super.orderField,
  });

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      PlanningMemoryDocument(store, '${super.path}/${path ?? 'auto'}');

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final snapshot = await super.get(options);
    final docs = [...snapshot.docs];
    if (orderField != null) {
      int comparable(Object? a, Object? b) {
        if (a is Timestamp && b is Timestamp) return a.compareTo(b);
        return '$a'.compareTo('$b');
      }

      docs.sort(
        (a, b) => comparable(a.data()[orderField], b.data()[orderField]),
      );
    }
    return MemoryQuerySnapshot(docs);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #orderBy) {
      return PlanningMemoryCollection(
        store,
        path,
        field: field,
        equal: equal,
        orderField: i.positionalArguments.first as String,
      );
    }
    if (i.memberName == #where) {
      return PlanningMemoryCollection(
        store,
        path,
        field: i.positionalArguments.first,
        equal: i.namedArguments[#isEqualTo],
        orderField: orderField,
      );
    }
    return super.noSuchMethod(i);
  }
}

class PlanningMemoryDocument extends MemoryDocument<Map<String, dynamic>> {
  PlanningMemoryDocument(super.store, super.path);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      PlanningMemoryCollection(store, '${this.path}/$path');

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    store.seed(path, {
      if (options?.merge == true) ...?store.documents[path],
      ...store.resolve(Map.of(data)),
    });
  }

  @override
  Future<void> delete() async {
    store.documents.remove(path);
    store.versions[path] = (store.versions[path] ?? 0) + 1;
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    store.seed(path, {
      ...?store.documents[path],
      ...store.resolve(Map<String, dynamic>.from(data)),
    });
  }
}

class PlanningMemoryBatch extends Fake implements WriteBatch {
  PlanningMemoryBatch(this.store);

  final PlanningMemoryFirestore store;
  final _operations = <void Function()>[];

  @override
  void set<T>(DocumentReference<T> reference, T data, [SetOptions? options]) {
    _operations.add(() {
      store.seed(reference.path, {
        if (options?.merge == true) ...?store.documents[reference.path],
        ...store.resolve(Map<String, dynamic>.from(data! as Map)),
      });
    });
  }

  @override
  void delete(DocumentReference<Object?> reference) {
    _operations.add(() {
      store.documents.remove(reference.path);
      store.versions[reference.path] =
          (store.versions[reference.path] ?? 0) + 1;
    });
  }

  @override
  void update<T>(DocumentReference<T> reference, T data) =>
      set(reference, data, SetOptions(merge: true));

  @override
  Future<void> commit() async {
    for (final operation in _operations) {
      operation();
    }
    _operations.clear();
  }
}

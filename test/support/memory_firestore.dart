// SDK-boundary test fakes deliberately implement plugin interface types.
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// A narrow SDK-boundary fake, not a Firestore server. Exercises the real
/// repository's reads, staged writes, retry behavior and field-preserving merges.
class MemoryFirestore extends Fake implements FirebaseFirestore {
  final documents = <String, Map<String, dynamic>>{};
  final versions = <String, int>{};
  final changes = StreamController<void>.broadcast(sync: true);
  void Function()? beforeCommit;
  bool failNextCommit = false;
  bool failAfterCommit = false;
  int attempts = 0;
  void seed(String path, Map<String, dynamic> value) {
    documents[path] = Map.of(value);
    versions[path] = (versions[path] ?? 0) + 1;
    changes.add(null);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      MemoryCollection(this, path);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    for (var n = 0; n < maxAttempts; n++) {
      attempts++;
      final transaction = MemoryTransaction(this);
      final value = await handler(transaction);
      final concurrent = beforeCommit;
      beforeCommit = null;
      concurrent?.call();
      if (transaction.readVersions.entries.any(
        (e) => (versions[e.key] ?? 0) != e.value,
      )) {
        continue;
      }
      if (failNextCommit) {
        failNextCommit = false;
        throw StateError('Simulated transport failure before commit');
      }
      for (final operation in transaction.operations) {
        operation();
      }
      if (failAfterCommit) {
        failAfterCommit = false;
        throw StateError('Simulated lost acknowledgement after commit');
      }
      return value;
    }
    throw StateError('Retry limit reached');
  }

  Map<String, dynamic> resolve(Map<String, dynamic> map) => map.map(
    (k, v) => MapEntry(
      k,
      v is FieldValue ? Timestamp.fromDate(DateTime.utc(2026, 11, 22)) : v,
    ),
  );
}

class MemoryCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  MemoryCollection(
    this.store,
    this.path, {
    this.field,
    this.equal,
    this.orderField,
    this.descending = false,
    this.maxRows,
  });
  final MemoryFirestore store;
  @override
  final String path;
  final Object? field, equal;
  final String? orderField;
  final bool descending;
  final int? maxRows;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      MemoryDocument<Map<String, dynamic>>(
        store,
        '${this.path}/${path ?? 'auto'}',
      );
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final e in store.documents.entries) {
      if (!e.key.startsWith('$path/') ||
          e.key.substring(path.length + 1).contains('/')) {
        continue;
      }
      if (field != null && e.value[field] != equal) continue;
      docs.add(
        MemoryQueryDocument(MemoryDocument(store, e.key), Map.of(e.value)),
      );
    }
    if (orderField != null) {
      docs.sort((a, b) {
        final av = a.data()[orderField], bv = b.data()[orderField];
        final result = av is Comparable ? av.compareTo(bv) : 0;
        return descending ? -result : result;
      });
    }
    return MemoryQuerySnapshot(
      maxRows == null ? docs : docs.take(maxRows!).toList(),
    );
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) async* {
    yield await get();
    await for (final _ in store.changes.stream) {
      yield await get();
    }
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #orderBy) {
      return MemoryCollection(
        store,
        path,
        field: field,
        equal: equal,
        orderField: i.positionalArguments.first as String,
        descending: i.namedArguments[#descending] == true,
        maxRows: maxRows,
      );
    }
    if (i.memberName == #limit) {
      return MemoryCollection(
        store,
        path,
        field: field,
        equal: equal,
        orderField: orderField,
        descending: descending,
        maxRows: i.positionalArguments.first as int,
      );
    }
    if (i.memberName == #where) {
      return MemoryCollection(
        store,
        path,
        field: i.positionalArguments.first,
        equal: i.namedArguments[#isEqualTo],
      );
    }
    return super.noSuchMethod(i);
  }
}

class MemoryDocument<T> extends Fake implements DocumentReference<T> {
  MemoryDocument(this.store, this.path);
  final MemoryFirestore store;
  @override
  Stream<DocumentSnapshot<T>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) async* {
    yield await get();
    await for (final _ in store.changes.stream) {
      yield await get();
    }
  }

  @override
  final String path;
  @override
  String get id => path.split('/').last;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      MemoryCollection(store, '${this.path}/$path');
  @override
  Future<DocumentSnapshot<T>> get([GetOptions? options]) async =>
      MemorySnapshot<T>(this, store.documents[path] as T?);
}

class MemorySnapshot<T> extends Fake implements DocumentSnapshot<T> {
  MemorySnapshot(this.reference, this.value);
  @override
  final DocumentReference<T> reference;
  final T? value;
  @override
  bool get exists => value != null;
  @override
  String get id => reference.id;
  @override
  T? data() => value;
}

class MemoryQueryDocument extends MemorySnapshot<Map<String, dynamic>>
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  MemoryQueryDocument(super.reference, super.value);
  @override
  Map<String, dynamic> data() => value!;
}

class MemoryQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  MemoryQuerySnapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

class MemoryTransaction extends Fake implements Transaction {
  MemoryTransaction(this.store);
  final MemoryFirestore store;
  final readVersions = <String, int>{};
  final operations = <void Function()>[];
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> reference,
  ) async {
    if (operations.isNotEmpty) {
      throw StateError('Read after write in transaction');
    }
    readVersions[reference.path] = store.versions[reference.path] ?? 0;
    final value = store.documents[reference.path];
    return MemorySnapshot<T>(
      reference,
      value == null ? null : Map<String, dynamic>.of(value) as T,
    );
  }

  @override
  Transaction set<T>(
    DocumentReference<T> reference,
    T data, [
    SetOptions? options,
  ]) {
    final value = Map<String, dynamic>.of(data as Map<String, dynamic>);
    operations.add(
      () => store.seed(reference.path, {
        if (options?.merge == true) ...?store.documents[reference.path],
        ...store.resolve(value),
      }),
    );
    return this;
  }

  @override
  Transaction update(DocumentReference reference, Map<Object, Object?> data) {
    final copy = data.map((k, v) => MapEntry(k as String, v));
    operations.add(() {
      if (!store.documents.containsKey(reference.path)) {
        throw StateError('Missing update target');
      }
      store.seed(reference.path, {
        ...store.documents[reference.path]!,
        ...store.resolve(copy),
      });
    });
    return this;
  }

  @override
  Transaction delete(DocumentReference reference) {
    operations.add(() {
      store.documents.remove(reference.path);
      store.versions[reference.path] =
          (store.versions[reference.path] ?? 0) + 1;
      store.changes.add(null);
    });
    return this;
  }
}

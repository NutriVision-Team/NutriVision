import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sufradepi/features/progress/presentation/screens/weight_screen.dart';
import 'package:sufradepi/data/models/weight_log_model.dart';
import 'package:sufradepi/features/progress/data/water_weight_repository.dart';
import 'package:sufradepi/features/progress/presentation/cubit/weight_cubit.dart';
import '../../support/memory_firestore.dart';
import 'progress_test.dart' as fixture;

class EditableWeights extends fixture.FakeWaterWeightRepository
    implements WeightRecordEditor {
  @override
  Future<void> updateWeightRecord(String uid, WeightLogModel log) async {
    weight = [
      for (final w in weight)
        if (w.weightId == log.weightId) log else w,
    ];
  }

  @override
  Future<void> deleteWeightRecord(String uid, String id) async {
    weight = weight.where((w) => w.weightId != id).toList();
  }
}

void main() {
  final at = DateTime(2026, 11, 22, 12);
  WeightLogModel log(double kg) => WeightLogModel(
    weightId: 'w',
    weightKg: kg,
    recordedAt: at,
    dateKey: '2026-11-22',
  );
  testWidgets(
    'history exposes edit and confirmed delete with safe dialog dismissal',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final r = EditableWeights()..weight = [log(90)];
      await fixture.pumpScreen(
        tester,
        WeightScreen(waterWeightRepository: r),
        fixture.FakeNutritionRepository(),
      );
      await tester.ensureVisible(find.byType(ExpansionTile));
      await tester.tap(find.byType(ExpansionTile));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.ensureVisible(find.byIcon(Icons.edit_outlined));
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.enterText(find.byType(TextField), '89');
      await tester.tap(find.text('احفظ'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(r.weight.single.weightKg, 89);
      await tester.ensureVisible(find.byIcon(Icons.delete_outline));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.widgetWithText(TextButton, 'حذف'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(r.weight, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test(
    'real weight repository update preserves metadata, delete idempotent, guards owner',
    () async {
      String? uid = 'u';
      final db = MemoryFirestore();
      db.seed('users/u/weight_logs/w', {...log(90).toMap(), 'custom': 'keep'});
      final r = FirestoreWaterWeightRepository(db, activeUserId: () => uid);
      await r.updateWeightRecord('u', log(89));
      expect(db.documents['users/u/weight_logs/w']!['weightKg'], 89);
      expect(db.documents['users/u/weight_logs/w']!['custom'], 'keep');
      await r.deleteWeightRecord('u', 'w');
      expect(db.documents.containsKey('users/u/weight_logs/w'), isFalse);
      await r.deleteWeightRecord('u', 'w');
      uid = 'other';
      await expectLater(r.updateWeightRecord('u', log(80)), throwsStateError);
    },
  );
  test('invalid/missing weight update cannot create a new record', () async {
    final db = MemoryFirestore();
    final r = FirestoreWaterWeightRepository(db, activeUserId: () => 'u');
    await expectLater(r.updateWeightRecord('u', log(90)), throwsStateError);
    expect(db.documents, isEmpty);
    await expectLater(
      r.updateWeightRecord('u', log(double.nan)),
      throwsArgumentError,
    );
    expect(db.documents, isEmpty);
  });
  test(
    'weight controller edit and delete reload real visible history',
    () async {
      final r = EditableWeights()..weight = [log(90)];
      final c = WeightCubit(
        waterWeightRepository: r,
        nutritionRepository: fixture.FakeNutritionRepository(),
        uid: 'u',
        currentUid: () => 'u',
      );
      await c.load();
      await c.changeRecord(log(89));
      expect(c.state.currentWeight, 89);
      await c.changeRecord(log(89), delete: true);
      expect(c.state.logs, isEmpty);
      await c.close();
    },
  );
}

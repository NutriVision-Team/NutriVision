import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/planner/domain/weekly_plan_generator.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';

void main() {
  test('audit assembly energy gaps and constraints', () {
    final j =
        jsonDecode(File('assets/data/foods.json').readAsStringSync()) as Map;
    final fs = (j['foods'] as List)
        .map((f) => LocalFoodRecord.fromJson(Map<String, dynamic>.from(f)))
        .toList();
    final g = WeeklyPlanGenerator(catalog: fs);
    final result = <Map<String, Object>>[];
    for (final target in [1200.0, 1800.0, 2400.0, 3000.0, 4000.0]) {
      for (final diet in [
        <String>[],
        ['vegan'],
        ['vegetarian'],
      ]) {
        final ratios = <double>[];
        for (var seed = 0; seed < 20; seed++) {
          final p = g.generate(
            weekStart: DateTime(2026, 11, 21),
            dailyCalorieTarget: target,
            seed: seed,
            dietaryPreferences: diet,
          );
          expect(p.meals.length, 28);
          for (var day = 0; day < 7; day++) {
            final key = '2026-11-${21 + day}';
            final meals = p.meals.where((m) => m.dateKey == key);
            final energy = meals.fold<double>(0, (s, m) => s + m.calories);
            ratios.add(energy / target);
            for (final m in meals) {
              expect(
                m.foodPortions!.fold<double>(0, (s, p) => s + p.grams),
                lessThanOrEqualTo(850),
              );
            }
          }
        }
        ratios.sort();
        result.add({
          'target': target,
          'diet': diet,
          'minRatio': ratios.first,
          'medianRatio': ratios[ratios.length ~/ 2],
          'maxRatio': ratios.last,
        });
      }
    }
    File(
      '/downloads/sufra/assembly_energy_audit2236.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
  });
}

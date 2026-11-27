import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import '../../planning/screens_smoke_test.dart' show SmokeNutritionRepository;
import '../../planning/coach_retry_test.dart' show AmbiguousCoachStore;
import 'coach_integration_test.dart' show SyntheticContractProvider;

class LocalWaterRecords extends SmokeNutritionRepository {
  @override
  Future<List<DailyLogModel>> getDailyLogs(
    String uid, {
    int limit = 30,
  }) async => [
    DailyLogModel(
      dateKey: '2026-11-24',
      timezone: 'Africa/Cairo',
      totalCalories: null,
      totalProtein: null,
      totalCarbs: null,
      totalFat: null,
      totalFiber: null,
      totalSugar: null,
      totalSodium: null,
      calorieTarget: 2000,
      proteinTarget: 0,
      carbsTarget: 0,
      fatTarget: 0,
      waterIntakeMl: 750,
      mealCount: 0,
    ),
  ];
}

class OfflineProvider implements HealthCoachProvider {
  @override
  Future<HealthCoachReply> generate(HealthCoachRequest request) async =>
      throw StateError('offline');
}

class UnavailableLocalRecords extends SmokeNutritionRepository {
  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async => throw StateError('meals unavailable');
  @override
  Future<List<DailyLogModel>> getDailyLogs(
    String uid, {
    int limit = 30,
  }) async => throw StateError('records unavailable');
}

void main() {
  test(
    'typed-only chat works when optional records fail without false cards',
    () async {
      final spy = SyntheticContractProvider();
      final c = CoachCubit(
        userId: 'u',
        store: AmbiguousCoachStore()..throwAfterAnswer = false,
        nutrition: UnavailableLocalRecords(),
        locale: 'en',
        healthOrchestrator: HealthCoachOrchestrator(provider: spy),
        healthConsent: const HealthCoachConsent(externalAi: true),
      );
      await c.load();
      await c.send('Explain labels');
      expect(c.state.sendFailure, false);
      expect(c.state.entries.last.origin, 'ai');
      expect(c.state.entries.last.stats, isEmpty);
      expect(spy.calls, 1);
      expect(spy.request!.context, isEmpty);
      await c.close();
    },
  );

  for (final mode in ['safety', 'unavailable', 'ai']) {
    test(
      '$mode reply keeps urgent/error answer free from unrelated local record cards',
      () async {
        final spy = SyntheticContractProvider();
        final c = CoachCubit(
          userId: 'u',
          store: AmbiguousCoachStore()..throwAfterAnswer = false,
          nutrition: LocalWaterRecords(),
          locale: 'en',
          clock: () => DateTime(2026, 11, 24),
          healthOrchestrator: HealthCoachOrchestrator(
            provider: mode == 'unavailable' ? OfflineProvider() : spy,
          ),
          healthConsent: const HealthCoachConsent(externalAi: true),
        );
        await c.load();
        await c.send(mode == 'safety' ? 'I have chest pain' : 'Explain labels');
        final reply = c.state.entries.last;
        expect(reply.origin, mode);
        if (mode == 'ai') {
          expect(reply.stats.single.value, '750 ml');
          expect(spy.request!.context, isEmpty);
        } else {
          expect(reply.stats, isEmpty);
          expect(reply.advice, isNull);
        }
        await c.close();
      },
    );
  }
}

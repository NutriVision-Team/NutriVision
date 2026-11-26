import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import '../../planning/coach_retry_test.dart' show AmbiguousCoachStore;
import '../../planning/screens_smoke_test.dart' show SmokeNutritionRepository;
import 'coach_integration_test.dart' show SyntheticContractProvider;

class DelayedCoachProfileRepository extends SmokeNutritionRepository {
  final entered = Completer<void>();
  final result = Completer<List<NutritionProfileModel>>();
  @override
  Future<List<NutritionProfileModel>> getNutritionProfiles(String uid) {
    entered.complete();
    return result.future;
  }
}

void main() {
  for (final invalidate in [
    'switch account',
    'close route',
    'reload generation',
  ]) {
    test(
      'late profile read after $invalidate cannot start external inference',
      () async {
        var uid = 'owner';
        final repository = DelayedCoachProfileRepository();
        final provider = SyntheticContractProvider();
        final store = AmbiguousCoachStore()..throwAfterAnswer = false;
        final cubit = CoachCubit(
          userId: 'owner',
          currentUid: () => uid,
          store: store,
          nutrition: repository,
          locale: 'en',
          healthOrchestrator: HealthCoachOrchestrator(provider: provider),
          healthConsent: const HealthCoachConsent(externalAi: true),
        );
        await cubit.load();
        final pending = cubit.send('Explain labels');
        await repository.entered.future;
        if (invalidate == 'switch account') uid = 'other';
        if (invalidate == 'close route') await cubit.close();
        if (invalidate == 'reload generation') await cubit.load();
        repository.result.complete([]);
        await pending;
        expect(
          provider.calls,
          0,
          reason: 'No stale owner/question may leave through a provider',
        );
        expect(store.saved.values.where((m) => m.role == 'assistant'), isEmpty);
        if (!cubit.isClosed) await cubit.close();
      },
    );
  }
}

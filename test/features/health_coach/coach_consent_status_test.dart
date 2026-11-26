import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_screen.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../planning/screens_smoke_test.dart'
    show SmokeNutritionRepository, FakeCoachDictation;
import '../../planning/coach_retry_test.dart' show AmbiguousCoachStore;
import 'coach_integration_test.dart' show SyntheticContractProvider;

void main() {
  testWidgets(
    'turning external question off updates header without sending or reload',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final provider = SyntheticContractProvider();
      final c = CoachCubit(
        userId: 'u',
        store: AmbiguousCoachStore(),
        nutrition: SmokeNutritionRepository(),
        locale: 'ar',
        healthOrchestrator: HealthCoachOrchestrator(provider: provider),
        healthConsent: const HealthCoachConsent(externalAi: true),
      );
      await c.load();
      addTearDown(c.close);
      final router = GoRouter(
        initialLocation: '/coach',
        routes: [
          GoRoute(
            path: '/coach',
            builder: (_, __) =>
                CoachScreen(cubit: c, dictation: FakeCoachDictation()),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.dark(),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('محادثتك'), findsOneWidget);
      c.updateHealthChoices(
        const HealthCoachConsent(),
        const HealthCoachProfile(),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('محادثتك'), findsNothing);
      expect(find.text('المحادثة مقفولة من الإعدادات'), findsOneWidget);
      expect(provider.calls, 0);
      expect(tester.takeException(), isNull);
      c.updateHealthChoices(
        const HealthCoachConsent(externalAi: true),
        const HealthCoachProfile(),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('محادثتك'), findsOneWidget);
    },
  );
}

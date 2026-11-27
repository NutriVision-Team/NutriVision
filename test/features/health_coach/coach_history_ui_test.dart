import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_screen.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../planning/coach_retry_test.dart' show AmbiguousCoachStore;
import '../../planning/screens_smoke_test.dart'
    show SmokeNutritionRepository, FakeCoachDictation;
import 'coach_integration_test.dart' show SyntheticContractProvider;

void main() {
  testWidgets(
    'actual history control previews only and cancellation sends nothing',
    (t) async {
      t.view.physicalSize = const Size(430, 1100);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final p = SyntheticContractProvider();
      final c = CoachCubit(
        userId: 'synthetic',
        currentUid: () => 'synthetic',
        store: AmbiguousCoachStore()..throwAfterAnswer = false,
        nutrition: SmokeNutritionRepository(),
        locale: 'en',
        healthOrchestrator: HealthCoachOrchestrator(provider: p),
        healthConsent: const HealthCoachConsent(externalAi: true),
      );
      await c.load();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CoachScreen(cubit: c, dictation: FakeCoachDictation()),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      await t.ensureVisible(find.byKey(const ValueKey('coach_review_history')));
      await t.tap(find.byKey(const ValueKey('coach_review_history')));
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.text('Last 7 days'));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Share this summary?'), findsOneWidget);
      expect(p.request, isNull);
      await t.tap(find.text('Back'));
      await t.pump(const Duration(seconds: 1));
      expect(p.request, isNull);
      await t.tap(find.byKey(const ValueKey('coach_review_history')));
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.text('All available records'));
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.text('Share and review'));
      await t.pump(const Duration(seconds: 1));
      expect(p.request!.context['reviewedHistory'], isA<Map>());
      expect(
        (p.request!.context['reviewedHistory'] as Map)['missingDays'],
        'unknown',
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await c.close();
    },
  );
}

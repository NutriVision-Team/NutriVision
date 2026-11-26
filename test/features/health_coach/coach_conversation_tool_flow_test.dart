import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_screen.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import 'package:sufradepi/features/health_coach/domain/coach_catalog_tools.dart';
import 'package:sufradepi/features/health_coach/domain/coach_conversation_tools.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';
import '../../planning/screens_smoke_test.dart'
    show SmokeNutritionRepository, FakeCoachDictation;
import '../../planning/coach_retry_test.dart' show AmbiguousCoachStore;
import 'coach_catalog_calculator_test.dart' show Foods;

class MockToolProvider implements HealthCoachProvider, CoachToolPlanner {
  int plans = 0, calls = 0;
  HealthCoachRequest? request;
  @override
  Future<CoachCalculationRequest?> selectCalculation(String question) async {
    plans++;
    return question == 'احسب سعرات ١٥٠ جرام عدس مطبوخ'
        ? CoachCalculationRequest({'synthetic': 150})
        : null;
  }

  @override
  Future<HealthCoachReply> generate(HealthCoachRequest r) async {
    calls++;
    request = r;
    return const HealthCoachReply(
      text:
          'دي نتيجة أداة الحساب المحلية للوزن اللي طلبته. بيانات الاختبار وهمية والرد ده من بديل تجريبي محلي، مش النموذج الخارجي.',
      origin: CoachReplyOrigin.ai,
    );
  }
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Reem Kufi',
    )..addFont(rootBundle.load('assets/fonts/ReemKufi-SemiBold.ttf'))).load();
    for (final family in ['Cairo', 'Tajawal']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family-Regular.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test('consent off does not invoke planner or provider', () async {
    final p = MockToolProvider();
    final o = HealthCoachOrchestrator(
      provider: p,
      conversationTools: CoachConversationTools(
        reviewedPortions: const {'synthetic': 150},
        catalog: CoachCatalogTools(
          foods: Foods(),
          recipes: RecipeCatalogRepository(),
        ),
      ),
    );
    await o.ask(
      question: 'احسب سعرات ١٥٠ جرام عدس مطبوخ',
      locale: 'ar',
      consent: const HealthCoachConsent(),
      profile: const HealthCoachProfile(),
    );
    expect(p.plans, 0);
    expect(p.calls, 0);
  });
  testWidgets(
    'actual Coach question invokes typed tool and displays independent catalog result',
    (t) async {
      t.view.physicalSize = const Size(430, 1100);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final p = MockToolProvider();
      final c = CoachCubit(
        userId: 'u',
        store: AmbiguousCoachStore()..throwAfterAnswer = false,
        nutrition: SmokeNutritionRepository(),
        locale: 'ar',
        healthOrchestrator: HealthCoachOrchestrator(
          provider: p,
          conversationTools: CoachConversationTools(
            reviewedPortions: const {'synthetic': 150},
            catalog: CoachCatalogTools(
              foods: Foods(),
              recipes: RecipeCatalogRepository(),
            ),
          ),
        ),
        healthConsent: const HealthCoachConsent(externalAi: true),
      );
      await c.load();
      addTearDown(c.close);
      final key = GlobalKey();
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
      await t.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.dark(),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => RepaintBoundary(key: key, child: child!),
        ),
      );
      await t.pump(const Duration(milliseconds: 500));
      await c.send('احسب سعرات ١٥٠ جرام عدس مطبوخ');
      await t.pump(const Duration(milliseconds: 500));
      expect(p.plans, 1);
      expect(p.calls, 1);
      expect(p.request!.context, isEmpty);
      expect(
        c.state.entries.last.stats.any((s) => s.value == '150.0 kcal'),
        true,
      );
      await t.ensureVisible(find.text('150.0 kcal'));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('150.0 kcal'), findsOneWidget);
      expect(find.text('الطاقة من الكتالوج'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/downloads/sufra-recovered/coach1309-conversation-tool-synthetic.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    },
  );
}

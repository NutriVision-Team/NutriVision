import 'package:go_router/go_router.dart';
import 'package:sufradepi/features/planner/domain/planner_food_choices.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_workspace_panel.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'screens_smoke_test.dart' show SmokeNutritionRepository;
import 'weekly_personal_review_test.dart' show m;
import 'package:sufradepi/data/models/meal_entry_model.dart';

class ReviewRepo extends SmokeNutritionRepository {
  bool fail = false;
  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async {
    if (fail) throw StateError('offline');
    return [
      m('one', '2026-11-24'),
      m('two', '2026-11-01', fiber: null),
      m('future', '2026-11-25'),
      m('old', '2026-10-01'),
    ];
  }
}

void main() {
  late CoachCubit c;
  late ReviewRepo repo;
  setUp(() {
    repo = ReviewRepo();
    c = CoachCubit(
      userId: 'u1',
      store: SessionCoachStore(ownerUid: 'u1', currentUid: () => 'u1'),
      nutrition: repo,
      locale: 'en',
      clock: () => DateTime(2026, 11, 24),
    );
  });
  tearDown(() async => c.close());
  Widget app(Widget w) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: w),
  );
  testWidgets(
    'progress periods show owned real coverage and never zero missing nutrients',
    (t) async {
      await t.pumpWidget(
        app(CoachWorkspacePanel(cubit: c, section: 3, onChat: () {})),
      );
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('1 of 7 days logged, 1 meals'), findsOneWidget);
      await t.tap(find.text('30 days'));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('2 of 30 days logged, 2 meals'), findsOneWidget);
      expect(find.textContaining('3.0 g/logged day (1/2'), findsOneWidget);
      await t.tap(find.text('Today'));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('1 of 1 days logged, 1 meals'), findsOneWidget);
    },
  );
  testWidgets(
    'overview and plan describe current session and unsupported matching',
    (t) async {
      await t.pumpWidget(
        app(CoachWorkspacePanel(cubit: c, section: 0, onChat: () {})),
      );
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Meals logged today: 1'), findsOneWidget);
      await t.pumpWidget(
        app(CoachWorkspacePanel(cubit: c, section: 2, onChat: () {})),
      );
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 300));
      expect(
        find.textContaining('Price and preparation time are not matched'),
        findsOneWidget,
      );
    },
  );
  testWidgets('load error offers retry instead of invented coverage', (
    t,
  ) async {
    repo.fail = true;
    await t.pumpWidget(
      app(CoachWorkspacePanel(cubit: c, section: 3, onChat: () {})),
    );
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Could not load records. Retry'), findsOneWidget);
    repo.fail = false;
    await t.tap(find.text('Could not load records. Retry'));
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('1 of 7 days logged, 1 meals'), findsOneWidget);
  });
  testWidgets('learn is source-linked, does not load private records', (
    t,
  ) async {
    repo.fail = true;
    await t.pumpWidget(
      app(CoachWorkspacePanel(cubit: c, section: 4, onChat: () {})),
    );
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('NHS: The Eatwell Guide'), findsOneWidget);
    expect(
      find.textContaining('not yet had specialist review'),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });
  testWidgets('record-gap action opens diary and planner keeps owner choices', (
    t,
  ) async {
    c.updateHealthChoices(
      const HealthCoachConsent(),
      const HealthCoachProfile(
        preferredFoods: ['rice'],
        excludedFoods: ['fish'],
        mealsPerDay: 3,
      ),
    );
    PlannerFoodChoices? choice;
    var openedDiary = false;
    final router = GoRouter(
      initialLocation: '/coach',
      routes: [
        GoRoute(
          path: '/coach',
          builder: (_, __) => Scaffold(
            body: CoachWorkspacePanel(cubit: c, section: 3, onChat: () {}),
          ),
        ),
        GoRoute(
          path: '/diary',
          builder: (_, __) {
            openedDiary = true;
            return const Scaffold(body: Text('Owned diary'));
          },
        ),
        GoRoute(
          path: '/planner',
          builder: (_, state) {
            choice = state.extra as PlannerFoodChoices?;
            return const Scaffold(body: Text('Owned plan'));
          },
        ),
      ],
    );
    await t.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await t.pump(const Duration(seconds: 1));
    final action = find.text('Open diary');
    await t.scrollUntilVisible(
      action,
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(
      t.element(action),
      duration: Duration.zero,
      alignment: .5,
    );
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(action);
    await t.pump(const Duration(seconds: 1));
    expect(openedDiary, true);
    await t.pumpWidget(const SizedBox());
    router.dispose();
    final planRouter = GoRouter(
      initialLocation: '/coach',
      routes: [
        GoRoute(
          path: '/coach',
          builder: (_, __) => Scaffold(
            body: CoachWorkspacePanel(cubit: c, section: 2, onChat: () {}),
          ),
        ),
        GoRoute(
          path: '/planner',
          builder: (_, state) {
            choice = state.extra as PlannerFoodChoices?;
            return const Scaffold(body: Text('Owned plan'));
          },
        ),
      ],
    );
    await t.pumpWidget(
      MaterialApp.router(
        routerConfig: planRouter,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.text('Open my plan'));
    await t.pump(const Duration(seconds: 1));
    expect(choice!.appliesTo('u1'), true);
    expect(choice!.appliesTo('other'), false);
    expect(choice!.excluded, ['fish']);
    expect(choice!.mealsPerDay, 3);
    await t.pumpWidget(const SizedBox());
    planRouter.dispose();
  });
  testWidgets('five sections render without overflow at 2x', (t) async {
    await c.load();
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: CoachScreen(cubit: c),
      ),
    );
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.byKey(const ValueKey('coach_section_selector_1')));
    await t.pump(const Duration(milliseconds: 400));
    final section = find.byKey(const ValueKey('coach_section_0')).last;
    await t.tap(section);
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
  });
}

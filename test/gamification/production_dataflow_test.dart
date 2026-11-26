import 'package:sufradepi/data/models/meal_plan_model.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/features/gamification/domain/progression_engine.dart';
import 'package:sufradepi/features/gamification/data/progression_repository.dart';
import 'package:sufradepi/features/gamification/presentation/progression_screen.dart';
import '../features/progress/progress_test.dart' show FakeNutritionRepository;

final config = ProgressionConfig.fromJson(
  jsonDecode(File('assets/data/progression.json').readAsStringSync()),
);

class Rules implements ProgressionConfigSource {
  @override
  Future<ProgressionConfig> load() async => config;
}

class MutableSource extends FakeNutritionRepository {
  int reads = 0;
  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async {
    reads++;
    return [...meals];
  }
}

MealEntryModel meal(
  String id, {
  String owner = 'u',
  String status = 'confirmed',
  String day = '2026-11-24',
  double calories = 100,
}) => MealEntryModel(
  mealId: id,
  userId: owner,
  dateKey: day,
  consumedAt: DateTime.parse(day),
  mealType: 'lunch',
  inputMethod: 'manual',
  title: 'Recorded meal',
  items: [],
  totalCalories: calories,
  totalProtein: null,
  totalCarbs: null,
  totalFat: null,
  totalFiber: null,
  totalSugar: null,
  totalSodium: null,
  analysisStatus: status,
);
void main() {
  test(
    'production adapter: create edit delete replay and pending state',
    () async {
      final source = MutableSource();
      final repository = ReadOnlyProgressionRepository(
        nutrition: source,
        currentUid: () => 'u',
        profile: () => null,
        configSource: Rules(),
      );
      Future<ProgressionProfile> read() async =>
          (await repository.load('u', '2026-11-24')).profile;
      expect((await read()).xp, 0);
      source.meals = [meal('m')];
      expect((await read()).xp, 10);
      source.meals = [meal('m', calories: 900)];
      expect((await read()).xp, 10);
      expect((await read()).counts['meal'], 1);
      source.meals = [meal('m'), meal('n')];
      expect((await read()).xp, 10);
      expect((await read()).counts['meal'], 2);
      source.meals = [meal('m', status: 'pending')];
      expect((await read()).xp, 0);
      source.meals = [];
      expect((await read()).xp, 0);
      expect((await read()).badges, isEmpty);
    },
  );
  testWidgets(
    'real screen plus production projection reloads create/edit/delete and disposes subscriptions',
    (tester) async {
      final source = MutableSource();
      final events = StreamController<void>.broadcast();
      addTearDown(events.close);
      String uid = 'u', day = '2026-11-24';
      UserProfileModel? profile;
      final repository = ReadOnlyProgressionRepository(
        nutrition: source,
        currentUid: () => uid,
        profile: () => null,
        loadProfile: () async => profile,
        configSource: Rules(),
        changes: (_) => events.stream,
      );
      Future<void> pump(String owner) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: ProgressionScreen(
              uid: owner,
              todayKey: '2026-11-24',
              currentDayKey: () => day,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> changed() async {
        events.add(null);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();
      }

      await pump('u');
      expect(find.text('0 XP'), findsOneWidget);
      source.meals = [meal('m')];
      await changed();
      expect(find.text('10 XP'), findsOneWidget);
      source.meals = [meal('m', calories: 900), meal('n')];
      await changed();
      expect(find.text('10 XP'), findsOneWidget);
      source.meals = [];
      await changed();
      expect(find.text('0 XP'), findsOneWidget);
      profile = const UserProfileModel(
        uid: 'u',
        displayName: 'User',
        onboardingCompleted: true,
      );
      await changed();
      expect(find.text('20 XP'), findsOneWidget);
      source.meals = [meal('m', day: '2026-11-25')];
      await changed();
      expect(find.text('20 XP'), findsOneWidget);
      day = '2026-11-25';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('30 XP'), findsOneWidget);
      uid = 'v';
      profile = null;
      source.meals = [];
      await pump('v');
      expect(find.text('0 XP'), findsOneWidget);
      expect(find.text('30 XP'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(events.hasListener, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'saved plan uses recorded creation date, edits do not multiply XP, inactive excluded',
    () async {
      final source = MutableSource();
      var plans = <MealPlanModel>[];
      MealPlanModel plan(
        String id, {
        String status = 'active',
        DateTime? createdAt,
      }) => MealPlanModel(
        planId: id,
        title: 'Plan',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 7),
        status: status,
        dailyCalorieTarget: 1800,
        meals: [
          const MealPlanMealModel(
            mealId: 'slot',
            title: 'meal',
            mealType: 'lunch',
            calories: 500,
            foods: ['food'],
          ),
        ],
        generatedBy: 'deterministic_catalog',
        createdAt: createdAt,
      );
      final repository = ReadOnlyProgressionRepository(
        nutrition: source,
        currentUid: () => 'u',
        profile: () => null,
        configSource: Rules(),
        loadPlans: (_) async => plans,
      );
      Future<ProgressionProfile> read() async =>
          (await repository.load('u', '2026-11-24')).profile;
      plans = [plan('week', createdAt: DateTime(2026, 11, 24))];
      expect((await read()).xp, 20);
      expect((await read()).badges, contains('planner'));
      expect((await read()).counts['plan'], 1);
      plans = [plan('week')];
      expect((await read()).xp, 0);
      plans = [
        plan('week', status: 'deleted', createdAt: DateTime(2026, 11, 24)),
      ];
      expect((await read()).xp, 0);
      plans = [
        plan('a', createdAt: DateTime(2026, 11, 24)),
        plan('b', createdAt: DateTime(2026, 11, 24)),
      ];
      expect((await read()).xp, 20);
      expect((await read()).counts['plan'], 2);
    },
  );
  test(
    'account switched during delayed plan load never yields previous account progress',
    () async {
      var uid = 'u';
      final gate = Completer<List<MealPlanModel>>();
      final repository = ReadOnlyProgressionRepository(
        nutrition: MutableSource(),
        currentUid: () => uid,
        profile: () => null,
        configSource: Rules(),
        loadPlans: (_) => gate.future,
      );
      final future = repository.load('u', '2026-11-24');
      await Future<void>.delayed(Duration.zero);
      uid = 'v';
      gate.complete([]);
      await expectLater(future, throwsStateError);
    },
  );
}

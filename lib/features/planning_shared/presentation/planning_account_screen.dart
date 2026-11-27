import '../../meal_log/domain/catalog_meal_draft.dart';
import 'dart:async';
import '../../progress/data/hydration_goal_store.dart';
import '../../../features/health_coach/data/coach_health_store.dart';
import '../../planner/domain/planner_food_choices.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../health_coach/data/http_health_coach_provider.dart';
import '../../health_coach/domain/health_coach_orchestrator.dart';
import '../../health_coach/domain/health_coach_profile.dart';
import '../../gamification/data/local_protected_ledger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/meal_plan_model.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../food_catalog/data/datasources/local_food_data_source.dart';
import '../../planner/data/planner_repository.dart';
import '../../planner/domain/weekly_plan_generator.dart';
import '../../planner/presentation/cubit/planner_cubit.dart';
import '../../planner/presentation/screens/planner_screen.dart';
import '../../shopping/data/shopping_repository.dart';
import '../../shopping/presentation/cubit/shopping_cubit.dart';
import '../../shopping/presentation/screens/shopping_screen.dart';
import '../../coach/data/coach_store.dart';
import '../../coach/presentation/cubit/coach_cubit.dart';
import '../../coach/presentation/screens/coach_screen.dart';
import '../../ramadan/data/ramadan_settings_store.dart';
import '../../ramadan/presentation/cubit/ramadan_cubit.dart';
import '../../ramadan/presentation/screens/ramadan_screen.dart';
import '../../../l10n/app_localizations.dart';

enum PlanningPage { planner, shopping, coach, ramadan }

/// Owns the route's async setup and Cubit. A UID-keyed parent disposes this
/// scope on sign-out/switch. No async callback may move data into a new scope.
// Set your own deployment with --dart-define=SUFRA_COACH_URL=https://.../chat
const _coachUrl = String.fromEnvironment(
  'SUFRA_COACH_URL',
  defaultValue: 'https://sufra-owner-coach.invalid/chat',
);

class PlanningAccountScreen extends StatefulWidget {
  const PlanningAccountScreen({
    super.key,
    required this.uid,
    required this.currentUid,
    required this.page,
    this.rewardCandidate,
    this.reviewedMeal,
    this.foodChoices = const PlannerFoodChoices(),
  });
  final CatalogMealDraft? reviewedMeal;
  final LocalRecordedActivityHook? rewardCandidate;
  final String uid;
  final String? Function() currentUid;
  final PlanningPage page;
  final PlannerFoodChoices foodChoices;
  @override
  State<PlanningAccountScreen> createState() => _PlanningAccountScreenState();
}

class _PlanningAccountScreenState extends State<PlanningAccountScreen> {
  Future<Widget>? _future;
  final _owned = <BlocBase<dynamic>>[];
  final _clients = <http.Client>[];
  final _sessions = <SessionCoachStore>[];
  final _coachProviders = <HttpHealthCoachProvider>[];
  StreamSubscription<User?>? _authChanges;

  @override
  void initState() {
    super.initState();
    // Account changes cancel the account-scoped transport immediately, even
    // before the UID-keyed router has completed disposing this screen.
    if (widget.page != PlanningPage.coach) return;
    _authChanges = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid != widget.uid) {
        for (final provider in _coachProviders) {
          provider.cancelPending();
        }
      }
    });
  }

  void _assert(String uid) {
    if (!mounted || uid != widget.uid || widget.currentUid() != uid) {
      throw StateError('Inactive account');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _prepare();
  }

  Future<Widget> _prepare() async {
    final uid = widget.uid;
    final nutrition = context.read<NutritionRepository>();
    final locale = Localizations.localeOf(context).languageCode;
    final source = LocalFoodDataSource();
    _assert(uid);
    switch (widget.page) {
      case PlanningPage.planner:
        final catalog = await source.getAll();
        _assert(uid);
        final cubit = PlannerCubit(
          userId: uid,
          currentUid: widget.currentUid,
          repository: FirestorePlannerRepository(
            FirebaseFirestore.instance,
            assertActive: _assert,
            localActivityHook: widget.rewardCandidate,
          ),
          nutrition: nutrition,
          generator: WeeklyPlanGenerator(catalog: catalog),
          foodChoices: widget.foodChoices,
          today: DateTime.now(),
        );
        _owned.add(cubit);
        return PlannerScreen(cubit: cubit);
      case PlanningPage.shopping:
        final repository = FirestorePlannerRepository(
          FirebaseFirestore.instance,
          assertActive: _assert,
        );
        final week = WeeklyPlanGenerator.weekStartOf(DateTime.now());
        final MealPlanModel? plan = await repository.getPlan(
          uid,
          WeeklyPlanGenerator.planIdFor(week),
        );
        _assert(uid);
        final cubit = ShoppingCubit(
          userId: uid,
          nutrition: nutrition,
          currentUid: widget.currentUid,
          repository: FirestoreShoppingRepository(
            FirebaseFirestore.instance,
            assertActive: _assert,
          ),
          foods: source,
        );
        _owned.add(cubit);
        return ShoppingScreen(cubit: cubit, currentPlan: plan);
      case PlanningPage.coach:
        const enabled = bool.fromEnvironment(
          'SUFRA_OWNER_COACH_ENABLED',
          defaultValue: true,
        );
        final allowed = enabled && uid.isNotEmpty;
        final client = http.Client();
        _clients.add(client);
        final provider = allowed
            ? HttpHealthCoachProvider(
                endpoint: Uri.parse(_coachUrl),
                allowedHosts: {Uri.parse(_coachUrl).host},
                userId: uid,
                currentUid: widget.currentUid,
                idToken: () async =>
                    FirebaseAuth.instance.currentUser?.getIdToken(),
                client: client,
              )
            : null;
        if (provider != null) _coachProviders.add(provider);
        final sessionStore = SessionCoachStore(
          ownerUid: uid,
          currentUid: widget.currentUid,
        );
        _sessions.add(sessionStore);
        final cubit = CoachCubit(
          userId: uid,
          currentUid: widget.currentUid,
          store: sessionStore,
          loadWaterTarget: () => HydrationGoalStore.read(uid),
          healthStore: FirestoreCoachHealthStore(
            FirebaseFirestore.instance,
            uid: uid,
            assertActive: _assert,
          ),
          healthOrchestrator: provider != null
              ? HealthCoachOrchestrator(provider: provider)
              : null,
          // Enable only with a deployed, validated bounded-context backend.
          contextSharingAvailable:
              allowed &&
              const bool.fromEnvironment(
                'SUFRA_OWNER_COACH_CONTEXT_ENABLED',
                defaultValue: true,
              ),
          healthConsent: HealthCoachConsent(externalAi: allowed),
          nutrition: nutrition,
          locale: locale,
        );
        _owned.add(cubit);
        await cubit.loadSavedHealth();
        _assert(uid);
        return CoachScreen(
          cubit: cubit,
          initialReviewedDraft: widget.reviewedMeal,
        );
      case PlanningPage.ramadan:
        final prefs = await SharedPreferences.getInstance();
        _assert(uid);
        final cubit = RamadanCubit(
          userId: uid,
          currentUid: widget.currentUid,
          settings: PrefsRamadanSettingsStore(preferences: prefs, userId: uid),
          nutrition: nutrition,
          foods: source,
        );
        _owned.add(cubit);
        return RamadanScreen(cubit: cubit);
    }
  }

  @override
  void dispose() {
    _authChanges?.cancel();
    for (final provider in _coachProviders) {
      provider.cancelPending();
    }
    for (final cubit in _owned) {
      cubit.close();
    }
    for (final client in _clients) {
      client.close();
    }
    for (final session in _sessions) {
      session.clear();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: _future,
    builder: (_, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => setState(() {
                _future = _prepare();
              }),
              child: Text(AppLocalizations.of(context).stateRetry),
            ),
          ),
        );
      }
      return snapshot.data ??
          const Scaffold(body: Center(child: CircularProgressIndicator()));
    },
  );
}

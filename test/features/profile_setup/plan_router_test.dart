import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/app/router/app_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/auth/presentation/cubit/session_cubit.dart';
import 'package:sufradepi/features/nutrition_plan/presentation/plan_screen.dart';
import 'package:sufradepi/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness;

void main() {
  testWidgets(
    'actual app router preserves freshly calculated owned plan after setup refresh',
    (t) async {
      final h = await Harness.signedIn();
      await h.preferences.setOnboardingSeen();
      h.setupCubit.update(
        ProfileSetupData(
          nutritionGoal: 'lose',
          gender: 'male',
          dateOfBirth: DateTime(2000, 8, 7),
          heightCm: 175,
          currentWeightKg: 90,
          targetWeightKg: 80,
          activityLevel: 'moderate',
        ),
      );
      while (h.setupCubit.state.step < 6) {
        h.setupCubit.next();
      }
      await t.runAsync(() async {
        await h.setupCubit.finish('u1');
        await h.sessionCubit.refreshProfile();
      });
      expect((h.setupCubit.state.status as SetupSaved).uid, 'u1');
      final router = createRouter(
        sessionCubit: h.sessionCubit,
        preferences: h.preferences,
      );
      router.go('/plan');
      await t.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: h.sessionCubit),
            BlocProvider<ProfileSetupCubit>.value(value: h.setupCubit),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.dark(),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(router.routeInformationProvider.value.uri.path, '/plan');
      expect(find.byType(PlanScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await h.dispose();
    },
  );
  testWidgets('plan refuses a cached calculation owned by another account', (
    t,
  ) async {
    final h = await Harness.signedIn();
    h.setupCubit.update(
      ProfileSetupData(
        nutritionGoal: 'lose',
        gender: 'male',
        dateOfBirth: DateTime(2000, 8, 7),
        heightCm: 175,
        currentWeightKg: 90,
        targetWeightKg: 80,
        activityLevel: 'moderate',
      ),
    );
    while (h.setupCubit.state.step < 6) {
      h.setupCubit.next();
    }
    await t.runAsync(() async {
      await h.setupCubit.finish('other-account');
    });
    await t.pumpWidget(h.wrap(const PlanScreen()));
    await t.pump();
    final l = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(l.homeNoGoalYet), findsOneWidget);
    expect(find.text('2397'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    await h.dispose();
  });
}

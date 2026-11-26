import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/ramadan/presentation/screens/ramadan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/app/router/app_router.dart';
import 'package:sufradepi/core/widgets/app_states.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/features/auth/presentation/cubit/session_cubit.dart';
import 'package:sufradepi/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../goldens/milestone1_screens_test.dart' show Harness;

void main() {
  testWidgets(
    'production Ramadan route loads local settings without Firebase',
    (t) async {
      final h = await Harness.signedIn();
      await h.preferences.setOnboardingSeen();
      await h.sessionCubit.refreshProfile();
      final router = createRouter(
        sessionCubit: h.sessionCubit,
        preferences: h.preferences,
      );
      router.go('/ramadan');
      await t.pumpWidget(
        RepositoryProvider<NutritionRepository>.value(
          value: h.nutritionRepository,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<SessionCubit>.value(value: h.sessionCubit),
              BlocProvider<ProfileSetupCubit>.value(value: h.setupCubit),
            ],
            child: MaterialApp.router(
              theme: AppTheme.dark(),
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        ),
      );
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(router.routeInformationProvider.value.uri.path, '/ramadan');
      expect(find.byType(RamadanScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      router.dispose();
      await h.dispose();
    },
  );
  for (final path in [
    '/food',
    '/meal-review',
    '/recipe-quantify',
    '/meal/id',
  ]) {
    testWidgets('production router rejects missing payload: $path', (t) async {
      final h = await Harness.signedIn();
      await h.preferences.setOnboardingSeen();
      await h.sessionCubit.refreshProfile();
      final router = createRouter(
        sessionCubit: h.sessionCubit,
        preferences: h.preferences,
      );
      router.go(path);
      await t.pumpWidget(
        RepositoryProvider<NutritionRepository>.value(
          value: h.nutritionRepository,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<SessionCubit>.value(value: h.sessionCubit),
              BlocProvider<ProfileSetupCubit>.value(value: h.setupCubit),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(router.routeInformationProvider.value.uri.path, path);
      expect(find.byType(AppErrorView), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      router.dispose();
      await h.dispose();
    });
  }
}

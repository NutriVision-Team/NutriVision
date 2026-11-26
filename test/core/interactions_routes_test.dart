import 'dart:io';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/features/home/presentation/cubit/home_cubit.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_log_hub_screen.dart';
import 'package:sufradepi/core/theme/theme_cubit.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/app/router/app_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/auth/presentation/cubit/session_cubit.dart';
import 'package:sufradepi/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'package:sufradepi/features/dashboard/presentation/destination_hubs.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final light in [true, false]) {
      testWidgets('production hubs nav privacy back $lang $light', (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final h = await Harness.signedIn();
        await h.preferences.setOnboardingSeen();
        await h.sessionCubit.refreshProfile();
        final router = createRouter(
          sessionCubit: h.sessionCubit,
          preferences: h.preferences,
        );
        router.go('/meals');
        final key = GlobalKey();
        await t.pumpWidget(
          RepositoryProvider<NutritionRepository>.value(
            value: h.nutritionRepository,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<HomeCubit>.value(value: h.homeCubit),
                BlocProvider<ThemeCubit>(
                  create: (_) => ThemeCubit(h.preferences),
                ),
                BlocProvider<SessionCubit>.value(value: h.sessionCubit),
                BlocProvider<ProfileSetupCubit>.value(value: h.setupCubit),
              ],
              child: RepaintBoundary(
                key: key,
                child: MaterialApp.router(
                  routerConfig: router,
                  debugShowCheckedModeBanner: false,
                  theme: light ? AppTheme.light() : AppTheme.dark(),
                  locale: Locale(lang),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                ),
              ),
            ),
          ),
        );
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(find.byType(MealsHubScreen), findsOneWidget);
        Future<void> shot(String name) async {
          expect(t.takeException(), isNull);
          await t.runAsync(() async {
            final im =
                await (key.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final b = await im.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '/downloads/sufra-recovered/interactions1930_${lang}_${light ? 'light' : 'dark'}_$name.png',
            ).writeAsBytes(b!.buffer.asUint8List());
            im.dispose();
          });
        }

        await shot('meals');
        final nav = find.byType(FloatingGlassNavBar);
        await t.tap(
          find.descendant(
            of: nav,
            matching: find.text(lang == 'ar' ? 'حسابي' : 'Account'),
          ),
        );
        await t.pump();
        for (var n = 0; n < 8; n++) {
          await t.pump(const Duration(milliseconds: 45));
          await shot('nav${n.toString().padLeft(3, '0')}');
        }
        expect(router.routeInformationProvider.value.uri.path, '/profile');
        expect(find.byType(ProfileHubScreen), findsOneWidget);
        await shot('profile');
        final premium = find.text(
          lang == 'ar' ? 'سفرة بريميوم' : 'Sufra Premium',
        );
        if (premium.evaluate().isNotEmpty) {
          await t.ensureVisible(premium);
          await t.pump();
        }
        router.push('/premium');
        await t.pump();
        for (var n = 0; n < 8; n++) {
          await t.pump(const Duration(milliseconds: 45));
          await shot('page${n.toString().padLeft(3, '0')}');
        }
        router.pop();
        await t.pump();
        await t.pump(const Duration(milliseconds: 450));

        final privacy = find.text(
          lang == 'ar' ? 'الخصوصية والاستخدام' : 'Privacy and use',
        );
        await t.scrollUntilVisible(
          privacy,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(t.element(privacy), alignment: 0.4);
        await t.pump();
        await t.tap(privacy);
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        expect(find.byType(Dialog), findsOneWidget);
        await shot('privacy');
        router.pop();
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        expect(find.byType(ProfileHubScreen), findsOneWidget);
        expect(find.byType(Dialog), findsNothing);
        await t.tap(
          find.descendant(
            of: find.byType(FloatingGlassNavBar),
            matching: find.text(lang == 'ar' ? 'اليومية' : 'Diary'),
          ),
        );
        await t.pump();
        await t.pump(const Duration(milliseconds: 400));
        expect(router.routeInformationProvider.value.uri.path, '/diary');
        expect(find.byType(MealsHubScreen), findsNothing);
        final bottom = find.byType(FloatingGlassNavBar);
        await t.tap(
          find.descendant(
            of: bottom,
            matching: find.text(lang == 'ar' ? 'الرئيسية' : 'Home'),
          ),
        );
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        expect(router.routeInformationProvider.value.uri.path, '/home');
        expect(find.byType(HomeScreen), findsOneWidget);
        await shot('home');
        router.go('/meals');
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        await t.tap(find.byTooltip(lang == 'ar' ? 'إضافة وجبة' : 'Add meal'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        expect(router.routeInformationProvider.value.uri.path, '/log');
        expect(find.byType(MealLogHubScreen), findsOneWidget);
        await shot('log');
        await t.pumpWidget(const SizedBox());
        router.dispose();
        await h.dispose();
      });
    }
  }
}

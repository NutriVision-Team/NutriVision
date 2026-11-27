import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/sufra_navigation.dart';
import 'package:sufradepi/features/dashboard/presentation/destination_hubs.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final ar in [true, false]) {
    testWidgets('all five destinations route, ${ar ? 'AR' : 'EN'}', (t) async {
      t.view.physicalSize = const Size(430, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              bottomNavigationBar: SufraNavigation(currentIndex: 0),
            ),
          ),
          for (final path in ['/home', '/diary', '/log', '/stats', '/profile'])
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(
                body: Text('route:$path'),
                bottomNavigationBar: const SufraNavigation(currentIndex: -1),
              ),
            ),
        ],
      );
      addTearDown(router.dispose);
      await t.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          locale: Locale(ar ? 'ar' : 'en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
        ),
      );
      for (final item in [
        (ar ? 'اليومية' : 'Diary', '/diary'),
        (ar ? 'تقدمي' : 'Progress', '/stats'),
        (ar ? 'حسابي' : 'Account', '/profile'),
        (ar ? 'إضافة وجبة' : 'Add meal', '/log'),
        (ar ? 'الرئيسية' : 'Home', '/home'),
      ]) {
        final finder = item.$2 == '/log'
            ? find.byTooltip(item.$1)
            : find.text(item.$1);
        await t.tap(finder);
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(find.text('route:${item.$2}'), findsOneWidget);
        expect(t.takeException(), isNull);
      }
    });
  }
  for (final entry in [
    ('ar', ThemeMode.dark, 390.0, 1.0),
    ('en', ThemeMode.light, 390.0, 1.0),
    ('ar', ThemeMode.dark, 320.0, 2.0),
    ('en', ThemeMode.light, 320.0, 2.0),
  ]) {
    for (final profile in [false, true]) {
      testWidgets('hub pixels $entry profile=$profile', (t) async {
        t.view.physicalSize = Size(entry.$3, 844);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = entry.$4;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final h = await Harness.signedIn();
        final key = GlobalKey();
        await t.runAsync(() async {
          await t.pumpWidget(
            RepaintBoundary(
              key: key,
              child: h.wrap(
                profile ? const ProfileHubScreen() : const MealsHubScreen(),
                locale: Locale(entry.$1),
                themeMode: entry.$2,
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await t.pump(const Duration(seconds: 1));
        expect(t.takeException(), isNull);
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra/verification/hub_${profile ? 'profile' : 'meals'}_${entry.$1}_${entry.$3}_${entry.$4}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          im.dispose();
        });
        await t.pumpWidget(const SizedBox());
        await h.dispose();
      });
    }
  }
}

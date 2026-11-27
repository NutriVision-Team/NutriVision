import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/auth/presentation/cubit/session_cubit.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_log_hub_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/services/auth_service.dart';
import '../goldens/milestone1_screens_test.dart'
    show FakeUserRepository, loadRealFonts;

void main() {
  setUpAll(() async {
    await loadRealFonts();
    final dir = Platform.environment['SUFRA_PRIVATE_FONT_DIR'];
    if (dir != null) {
      final loader = FontLoader('Thmanyah Sans');
      for (final w in ['Regular', 'Medium', 'Bold']) {
        final b = File('$dir/thmanyahsans-$w.otf').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(b.buffer)));
      }
      await loader.load();
    }
  });
  for (final lang in ['ar', 'en']) {
    testWidgets('logging methods $lang 320px 2x full card labels and routes', (
      t,
    ) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Platform.environment['SUFRA_NORMAL_REVIEW'] == '1'
          ? const Size(390, 844)
          : const Size(320, 844);
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
      final session = SessionCubit(
        authService: AuthService.withAuth(MockFirebaseAuth()),
        userRepository: FakeUserRepository(),
      );
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const MealLogHubScreen()),
          for (final path in [
            '/camera',
            '/barcode',
            '/food-search',
            '/favorites',
            '/voice-meal',
          ])
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(body: Text('target $path')),
            ),
        ],
      );
      await t.pumpWidget(
        BlocProvider.value(
          value: session,
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.dark(),
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                textScaler: TextScaler.linear(
                  Platform.environment['SUFRA_NORMAL_REVIEW'] == '1' ? 1 : 2,
                ),
                disableAnimations: true,
              ),
              child: RepaintBoundary(
                key: const ValueKey('hub-shot'),
                child: child!,
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      final l = await AppLocalizations.delegate.load(Locale(lang));
      final labels = [
        l.logHubPhotoTitle,
        l.logHubBarcodeTitle,
        l.logHubSearchTitle,
        l.logHubFavoritesTitle,
      ];
      final paths = ['/camera', '/barcode', '/food-search', '/favorites'];
      for (var i = 0; i < labels.length; i++) {
        final label = labels[i];
        final target = find.textContaining(label).last;
        if (find.textContaining(label).evaluate().isEmpty) {
          await t.scrollUntilVisible(
            find.textContaining(label),
            250,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await t.ensureVisible(target);
        await t.pump();
        expect(t.takeException(), isNull);
        final pixel = Platform.environment['SUFRA_HUB_PIXEL'];
        if (pixel != null && i == 1) {
          await t.runAsync(() async {
            final context = t.element(find.byType(Scaffold).first);
            for (final a in ['neb.jpg', 'spA.webp', 'spB.webp']) {
              await precacheImage(AssetImage('assets/images/art/$a'), context);
            }
          });
          await t.pump();
          final b = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('hub-shot')),
          );
          await t.runAsync(() async {
            final image = await b.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            File(
              '$pixel-$lang.png',
            ).writeAsBytesSync(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        await t.tap(find.textContaining(label).last);
        await t.pumpAndSettle();
        expect(find.text('target ${paths[i]}'), findsOneWidget);
        router.pop();
        await t.pumpAndSettle();
      }
      await t.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await session.close();
    });
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/nebula_background.dart';
import 'package:sufradepi/core/widgets/glass_shortcut.dart';
import 'package:sufradepi/data/models/favorite_model.dart';
import 'package:sufradepi/features/home/presentation/cubit/home_cubit.dart';
import 'package:sufradepi/features/home/presentation/widgets/home_activity_story.dart';
import 'package:sufradepi/features/home/presentation/widgets/home_progress_card.dart';
import 'package:sufradepi/features/gamification/data/progression_repository.dart';
import 'package:sufradepi/features/gamification/domain/progression_engine.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../gamification/progression_screen_test.dart' show fixtureConfig;
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts, Harness;
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';

class Repository implements ProgressionRepository, LiveProgressionRepository {
  final changes = StreamController<void>.broadcast();
  bool fails = false;
  int reads = 0;
  final keys = <String>[];
  @override
  Stream<void> watchChanges(String uid) => changes.stream;
  @override
  Future<ProgressionSnapshot> load(String uid, String todayKey) async {
    reads++;
    keys.add(todayKey);
    if (fails) throw StateError('fixture');
    final events = [
      ProgressionEvent(
        uid: uid,
        sourceId: 'setup',
        kind: 'profile',
        dayKey: '',
      ),
      for (var i = 1; i <= 9; i++)
        ProgressionEvent(
          uid: uid,
          sourceId: 'm$i',
          kind: 'meal',
          dayKey: '2026-11-${i.toString().padLeft(2, '0')}',
        ),
    ];
    return ProgressionSnapshot(
      ProgressionEngine(fixtureConfig).project(uid, todayKey, events),
      fixtureConfig,
      events,
    );
  }
}

const activity = HomeLoaded(
  profile: null,
  nutritionProfile: null,
  todaysMeals: [],
  dailyLog: null,
  streakDays: 0,
  favorites: [
    FavoriteModel(
      favoriteId: 'm',
      targetId: 'x',
      targetType: 'meal',
      title: 'كشري مصري · Egyptian koshari',
    ),
  ],
);

void main() {
  setUpAll(loadRealFonts);
  Future<void> capture(WidgetTester t, GlobalKey key, String name) async {
    await t.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '/downloads/sufra-recovered/home1440_$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('journey and story $lang $dark $scale', (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final r = Repository();
          final key = GlobalKey();
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Scaffold(
                  body: NebulaBackground(
                    child: SafeArea(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          HomeProgressCard(
                            uid: 'u',
                            repository: r,
                            todayKey: '2026-11-22',
                          ),
                          const SizedBox(height: 16),
                          HomeActivityStory(
                            data: activity,
                            now: DateTime(2026, 11, 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/stats',
                builder: (context, _) => Scaffold(
                  body: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Return'),
                  ),
                ),
              ),
            ],
          );
          await t.pumpWidget(
            MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) =>
                  RepaintBoundary(key: key, child: child!),
            ),
          );
          await t.pump();
          await t.pump(const Duration(seconds: 2));
          expect(t.takeException(), isNull);
          expect(find.text('110 XP'), findsOneWidget);
          final indicator = t.widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          );
          expect(indicator.value, closeTo(.05, .001));
          expect(
            find.textContaining(
              lang == 'ar'
                  ? 'داخل المستوى: 10 من 200'
                  : 'Within level: 10 of 200',
            ),
            findsOneWidget,
          );
          expect(r.keys.single, '2026-11-22');
          await capture(
            t,
            key,
            '${lang}_${dark ? 'dark' : 'light'}_${scale}_top',
          );
          await t.scrollUntilVisible(
            find.text(
              lang == 'ar'
                  ? 'أكلات بتحب ترجع لها'
                  : 'Meals you like coming back to',
            ),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await t.pump();
          await t.pump(const Duration(seconds: 2));
          expect(t.takeException(), isNull);
          await capture(
            t,
            key,
            '${lang}_${dark ? 'dark' : 'light'}_${scale}_story',
          );
          await t.scrollUntilVisible(
            find.byType(GlassShortcut),
            -250,
            scrollable: find.byType(Scrollable).first,
          );
          await t.ensureVisible(find.byType(GlassShortcut));
          await t.pump(const Duration(milliseconds: 300));
          final gesture = await t.startGesture(
            t.getCenter(find.byType(GlassShortcut)),
          );
          await t.pump(const Duration(milliseconds: 350));
          if (lang == 'ar' && dark && scale == 1.0) {
            for (var frame = 0; frame < 12; frame++) {
              await t.pump(const Duration(milliseconds: 100));
              await capture(
                t,
                key,
                'motion_${frame.toString().padLeft(3, '0')}',
              );
            }
          }
          await capture(
            t,
            key,
            '${lang}_${dark ? 'dark' : 'light'}_${scale}_press',
          );
          await gesture.up();
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          expect(find.text('Return'), findsOneWidget);
          await t.tap(find.text('Return'));
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          expect(r.reads, 2);
          r.changes.add(null);
          await t.pump(const Duration(milliseconds: 140));
          await t.pump();
          expect(r.reads, 3);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
          router.dispose();
          await r.changes.close();
        });
      }
    }
  }
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('full Home integration $lang $dark $scale', (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final r = Repository();
          final h = await Harness.signedIn();
          final key = GlobalKey();
          await t.runAsync(() async {
            await t.pumpWidget(
              RepaintBoundary(
                key: key,
                child: h.wrap(
                  HomeScreen(
                    clock: () => DateTime(2026, 11, 22, 9),
                    progression: r,
                  ),
                  locale: Locale(lang),
                  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
            );
            await Future<void>.delayed(const Duration(milliseconds: 150));
          });
          await t.pump();
          await t.pump(const Duration(seconds: 2));
          await capture(
            t,
            key,
            '${lang}_${dark ? 'dark' : 'light'}_${scale}_fullhome',
          );
          await t.scrollUntilVisible(
            find.byType(HomeProgressCard),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await t.pump();
          await t.pump(const Duration(seconds: 2));
          await capture(
            t,
            key,
            '${lang}_${dark ? 'dark' : 'light'}_${scale}_integrated',
          );
          expect(r.keys.last, '2026-11-22');
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
          await h.dispose();
          await r.changes.close();
        });
      }
    }
  }
  testWidgets('retry and reduced motion retain factual XP', (t) async {
    final r = Repository()..fails = true;
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: HomeProgressCard(
              uid: 'u',
              repository: r,
              todayKey: '2026-11-22',
            ),
          ),
        ),
      ),
    );
    await t.pump();
    expect(find.text('Try again'), findsOneWidget);
    r.fails = false;
    await t.tap(find.text('Try again'));
    await t.pump();
    await t.pump();
    expect(find.text('110 XP'), findsOneWidget);
    for (final a in t.widgetList<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    )) {
      expect(a.duration, Duration.zero);
    }
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(t.getCenter(find.byType(GlassShortcut)));
    await t.pump();
    expect(t.takeException(), isNull);
    await mouse.removePointer();
    await t.pumpWidget(const SizedBox.shrink());
    await r.changes.close();
  });
}

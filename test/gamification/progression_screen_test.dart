import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/features/gamification/domain/progression_engine.dart';
import 'package:sufradepi/features/gamification/data/progression_repository.dart';
import 'package:sufradepi/features/gamification/presentation/progression_screen.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;

final fixtureConfig = ProgressionConfig.fromJson(
  jsonDecode(File('assets/data/progression.json').readAsStringSync()),
);

class FixtureRepository implements ProgressionRepository {
  bool fails = false;
  int reads = 0;
  @override
  Future<ProgressionSnapshot> load(String uid, String todayKey) async {
    reads++;
    if (fails) throw StateError('fixture error');
    final c = fixtureConfig;
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
      ProgressionEngine(c).project(uid, todayKey, events),
      c,
      events,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);
  for (final config in [
    ('ar', true, 390.0, 1.0),
    ('en', true, 320.0, 2.0),
    ('ar', false, 320.0, 2.0),
    ('en', false, 390.0, 1.0),
  ]) {
    testWidgets('journey full scroll $config', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(config.$3, 844);
      tester.platformDispatcher.textScaleFactorTestValue = config.$4;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: config.$2 ? ThemeMode.light : ThemeMode.dark,
          locale: Locale(config.$1),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: RepaintBoundary(key: key, child: child!),
          ),
          home: ProgressionScreen(
            uid: 'u',
            todayKey: '2026-11-24',
            repository: FixtureRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Future<void> snap(String suffix) async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '/downloads/sufra/verification/journey_${config.$1}_${config.$2 ? "light" : "dark"}_${config.$3.toInt()}_$suffix.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      }

      await tester.runAsync(() => snap('top'));
      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -590));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() => snap('scroll$i'));
      }
      await tester.scrollUntilVisible(
        find.text(config.$1 == 'ar' ? 'صحتك بالأرقام' : 'Your health records'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() => snap('bottom'));
      expect(tester.takeException(), isNull);
      // Badge details stay explicit about unsupported tracking.
      await tester.scrollUntilVisible(
        find.text(config.$1 == 'ar' ? 'محب المعرفة' : 'Knowledge seeker'),
        -350,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(
          find.text(config.$1 == 'ar' ? 'محب المعرفة' : 'Knowledge seeker'),
        ),
        alignment: .4,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(config.$1 == 'ar' ? 'محب المعرفة' : 'Knowledge seeker'),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() => snap('detail'));
      expect(find.text(config.$1 == 'ar' ? 'تمام' : 'Done'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('failure is recoverable, owner change discards old data', (
    tester,
  ) async {
    final r = FixtureRepository()..fails = true;
    Future<void> pump(String uid) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: ProgressionScreen(
            uid: uid,
            todayKey: '2026-11-24',
            repository: r,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump('u');
    expect(find.text('Try again'), findsOneWidget);
    r.fails = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('110 XP'), findsOneWidget);
    await pump('v');
    expect(find.text('110 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('mission routes to logging and refreshes when returning', (
    tester,
  ) async {
    final repository = FixtureRepository();
    final router = GoRouter(
      initialLocation: '/stats',
      routes: [
        GoRoute(
          path: '/stats',
          builder: (_, _) => ProgressionScreen(
            uid: 'u',
            todayKey: '2026-11-24',
            repository: repository,
          ),
        ),
        GoRoute(
          path: '/log',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Return from logging'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.reads, 1);
    await Scrollable.ensureVisible(
      tester.element(find.text('Log a meal')),
      alignment: .4,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log a meal'));
    await tester.pumpAndSettle();
    expect(find.text('Return from logging'), findsOneWidget);
    await tester.tap(find.text('Return from logging'));
    await tester.pumpAndSettle();
    expect(repository.reads, 2);
    expect(tester.takeException(), isNull);
  });
}

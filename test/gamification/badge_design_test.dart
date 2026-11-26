import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/features/gamification/presentation/widgets/sufra_badge.dart';
import 'package:sufradepi/features/gamification/presentation/widgets/badge_celebration.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);
  const ids = [
    'journey',
    'first_meal',
    'aware',
    'planner',
    'planner3',
    'active7',
    'active30',
    'learner',
    'cook',
    'returning',
  ];
  const titles = [
    'بداية الرحلة',
    'أول وجبة',
    'اختيارات واعية',
    'المخطط الذكي',
    'عادة التخطيط',
    'روح الاستمرارية',
    'رحلة شهر',
    'محب المعرفة',
    'مستكشف الوصفات',
    'خطوة بخطوة',
  ];
  Future<void> capture(WidgetTester t, GlobalKey key, String path) async {
    await t.runAsync(() async {
      final im =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final data = await im.toByteData(format: ui.ImageByteFormat.png);
      File(path).writeAsBytesSync(data!.buffer.asUint8List());
      im.dispose();
    });
  }

  for (final dark in [false, true]) {
    testWidgets('all10 original badge designs dark=$dark', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(750, 1070);
      addTearDown(t.view.reset);
      final key = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        dark
                            ? 'Sufra • Achievement collection'
                            : 'سُفرة • مجموعة الإنجازات',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 5,
                          childAspectRatio: .50,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 24,
                          children: [
                            for (var i = 0; i < 10; i++)
                              Column(
                                children: [
                                  SufraBadge(
                                    id: ids[i],
                                    unlocked: true,
                                    size: 110,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    titles[i],
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SufraBadge(
                                    id: ids[i],
                                    unlocked: false,
                                    size: 60,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await capture(
        t,
        key,
        '/downloads/sufra/verification/badge_collection_${dark ? "dark" : "light"}0732.png',
      );
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('actual unlock motion frames and reduced motion', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(390, 844);
    addTearDown(t.view.reset);
    final key = GlobalKey();
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RepaintBoundary(
          key: key,
          child: const Scaffold(
            body: BadgeCelebration(id: 'journey', title: 'بداية الرحلة'),
          ),
        ),
      ),
    );
    for (var i = 0; i < 32; i++) {
      await t.pump(const Duration(milliseconds: 50));
      await capture(
        t,
        key,
        '/downloads/sufra/verification/badge_motion_${i.toString().padLeft(3, '0')}.png',
      );
      expect(t.takeException(), isNull);
    }
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: true, textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: key,
          child: const Scaffold(
            body: BadgeCelebration(id: 'learner', title: 'Knowledge seeker'),
          ),
        ),
      ),
    );
    await t.pump();
    await capture(
      t,
      key,
      '/downloads/sufra/verification/badge_celebration_large0732.png',
    );
    expect(t.takeException(), isNull);
  });
}

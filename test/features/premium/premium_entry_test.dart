import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/features/dashboard/presentation/destination_hubs.dart';
import 'package:sufradepi/features/premium/presentation/screens/premium_screen.dart';

import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final entry in [('ar', ThemeMode.dark), ('en', ThemeMode.light)]) {
    testWidgets(
      'profile Premium entry opens /premium and backs out ${entry.$1}',
      (t) async {
        t.view.physicalSize = const Size(390, 1500);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final h = await Harness.signedIn();
        final key = GlobalKey();
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: h.wrap(
              const ProfileHubScreen(),
              locale: Locale(entry.$1),
              themeMode: entry.$2,
              additionalRoutes: [
                GoRoute(
                  path: '/premium',
                  builder: (_, _) => const PremiumScreen(),
                ),
              ],
            ),
          ),
        );
        await t.pump(const Duration(seconds: 2));
        final label = entry.$1 == 'ar' ? 'سفرة بريميوم' : 'Sufra Premium';
        expect(find.text(label), findsOneWidget);
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'build/premium_entry/profile_${entry.$1}.png',
          ).writeAsBytes(b!.buffer.asUint8List());
          im.dispose();
        });
        await t.ensureVisible(find.text(label));
        await t.tap(find.text(label));
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(find.byType(PremiumScreen), findsOneWidget);
        expect(find.byType(ProfileHubScreen), findsNothing);
        // System back returns to the profile.
        await t.binding.handlePopRoute();
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(find.byType(ProfileHubScreen), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await h.dispose();
      },
    );
  }
}

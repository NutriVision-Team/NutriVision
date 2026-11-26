import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/auth/presentation/cubit/session_cubit.dart';
import 'package:sufradepi/features/dashboard/presentation/destination_hubs.dart';

import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final entry in [('ar', ThemeMode.dark), ('en', ThemeMode.light)]) {
    testWidgets(
      'profile log out confirms, signs out, cancel keeps session ${entry.$1}',
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
            ),
          ),
        );
        await t.pump(const Duration(seconds: 2));
        expect(h.sessionCubit.state, isA<SessionAuthenticated>());
        final ar = entry.$1 == 'ar';
        final label = ar ? 'تسجيل الخروج' : 'Log out';
        Future<void> shot(String name) => t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'build/logout/${name}_${entry.$1}.png',
          ).writeAsBytes(b!.buffer.asUint8List());
          im.dispose();
        });
        Directory('build/logout').createSync(recursive: true);
        await shot('profile');
        await t.ensureVisible(find.text(label));
        await t.tap(find.text(label));
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(find.text(ar ? 'تسجيل الخروج؟' : 'Log out?'), findsOneWidget);
        await shot('dialog');
        // Cancel keeps the session.
        await t.tap(find.text(ar ? 'إلغاء' : 'Cancel'));
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(h.sessionCubit.state, isA<SessionAuthenticated>());
        // Confirm signs out.
        await t.tap(find.text(label));
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        await t.tap(
          find.descendant(
            of: find.bySubtype<AlertDialog>(),
            matching: find.text(label),
          ),
        );
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await t.pump(const Duration(seconds: 1));
        expect(h.sessionCubit.state, isA<SessionUnauthenticated>());
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await h.dispose();
      },
    );
  }
}

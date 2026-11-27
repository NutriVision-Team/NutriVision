import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/welcome_heading.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';
import 'package:sufradepi/features/auth/presentation/screens/welcome_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final size in [const Size(390, 844), const Size(1280, 720)]) {
    for (final name in ['Mostafa Ghonime', 'مصطفى غنيم', 'مصطفى Mostafa', '']) {
      testWidgets('welcome mixed script $name ${size.width}', (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = size;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final h = await Harness.signedIn();
        h.userRepository.user = UserProfileModel(
          uid: 'u1',
          displayName: name,
          email: name.isEmpty ? null : 'fixture@example.invalid',
        );
        await t.pumpWidget(h.wrap(const SizedBox.shrink()));
        await t.pump(const Duration(milliseconds: 500));
        await h.sessionCubit.refreshProfile();
        await t.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('mixed-capture'),
            child: h.wrap(const WelcomeScreen()),
          ),
        );
        await t.pump(const Duration(seconds: 4));
        await t.runAsync(() async {
          final c = t.element(find.byType(WelcomeScreen));
          await precacheImage(
            const AssetImage('assets/images/art/hero_art.webp'),
            c,
          );
          await precacheImage(const AssetImage('assets/images/art/neb.jpg'), c);
        });
        await t.pump();
        expect(t.takeException(), isNull);
        expect(find.byType(WelcomeHeading), findsOneWidget);
        if (name.isNotEmpty) expect(find.text(name), findsOneWidget);
        if (name == 'Mostafa Ghonime') {
          final greeting = t.getRect(find.text('أهلاً بيك يا'));
          final nameRect = t.getRect(find.text(name));
          expect(greeting.overlaps(nameRect), isFalse);
          final target = Platform.environment['SUFRA_MIXED_PIXELS'];
          if (target != null) {
            final boundary = t.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('mixed-capture')),
            );
            await t.runAsync(() async {
              final image = await boundary.toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File(
                '$target-${size.width.toInt()}.png',
              ).writeAsBytesSync(data!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
        await t.pumpWidget(const SizedBox.shrink());
        await h.dispose();
      });
    }
  }
}

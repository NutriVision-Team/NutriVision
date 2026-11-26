import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
// Test-only host path fake for the existing transitive plugin interface.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sufradepi/features/home/presentation/widgets/local_profile_avatar.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_screen.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;
import '../../planning/screens_smoke_test.dart' show FakeCoachDictation;

class Paths extends PathProviderPlatform {
  Paths(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  setUpAll(loadRealFonts);
  testWidgets(
    'choose profile photo persists and appears in actual Coach user bubble',
    (t) async {
      final dir = (await t.runAsync(
        () => Directory.systemTemp.createTemp('avatar-ui'),
      ))!;
      addTearDown(() => dir.delete(recursive: true));
      final old = PathProviderPlatform.instance;
      PathProviderPlatform.instance = Paths(dir.path);
      addTearDown(() => PathProviderPlatform.instance = old);
      final pic = image.Image(width: 80, height: 80);
      image.fill(pic, color: image.ColorRgb8(30, 150, 180));
      image.fillCircle(
        pic,
        x: 40,
        y: 32,
        radius: 15,
        color: image.ColorRgb8(255, 205, 110),
      );
      final source = File('${dir.path}/portrait.png')
        ..writeAsBytesSync(image.encodePng(pic));
      final h = await Harness.signedIn();
      final key = GlobalKey();
      await t.pumpWidget(
        h.wrap(
          Scaffold(
            body: Center(
              child: LocalProfileAvatar(
                uid: 'u1',
                pick: () async => source.path,
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await t.tap(find.byType(LocalProfileAvatar));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      await t.tap(find.byType(FilledButton));
      await t.pump();
      for (var i = 0; i < 30; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump(const Duration(milliseconds: 100));
        if (find
            .byWidgetPredicate((w) => w is Image && w.image is MemoryImage)
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
      final original =
          t
                  .widget<Image>(
                    find
                        .byWidgetPredicate(
                          (w) => w is Image && w.image is MemoryImage,
                        )
                        .first,
                  )
                  .image
              as MemoryImage;
      expect(original.bytes, isNotEmpty);
      expect(source.existsSync(), true);
      final c = CoachCubit(
        userId: 'u1',
        store: SessionCoachStore(ownerUid: 'u1', currentUid: () => 'u1'),
        nutrition: h.nutritionRepository,
        locale: 'ar',
      );
      await t.runAsync(() async {
        await c.load();
        await c.send('أهلا');
      });
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: h.wrap(CoachScreen(cubit: c, dictation: FakeCoachDictation())),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      // Chat is the default section; force through the real selector if needed.
      final bubbles = find.byWidgetPredicate(
        (w) => w is LocalProfileAvatar && !w.editable,
      );
      if (bubbles.evaluate().isEmpty) {
        await t.tap(find.byType(DropdownButtonFormField<int>));
        await t.pump(const Duration(milliseconds: 400));
        await t.tap(find.byKey(const ValueKey('coach_section_1')).last);
        await t.pump(const Duration(milliseconds: 500));
      }
      for (var i = 0; i < 30; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump(const Duration(milliseconds: 100));
        if (find
            .descendant(of: bubbles, matching: find.byType(Image))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
      expect(bubbles, findsWidgets);
      final rendered =
          t
                  .widget<Image>(
                    find.descendant(
                      of: bubbles.first,
                      matching: find.byType(Image),
                    ),
                  )
                  .image
              as MemoryImage;
      expect(rendered.bytes, original.bytes);
      await t.runAsync(() async {
        final im =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final b = await im.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/downloads/sufra-recovered/avatar1635_coach.png',
        ).writeAsBytes(b!.buffer.asUint8List());
        im.dispose();
      });
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await c.close();
      await h.dispose();
    },
  );
}

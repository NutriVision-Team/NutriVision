import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/config/app_preferences.dart';
import 'package:sufradepi/core/theme/theme_cubit.dart';
import 'package:sufradepi/core/widgets/theme_switcher.dart';

Future<ThemeCubit> _cubit() async {
  SharedPreferences.setMockInitialValues(const {});
  final prefs = await AppPreferences.load();
  return ThemeCubit(prefs);
}

Widget _app(ThemeCubit cubit) {
  return BlocProvider<ThemeCubit>.value(
    value: cubit,
    child: BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: state.mode,
          home: RepaintBoundary(
            key: sufraRootBoundaryKey,
            child: const Scaffold(body: Center(child: LiquidThemeButton())),
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets(
    'off-center reveal uses actual toggle origin and invokes haptic',
    (tester) async {
      final cubit = await _cubit();
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            home: RepaintBoundary(
              key: sufraRootBoundaryKey,
              child: const Scaffold(
                body: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: LiquidThemeButton(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final center = tester.getCenter(find.byType(LiquidThemeButton));
      await tester.tap(find.byType(LiquidThemeButton));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      final clip = tester
          .widgetList<ClipPath>(find.byType(ClipPath))
          .where((w) => w.clipper != null)
          .last;
      final path = clip.clipper!.getClip(const Size(800, 600));
      expect(path.contains(center), isFalse);
      expect(path.contains(const Offset(1, 1)), isTrue);
      expect(calls.any((c) => c.method == 'HapticFeedback.vibrate'), isTrue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'overlapping captures accept latest only and auth cancel removes snapshot',
    (tester) async {
      final cubit = await _cubit();
      final captures = <Completer<ui.Image>>[];
      Future<ui.Image> image() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 20, 20),
          Paint()..color = Colors.red,
        );
        final picture = recorder.endRecording();
        final img = await picture.toImage(20, 20);
        picture.dispose();
        return img;
      }

      late ui.Image first, second;
      await tester.runAsync(() async {
        first = await image();
        second = await image();
      });
      await tester.pumpWidget(
        BlocProvider<ThemeCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: RepaintBoundary(
              key: sufraRootBoundaryKey,
              child: Scaffold(
                body: LiquidThemeButton(
                  capture: (_) {
                    final c = Completer<ui.Image>();
                    captures.add(c);
                    return c.future;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(LiquidThemeButton));
      await tester.pump();
      await tester.tap(find.byType(LiquidThemeButton));
      await tester.pump();
      expect(captures.length, 2);
      captures[1].complete(second);
      await tester.pump();
      expect(find.byType(RawImage), findsNothing);
      expect(cubit.isDark, isTrue);
      captures[0].complete(first);
      await tester.pump();
      expect(find.byType(RawImage), findsNothing);
      expect(cubit.isDark, isTrue);
      cancelThemeReveals();
      await tester.pump();
      expect(find.byType(RawImage), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('tap toggles the theme and the reveal cleans itself up', (
    tester,
  ) async {
    final cubit = await _cubit();
    await tester.pumpWidget(_app(cubit));
    expect(cubit.isDark, isTrue);

    await tester.tap(find.byType(LiquidThemeButton));
    await tester.pump();
    expect(cubit.isDark, isFalse);

    // Reveal finishes and disposes its overlay/controller/snapshot.
    await tester.pumpAndSettle();
    expect(cubit.isDark, isFalse);
  });

  testWidgets('rapid repeated toggles never stack overlays or throw', (
    tester,
  ) async {
    final cubit = await _cubit();
    await tester.pumpWidget(_app(cubit));

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byType(LiquidThemeButton));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pumpAndSettle();
    // 6 toggles from dark = back to dark.
    expect(cubit.isDark, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing the button mid-reveal releases everything', (
    tester,
  ) async {
    final cubit = await _cubit();
    await tester.pumpWidget(_app(cubit));
    await tester.tap(find.byType(LiquidThemeButton));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced-motion preference toggles instantly with no overlay', (
    tester,
  ) async {
    final cubit = await _cubit();
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(_app(cubit));
    await tester.tap(find.byType(LiquidThemeButton));
    await tester.pump();
    expect(cubit.isDark, isFalse);
    expect(find.byType(RawImage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long-press cycles the accent for the current brightness only', (
    tester,
  ) async {
    final cubit = await _cubit();
    await tester.pumpWidget(_app(cubit));

    await tester.longPress(find.byType(LiquidThemeButton));
    await tester.pump();
    // Dark mode: turquoise -> blue (next in the catalog); light untouched.
    expect(cubit.state.darkAccentId, 'blue');
    expect(cubit.state.lightAccentId, isEmpty);

    await tester.longPress(find.byType(LiquidThemeButton));
    await tester.pump();
    expect(cubit.state.darkAccentId, 'purple');
  });

  testWidgets('AccentPalettePicker selects and highlights the active accent', (
    tester,
  ) async {
    final cubit = await _cubit();
    await tester.pumpWidget(
      BlocProvider<ThemeCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: Center(child: AccentPalettePicker())),
        ),
      ),
    );
    // Default dark accent (turquoise) shows the check mark.
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(
      find.byType(InkWell).at(2),
    ); // copper? no: index 2 = purple
    await tester.pump();
    expect(cubit.state.darkAccentId, 'purple');
    expect(cubit.state.lightAccentId, isEmpty);
  });
}

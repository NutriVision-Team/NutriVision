import 'package:sufradepi/data/models/water_log_model.dart';
import 'package:sufradepi/core/utils/date_utils.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';
import 'package:sufradepi/features/home/presentation/cubit/home_cubit.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import 'package:sufradepi/features/home/presentation/widgets/home_loading_skeleton.dart';
import 'package:sufradepi/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/water_screen.dart';
import 'package:sufradepi/features/progress/presentation/cubit/water_cubit.dart';
import 'package:sufradepi/features/progress/presentation/widgets/water_glass.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:sufradepi/core/widgets/app_states.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../goldens/milestone1_screens_test.dart'
    show Harness, loadRealFonts, FakeUserRepository;
import '../discovery/discovery_features_test.dart'
    show activity, StaticActivityLoader, CaptureAchievements;
import '../features/progress/progress_test.dart' show FakeWaterWeightRepository;

class PendingUser extends FakeUserRepository {
  final gate = Completer<UserProfileModel?>();
  @override
  Future<UserProfileModel?> getCurrentUser() => gate.future;
}

class StoredWater extends FakeWaterWeightRepository {
  @override
  Future<void> addWaterLog(
    String uid,
    double amountMl,
    DateTime at, {
    String? operationId,
  }) async {
    await super.addWaterLog(uid, amountMl, at, operationId: operationId);
    water.add(
      WaterLogModel(
        waterId: operationId ?? 'local',
        amountMl: amountMl,
        consumedAt: at,
        dateKey: SufraDateUtils.toDateKey(at),
      ),
    );
  }
}

void main() {
  setUpAll(loadRealFonts);
  for (final light in [true, false]) {
    testWidgets('actual screen loading water badge interactions $light', (
      t,
    ) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await Harness.signedIn();
      final key = GlobalKey();
      final reduced = ValueNotifier(false);
      addTearDown(reduced.dispose);
      final haptics = <String>[];
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      Future<void> mount(Widget w) async {
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: h.wrap(
              ValueListenableBuilder(
                valueListenable: reduced,
                builder: (c, v, _) => MediaQuery(
                  data: MediaQuery.of(c).copyWith(disableAnimations: v),
                  child: w,
                ),
              ),
              themeMode: light ? ThemeMode.light : ThemeMode.dark,
            ),
          ),
        );
        await t.pump();
      }

      Future<List<int>> shot(String name) async {
        await t.runAsync(() async {
          for (final e in find.byType(Image).evaluate()) {
            await precacheImage((e.widget as Image).image, e);
          }
        });
        await t.pump();
        return (await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          im.dispose();
          final bytes = b!.buffer.asUint8List();
          await File(
            '/downloads/sufra-recovered/interactions1928_${light ? 'light' : 'dark'}_$name.png',
          ).writeAsBytes(bytes);
          return bytes;
        }))!;
      }

      Future<void> frames(String name, int n, {int ms = 100}) async {
        for (var i = 0; i < n; i++) {
          await t.pump(Duration(milliseconds: ms));
          await shot('$name${i.toString().padLeft(3, '0')}');
        }
      }

      final pending = PendingUser();
      final home = HomeCubit(
        userRepository: pending,
        nutritionRepository: h.nutritionRepository,
        clock: () => DateTime(2026, 11, 22),
      );
      await mount(
        BlocProvider<HomeCubit>.value(
          value: home,
          child: HomeScreen(clock: () => DateTime(2026, 11, 22)),
        ),
      );
      expect(find.byType(HomeLoadingSkeleton), findsOneWidget);
      expect(find.byType(SkeletonBlock), findsWidgets);
      final a = await shot('loading0');
      await t.pump(const Duration(milliseconds: 400));
      final b = await shot('loading1');
      expect(a, isNot(equals(b)));
      await frames('load', 10);
      reduced.value = true;
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      final still = await shot('reduced0');
      await t.pump(const Duration(seconds: 1));
      expect(await shot('reduced1'), still);
      reduced.value = false;
      await t.pump();
      pending.gate.complete(h.userRepository.user);
      await t.pump();
      await frames('loadedProgress', 14, ms: 100);
      expect(home.state, isA<HomeLoaded>());
      expect(find.byType(SkeletonBlock), findsNothing);
      await shot('homeLoaded');
      final water = StoredWater();
      await mount(WaterScreen(waterWeightRepository: water));
      await t.pump(const Duration(seconds: 2));
      expect(find.byType(WaterGlass), findsOneWidget);
      final wc = t.element(find.byType(WaterGlass)).read<WaterCubit>();
      final before = wc.state.totalMl;
      final l = AppLocalizations.of(t.element(find.byType(WaterGlass)));
      await t.tap(find.text(l.waterAdd250));
      await t.pump();
      await frames('water', 12, ms: 80);
      expect(haptics, isNotEmpty);
      expect(water.addWaterCalls, 1);
      expect(wc.state.totalMl, before + 250);
      await t.tap(find.text(l.waterAddCustom));
      await t.pump();
      final nav = find.byType(FloatingGlassNavBar);
      // A nav selection triggers the coded platform haptic, not proof of hardware vibration.
      await t.tap(find.descendant(of: nav, matching: find.text('الرئيسية')));
      await t.pump(const Duration(milliseconds: 400));
      expect(haptics, isNotEmpty);
      final state = ValueNotifier(false);
      addTearDown(state.dispose);
      final rules = CaptureAchievements();
      final locked = StaticActivityLoader(activity());
      final earned = StaticActivityLoader(activity(days: {'2026-11-22'}));
      await mount(
        ValueListenableBuilder(
          valueListenable: state,
          builder: (c, v, _) => AchievementsScreen(
            userId: 'owner',
            todayKey: '2026-11-22',
            catalog: rules,
            loader: v ? earned : locked,
          ),
        ),
      );
      await t.pump(const Duration(seconds: 2));
      final badge = find.text('أول وجبة');
      await t.scrollUntilVisible(
        badge,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(t.element(badge), alignment: .45);
      await t.pump(const Duration(seconds: 1));
      await shot('badgeLocked');
      expect(
        find.byKey(const ValueKey('first_meal_log:false')),
        findsOneWidget,
      );
      state.value = true;
      await t.pump();
      await t.pump();
      await frames('badge', 12, ms: 70);
      await shot('badgeEarned');
      expect(find.byKey(const ValueKey('first_meal_log:true')), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsWidgets);
      reduced.value = true;
      await t.pump();
      await t.pump(const Duration(seconds: 2));
      expect(t.binding.transientCallbackCount, 0);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await home.close();
      await h.dispose();
    });
  }
}

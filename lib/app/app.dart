import '../features/favorites/data/favorites_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/health_coach/coach_access_host.dart';
import '../features/gamification/data/local_account_day_ledger.dart';
import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import '../services/fcm_service.dart';
import '../services/push_device_lifecycle.dart';
import 'dart:async';
import '../services/local_notifications_host.dart';
import '../features/reminders/domain/reminder_plan.dart';
import '../features/reminders/domain/reminder_models.dart';
import '../features/reminders/data/reminder_runtime.dart';
import '../features/reminders/data/reminder_guard.dart';
import '../features/reminders/presentation/screens/reminders_host.dart';
import '../data/repositories/food_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_preferences.dart';
import '../core/theme/app_accents.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_cubit.dart';
import '../core/widgets/theme_switcher.dart';
import '../data/repositories/nutrition_repository.dart';
import '../data/repositories/user_repository.dart';
import '../features/auth/presentation/cubit/session_cubit.dart';
import '../features/home/presentation/cubit/home_cubit.dart';
import '../features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'responsive_frame.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import 'back_guard.dart';
import 'router/app_router.dart';

/// Root application widget: wires repositories, session state, theme,
/// locale and the router.
class SufraApp extends StatefulWidget {
  const SufraApp({
    super.key,
    required this.preferences,
    this.reminders,
    this.rewardCandidate,
    required this.userRepository,
    required this.nutritionRepository,
    required this.foodRepository,
  });

  final LocalAccountDayLedger? rewardCandidate;
  final ReminderRuntime? reminders;
  final AppPreferences preferences;
  final UserRepository userRepository;
  final NutritionRepository nutritionRepository;
  final FoodRepository foodRepository;

  @override
  State<SufraApp> createState() => _SufraAppState();
}

class _SufraAppState extends State<SufraApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _signingOut = false;
  StreamSubscription<String?>? _reminderTaps;
  StreamSubscription<String>? _pushRoutes;
  String? _pendingReminderTap;
  late final SessionCubit _sessionCubit;
  late final ThemeCubit _themeCubit;
  ThemeMode? _renderedThemeMode;
  late final LocaleCubit _localeCubit;
  late final ProfileSetupCubit _setupCubit;
  late final HomeCubit _homeCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _pushRoutes = FirebaseMessagingService.instance.routes.listen(
      _openReminder,
    );
    _sessionCubit = SessionCubit(
      authService: AuthService.instance,
      userRepository: widget.userRepository,
      afterSignOut: () {
        _signingOut = false;
      },
      beforeSignOut: () async {
        _signingOut = true;
        try {
          await FirebaseMessagingService.instance.unlinkBeforeSignOut();
        } catch (_) {
          _showCleanupFailure();
          rethrow;
        }
        widget.reminders?.scheduler.ownerChanged();
        cancelThemeReveals();
        final runtime = widget.reminders;
        if (runtime != null) {
          final result = await ReminderGuard(
            store: runtime.store,
            scheduler: runtime.scheduler,
          ).cancelEverything();
          if (result == CleanupResult.failed) _showCleanupFailure();
        }
      },
    );
    widget.reminders?.scheduler.currentUid = () {
      if (_signingOut) return null;
      final s = _sessionCubit.state;
      return s is SessionAuthenticated ? s.user.uid : null;
    };
    _themeCubit = ThemeCubit(widget.preferences);
    _localeCubit = LocaleCubit(widget.preferences);
    _setupCubit = ProfileSetupCubit(
      currentUid: () {
        final state = _sessionCubit.state;
        return state is SessionAuthenticated ? state.user.uid : null;
      },
      nutritionRepository: widget.nutritionRepository,
      userRepository: widget.userRepository,
    );
    _homeCubit = HomeCubit(
      favoritesBackend: FirestoreFavoritesBackend(
        FirebaseFirestore.instance,
        assertActive: (uid) {
          final s = _sessionCubit.state;
          if (_signingOut || s is! SessionAuthenticated || s.user.uid != uid) {
            throw StateError('Inactive account');
          }
        },
      ),
      userRepository: widget.userRepository,
      nutritionRepository: widget.nutritionRepository,
    );
    _router = createRouter(
      sessionCubit: _sessionCubit,
      rewardCandidate: widget.rewardCandidate,
      preferences: widget.preferences,
    );
    _pendingReminderTap = FirebaseMessagingService.instance.takePendingRoute();
    if (widget.reminders != null) {
      _pendingReminderTap ??= LocalNotificationsHost.instance
          .takeInitialPayload();
      _reminderTaps = LocalNotificationsHost.instance.taps.listen(
        _openReminder,
      );
    }
  }

  void _openReminder(String? payload) {
    if (payload != null && payload.startsWith('sufra:push:')) {
      final parts = payload.split(':');
      final state = _sessionCubit.state;
      if (state is SessionUnknown) {
        _pendingReminderTap = payload;
        return;
      }
      if (parts.length == 4 && state is SessionAuthenticated) {
        final route = ownedPushRoute({
          'uid': parts[2],
          'type': parts[3],
        }, state.user.uid);
        if (route != null) {
          if (state.isReady) {
            _router.push(route);
          } else {
            _pendingReminderTap = payload;
          }
        }
      }
      return;
    }
    if (ReminderPayload.kindOf(payload) == null) return;
    final state = _sessionCubit.state;
    if (state is SessionUnauthenticated) {
      _pendingReminderTap = null;
      return;
    }
    if (state is! SessionAuthenticated || !state.isReady) {
      _pendingReminderTap = payload;
      return;
    }
    final target = switch (ReminderPayload.kindOf(payload)) {
      ReminderKind.water => '/water',
      ReminderKind.weight => '/weight',
      ReminderKind.meal => '/diary',
      _ => null,
    };
    if (target != null) _router.push(target);
  }

  void _showCleanupFailure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = _messengerKey.currentContext;
      if (c != null) {
        _messengerKey.currentState?.showSnackBar(
          SufraSnackBar(
            content: Text(AppLocalizations.of(c).reminderCleanupFailed),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _pushRoutes?.cancel();
    _reminderTaps?.cancel();
    _sessionCubit.close();
    _themeCubit.close();
    _localeCubit.close();
    _setupCubit.close();
    _homeCubit.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        if (widget.reminders != null)
          RepositoryProvider<ReminderRuntime>.value(value: widget.reminders!),
        RepositoryProvider<FoodRepository>.value(value: widget.foodRepository),
        RepositoryProvider<UserRepository>.value(value: widget.userRepository),
        RepositoryProvider<NutritionRepository>.value(
          value: widget.nutritionRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: _sessionCubit),
          BlocProvider<ThemeCubit>.value(value: _themeCubit),
          BlocProvider<LocaleCubit>.value(value: _localeCubit),
          BlocProvider<ProfileSetupCubit>.value(value: _setupCubit),
          BlocProvider<HomeCubit>.value(value: _homeCubit),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            final modeChanged = _renderedThemeMode != themeState.mode;
            _renderedThemeMode = themeState.mode;
            final lightAccent = SufraAccents.resolve(
              themeState.lightAccentId,
              brightness: Brightness.light,
            );
            final darkAccent = SufraAccents.resolve(
              themeState.darkAccentId,
              brightness: Brightness.dark,
            );
            return BlocBuilder<LocaleCubit, Locale>(
              builder: (context, locale) {
                return MaterialApp.router(
                  scaffoldMessengerKey: _messengerKey,
                  title: 'Sufra — سفرة',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light(accent: lightAccent.color),
                  darkTheme: AppTheme.dark(accent: darkAccent.color),
                  themeMode: themeState.mode,
                  themeAnimationDuration:
                      modeChanged ||
                          WidgetsBinding
                              .instance
                              .platformDispatcher
                              .accessibilityFeatures
                              .disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  locale: locale,
                  // Snapshot boundary for the liquid theme reveal.
                  builder: (context, child) =>
                      BlocConsumer<SessionCubit, SessionState>(
                        listener: (_, state) {
                          final pending = _pendingReminderTap;
                          if (pending != null && state is! SessionUnknown) {
                            _pendingReminderTap = null;
                            _openReminder(pending);
                          }
                          _setupCubit.ownerChanged(
                            state is SessionAuthenticated
                                ? state.user.uid
                                : null,
                          );
                          cancelThemeReveals();
                          widget.reminders?.scheduler.ownerChanged();
                          if (state is SessionUnauthenticated) {
                            _signingOut = false;
                          }
                        },
                        builder: (context, state) {
                          Widget content = child ?? const SizedBox.shrink();
                          // Tablets use the width; very wide screens centre
                          // the content over the full-bleed background.
                          content = ResponsiveFrame(child: content);
                          final runtime = widget.reminders;
                          if (runtime != null) {
                            content = RemindersHost(
                              uid: state is SessionAuthenticated
                                  ? state.user.uid
                                  : null,
                              authResolved: state is! SessionUnknown,
                              store: runtime.store,
                              scheduler: runtime.scheduler,
                              onCleanupFailed: _showCleanupFailure,
                              child: content,
                            );
                          }
                          return RepaintBoundary(
                            key: sufraRootBoundaryKey,
                            child: CoachAccessHost(
                              router: _router,
                              enabled:
                                  state is SessionAuthenticated &&
                                  state.isReady,
                              child: BackGuard(
                                router: _router,
                                stepBack: () {
                                  final setup = context
                                      .read<ProfileSetupCubit>();
                                  if (setup.state.step == 0) return false;
                                  setup.back();
                                  return true;
                                },
                                child: content,
                              ),
                            ),
                          );
                        },
                      ),
                  supportedLocales: const [Locale('ar'), Locale('en')],
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  routerConfig: _router,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

import '../../../../core/widgets/sufra_licenses_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/achievement_activity.dart';
import '../../data/persistence/achievement_progress_store.dart';
import '../../../../data/models/achievement_model.dart';
import '../../../recipes/presentation/widgets/discovery_widgets.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({
    super.key,
    required this.userId,
    required this.todayKey,
    required this.loader,
    this.catalog,
    this.progressStore,
  });
  static const routePath = '/achievements';
  final String userId;

  /// Today's date key in the user's diary timezone, not the device UTC date.
  final String todayKey;
  final AchievementActivityLoader loader;
  final AchievementCatalog? catalog;
  final AchievementProgressStore? progressStore;
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late Future<
    (AchievementActivity, List<AchievementRule>, AchievementSyncResult?)
  >
  _load;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _load = _fetch(++_generation);
  }

  Future<(AchievementActivity, List<AchievementRule>, AchievementSyncResult?)>
  _fetch(int generation) async {
    final userId = widget.userId;
    final todayKey = widget.todayKey;
    final progressStore = widget.progressStore;
    if (userId.trim().isEmpty) throw ArgumentError.value(userId, 'userId');
    final loaded = await Future.wait<Object>([
      widget.loader.load(userId),
      (widget.catalog ?? AchievementCatalog()).load(),
    ]);
    final activity = loaded[0] as AchievementActivity;
    final rules = loaded[1] as List<AchievementRule>;
    if (activity.userId != userId) {
      throw StateError('Activity account mismatch');
    }
    if (!mounted || generation != _generation || widget.userId != userId) {
      throw StateError('Stale achievement load');
    }
    if (AchievementActivity.day(todayKey) == null) {
      throw const FormatException('Invalid today key');
    }
    final sync = await progressStore?.synchronize(activity, rules);
    return (activity, rules, sync);
  }

  @override
  void didUpdateWidget(covariant AchievementsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.loader != widget.loader ||
        oldWidget.catalog != widget.catalog ||
        oldWidget.todayKey != widget.todayKey ||
        oldWidget.progressStore != widget.progressStore) {
      _reload();
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DiscoveryScaffold(
    child:
        FutureBuilder<
          (AchievementActivity, List<AchievementRule>, AchievementSyncResult?)
        >(
          future: _load,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: DiscoveryError(onRetry: () => setState(_reload)),
              );
            }
            final data = snapshot.data;
            if (data == null || data.$1.userId != widget.userId) {
              return const SizedBox.shrink();
            }
            final activity = data.$1;
            final persisted = {
              for (final record in data.$3?.records ?? <AchievementModel>[])
                record.achievementId: record,
            };
            final streak = activity.currentStreak(widget.todayKey);
            final today = AchievementActivity.day(widget.todayKey)!;
            final weekStart = today.subtract(
              Duration(days: (today.weekday - DateTime.saturday + 7) % 7),
            );
            final week = List.generate(
              7,
              (index) => weekStart.add(Duration(days: index)),
            );
            return RefreshIndicator(
              onRefresh: () async {
                setState(_reload);
                try {
                  await _load;
                } catch (_) {
                  /* The FutureBuilder shows the retry state. */
                }
              },
              child: DiscoveryList(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SufraLicensesScreen(),
                        ),
                      ),
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'التراخيص'
                            : 'Licenses',
                      ),
                    ),
                  ),
                  GlassCard(
                    borderColor: const Color(0x80FFB74D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    gradient: const RadialGradient(
                      center: Alignment(0, -.6),
                      radius: 1.1,
                      colors: [
                        Color(0x4DFB8C00),
                        Color(0x21FFFFFF),
                        Color(0x0AFFFFFF),
                      ],
                    ),
                    child: Column(
                      children: [
                        LanternArt(lit: streak > 0),
                        Text(
                          discoveryNumber(context, streak),
                          style: TextStyle(
                            fontFamily: Theme.of(
                              context,
                            ).textTheme.titleLarge?.fontFamily,
                            fontSize: 52,
                            height: 1.1,
                            shadows: [
                              Shadow(color: Color(0xB3FB8C00), blurRadius: 28),
                            ],
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context).discoveryMsg070,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (final date in week)
                              Expanded(
                                child: Column(
                                  children: [
                                    Semantics(
                                      label:
                                          '${AchievementActivity.keyOf(date)}: ${activity.loggedDays.contains(AchievementActivity.keyOf(date)) ? AppLocalizations.of(context).discoveryMsg071 : AppLocalizations.of(context).discoveryMsg072}',
                                      child: CustomPaint(
                                        size: const Size(26, 32),
                                        painter: _WeekLanternPainter(
                                          light:
                                              Theme.of(context).brightness ==
                                              Brightness.light,
                                          lit: activity.loggedDays.contains(
                                            AchievementActivity.keyOf(date),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _weekday(context, date.weekday),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GlassCard(
                    borderColor: const Color(0x80FFB74D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text(
                              AppLocalizations.of(context).discoveryMsg073,
                              style: const TextStyle(fontSize: 13),
                            ),
                            DiscoveryProgressPair(
                              current: streak,
                              target: 14,
                              unit: AppLocalizations.of(
                                context,
                              ).discoveryMsg074,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (streak / 14).clamp(0.0, 1.0),
                          minHeight: 8,
                          color: AppColors.copper,
                          backgroundColor: Colors.white12,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ],
                    ),
                  ),
                  DiscoveryTitle(
                    AppLocalizations.of(context).discoveryMsg075,
                    size: 18,
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          MediaQuery.textScalerOf(context).scale(12) > 17
                          ? 2
                          : 3;
                      final width =
                          (constraints.maxWidth - 8 * (columns - 1)) / columns;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          for (final (index, rule) in data.$2.indexed)
                            SizedBox(
                              width: width,
                              child: DiscoveryEntrance(
                                index: index,
                                child: _AchievementBadge(
                                  rule: rule,
                                  index: index,
                                  progress: activity.progress(rule),
                                  persisted: persisted[rule.id],
                                  animateUnlock:
                                      data.$3?.newUnlockIds.contains(rule.id) ??
                                      false,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  DiscoveryNotice(AppLocalizations.of(context).discoveryMsg076),
                ],
              ),
            );
          },
        ),
  );
  String _weekday(BuildContext context, int weekday) => [
    AppLocalizations.of(context).discoveryWeekday1,
    AppLocalizations.of(context).discoveryWeekday2,
    AppLocalizations.of(context).discoveryWeekday3,
    AppLocalizations.of(context).discoveryWeekday4,
    AppLocalizations.of(context).discoveryWeekday5,
    AppLocalizations.of(context).discoveryWeekday6,
    AppLocalizations.of(context).discoveryWeekday7,
  ][weekday - 1];
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.rule,
    required this.index,
    required this.progress,
    this.persisted,
    this.animateUnlock = false,
  });
  final AchievementRule rule;
  final int index;
  final int? progress;
  final AchievementModel? persisted;
  final bool animateUnlock;
  @override
  Widget build(BuildContext context) {
    final earned =
        persisted?.isUnlocked ?? (progress != null && progress! >= rule.target);
    final displayedProgress = persisted?.progress.toInt() ?? progress;
    final fraction = displayedProgress == null
        ? 0.0
        : (displayedProgress / rule.target).clamp(0.0, 1.0);
    final name = discoveryArabic(context) ? rule.titleAr : rule.titleEn;
    return Semantics(
      button: true,
      label:
          '$name: ${earned
              ? AppLocalizations.of(context).discoveryMsg077
              : displayedProgress == null
              ? AppLocalizations.of(context).discoveryMsg078
              : '${AppLocalizations.of(context).discoveryMsg050}: ${discoveryNumber(context, displayedProgress)}\n${AppLocalizations.of(context).discoveryMsg051}: ${discoveryNumber(context, rule.target)}'}',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => discoveryExplain(
          context,
          name,
          '${discoveryArabic(context) ? rule.descriptionAr : rule.descriptionEn}\n\n${displayedProgress == null ? AppLocalizations.of(context).discoveryMsg079 : '${AppLocalizations.of(context).discoveryMsg050}: ${discoveryNumber(context, displayedProgress)}\n${AppLocalizations.of(context).discoveryMsg051}: ${discoveryNumber(context, rule.target)}'}'
          '${persisted?.isUnlocked == true ? '\n\n${persisted?.unlockedAt == null ? AppLocalizations.of(context).discoveryMsg080 : '${AppLocalizations.of(context).discoveryMsg081}: ${_recordedTime(context, persisted!.unlockedAt!)}'}' : ''}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 450),
                      switchInCurve: Curves.easeOutCubic,
                      child: DiscoveryUnlockReveal(
                        key: ValueKey('${rule.id}:$earned'),
                        animate: animateUnlock,
                        child: DiscoveryFloat(
                          child: DiscoverySprite(
                            asset: 'assets/images/art/spC.webp',
                            column: index % 3,
                            row: 1 + (index ~/ 3) % 2,
                            cells: 3,
                            size: 78,
                            muted: !earned,
                          ),
                        ),
                      ),
                    ),
                    if (!earned)
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: fraction,
                          strokeWidth: 3,
                          color: AppColors.cyanLight,
                          backgroundColor: Colors.white.withValues(alpha: .18),
                        ),
                      ),
                    if (displayedProgress == null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon(
                          Icons.help_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (displayedProgress == null)
                Text(
                  AppLocalizations.of(context).discoveryMsg078,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                )
              else
                DiscoveryProgressPair(
                  current: displayedProgress,
                  target: rule.target,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _recordedTime(BuildContext context, DateTime time) {
  final lang = Localizations.localeOf(context).languageCode;
  return '${DateFormat.yMMMMd(lang).add_jm().format(time.toUtc())} (UTC)';
}

class LanternArt extends StatefulWidget {
  const LanternArt({super.key, required this.lit});
  final bool lit;
  @override
  State<LanternArt> createState() => _LanternArtState();
}

class _LanternArtState extends State<LanternArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
      _motion.value = 0;
    } else {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).discoveryMsg082,
    child: AnimatedBuilder(
      animation: _motion,
      builder: (_, _) => Transform.rotate(
        alignment: Alignment.topCenter,
        angle: .04 * math.sin(_motion.value * 2 * math.pi),
        child: CustomPaint(
          size: const Size(120, 170),
          painter: _LanternPainter(
            lit: widget.lit,
            glow: .75 + .25 * math.sin(_motion.value * 4 * math.pi),
          ),
        ),
      ),
    ),
  );
}

class _LanternPainter extends CustomPainter {
  const _LanternPainter({required this.lit, required this.glow});
  final bool lit;
  final double glow;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 150);
    final line = Paint()
      ..color = AppColors.orangeLight.withValues(alpha: lit ? 1 : .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    if (lit) {
      canvas.drawCircle(
        const Offset(50, 70),
        46,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF3E0).withValues(alpha: .45 * glow),
              AppColors.copper.withValues(alpha: 0),
            ],
          ).createShader(const Rect.fromLTWH(4, 24, 92, 92)),
      );
    }
    canvas.drawLine(const Offset(50, 4), const Offset(50, 18), line);
    canvas.drawCircle(const Offset(50, 6), 4, line..strokeWidth = 2);
    final roof = Path()
      ..moveTo(30, 36)
      ..quadraticBezierTo(50, 14, 70, 36)
      ..close();
    canvas.drawPath(
      roof,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFDE68A), Color(0xFFC2410C)],
        ).createShader(const Rect.fromLTWH(30, 20, 40, 20)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(28, 34, 44, 7),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.orangeLight.withValues(alpha: lit ? 1 : .45),
    );
    final body = Path()
      ..moveTo(32, 41)
      ..lineTo(68, 41)
      ..lineTo(76, 63)
      ..lineTo(68, 99)
      ..lineTo(32, 99)
      ..lineTo(24, 63)
      ..close();
    canvas.drawPath(
      body,
      Paint()..color = AppColors.orangeLight.withValues(alpha: .16),
    );
    canvas.drawPath(body, line..strokeWidth = 2.5);
    line
      ..strokeWidth = 1.5
      ..color = AppColors.orangeLight.withValues(alpha: .55);
    canvas.drawLine(const Offset(41, 41), const Offset(37, 99), line);
    canvas.drawLine(const Offset(50, 41), const Offset(50, 99), line);
    canvas.drawLine(const Offset(59, 41), const Offset(63, 99), line);
    if (lit) {
      canvas.drawPath(
        Path()
          ..moveTo(50, 56)
          ..quadraticBezierTo(60, 69, 50, 82)
          ..quadraticBezierTo(40, 69, 50, 56),
        Paint()..color = const Color(0xFFFFF3E0).withValues(alpha: glow),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 99, 40, 7),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.orangeLight.withValues(alpha: lit ? 1 : .45),
    );
    line
      ..strokeWidth = 2
      ..color = AppColors.orangeLight.withValues(alpha: lit ? 1 : .45);
    canvas.drawLine(const Offset(50, 106), const Offset(50, 122), line);
    canvas.drawLine(const Offset(44, 106), const Offset(41, 120), line);
    canvas.drawLine(const Offset(56, 106), const Offset(59, 120), line);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LanternPainter old) =>
      lit != old.lit || glow != old.glow;
}

class _WeekLanternPainter extends CustomPainter {
  const _WeekLanternPainter({required this.lit, required this.light});
  final bool lit, light;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 46, size.height / 60);
    final path = Path()
      ..moveTo(14, 14)
      ..lineTo(32, 14)
      ..lineTo(38, 22)
      ..lineTo(38, 44)
      ..lineTo(30, 52)
      ..lineTo(16, 52)
      ..lineTo(8, 44)
      ..lineTo(8, 22)
      ..close();
    if (lit) {
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.copper.withValues(alpha: .5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lit
            ? AppColors.orangeLight
            : light
            ? const Color(0x33465062)
            : Colors.white12,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lit
            ? AppColors.copper
            : light
            ? const Color(0xFF667085)
            : Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WeekLanternPainter old) =>
      lit != old.lit || light != old.light;
}

class DiscoveryUnlockReveal extends StatelessWidget {
  const DiscoveryUnlockReveal({
    super.key,
    required this.animate,
    required this.child,
  });
  final bool animate;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (!animate || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .75, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (_, value, child) => Transform.scale(scale: value, child: child),
      child: child,
    );
  }
}

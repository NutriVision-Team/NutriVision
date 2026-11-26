import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/glass_shortcut.dart';
import '../../../../core/widgets/viewport_reveal.dart';
import '../../../gamification/presentation/widgets/sufra_badge.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../gamification/data/progression_repository.dart';

class HomeProgressCard extends StatefulWidget {
  const HomeProgressCard({
    super.key,
    required this.uid,
    required this.repository,
    this.todayKey,
  });
  final String uid;
  final String? todayKey;
  final ProgressionRepository repository;
  @override
  State<HomeProgressCard> createState() => _HomeProgressCardState();
}

class _HomeProgressCardState extends State<HomeProgressCard>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _subscription;
  Timer? _debounce;
  late Future<ProgressionSnapshot> _future;
  void _load() {
    _future = widget.repository.load(
      widget.uid,
      widget.todayKey ?? SufraDateUtils.toDateKey(DateTime.now()),
    );
  }

  void _start() {
    _subscription?.cancel();
    final repository = widget.repository;
    if (repository is LiveProgressionRepository) {
      _subscription = (repository as LiveProgressionRepository)
          .watchChanges(widget.uid)
          .listen(
            (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 120), () {
                if (mounted) setState(_load);
              });
            },
            onError: (Object e, StackTrace s) {
              if (mounted) setState(_load);
            },
          );
    }
    _load();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(_load);
  }

  @override
  void didUpdateWidget(covariant HomeProgressCard old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid ||
        old.repository != widget.repository ||
        old.todayKey != widget.todayKey) {
      _debounce?.cancel();
      _start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _openJourney() async {
    await context.push('/stats');
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return ViewportReveal(
      builder: (context, visible) => GlassCard(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart.resolve(
            Directionality.of(context),
          ),
          end: AlignmentDirectional.bottomEnd.resolve(
            Directionality.of(context),
          ),
          colors: dark
              ? const [Color(0xC0183D54), Color(0xA02C254A)]
              : const [Color(0xF0FFFFFF), Color(0xE0E4F6F7), Color(0xEBF1EBFF)],
        ),
        child: FutureBuilder<ProgressionSnapshot>(
          future: _future,
          builder: (context, s) {
            final data = s.connectionState == ConnectionState.done
                ? s.data
                : null;
            final p = data?.profile;
            final owner = p != null && p.uid == widget.uid;
            final badge = owner
                ? data!.config.badges
                      .where((b) => p.badges.contains(b.id))
                      .firstOrNull
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      color: AppColors.orangeDeep,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        ar
                            ? 'رحلتك وإنجازاتك'
                            : 'Your journey and achievements',
                        style: context.readableDisplayStyle(size: 19),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (s.hasError)
                  Text(
                    ar
                        ? 'مش قادرين نحسب تقدمك دلوقتي. حاول تاني.'
                        : 'Your progress could not be loaded. Try again.',
                  )
                else if (!owner)
                  const LinearProgressIndicator()
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ExcludeSemantics(
                        child: SufraBadge(
                          id: badge?.id ?? 'journey',
                          unlocked: badge != null,
                          size: 70,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ar ? p.level.ar : p.level.en,
                              style: context.readableDisplayStyle(size: 24),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 12,
                              runSpacing: 5,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${p.xp} XP',
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: dark
                                        ? AppColors.cyanLight
                                        : AppColors.primaryBlue,
                                  ),
                                ),
                                Text(
                                  ar
                                      ? 'الأوسمة: ${p.badges.length}'
                                      : 'Badges: ${p.badges.length}',
                                  style: context.mutedStyle(size: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: visible ? p.levelProgress : 0),
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 950),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 9,
                        color: dark
                            ? AppColors.turquoise
                            : AppColors.primaryBlue,
                        backgroundColor:
                            (dark ? Colors.white : AppColors.primaryBlue)
                                .withValues(alpha: .12),
                        semanticsLabel: ar
                            ? 'التقدم للمستوى الجاي'
                            : 'Progress to next level',
                        semanticsValue: '${(p.levelProgress * 100).round()}%',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (p.nextLevel != null)
                    Text(
                      ar
                          ? 'داخل المستوى: ${p.xp - p.level.xp} من ${p.nextLevel!.xp - p.level.xp} نقطة'
                          : 'Within level: ${p.xp - p.level.xp} of ${p.nextLevel!.xp - p.level.xp} XP · ${p.level.xp} to ${p.nextLevel!.xp}',
                      style: context.mutedStyle(size: 12),
                    ),
                  if (p.nextLevel != null && ar)
                    Text(
                      'بداية المستوى ${p.level.xp} نقطة، واللي بعده ${p.nextLevel!.xp}',
                      style: context.mutedStyle(size: 12),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    p.nextLevel == null
                        ? (ar
                              ? 'وصلت لأعلى مستوى في القواعد الحالية'
                              : 'Highest level in the current rules')
                        : (ar
                              ? 'باقي ${p.remainingXp} نقطة للمستوى الجاي'
                              : '${p.remainingXp} XP to the next level'),
                    style: context.mutedStyle(size: 13),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ar
                        ? (data!.authoritative
                              ? 'السجل ده متحقق منه في الاختبار المحلي بس. قواعد النقاط والأوسمة لسه مسودة.'
                              : 'التقدم محسوب من سجلك، مش مكافآت سحابية موثّقة.')
                        : (data!.authoritative
                              ? 'Verified in the local test ledger only. XP rules and badges are still a draft.'
                              : 'Calculated from your records, not verified cloud rewards.'),
                    style: context.mutedStyle(size: 11),
                  ),
                ],
                const SizedBox(height: 14),
                if (s.hasError)
                  GlassShortcut(
                    label: ar ? 'حاول تاني' : 'Try again',
                    icon: Icons.refresh_rounded,
                    glossyInteraction: true,
                    onPressed: () => setState(_load),
                  )
                else
                  GlassShortcut(
                    label: ar ? 'افتح رحلتك' : 'Explore your journey',
                    icon: Icons.arrow_forward_rounded,
                    glossyInteraction: true,
                    onPressed: _openJourney,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

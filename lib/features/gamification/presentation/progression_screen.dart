import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import '../data/bounded_firestore_progression.dart';
import 'dart:async';
import 'widgets/sufra_badge.dart';
import 'widgets/badge_celebration.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/nebula_background.dart';
import '../../progress/presentation/widgets/progress_nav.dart';
import '../data/progression_repository.dart';

/// Habit-first My Progress. Health measurements remain available separately.
class ProgressionScreen extends StatefulWidget {
  const ProgressionScreen({
    super.key,
    required this.uid,
    required this.todayKey,
    required this.repository,
    this.currentDayKey,
  });
  final String uid, todayKey;
  final String Function()? currentDayKey;
  final ProgressionRepository repository;
  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _changes;
  Timer? _debounce;
  void _subscribe() {
    _changes?.cancel();
    final repository = widget.repository;
    if (repository is LiveProgressionRepository) {
      _changes = (repository as LiveProgressionRepository)
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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(_load);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _changes?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  late Future<ProgressionSnapshot> _future;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _subscribe();
  }

  void _load() {
    _future = widget.repository.load(
      widget.uid,
      widget.currentDayKey?.call() ?? widget.todayKey,
    );
  }

  @override
  void didUpdateWidget(covariant ProgressionScreen old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid ||
        old.todayKey != widget.todayKey ||
        old.repository != widget.repository) {
      _debounce?.cancel();
      _load();
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String t(String a, String e) => ar ? a : e;
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: FutureBuilder<ProgressionSnapshot>(
            future: _future,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (s.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.error is ProgressionHistoryTooLarge
                              ? t(
                                  'سجلك كبير ومحتاج تجميع آمن قبل حساب التقدم. سجلات صحتك لسه متاحة.',
                                  'Your history needs safe aggregation before progress can be calculated. Your health records are still available.',
                                )
                              : t(
                                  'مش قادرين نحمّل تقدمك دلوقتي',
                                  'Your progress could not be loaded',
                                ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/nutrition-stats'),
                          child: Text(
                            t('افتح سجلات التغذية', 'Open nutrition records'),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(_load);
                            _subscribe();
                          },
                          child: Text(t('حاول تاني', 'Try again')),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final data = s.data;
              if (data == null || data.profile.uid != widget.uid) {
                return const SizedBox.shrink();
              }
              return _JourneyContent(
                snapshot: data,
                onRefresh: () async {
                  if (!mounted) return;
                  setState(_load);
                  try {
                    await _future;
                  } catch (_) {}
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const ProgressNavBar(currentIndex: 2),
    );
  }
}

class _JourneyContent extends StatelessWidget {
  const _JourneyContent({required this.snapshot, required this.onRefresh});
  final ProgressionSnapshot snapshot;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String t(String a, String e) => ar ? a : e;
    final p = snapshot.profile, c = snapshot.config;
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    const accent = Color(0xff09b6c8);
    Widget title(String a, String e) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        t(a, e),
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink),
      ),
    );
    final today = snapshot.events
        .where((e) => e.dayKey == p.todayKey)
        .map((e) => e.kind)
        .toSet();
    final nextBadge = c.badges
        .where(
          (b) =>
              !p.badges.contains(b.id) &&
              ['meal', 'activeDay', 'plan'].contains(b.kind),
        )
        .firstOrNull;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(
            t('تقدمي', 'My progress'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t('رحلتك، على مهلك', 'Your journey, at your pace'),
            style: TextStyle(fontSize: 15, color: muted),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: accent,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('مستواك الحالي', 'Current level'),
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                          Text(
                            ar ? p.level.ar : p.level.en,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: ink,
                            ),
                          ),
                          Text(
                            '${p.xp} XP',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: p.levelProgress),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 600),
                  builder: (context, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 9,
                      color: accent,
                      backgroundColor: accent.withValues(alpha: .14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  p.nextLevel == null
                      ? t(
                          'وصلت لأعلى مستوى في الرحلة الحالية',
                          'You reached this journey’s top level',
                        )
                      : t(
                          'باقي ${p.remainingXp} نقطة لمستوى ${p.nextLevel!.ar}',
                          '${p.remainingXp} XP to ${p.nextLevel!.en}',
                        ),
                  style: TextStyle(fontSize: 14, color: ink),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      icon: Icons.verified_outlined,
                      label: t(
                        '${p.badges.length} إنجازات',
                        '${p.badges.length} achievements',
                      ),
                    ),
                    _Pill(
                      icon: Icons.calendar_month_outlined,
                      label: t(
                        '${snapshot.activeDayCount ?? p.activeDays.length} أيام نشاط',
                        '${snapshot.activeDayCount ?? p.activeDays.length} active days',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t(
                      snapshot.authoritative
                          ? 'سجل معتمد بقواعد Firebase في الاختبار المحلي فقط. السياسة والأوسمة مسودة. قيد المزامنة: ${snapshot.pendingCount}.'
                          : 'دي قراءة من سجلاتك الحالية، مش مكافآت معتمدة من الخادم. مزامنة نقاط موثّقة لسه مش مفعّلة.',
                      snapshot.authoritative
                          ? 'Firebase Rules-verified local test ledger. Draft policy/catalog. Pending: ${snapshot.pendingCount}.'
                          : 'Calculated from your current records, not server-verified rewards. Verified XP sync is not enabled yet.',
                    ),
                    style: TextStyle(fontSize: 12, height: 1.5, color: muted),
                  ),
                ),
              ],
            ),
          ),
          title('خطوتك الجاية', 'Your next step'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextBadge == null
                      ? t('كمّل عاداتك بهدوء', 'Keep building your habits')
                      : ar
                      ? nextBadge.ar
                      : nextBadge.en,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'كل خطوة صغيرة ليها قيمة. مفيش نقاط لنزول الوزن أو تقليل أكلك.',
                    'Small steps count. No points for weight loss or eating less.',
                  ),
                  style: TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await context.push(
                      nextBadge?.kind == 'plan' ? '/planner' : '/log',
                    );
                    await onRefresh();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    nextBadge?.kind == 'plan'
                        ? t('خطط لوجباتك', 'Plan your meals')
                        : t('سجّل وجبة', 'Log a meal'),
                  ),
                ),
              ],
            ),
          ),
          if (!snapshot.authoritative) ...[
            title('مهام اليوم', 'Today’s missions'),
            Text(
              t(
                'مكافأة كل نشاط مرة واحدة في اليوم، مش بعدد الوجبات.',
                'Each activity rewards once per day, not per meal.',
              ),
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            _Mission(
              label: t('سجّل وجبة النهاردة', 'Log a meal today'),
              xp: c.dailyXp['meal'] ?? 0,
              done: today.contains('meal'),
              icon: Icons.restaurant_rounded,
              onTap: () async {
                await context.push('/log');
                await onRefresh();
              },
            ),
            const SizedBox(height: 10),
            _Mission(
              label: t('احفظ خطة وجبات', 'Save a meal plan'),
              xp: c.dailyXp['plan'] ?? 0,
              done: today.contains('plan'),
              icon: Icons.event_note_rounded,
              onTap: () async {
                await context.push('/planner');
                await onRefresh();
              },
            ),
            title('الاستمرارية من غير ضغط', 'Consistency without pressure'),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _Pill(
                        icon: Icons.local_fire_department_outlined,
                        label: t(
                          '${p.currentStreak} أيام متتالية',
                          '${p.currentStreak} day streak',
                        ),
                      ),
                      _Pill(
                        icon: Icons.flag_outlined,
                        label: t(
                          'أفضل فترة: ${p.bestStreak}',
                          'Best run: ${p.bestStreak}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t(
                      'لو فاتك يوم، إنجازاتك وقيمة اللي عملته مش بتضيع. ارجع وقت ما تكون جاهز.',
                      'Missed a day? Your achievements and effort still count. Return when you’re ready.',
                    ),
                    style: TextStyle(color: muted, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
          title('أوسمتك', 'Your achievements'),
          for (final b in c.badges) ...[
            GlassCard(
              padding: const EdgeInsets.all(14),
              onTap: () => showSufraBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (context) => SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: SufraBadge(
                            id: b.id,
                            unlocked: p.badges.contains(b.id),
                            size: 132,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ar ? b.ar : b.en,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t(
                            'التقدم: ${p.counts[b.kind] ?? 0} من ${b.target}',
                            'Progress: ${p.counts[b.kind] ?? 0} of ${b.target}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ['lesson', 'recipe'].contains(b.kind)
                              ? t(
                                  'لسه مفيش سجل موثوق لإتمام النشاط ده. الوسام هيفضل مقفول، مش هنفترض إنك أنجزته.',
                                  'Completion tracking is not connected for this activity. This achievement stays locked, with no assumed completion.',
                                )
                              : t(
                                  snapshot.authoritative
                                      ? 'الإنجاز من السجل المحمي في الاختبار المحلي، مش من الأوسمة القابلة للتعديل.'
                                      : 'الإنجاز بيتحسب من نشاط مسجّل، ومش مكافأة معتمدة من الخادم.',
                                  snapshot.authoritative
                                      ? 'From the protected local test ledger, not editable legacy achievements.'
                                      : 'Based on recorded activity, not a server-verified award.',
                                ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => showBadgeCelebration(
                            context,
                            id: b.id,
                            title: ar ? b.ar : b.en,
                          ),
                          icon: const Icon(Icons.play_circle_outline_rounded),
                          label: Text(
                            t('معاينة الاحتفال', 'Preview celebration'),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(t('تمام', 'Done')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SufraBadge(
                    id: b.id,
                    unlocked: p.badges.contains(b.id),
                    size: 68,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ar ? b.ar : b.en,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ink,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          ['lesson', 'recipe'].contains(b.kind)
                              ? t(
                                  'التتبع لسه مش متصل',
                                  'Tracking not connected',
                                )
                              : t(
                                  '${(p.counts[b.kind] ?? 0).clamp(0, b.target)} من ${b.target}',
                                  '${(p.counts[b.kind] ?? 0).clamp(0, b.target)} of ${b.target}',
                                ),
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: muted),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          title('صحتك بالأرقام', 'Your health records'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/nutrition-stats'),
                icon: const Icon(Icons.bar_chart_rounded),
                label: Text(t('التغذية', 'Nutrition')),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/water'),
                icon: const Icon(Icons.water_drop_outlined),
                label: Text(t('المياه', 'Water')),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/weight'),
                icon: const Icon(Icons.monitor_weight_outlined),
                label: Text(t('الوزن', 'Weight')),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/report'),
                icon: const Icon(Icons.description_outlined),
                label: Text(t('التقارير', 'Reports')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}

class _Mission extends StatelessWidget {
  const _Mission({
    required this.label,
    required this.xp,
    required this.done,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final int xp;
  final bool done;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done ? Icons.check_circle_rounded : icon,
          color: done ? const Color(0xff16a777) : const Color(0xff09b6c8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '+$xp XP',
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    ),
  );
}

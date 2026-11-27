import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../achievements/domain/achievement_activity.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Reuses the achievements rule engine. It reads activity only and never
/// awards badges or fabricates unlock dates while visiting Stats.
class StatsAchievementCard extends StatefulWidget {
  const StatsAchievementCard({
    super.key,
    required this.uid,
    required this.currentUid,
    this.loader,
  });
  final String uid;
  final String? Function() currentUid;
  final AchievementActivityLoader? loader;
  @override
  State<StatsAchievementCard> createState() => _StatsAchievementCardState();
}

class _StatsAchievementCardState extends State<StatsAchievementCard> {
  Future<List<(AchievementRule, int?)>>? _future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(StatsAchievementCard old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid || old.loader != widget.loader) _load();
  }

  void _load() {
    _future = widget.loader == null ? null : _fetch();
  }

  Future<List<(AchievementRule, int?)>> _fetch() async {
    final uid = widget.uid;
    final activity = await widget.loader!.load(uid);
    final rules = await AchievementCatalog().load();
    if (!mounted || widget.currentUid() != uid || activity.userId != uid) {
      throw StateError('Stale badges');
    }
    return [for (final rule in rules) (rule, activity.progress(rule))];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.onSurface;
    final muted = dark ? AppColors.textMuted : AppColors.lightTextMuted;
    return FutureBuilder<List<(AchievementRule, int?)>>(
      future: _future,
      builder: (_, snapshot) {
        final records = snapshot.data;
        final earned = records
            ?.where((r) => r.$2 != null && r.$2! >= r.$1.target)
            .toList();
        final ar = Localizations.localeOf(context).languageCode == 'ar';
        return GlassCard(
          onTap: () => context.push('/achievements'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 128),
            child: Column(
              children: [
                Text(
                  l.statsBadgesTitle,
                  style: TextStyle(fontWeight: FontWeight.w700, color: primary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Tooltip(
                        message: earned != null && i < earned.length
                            ? (ar ? earned[i].$1.titleAr : earned[i].$1.titleEn)
                            : l.statsBadgesUnknown,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: earned != null && i < earned.length
                                ? AppColors.aiPurple.withValues(alpha: .6)
                                : primary.withValues(alpha: .08),
                            border: Border.all(
                              color: primary.withValues(alpha: .2),
                            ),
                          ),
                          child: Icon(
                            [
                              Icons.emoji_events_outlined,
                              Icons.water_drop_outlined,
                              Icons.auto_awesome_outlined,
                            ][i],
                            size: 18,
                            color: earned != null && i < earned.length
                                ? Colors.white
                                : muted,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (records != null)
                  Text(
                    l.statsBadgesEarned(
                      '${earned!.length}',
                      '${records.length}',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: muted),
                  )
                else if (snapshot.hasError)
                  TextButton(
                    onPressed: () => setState(_load),
                    child: Text(l.stateRetry),
                  )
                else
                  Text(
                    l.statsBadgesUnknown,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: muted),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

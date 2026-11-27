import 'package:flutter/material.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../l10n/app_localizations.dart';

/// Placeholder geometry only, rendered while HomeCubit awaits real records.
/// No artificial minimum duration and no invented nutrition values.
class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).stateLoading,
    liveRegion: true,
    child: ExcludeSemantics(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 130),
        children: [
          Row(
            children: [
              const SkeletonBlock(width: 54, height: 54, borderRadius: 18),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBlock(width: 100, height: 14),
                    SizedBox(height: 10),
                    SkeletonBlock(width: 150, height: 22),
                  ],
                ),
              ),
              const SkeletonBlock(width: 48, height: 48, borderRadius: 16),
            ],
          ),
          const SizedBox(height: 20),
          const SkeletonBlock(height: 52, borderRadius: 28),
          const SizedBox(height: 14),
          const SkeletonBlock(height: 200, borderRadius: 28),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: SkeletonBlock(height: 135, borderRadius: 24)),
              SizedBox(width: 14),
              Expanded(child: SkeletonBlock(height: 135, borderRadius: 24)),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: SkeletonBlock(height: 110, borderRadius: 20)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBlock(height: 110, borderRadius: 20)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBlock(height: 110, borderRadius: 20)),
            ],
          ),
        ],
      ),
    ),
  );
}

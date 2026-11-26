import '../../../barcode/presentation/screens/barcode_scanner_screen.dart';
import '../../../voice_logging/voice_meal_screen.dart';
import '../../../camera_analysis/presentation/camera_analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/method_cube.dart';
import '../../../../core/widgets/viewport_reveal.dart';
import '../../../../core/widgets/glass_highlight.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../core/widgets/interactive_food_bowl.dart';
import '../../../../l10n/app_localizations.dart';
import 'food_search_screen.dart';
import 'recent_meal_card.dart';

/// Native log-method hub. Unimplemented capture paths are labeled as such,
/// never represented as a successful analysis or a saved meal.
class MealLogHubScreen extends StatelessWidget {
  const MealLogHubScreen({super.key});
  static const String routePath = '/log';
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              const SizedBox(height: 8),
              Text(
                l.logHubTitle,
                style: context.readableDisplayStyle(size: 28),
              ),
              const SizedBox(height: 4),
              Text(l.logHubSubtitle, style: context.mutedStyle()),
              const SizedBox(height: 12),
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1,
                child: const MethodCube(),
              ),
              const SizedBox(height: 12),
              _MethodCard(
                title: l.logHubVoiceTitle,
                subtitle: l.logHubVoiceSubtitle,
                color: const Color(0x997C3AED),
                art: 'voice',
                icon: Icons.mic_none_rounded,
                onTap: () => context.push(VoiceMealScreen.routePath),
                hero: true,
              ),
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l.logHubFastest,
                    style: context.badgeStyle(color: const Color(0xFF0A1022)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cards = <Widget>[
                    _MethodCard(
                      title: l.logHubPhotoTitle,
                      subtitle: l.logHubPhotoSubtitle,
                      color: const Color(0x8C06B6D4),
                      art: 'camera',
                      icon: Icons.photo_camera_outlined,
                      onTap: () => context.push(CameraAnalysisScreen.routePath),
                    ),
                    _MethodCard(
                      title: l.logHubBarcodeTitle,
                      subtitle: l.logHubBarcodeSubtitle,
                      color: const Color(0x8CFB8C00),
                      art: 'barcode',
                      icon: Icons.qr_code_scanner_rounded,
                      onTap: () => context.push(BarcodeScannerScreen.routePath),
                    ),
                    _MethodCard(
                      title: l.logHubSearchTitle,
                      subtitle: l.logHubSearchSubtitle,
                      color: const Color(0x734ADE80),
                      art: 'search',
                      icon: Icons.search_rounded,
                      onTap: () => context.push(FoodSearchScreen.routePath),
                    ),
                    _MethodCard(
                      title: l.logHubFavoritesTitle,
                      subtitle: l.logHubFavoritesSubtitle,
                      color: const Color(0x73FB7185),
                      art: 'favorite',
                      icon: Icons.favorite_border_rounded,
                      onTap: () => context.push('/favorites'),
                    ),
                  ];
                  if (constraints.maxWidth < 340 ||
                      MediaQuery.textScalerOf(context).scale(13) > 18) {
                    return Column(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          cards[i],
                        ],
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final card in cards)
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 112),
                            child: card,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              const RecentMealCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatefulWidget {
  const _MethodCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.art,
    required this.icon,
    required this.onTap,
    this.hero = false,
  });
  final String title;
  final String subtitle;
  final Color color;
  final String art;
  final IconData icon;
  final VoidCallback onTap;
  final bool hero;
  @override
  State<_MethodCard> createState() => _MethodCardState();
}

class _MethodCardState extends State<_MethodCard> {
  bool pressed = false, hovered = false;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final color = widget.color.withValues(alpha: 1);
    return ViewportReveal(
      builder: (context, visible) => AnimatedSlide(
        offset: visible || reduced ? Offset.zero : const Offset(0, .08),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 420),
        child: AnimatedScale(
          scale: pressed && !reduced ? .98 : 1,
          duration: reduced ? Duration.zero : const Duration(milliseconds: 130),
          child: AnimatedContainer(
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color:
                      (pressed
                              ? const Color(0xFF06B6D4)
                              : hovered
                              ? const Color(0xFFFB8C00)
                              : color)
                          .withValues(
                            alpha: pressed || hovered
                                ? .26
                                : dark
                                ? .12
                                : .06,
                          ),
                  blurRadius: pressed || hovered ? 22 : 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (v) => setState(() => pressed = v),
                onHover: (v) => setState(() => hovered = v),
                onFocusChange: (v) => setState(() => hovered = v),
                borderRadius: BorderRadius.circular(24),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dark
                          ? [widget.color, Colors.white.withValues(alpha: .04)]
                          : [
                              Color.alphaBlend(
                                color.withValues(alpha: .13),
                                Colors.white,
                              ),
                              Colors.white.withValues(alpha: .82),
                            ],
                    ),
                    border: Border.all(
                      color: (dark ? Colors.white : color).withValues(
                        alpha: hovered || pressed ? .6 : .25,
                      ),
                    ),
                  ),
                  child: GlassHighlight(
                    radius: 24,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 220;
                          final artwork = ExcludeSemantics(
                            child: InteractiveFoodBowl(
                              size: widget.hero ? 62 : 50,
                              category: widget.art,
                            ),
                          );
                          final copy = Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                  fontWeight: FontWeight.w700,
                                  color: dark
                                      ? const Color(0xFFF5F7FA)
                                      : const Color(0xFF0A1022),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle,
                                style: context
                                    .mutedStyle(size: 12)
                                    .copyWith(height: 1.5),
                              ),
                            ],
                          );
                          return compact
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Align(
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: artwork,
                                    ),
                                    const SizedBox(height: 8),
                                    copy,
                                  ],
                                )
                              : Row(
                                  children: [
                                    artwork,
                                    const SizedBox(width: 10),
                                    Expanded(child: copy),
                                  ],
                                );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

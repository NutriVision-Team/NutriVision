import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sufra_button_response.dart';
import '../../../../core/widgets/glass_highlight.dart';
import '../../../../core/widgets/viewport_reveal.dart';
import '../../../../l10n/app_localizations.dart';

/// Existing four Home destinations, with one accessible target per action.
/// Idle tiles have no ambient ticker. Flowing water runs only while pressed.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key, this.onOpen});
  final ValueChanged<String>? onOpen;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final entries = [
      (
        '/planner',
        l.plannerTitle,
        ar ? 'رتّب وجبات أيامك' : 'Arrange your meals',
        Icons.calendar_month_rounded,
        const Color(0xFF1565C0),
      ),
      (
        '/shopping',
        l.shoppingTitle,
        ar ? 'احتياجاتك في مكان واحد' : 'Keep your list together',
        Icons.shopping_bag_outlined,
        const Color(0xFF06B6D4),
      ),
      (
        '/coach',
        l.coachTitle,
        ar ? 'ارجع لمساحتك' : 'Open your workspace',
        Icons.auto_awesome_rounded,
        const Color(0xFF7C3AED),
      ),
      (
        '/ramadan',
        l.ramadanGreeting,
        ar ? 'افتح مساحة رمضان' : 'Open your Ramadan space',
        Icons.nightlight_round,
        const Color(0xFFFB8C00),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final single =
            constraints.maxWidth < 330 ||
            MediaQuery.textScalerOf(context).scale(14) > 19;
        final width = single
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ar ? 'خطوتك الجاية' : 'Your next step',
              style: context.readableDisplayStyle(size: 20),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final e in entries)
                  SizedBox(
                    width: width,
                    child: ViewportReveal(
                      builder: (context, visible) {
                        final reduced = MediaQuery.disableAnimationsOf(context);
                        return AnimatedSlide(
                          offset: visible || reduced
                              ? Offset.zero
                              : const Offset(0, .09),
                          duration: reduced
                              ? Duration.zero
                              : Duration(
                                  milliseconds: 420 + entries.indexOf(e) * 100,
                                ),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: visible || reduced ? 1 : 0,
                            duration: reduced
                                ? Duration.zero
                                : Duration(
                                    milliseconds:
                                        320 + entries.indexOf(e) * 100,
                                  ),
                            child: _QuickAction(
                              key: ValueKey('home-action${e.$1}'),
                              title: e.$2,
                              subtitle: e.$3,
                              icon: e.$4,
                              color: e.$5,
                              onTap: () {
                                if (onOpen != null) {
                                  onOpen!(e.$1);
                                } else {
                                  context.push(e.$1);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatefulWidget {
  const _QuickAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool hovered = false, focused = false, pressed = false;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final active = hovered || focused || pressed;
    final ink = active ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return AnimatedSlide(
      offset: active && !pressed && !reduced
          ? const Offset(0, -.025)
          : Offset.zero,
      duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
      child: AnimatedScale(
        scale: pressed && !reduced ? .98 : 1,
        duration: reduced ? Duration.zero : const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:
                    (pressed
                            ? const Color(0xFF06B6D4)
                            : active
                            ? const Color(0xFFFB8C00)
                            : widget.color)
                        .withValues(alpha: active ? (dark ? .42 : .24) : .08),
                blurRadius: active ? 26 : 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: active ? const Color(0xFFFFBD66) : const Color(0x88D99A35),
              width: active ? 1.5 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? [
                      widget.color.withValues(alpha: .22),
                      const Color(0x99111A33),
                    ]
                  : [
                      const Color(0xEEFFFFFF),
                      widget.color.withValues(alpha: .09),
                    ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Material(
              type: MaterialType.transparency,
              child: SufraButtonResponse(
                pressed: pressed,
                hovered: hovered || focused,
                radius: 23,
                child: InkWell(
                  borderRadius: BorderRadius.circular(23),
                  onHover: (v) => setState(() => hovered = v),
                  onFocusChange: (v) => setState(() => focused = v),
                  onHighlightChanged: (v) => setState(() => pressed = v),
                  onTap: widget.onTap,
                  child: GlassHighlight(
                    radius: 23,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AnimatedRotation(
                                turns: active && !reduced ? -.035 : 0,
                                duration: reduced
                                    ? Duration.zero
                                    : const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: active
                                        ? Colors.white.withValues(alpha: .18)
                                        : widget.color.withValues(
                                            alpha: dark ? .24 : .12,
                                          ),
                                    border: Border.all(
                                      color: active
                                          ? Colors.white38
                                          : widget.color.withValues(alpha: .22),
                                    ),
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    color: active
                                        ? Colors.white
                                        : dark
                                        ? const Color(0xFFB9EFFF)
                                        : const Color(0xFF164F85),
                                    size: 25,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_outward_rounded,
                                size: 18,
                                color: ink.withValues(alpha: .7),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: ink.withValues(
                                alpha: dark || active ? .83 : .76,
                              ),
                            ),
                          ),
                        ],
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

import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/nebula_background.dart';

bool discoveryArabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';
String discoveryNumber(BuildContext context, num? value) {
  if (value == null || !value.isFinite) return '—';
  final raw = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  return discoveryArabic(context)
      ? raw
            .split('')
            .map(
              (c) => '0123456789'.contains(c) ? '٠١٢٣٤٥٦٧٨٩'[int.parse(c)] : c,
            )
            .join()
      : raw;
}

class DiscoveryScaffold extends StatelessWidget {
  const DiscoveryScaffold({
    super.key,
    required this.child,
    this.showNavigation = true,
  });
  final Widget child;
  final bool showNavigation;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: NebulaBackground(
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              bottom:
                  showNavigation &&
                      MediaQuery.textScalerOf(context).scale(11) > 15
                  ? FloatingGlassNavBar.contentClearance(context)
                  : 0,
              child: child,
            ),
            if (showNavigation)
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: FloatingGlassNavBar(
                  currentIndex: 0,
                  onAdd: () => context.go('/log'),
                  items: [
                    NavItem(
                      label: AppLocalizations.of(context).discoveryMsg043,
                      icon: Icons.home_outlined,
                      onTap: () => context.go('/home'),
                    ),
                    NavItem(
                      label: AppLocalizations.of(context).discoveryMsg044,
                      icon: Icons.book_outlined,
                      onTap: () => context.go('/diary'),
                    ),
                    NavItem(
                      label: AppLocalizations.of(context).discoveryMsg045,
                      icon: Icons.bar_chart,
                      onTap: () => context.go('/stats'),
                    ),
                    NavItem(
                      label: AppLocalizations.of(context).discoveryMsg046,
                      icon: Icons.person_outline,
                      onTap: () => context.go('/achievements'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class DiscoveryList extends StatelessWidget {
  const DiscoveryList({super.key, required this.children, this.bottom = 120});
  final List<Widget> children;
  final double bottom;
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: EdgeInsets.fromLTRB(16, 24, 16, bottom),
    itemCount: children.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (_, i) => children[i],
  );
}

class DiscoveryTitle extends StatelessWidget {
  const DiscoveryTitle(this.text, {super.key, this.size = 28});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
        fontWeight: FontWeight.w700,
        height: 1.6,
      ),
    ),
  );
}

class DiscoveryNotice extends StatelessWidget {
  const DiscoveryNotice(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: warning
          ? AppColors.orangeLight
          : Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 12,
      height: 1.7,
    ),
  );
}

class DiscoveryError extends StatelessWidget {
  const DiscoveryError({super.key, required this.onRetry, this.message});
  final VoidCallback onRetry;
  final String? message;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.cloud_off_outlined,
        color: AppColors.orangeLight,
        size: 36,
      ),
      Text(message ?? AppLocalizations.of(context).discoveryMsg047),
      TextButton(
        onPressed: onRetry,
        child: Text(AppLocalizations.of(context).discoveryMsg048),
      ),
    ],
  );
}

/// Atlas cell without a forced circular crop. spC is 3x3, not 4x4.
class DiscoverySprite extends StatelessWidget {
  const DiscoverySprite({
    super.key,
    required this.asset,
    required this.column,
    required this.row,
    this.cells = 4,
    this.size = 60,
    this.muted = false,
  });
  final String asset;
  final int column, row, cells;
  final double size;
  final bool muted;
  @override
  Widget build(BuildContext context) {
    Widget image = ClipRect(
      child: SizedBox(
        width: size,
        height: size,
        child: OverflowBox(
          minWidth: size * cells,
          maxWidth: size * cells,
          minHeight: size * cells,
          maxHeight: size * cells,
          child: Transform.translate(
            offset: Offset(
              ((cells - 1) / 2 - column) * size,
              ((cells - 1) / 2 - row) * size,
            ),
            child: Image.asset(
              asset,
              width: size * cells,
              height: size * cells,
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    );
    if (muted) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          .2126,
          .7152,
          .0722,
          0,
          0,
          .2126,
          .7152,
          .0722,
          0,
          0,
          .2126,
          .7152,
          .0722,
          0,
          0,
          0,
          0,
          0,
          .55,
          0,
        ]),
        child: image,
      );
    }
    return image;
  }
}

class DiscoveryEntrance extends StatelessWidget {
  const DiscoveryEntrance({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + index * 90),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (_, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(-70 * (1 - value), 0),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class DiscoveryFloat extends StatefulWidget {
  const DiscoveryFloat({super.key, required this.child});
  final Widget child;
  @override
  State<DiscoveryFloat> createState() => _DiscoveryFloatState();
}

class _DiscoveryFloatState extends State<DiscoveryFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
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

  double _referenceProgress(double t) =>
      Curves.easeInOut.transform(t <= .5 ? t * 2 : (1 - t) * 2);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _motion,
    builder: (_, child) => Transform.translate(
      offset: Offset(0, -7 * _referenceProgress(_motion.value)),
      child: Transform.rotate(
        angle: (2 * math.pi / 180) * _referenceProgress(_motion.value),
        child: child,
      ),
    ),
    child: widget.child,
  );
}

Future<void> discoveryExplain(
  BuildContext context,
  String title,
  String body,
) => showSufraDialog<void>(
  context: context,
  builder: (c) => SufraAlertDialog(
    title: Text(title),
    content: SingleChildScrollView(child: SelectableText(body)),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(c),
        child: Text(AppLocalizations.of(c).discoveryMsg049),
      ),
    ],
  ),
);

/// The fraction stays current / target even inside an RTL paragraph.
class DiscoveryProgressPair extends StatelessWidget {
  const DiscoveryProgressPair({
    super.key,
    required this.current,
    required this.target,
    this.unit,
  });
  final int current, target;
  final String? unit;
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${AppLocalizations.of(context).discoveryMsg050}: ${discoveryNumber(context, current)}. ${AppLocalizations.of(context).discoveryMsg051}: ${discoveryNumber(context, target)}',
    child: ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: DiscoveryNumberSequence(
          first: current,
          second: target,
          unit: unit,
        ),
      ),
    ),
  );
}

/// Separate layout boxes prevent Arabic numeral runs from swapping under bidi.
class DiscoveryNumberSequence extends StatelessWidget {
  const DiscoveryNumberSequence({
    super.key,
    required this.first,
    required this.second,
    this.separator = ' / ',
    this.unit,
    this.style,
  });
  final num? first, second;
  final String separator;
  final String? unit;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        Text(
          discoveryNumber(context, first),
          style:
              style ??
              TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (separator.contains('→'))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward,
              size: 14,
              color:
                  style?.color ??
                  Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          Text(
            separator,
            style:
                style ??
                TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        Text(
          discoveryNumber(context, second),
          style:
              style ??
              TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (unit != null)
          Text(
            ' $unit',
            style:
                style ??
                TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/nebula_background.dart';

/// Full-viewport composition only. Coach entry points live in Home and Profile,
/// where they participate in layout instead of covering page controls.
class CoachAccessHost extends StatelessWidget {
  const CoachAccessHost({
    super.key,
    required this.child,
    required this.router,
    required this.enabled,
  });
  final Widget child;
  final GoRouter router;
  final bool enabled;

  @override
  Widget build(BuildContext context) => NebulaBackground(
    child: Theme(
      data: Theme.of(
        context,
      ).copyWith(scaffoldBackgroundColor: Colors.transparent),
      child: SizedBox.expand(child: child),
    ),
  );
}

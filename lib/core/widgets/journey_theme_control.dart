import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/theme_cubit.dart';
import 'theme_switcher.dart';

/// The design's top-center theme affordance. Overlay placement does not move
/// the page content; its 44px target surrounds the original 30px visual.
class JourneyThemeControl extends StatelessWidget {
  const JourneyThemeControl({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.watch<ThemeCubit?>() == null) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: MediaQuery.paddingOf(context).top,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                children: [
                  Positioned.fill(
                    left: 7,
                    right: 7,
                    top: 7,
                    bottom: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: .55),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: .2),
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(child: LiquidThemeButton(size: 30)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// Keeps screens readable on wide displays without hiding the app background.
///
/// Phones are untouched. On tablets the content uses the full width up to
/// [maxContentWidth]; beyond that it is centred. The frame never paints an
/// opaque fill, so the full-viewport nebula background stays visible around
/// and behind the content.
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({
    super.key,
    required this.child,
    this.maxContentWidth = 960,
  });

  final Widget child;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= maxContentWidth) return child;
    return Center(
      child: SizedBox(
        width: maxContentWidth,
        child: MediaQuery(
          data: media.copyWith(size: Size(maxContentWidth, media.size.height)),
          child: child,
        ),
      ),
    );
  }
}

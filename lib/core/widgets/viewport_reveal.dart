import 'package:flutter/material.dart';

/// Starts content motion only when its actual box enters the visible viewport.
class ViewportReveal extends StatefulWidget {
  const ViewportReveal({super.key, required this.builder});
  final Widget Function(BuildContext, bool) builder;
  @override
  State<ViewportReveal> createState() => _ViewportRevealState();
}

class _ViewportRevealState extends State<ViewportReveal> {
  ScrollPosition? position;
  bool visible = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (position != next) {
      position?.removeListener(scheduleCheck);
      position = next;
      position?.addListener(scheduleCheck);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => check());
  }

  void scheduleCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) => check());
  }

  void check() {
    if (!mounted || visible) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final y = box.localToGlobal(Offset.zero).dy;
    final h = MediaQuery.sizeOf(context).height;
    if (y < h * .88 && y + box.size.height > 0) {
      setState(() => visible = true);
      position?.removeListener(scheduleCheck);
    }
  }

  @override
  void dispose() {
    position?.removeListener(scheduleCheck);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    visible || MediaQuery.disableAnimationsOf(context),
  );
}

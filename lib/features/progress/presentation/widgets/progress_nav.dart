import 'package:flutter/material.dart';
import '../../../../core/widgets/sufra_navigation.dart';

class ProgressNavBar extends StatelessWidget {
  const ProgressNavBar({super.key, required this.currentIndex});
  final int currentIndex;
  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: SufraNavigation(currentIndex: currentIndex),
  );
}

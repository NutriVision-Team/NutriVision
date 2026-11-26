import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import '../../../planner/domain/planner_food_choices.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Fixed user-selected navigation, never model-selected actions or writes.
Future<void> showCoachTools(
  BuildContext context, {
  PlannerFoodChoices? foodChoices,
  VoidCallback? onHabits,
}) async {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  final destination = await showSufraBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar ? 'يومك وخطتك' : 'Your day and plan',
                style: context.readableDisplayStyle(size: 20),
              ),
              for (final item in <(IconData, String, String)>[
                if (onHabits != null)
                  (
                    Icons.checklist_outlined,
                    ar ? 'خطوة النهاردة' : "Today's step",
                    'habits',
                  ),
                (
                  Icons.calendar_month_outlined,
                  ar ? 'خطتي للأسبوع' : 'My weekly plan',
                  '/planner',
                ),
                (
                  Icons.assessment_outlined,
                  ar ? 'تقرير تقدمي' : 'My progress report',
                  '/report',
                ),
                (
                  Icons.today_outlined,
                  ar ? 'وجباتي النهاردة' : 'Today\'s meals',
                  '/diary',
                ),
                (
                  Icons.swap_horiz,
                  ar ? 'قارن أصناف بديلة' : 'Compare food alternatives',
                  '/alternatives',
                ),
                (
                  Icons.menu_book_outlined,
                  ar ? 'وصفات أختار منها' : 'Browse recipes',
                  '/recipes',
                ),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(item.$1),
                  title: Text(item.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(sheet, item.$3),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  if (destination == 'habits' && context.mounted) {
    onHabits?.call();
    return;
  }
  if (destination != null && context.mounted) {
    context.push(
      destination,
      extra: destination == '/planner' ? foodChoices : null,
    );
  }
}

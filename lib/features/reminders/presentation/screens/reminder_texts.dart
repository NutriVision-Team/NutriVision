import '../../../../l10n/app_localizations.dart';
import '../../domain/reminder_models.dart';

/// Notification copy in the current app language. Generic on purpose.
ReminderTexts reminderTextsFor(AppLocalizations l) {
  final names = {
    'breakfast': l.mealBreakfast,
    'lunch': l.mealLunch,
    'dinner': l.mealDinner,
    'snack': l.mealSnack,
  };
  return ReminderTexts(
    title: l.remindersNotifTitle,
    water: l.remindersNotifWater,
    weight: l.remindersNotifWeight,
    meals: {
      for (final e in names.entries) e.key: l.remindersNotifMeal(e.value),
    },
    waterChannel: l.remindersChannelWater,
    mealChannel: l.remindersChannelMeals,
    weightChannel: l.remindersChannelWeight,
  );
}

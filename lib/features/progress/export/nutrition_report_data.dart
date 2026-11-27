import 'coach_report_snapshot.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:clock/clock.dart' as time;
import '../domain/day_nutrition.dart';
import '../presentation/cubit/weight_cubit.dart';

class NutritionReportData {
  const NutritionReportData({
    required this.days,
    required this.weight,
    required this.l10n,
    this.displayName,
    this.hydrationGoalMl,
    this.coach,
  });
  final List<DayNutrition> days;
  final WeightState weight;
  final AppLocalizations l10n;
  final String? displayName;
  final double? hydrationGoalMl;
  final CoachReportSnapshot? coach;
  CoachReportSnapshot? get selectedCoach =>
      coach?.forDates(days.map((d) => d.dateKey).toSet());

  /// Current profile context, not a reconstruction of historical profile values.
  List<String> get profileLines {
    final p = weight.activeProfile;
    if (p == null) return const [];
    final now = time.clock.now(), dob = p.dateOfBirth;
    final age =
        now.year -
        dob.year -
        ((now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day))
            ? 1
            : 0);
    final current = weight.currentWeight;
    final bmi = current != null && p.heightCm > 0
        ? current / ((p.heightCm / 100) * (p.heightCm / 100))
        : null;
    String number(double v) =>
        v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
    return [
      [
        if (age >= 0) l10n.exportYearsOld('$age'),
        if (p.heightCm > 0) l10n.exportCmLabel(number(p.heightCm)),
      ].join(' · '),
      [
        if (current != null &&
            current > p.targetWeightKg &&
            p.targetWeightKg > 0)
          l10n.exportGoalLoss(number(current - p.targetWeightKg)),
        if (bmi != null) l10n.exportBmiLabel(number(bmi)),
      ].join(' · '),
    ].where((line) => line.isNotEmpty).toList();
  }
}

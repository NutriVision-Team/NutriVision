/// Optional self-reported daily context, separate from nutrition and habits.
/// Session-only. Never diagnoses, scores or infers activity/sleep from a profile.
class CoachDailyCheckin {
  const CoachDailyCheckin({
    this.activityMinutes,
    this.sleepHours,
    this.feeling,
  });
  final int? activityMinutes;
  final double? sleepHours;

  /// A bounded description selected by the user, not a clinical assessment.
  final String? feeling;
  static const feelings = {'good', 'okay', 'low', 'prefer_not'};
  bool get empty =>
      activityMinutes == null && sleepHours == null && feeling == null;
  void validate() {
    if (activityMinutes != null &&
        (activityMinutes! < 0 || activityMinutes! > 1440)) {
      throw ArgumentError.value(activityMinutes);
    }
    if (sleepHours != null &&
        (!sleepHours!.isFinite || sleepHours! < 0 || sleepHours! > 24)) {
      throw ArgumentError.value(sleepHours);
    }
    if (feeling != null && !feelings.contains(feeling)) {
      throw ArgumentError.value(feeling);
    }
  }

  static String feelingLabel(String id, bool ar) => switch (id) {
    'good' => ar ? 'كويس' : 'Good',
    'okay' => ar ? 'عادي' : 'Okay',
    'low' => ar ? 'طاقتي قليلة' : 'Low energy',
    'prefer_not' => ar ? 'أفضل ما أقولش' : 'Prefer not to say',
    _ => ar ? 'مش مسجل' : 'Not recorded',
  };
}

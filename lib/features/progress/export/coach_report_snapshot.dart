import '../../health_coach/domain/health_coach_profile.dart';

/// Owner-bound, explicit local/session or saved check-ins. No automatic sharing.
class CoachReportSnapshot {
  CoachReportSnapshot({
    required this.ownerUid,
    required List<String> goals,
    List<String> habits = const [],
    required Map<String, Set<String>> checkins,
  }) : goals = List.unmodifiable(goals),
       habits = List.unmodifiable(habits),
       checkins = Map.unmodifiable(
         checkins.map((k, v) => MapEntry(k, Set<String>.unmodifiable(v))),
       );
  final String ownerUid;
  final List<String> goals;
  final List<String> habits;
  final Map<String, Set<String>> checkins;
  CoachReportSnapshot forDates(Set<String> dates) => CoachReportSnapshot(
    ownerUid: ownerUid,
    goals: goals,
    habits: habits,
    checkins: Map.fromEntries(
      checkins.entries.where((e) => dates.contains(e.key)),
    ),
  );
  CoachReportSnapshot? forOwner(String? uid) =>
      uid == ownerUid && ownerUid.isNotEmpty ? this : null;
  List<String> goalLabels(bool ar) =>
      goals.map((g) => CoachGoalLabels.label(g, ar)).toList(growable: false);
  String summary(bool ar) => ar
      ? 'تأكيداتك خلال الفترة: $confirmations. عدد الأيام اللي فيها تأكيدات: $confirmedDays.'
      : '$confirmations ${confirmations == 1 ? 'check-in' : 'check-ins'} across $confirmedDays ${confirmedDays == 1 ? 'day' : 'days'} in this period';
  static String label(String id, bool ar) => switch (id) {
    'log_meal' => ar ? 'تسجيل وجبة' : 'Log one meal',
    'prepare_meal' => ar ? 'تجهيز وجبة' : 'Prepare for a meal',
    'review_ingredients' => ar ? 'مراجعة المكونات' : 'Review ingredients',
    _ => ar ? 'خطوة مختارة' : 'Selected step',
  };
  int get confirmedDays => checkins.values.where((v) => v.isNotEmpty).length;
  int get confirmations => checkins.values.fold(0, (n, v) => n + v.length);
}

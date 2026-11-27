import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../domain/coach_daily_checkin.dart';
import '../cubit/coach_cubit.dart';

class CoachDailyCheckinScreen extends StatefulWidget {
  const CoachDailyCheckinScreen({super.key, required this.cubit});
  final CoachCubit cubit;
  @override
  State<CoachDailyCheckinScreen> createState() =>
      _CoachDailyCheckinScreenState();
}

class _CoachDailyCheckinScreenState extends State<CoachDailyCheckinScreen>
    with WidgetsBindingObserver {
  final form = GlobalKey<FormState>();
  final activity = TextEditingController(), sleep = TextEditingController();
  String? feeling;
  late String day;
  Timer? timer;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String t(String a, String e) => ar ? a : e;
  String digits(String input) {
    var s = input.trim().replaceAll('٫', '.');
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i').replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i');
    }
    return s;
  }

  void load() {
    day = widget.cubit.habitTodayKey;
    final v = widget.cubit.dailyCheckin;
    activity.text = v.activityMinutes?.toString() ?? '';
    sleep.text = v.sleepHours?.toString() ?? '';
    feeling = v.feeling;
  }

  @override
  void initState() {
    super.initState();
    load();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 30), (_) => refreshDay());
  }

  void refreshDay() {
    if (mounted && day != widget.cubit.habitTodayKey) setState(load);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshDay();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    activity.dispose();
    sleep.dispose();
    super.dispose();
  }

  void save() {
    if (widget.cubit.inactive) {
      Navigator.of(context).pop();
      return;
    }
    if (day != widget.cubit.habitTodayKey) {
      setState(load);
      ScaffoldMessenger.of(context).showSnackBar(
        SufraSnackBar(
          content: Text(
            t(
              'اليوم اتغير. راجع بيانات النهاردة قبل الحفظ.',
              'The day changed. Review today before saving.',
            ),
          ),
        ),
      );
      return;
    }
    if (!form.currentState!.validate()) return;
    widget.cubit.updateDailyCheckin(
      CoachDailyCheckin(
        activityMinutes: int.tryParse(digits(activity.text)),
        sleepHours: double.tryParse(digits(sleep.text)),
        feeling: feeling,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(t('راجع يومك', 'Your daily check-in'))),
    body: NebulaBackground(
      child: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(day, textDirection: TextDirection.ltr),
              const SizedBox(height: 12),
              Text(
                t(
                  'اختياري وللجلسة بس. مش بيتحفظ على حسابك ولا بيتبعت للمدرب. اللي تسيبه فاضي يفضل غير معروف، مش صفر.',
                  'Optional and session-only. Not saved to your account or sent to the Coach. Blank fields remain unknown, not zero.',
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('daily_activity'),
                controller: activity,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t(
                    'نشاط سجلته بنفسك، بالدقائق',
                    'Self-reported activity, minutes',
                  ),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(digits(v));
                  return n == null || n < 0 || n > 1440
                      ? t('اكتب من ٠ لـ ١٤٤٠ دقيقة', 'Enter 0 to 1440 minutes')
                      : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('daily_sleep'),
                controller: sleep,
                maxLength: 5,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t('نمت كام ساعة؟', 'Hours slept'),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(digits(v));
                  return n == null || !n.isFinite || n < 0 || n > 24
                      ? t('اكتب من ٠ لـ ٢٤ ساعة', 'Enter 0 to 24 hours')
                      : null;
                },
              ),
              const SizedBox(height: 20),
              Text(t('حاسس إزاي بشكل عام؟', 'How are you feeling in general?')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in CoachDailyCheckin.feelings)
                    ChoiceChip(
                      key: ValueKey('daily_feeling_$f'),
                      label: Text(CoachDailyCheckin.feelingLabel(f, ar)),
                      selected: feeling == f,
                      onSelected: (v) => setState(() => feeling = v ? f : null),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                t(
                  'دي ملاحظات منك، مش تقييم طبي ولا هدف لازم توصله. تقدر تعدّل أو تمسح في أي وقت.',
                  'These are your notes, not a medical assessment or a target. You can edit or clear them at any time.',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('daily_save'),
                onPressed: save,
                child: Text(t('احتفظ للجلسة', 'Keep for this session')),
              ),
              TextButton(
                key: const ValueKey('daily_clear'),
                onPressed: () {
                  if (!widget.cubit.inactive) {
                    widget.cubit.updateDailyCheckin(const CoachDailyCheckin());
                  }
                  Navigator.of(context).pop();
                },
                child: Text(t('امسح بيانات النهاردة', 'Clear today')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

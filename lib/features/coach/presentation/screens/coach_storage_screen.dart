import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../cubit/coach_cubit.dart';

class CoachStorageScreen extends StatefulWidget {
  const CoachStorageScreen({super.key, required this.cubit});
  final CoachCubit cubit;
  @override
  State<CoachStorageScreen> createState() => _CoachStorageScreenState();
}

class _CoachStorageScreenState extends State<CoachStorageScreen> {
  late Set<String> selected;
  bool busy = false;
  String? message;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String t(String a, String e) => ar ? a : e;
  @override
  void initState() {
    super.initState();
    selected = widget.cubit.savedHealth.fields.toSet();
  }

  Future<void> run(Future<void> Function() action, String success) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
      if (mounted) setState(() => message = success);
    } catch (_) {
      if (mounted) {
        setState(
          () => message = t(
            'العملية ما اتأكدتش. راجع الاتصال وجرّب بإيدك؛ مفيش إعادة إرسال تلقائية.',
            'Operation could not be confirmed. Check your connection and retry manually; no automatic resend.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = <String, String>{
      'age': t('العمر', 'Age'),
      'heightCm': t('الطول', 'Height'),
      'weightKg': t('الوزن', 'Weight'),
      'activity': t('وصف النشاط', 'Activity note'),
      'lifestyle': t('نمط الحياة', 'Lifestyle'),
      'sleepSchedule': t('مواعيد النوم', 'Sleep schedule'),
      'preferredFoods': t('الأكل المفضل', 'Preferred foods'),
      'excludedFoods': t('الأكل المستبعد', 'Excluded foods'),
      'allergens': t('الحساسية', 'Allergies'),
      'dietaryRestrictions': t('التفضيلات الغذائية', 'Dietary choices'),
      'budget': t('ملاحظة الميزانية', 'Budget note'),
      'mealsPerDay': t('عدد الوجبات', 'Meal count'),
      'preparationMinutes': t('ملاحظة وقت التحضير', 'Preparation note'),
      'conditions': t('الحالات المعلنة', 'Disclosed conditions'),
      'specialistGuidance': t('تعليمات المختص', 'Professional guidance'),
      'goals': t('الأهداف المختارة', 'Chosen goals'),
      'habits': t('الخطوات وتأكيد النهاردة', 'Steps and today check-in'),
    };
    final saved = widget.cubit.savedHealth;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('الحفظ في حسابي', 'Save in my account'),
          style: context.readableDisplayStyle(size: 20),
        ),
      ),
      body: NebulaBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              t(
                'اختار بس البيانات اللي عايز تحتفظ بيها على Firebase. الحفظ بإيدك، مش تلقائي. لا محادثات ولا صور ولا صوت، ومش بتتبعت للذكاء الاصطناعي.',
                'Select only what you want retained in Firebase. Save manually, not automatically. No chat, photos or audio, and nothing here is sent to AI.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t(
                'تقدر تفضل بالجلسة بس من غير ما تضغط حفظ. حذف السحابة مش بيمسح يوميات وجباتك، والاختيارات الحالية تفضل للجلسة.',
                'Stay session-only by not saving. Cloud deletion does not remove your meal diary; current choices remain for this session.',
              ),
            ),
            if (widget.cubit.healthLoadFailed)
              Text(
                t(
                  'تعذر تحميل المحفوظ. حمّله تاني قبل ما تستبدله.',
                  'Saved choices could not be loaded. Reload them before replacing.',
                ),
              ),
            for (final e in labels.entries)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.value),
                value: selected.contains(e.key),
                onChanged: busy
                    ? null
                    : (v) => setState(() {
                        if (v == true) {
                          selected.add(e.key);
                        } else {
                          selected.remove(e.key);
                        }
                      }),
              ),
            FilledButton(
              key: const ValueKey('save_coach_cloud'),
              onPressed:
                  busy ||
                      widget.cubit.healthStore == null ||
                      widget.cubit.healthLoadFailed
                  ? null
                  : () => run(
                      () => widget.cubit.saveHealthFields(selected),
                      t(
                        'تم الحفظ واتراجع من الخادم.',
                        'Saved and checked from server.',
                      ),
                    ),
              child: Text(
                t('احفظ المحدد في حسابي', 'Save selected to my account'),
              ),
            ),
            OutlinedButton(
              onPressed: busy || widget.cubit.healthStore == null
                  ? null
                  : () => run(() async {
                      await widget.cubit.loadSavedHealth();
                      if (widget.cubit.healthLoadFailed) {
                        throw StateError('Load failed');
                      }
                      if (mounted) {
                        setState(
                          () => selected = widget.cubit.savedHealth.fields
                              .toSet(),
                        );
                      }
                    }, t('تم تحميل المحفوظ.', 'Saved choices loaded.')),
              child: Text(t('حمّل المحفوظ', 'Reload saved choices')),
            ),
            if (saved.checkins.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                t('أيام محفوظة (آخر ٦٢ سجل)', 'Saved days (latest 62 records)'),
              ),
              for (final day in saved.checkins.keys)
                ListTile(
                  title: Text(day, textDirection: TextDirection.ltr),
                  subtitle: Text(
                    t(
                      'تأكيدات: ${saved.checkins[day]!.length}',
                      'Check-ins: ${saved.checkins[day]!.length}',
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: t('امسح اليوم', 'Delete day'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: busy
                        ? null
                        : () => run(
                            () => widget.cubit.deleteHealthDay(day),
                            t('تم مسح اليوم.', 'Day deleted.'),
                          ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              key: const ValueKey('delete_coach_cloud'),
              onPressed: busy || widget.cubit.healthStore == null
                  ? null
                  : () async {
                      final yes = await showSufraDialog<bool>(
                        context: context,
                        builder: (d) => SufraAlertDialog(
                          title: Text(
                            t(
                              'امسح بيانات المدرب المحفوظة؟',
                              'Delete saved Coach data?',
                            ),
                            style: context.readableDisplayStyle(size: 18),
                          ),
                          content: Text(
                            t(
                              'الملف والأهداف والخطوات وتأكيدات الأيام فقط. يوميات الأكل والمحادثات مش هتتمسح.',
                              'Only saved profile, goals, steps and day check-ins. Meal diary and chats are not deleted.',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(d, false),
                              child: Text(t('إلغاء', 'Cancel')),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(d, true),
                              child: Text(t('امسح', 'Delete')),
                            ),
                          ],
                        ),
                      );
                      if (yes == true) {
                        await run(
                          widget.cubit.deleteSavedHealth,
                          t(
                            'اتمسحت بيانات المدرب المحفوظة.',
                            'Saved Coach data deleted.',
                          ),
                        );
                      }
                    },
              child: Text(
                t(
                  'امسح بيانات المدرب من السحابة',
                  'Delete Coach data from cloud',
                ),
              ),
            ),
            if (busy) const LinearProgressIndicator(),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(message!),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

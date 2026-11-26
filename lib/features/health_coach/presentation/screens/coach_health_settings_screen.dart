import 'package:flutter/material.dart';
import '../../../auth/presentation/personal_educational_policy.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../domain/health_coach_profile.dart';

/// Optional, session-only profile editor. No cloud or external service calls.
/// Optional cloud retention is selected and saved on the separate storage screen.
class CoachHealthSettingsScreen extends StatefulWidget {
  const CoachHealthSettingsScreen({
    super.key,
    required this.profile,
    required this.consent,
    required this.onSave,
    this.providerAvailable = false,
    this.contextSharingAvailable = false,
  });
  final HealthCoachProfile profile;
  final HealthCoachConsent consent;
  final bool providerAvailable, contextSharingAvailable;
  final void Function(HealthCoachProfile, HealthCoachConsent) onSave;
  @override
  State<CoachHealthSettingsScreen> createState() =>
      _CoachHealthSettingsScreenState();
}

class _CoachHealthSettingsScreenState extends State<CoachHealthSettingsScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> fields;
  late bool external, profileContext, records, history;
  final builtInGoals = <String>{};
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String t(String a, String e) => ar ? a : e;
  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    builtInGoals.addAll(p.goals.where(CoachGoalLabels.ids.contains));
    fields = {
      for (final e in <String, String>{
        'age': p.age?.toString() ?? '',
        'height': p.heightCm?.toString() ?? '',
        'weight': p.weightKg?.toString() ?? '',
        'activity': p.activity ?? '',
        'lifestyle': p.lifestyle ?? '',
        'sleep': p.sleepSchedule ?? '',
        'preferred': p.preferredFoods.join(', '),
        'excluded': p.excludedFoods.join(', '),
        'allergens': p.allergens.join(', '),
        'restrictions': p.dietaryRestrictions.join(', '),
        'goals': p.goals
            .where((g) => !CoachGoalLabels.ids.contains(g))
            .join(', '),
        'budget': p.budgetDescription ?? '',
        'meals': p.mealsPerDay?.toString() ?? '',
        'minutes': p.preparationMinutes?.toString() ?? '',
        'conditions': p.disclosedConditions.join(', '),
        'guidance': p.specialistGuidance ?? '',
      }.entries)
        e.key: TextEditingController(text: e.value),
    };
    external = widget.providerAvailable && widget.consent.externalAi;
    profileContext =
        widget.contextSharingAvailable && widget.consent.profileContext;
    records = widget.contextSharingAvailable && widget.consent.recordContext;
    history =
        widget.contextSharingAvailable && widget.consent.conversationContext;
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String number(String raw) {
    var result = raw.replaceAll('٫', '.');
    const arabic = '٠١٢٣٤٥٦٧٨٩', persian = '۰۱۲۳۴۵۶۷۸۹';
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
    }
    return result;
  }

  String? value(String k) =>
      fields[k]!.text.trim().isEmpty ? null : fields[k]!.text.trim();
  List<String> list(String k) => (value(k) ?? '')
      .split(RegExp('[,،\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  Widget field(
    String key,
    String label,
    String reason, {
    double? min,
    double? max,
    bool integer = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('health_$key'),
      controller: fields[key],
      maxLength: min == null ? 500 : 8,
      keyboardType: min == null
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        helperText: reason,
        helperMaxLines: 3,
        counterText: '',
      ),
      validator: (raw) {
        if (raw == null || raw.trim().isEmpty) return null;
        if (min == null) {
          if (const {
            'preferred',
            'excluded',
            'allergens',
            'restrictions',
            'goals',
            'conditions',
          }.contains(key)) {
            final entries = list(key);
            if (entries.length > 20 || entries.any((s) => s.length > 100)) {
              return t(
                'بحد أقصى ٢٠ اختيار، وكل اختيار ١٠٠ حرف',
                'Up to 20 entries, each at most 100 characters',
              );
            }
          }
          return null;
        }
        final v = double.tryParse(number(raw));
        if (v == null ||
            !v.isFinite ||
            v < min ||
            v > max! ||
            (integer && v != v.roundToDouble())) {
          return t(
            'راجع القيمة أو سيبها فاضية',
            'Check this value or leave it blank',
          );
        }
        return null;
      },
    ),
  );
  void save() {
    if (!_form.currentState!.validate()) return;
    final p = HealthCoachProfile(
      age: int.tryParse(number(value('age') ?? '')),
      heightCm: double.tryParse(number(value('height') ?? '')),
      weightKg: double.tryParse(number(value('weight') ?? '')),
      activity: value('activity'),
      lifestyle: value('lifestyle'),
      sleepSchedule: value('sleep'),
      preferredFoods: list('preferred'),
      excludedFoods: list('excluded'),
      allergens: list('allergens'),
      dietaryRestrictions: list('restrictions'),
      goals: [...builtInGoals, ...list('goals')],
      budgetDescription: value('budget'),
      mealsPerDay: int.tryParse(number(value('meals') ?? '')),
      preparationMinutes: int.tryParse(number(value('minutes') ?? '')),
      disclosedConditions: list('conditions'),
      specialistGuidance: value('guidance'),
    );
    widget.onSave(
      p,
      HealthCoachConsent(
        externalAi: external && widget.providerAvailable,
        profileContext: profileContext,
        recordContext: records,
        conversationContext: history,
        durableMemory: false,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        t('اختيارات المدرب', 'Coach choices'),
        style: context.readableDisplayStyle(size: 20),
      ),
    ),
    body: NebulaBackground(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              t(
                'كل البيانات اختيارية. تقدر تستخدم السجل والأدوات من غير ما تملاها. التعديلات هنا للجلسة الحالية فقط، ومش بتتزامن أو تتحفظ بعد قفل التطبيق.',
                'Every field is optional. Records and tools work without them. These changes are for this session only and are not synced or retained after closing the app.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t(
                'مش بديل للطبيب أو مختص التغذية. الحساسية والحالات الصحية ما ينفعش نعتمد فيها على ضمان من المدرب.',
                'Not a replacement for a clinician or qualified dietitian. Do not rely on the coach for allergy-safety guarantees or medical care.',
              ),
            ),
            const SizedBox(height: 20),
            field(
              'age',
              t('العمر', 'Age'),
              t(
                'لضبط حدود السلامة، مش للتشخيص',
                'For safety limits, not diagnosis',
              ),
              min: 1,
              max: 120,
              integer: true,
            ),
            field(
              'height',
              t('الطول بالسنتيمتر', 'Height in cm'),
              t(
                'اختياري لفهم السياق، مش لقياس صحتك',
                'Optional context, not a health score',
              ),
              min: 40,
              max: 250,
            ),
            field(
              'weight',
              t('الوزن بالكيلوجرام', 'Weight in kg'),
              t(
                'اختياري، المتابعة مش مبنية على الوزن وحده',
                'Optional, progress is not judged by weight alone',
              ),
              min: 5,
              max: 500,
            ),
            field(
              'activity',
              t('النشاط', 'Activity'),
              t(
                'ملاحظة للجلسة فقط؛ مش بتغيّر الخطة تلقائيًا',
                'Session note only; does not automatically change plans',
              ),
            ),
            field(
              'lifestyle',
              t('نمط الحياة والشغل', 'Lifestyle and work'),
              t(
                'ملاحظة للجلسة فقط؛ مفيش جدولة تلقائية',
                'Session note only; no automatic scheduling',
              ),
            ),
            field(
              'sleep',
              t('مواعيد النوم والصحيان', 'Sleep and waking schedule'),
              t(
                'ملاحظة للجلسة فقط؛ مش بنحسب مواعيد وجبات منها',
                'Session note only; not used to calculate meal times',
              ),
            ),
            field(
              'preferred',
              t('أكل بتحبه', 'Preferred foods'),
              t(
                'افصل العناصر بفاصلة، عشان الاختيارات تناسبك',
                'Separate with commas, to match food choices',
              ),
            ),
            field(
              'excluded',
              t('أكل مش مناسب لك', 'Excluded foods'),
              t('عشان نتجنبه في الاقتراحات', 'To exclude it from suggestions'),
            ),
            field(
              'allergens',
              t('حساسية غذائية', 'Food allergies'),
              t(
                'حدود مهمة، راجع المكونات والملصق بنفسك',
                'Important limits, still check ingredients and labels yourself',
              ),
            ),
            field(
              'restrictions',
              t('قيود وتفضيلات غذائية', 'Dietary restrictions'),
              t(
                'عشان البدائل تناسب اختياراتك',
                'To match alternatives to your choices',
              ),
            ),
            Text(
              t('اختار خطوة تشتغل عليها', 'Choose a focus'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final goal in CoachGoalLabels.ids)
                  FilterChip(
                    label: Text(CoachGoalLabels.label(goal, ar)),
                    selected: builtInGoals.contains(goal),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        builtInGoals.add(goal);
                      } else {
                        builtInGoals.remove(goal);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            field(
              'goals',
              t('أهدافك', 'Your goals'),
              t(
                'زي تنويع الأكل أو تنظيم الوجبات',
                'Such as food variety or meal organization',
              ),
            ),
            field(
              'budget',
              t('ميزانية الأكل', 'Food budget'),
              t(
                'ملاحظة للجلسة فقط؛ مطابقة الخطط بالأسعار لسه غير متاحة',
                'Session note only; price-based plan matching is not available',
              ),
            ),
            field(
              'meals',
              t('عدد الوجبات المفضل', 'Preferred meals per day'),
              t(
                'الخطة بتدعم ٣ أو ٤ وجبات حاليًا',
                'Plans currently support 3 or 4 meals',
              ),
              min: 1,
              max: 10,
              integer: true,
            ),
            field(
              'minutes',
              t('وقت التحضير بالدقايق', 'Preparation time in minutes'),
              t(
                'ملاحظة للجلسة فقط؛ تصفية الوصفات بالوقت لسه غير متاحة',
                'Session note only; recipe time filtering is not available',
              ),
              min: 0,
              max: 600,
              integer: true,
            ),
            field(
              'conditions',
              t(
                'حالات صحية تختار تشاركها',
                'Conditions you choose to disclose',
              ),
              t(
                'لحدود الأمان والتحويل لمختص، مش لتوليد علاج',
                'For safety and referral, not treatment generation',
              ),
            ),
            field(
              'guidance',
              t('تعليمات مختص، لو موجودة', 'Professional guidance, if any'),
              t(
                'لعدم اقتراح تغيير مستقل لتعليماته',
                'To avoid independently changing professional guidance',
              ),
            ),
            const Divider(),
            Text(
              t('خصوصية المدرّب', 'Coach privacy'),
              style: context.readableDisplayStyle(size: 18),
            ),
            if (!widget.providerAvailable)
              Text(
                t(
                  'الخدمة الخارجية لسه مش مفعلة. مفيش بيانات هتتبعت من الاختيارات دي.',
                  'The external service is not enabled. These choices do not send any data.',
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t('استخدام المدرّب الذكي', 'Use the Coach')),
              subtitle: Text(
                t(
                  'سؤالك بيتبعت لخدمة المدرب على الإنترنت عشان ترد عليك. تفاصيل معالجة البيانات في سياسة الخصوصية.',
                  'Your question is sent to the online Coach service for a reply. See the privacy policy for data processing details.',
                ),
              ),
              value: external,
              onChanged: widget.providerAvailable
                  ? (v) => setState(() => external = v)
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                t('مشاركة بيانات ملف الجلسة', 'Share session profile'),
              ),
              value: profileContext,
              onChanged: widget.contextSharingAvailable
                  ? (v) => setState(() => profileContext = v)
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                t(
                  'مشاركة ملخص أكل ومياه اليوم',
                  'Share today’s food and water summary',
                ),
              ),
              value: records,
              onChanged: widget.contextSharingAvailable
                  ? (v) => setState(() => records = v)
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t('تذكّر آخر ٨ رسائل', 'Use the last 8 messages')),
              value: history,
              onChanged: widget.contextSharingAvailable
                  ? (v) => setState(() => history = v)
                  : null,
            ),
            Text(
              t(
                widget.contextSharingAvailable
                    ? 'اختار البيانات اللي تساعد المدرّب يرد عليك. تقدر توقف المشاركة في أي وقت. الاختيارات للجلسة الحالية.'
                    : 'مشاركة البيانات لسه غير متاحة. دلوقتي بيتبعت سؤالك المكتوب بس. الاختيارات للجلسة الحالية.',
                widget.contextSharingAvailable
                    ? 'Choose what helps the Coach reply. You can stop sharing at any time. Choices apply to this session.'
                    : 'Data sharing is not available yet. Only your typed question is sent. Choices apply to this session.',
              ),
            ),
            TextButton(
              key: const ValueKey('coach_privacy_policy'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(t('سياسة الخصوصية', 'Privacy policy')),
                  content: const SingleChildScrollView(
                    child: SelectableText(personalEducationalPolicyTextAr),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(t('إغلاق', 'Close')),
                    ),
                  ],
                ),
              ),
              child: Text(t('سياسة الخصوصية', 'Privacy policy')),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('save_health_choices'),
              onPressed: save,
              child: Text(t('استخدم للجلسة الحالية', 'Use for this session')),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

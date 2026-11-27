import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/coach_learn_content.dart';

class CoachLearnArticleScreen extends StatelessWidget {
  const CoachLearnArticleScreen({super.key, required this.topic});
  final CoachLearnTopic topic;
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(ar ? topic.titleAr : topic.titleEn)),
      body: NebulaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                ar
                    ? 'معلومات عامة، مش علاج. ملخصات التطبيق لسه ما اتراجعتش من مختص. لو عندك حالة صحية أو احتياج خاص، راجع مختص مؤهل.'
                    : 'General information, not treatment. These app summaries have not yet had specialist review. Discuss medical or special dietary needs with a qualified professional.',
              ),
              const SizedBox(height: 16),
              for (final section in topic.sections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          ar ? section.titleAr : section.titleEn,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Text(ar ? section.bodyAr : section.bodyEn),
                      ],
                    ),
                  ),
                ),
              Text(
                ar ? 'المصدر الرسمي' : 'Official source',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(topic.sourceName),
              const SizedBox(height: 6),
              SelectableText(
                topic.sourceUrl,
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: () async {
                  try {
                    if (await launchUrl(
                      Uri.parse(topic.sourceUrl),
                      mode: LaunchMode.externalApplication,
                    )) {
                      return;
                    }
                  } catch (_) {}
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SufraSnackBar(
                        content: Text(
                          ar
                              ? 'تعذر فتح المصدر. تقدر تنسخ الرابط.'
                              : 'Could not open source. You can copy the link.',
                        ),
                      ),
                    );
                  }
                },
                child: Text(ar ? 'افتح المصدر' : 'Open source'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.push(topic.actionRoute),
                child: Text(ar ? topic.actionAr : topic.actionEn),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:flutter/material.dart';
import '../data/local_protected_ledger.dart';
import '../data/local_protected_progression_repository.dart';
import '../domain/progression_engine.dart';
import 'progression_screen.dart';
import 'widgets/badge_celebration.dart';

/// Demo-only protected experience. Production routing never constructs this.
class LocalProtectedExperience extends StatefulWidget {
  const LocalProtectedExperience({
    super.key,
    required this.uid,
    required this.ledger,
  });
  final String uid;
  final LocalProtectedLedger ledger;
  @override
  State<LocalProtectedExperience> createState() =>
      _LocalProtectedExperienceState();
}

class _LocalProtectedExperienceState extends State<LocalProtectedExperience> {
  late LocalProtectedProgressionRepository repository;
  int revision = 0;
  @override
  void initState() {
    super.initState();
    repository = LocalProtectedProgressionRepository(widget.ledger);
  }

  @override
  void didUpdateWidget(covariant LocalProtectedExperience old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid || old.ledger != widget.ledger) {
      repository = LocalProtectedProgressionRepository(widget.ledger);
      revision++;
    }
  }

  Future<void> recover() async {
    final owner = widget.uid;
    final before = await widget.ledger.load(owner);
    await widget.ledger.recover(owner);
    final after = await widget.ledger.load(owner);
    widget.ledger.assertOwner(owner);
    if (!mounted || widget.uid != owner) return;
    setState(() => revision++);
    final old = (before?['badges'] as Map?) ?? {};
    final earned = ((after?['badges'] as Map?) ?? {}).entries
        .where((e) => e.value == true && old[e.key] != true)
        .map((e) => e.key as String)
        .toList();
    if (earned.isNotEmpty) {
      final snapshot = await repository.load(
        owner,
        ProgressionEngine.keyOf(DateTime.now().toUtc()),
      );
      if (!mounted || widget.uid != owner) return;
      final badge = snapshot.config.badges.singleWhere(
        (b) => b.id == earned.first,
      );
      await showBadgeCelebration(
        context,
        id: badge.id,
        title: Localizations.localeOf(context).languageCode == 'ar'
            ? badge.ar
            : badge.en,
        preview: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ProgressionScreen(
        key: ValueKey('${widget.uid}:$revision'),
        uid: widget.uid,
        todayKey: ProgressionEngine.keyOf(DateTime.now().toUtc()),
        repository: repository,
      ),
      Positioned(
        top: 8,
        left: 12,
        child: SafeArea(
          child: FilledButton.tonal(
            key: const ValueKey('recover-protected-pending'),
            onPressed: () async {
              try {
                await recover();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SufraSnackBar(
                      content: Text(
                        'Local ledger unavailable. No projected rewards.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('مزامنة المحفوظ'),
          ),
        ),
      ),
    ],
  );
}

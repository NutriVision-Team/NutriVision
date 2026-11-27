import 'package:flutter/widgets.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/reminder_guard.dart';
import '../../domain/reminder_models.dart';
import '../../data/reminder_scheduler.dart';
import '../../data/reminder_store.dart';
import 'reminder_texts.dart';

/// Keeps the OS schedule equal to the signed-in account's saved settings.
/// Place it inside MaterialApp (needs localizations), above the router
/// content, with the current uid (null when signed out):
///  - uid becomes null or changes: everything is cancelled, then only the
///    new account's reminders are scheduled after verified cleanup. Native
///    stale alarms before the next app start remain a documented limitation;
///  - app start, resume, language change: re-applied, so a changed device
///    timezone or a system-cleared schedule is repaired.
/// It never asks for permission.
class RemindersHost extends StatefulWidget {
  const RemindersHost({
    super.key,
    required this.uid,
    required this.authResolved,
    required this.store,
    required this.scheduler,
    required this.child,
    this.onCleanupFailed,
  });
  final String? uid;

  /// False while auth is still initialising. Nothing is cancelled or
  /// scheduled until it is true, so a null uid at cold start is not read
  /// as a sign-out.
  final bool authResolved;
  final void Function()? onCleanupFailed;
  final ReminderStore store;
  final ReminderScheduler scheduler;
  final Widget child;

  @override
  State<RemindersHost> createState() => _RemindersHostState();
}

class _RemindersHostState extends State<RemindersHost>
    with WidgetsBindingObserver {
  String? _lastLocale;
  bool _first = true;
  int _gen = 0;
  String? _activeUid;
  Future<void> _chain = Future.value();
  late final ReminderGuard _guard = ReminderGuard(
    store: widget.store,
    scheduler: widget.scheduler,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _gen++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_first || locale != _lastLocale) {
      _first = false;
      _lastLocale = locale;
      _sync();
    }
  }

  @override
  void didUpdateWidget(RemindersHost old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid || old.authResolved != widget.authResolved) {
      _sync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  void _sync() {
    final gen = ++_gen;
    if (!widget.authResolved) return;
    final uid = widget.uid,
        texts = reminderTextsFor(AppLocalizations.of(context));
    _chain = _chain
        .then((_) async {
          if (mounted && gen == _gen) await _syncJob(gen, uid, texts);
        })
        .catchError((Object _) {
          if (mounted) widget.onCleanupFailed?.call();
        });
  }

  Future<void> _syncJob(int gen, String? uid, ReminderTexts texts) async {
    final signedIn = uid != null && uid.isNotEmpty;
    final owner = widget.store.scheduledOwner;
    // Clean first (verified) when: signed out, a previous cleanup is
    // unfinished, the account changed, or the OS may hold another account's
    // schedule (owner marker differs).
    final needClean =
        !signedIn ||
        _guard.needsCleanup ||
        (_activeUid != null && _activeUid != uid) ||
        (owner != null && owner != uid);
    if (needClean) {
      final r = await _guard.cancelEverything();
      if (r == CleanupResult.failed) {
        // Do not schedule anything on top of an unverified cancel. The
        // pending flag stays set; the next start/resume retries.
        if (mounted && gen == _gen) widget.onCleanupFailed?.call();
        return;
      }
      _activeUid = null;
    }
    if (!mounted || gen != _gen || !signedIn) {
      return;
    }
    _activeUid = uid;
    try {
      await widget.store.setScheduledOwner(uid);
    } catch (_) {
      if (mounted && gen == _gen) widget.onCleanupFailed?.call();
      return; // cannot record ownership: do not schedule
    }
    if (!mounted || gen != _gen) return;
    await widget.scheduler.sync(
      uid: uid,
      settings: widget.store.load(uid),
      texts: texts,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../data/dictation_service.dart';

/// A return-text-only sheet. It never searches, sends a question or saves a meal.
class DictationTextSheet extends StatefulWidget {
  const DictationTextSheet({super.key, this.initialText = '', this.dictation});
  final String initialText;
  final DictationService? dictation;
  @override
  State<DictationTextSheet> createState() => _DictationTextSheetState();
}

class _DictationTextSheetState extends State<DictationTextSheet>
    with WidgetsBindingObserver {
  late final DictationService _service;
  late final int _lease;
  late final TextEditingController _text;
  String _seen = '';
  bool _edited = false;
  @override
  void initState() {
    super.initState();
    _service = widget.dictation ?? PlatformDictationService.shared;
    _lease = _service.acquire();
    _text = TextEditingController(text: widget.initialText);
    _service.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  void _changed() {
    if (!mounted) return;
    if (_service.text != _seen) {
      _seen = _service.text;
      if (!_edited && _seen.isNotEmpty) {
        final value = [
          widget.initialText.trim(),
          _seen,
        ].where((s) => s.isNotEmpty).join(' ');
        _text.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      }
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _service.stop(_lease);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.removeListener(_changed);
    _service.release(_lease);
    _text.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_service.status == DictationStatus.listening ||
        _service.status == DictationStatus.starting) {
      await _service.stop(_lease);
    } else {
      _edited = false;
      await _service.start(
        _lease,
        Localizations.localeOf(context).languageCode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final active =
        _service.status == DictationStatus.listening ||
        _service.status == DictationStatus.starting;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.voiceDescription,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                l.voicePrivacy,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              IconButton(
                key: const ValueKey('dictation-sheet-mic'),
                onPressed: _toggle,
                tooltip: active ? l.voiceStop : l.voiceStart,
                icon: Icon(
                  active ? Icons.stop_circle_outlined : Icons.mic_none,
                  size: 40,
                ),
              ),
              if (!const {
                DictationStatus.idle,
                DictationStatus.starting,
                DictationStatus.listening,
              }.contains(_service.status))
                Text(l.voiceUnavailable),
              TextField(
                controller: _text,
                maxLength: 1000,
                minLines: 2,
                maxLines: 5,
                onChanged: (_) {
                  _edited = true;
                  setState(() {});
                },
                decoration: InputDecoration(labelText: l.voiceDescription),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.actionCancel),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('dictation-use-text'),
                    onPressed: _text.text.length > 1000
                        ? null
                        : () async {
                            await _service.stop(_lease);
                            if (context.mounted) {
                              Navigator.pop(context, _text.text.trim());
                            }
                          },
                    child: Text(l.actionSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

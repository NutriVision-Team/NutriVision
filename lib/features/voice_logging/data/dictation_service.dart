import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum DictationStatus {
  idle,
  starting,
  listening,
  unavailable,
  denied,
  languageUnavailable,
  noSpeech,
  failed,
}

/// One platform recognizer per process. Leases keep late results from crossing
/// screens or accounts. The service holds no persisted transcript or audio.
abstract class DictationService extends ChangeNotifier {
  DictationStatus get status;
  String get text;
  int acquire();
  Future<void> start(int lease, String language);
  Future<void> stop(int lease);
  void release(int lease);
}

class PlatformDictationService extends DictationService {
  PlatformDictationService._();
  static final shared = PlatformDictationService._();
  final _speech = SpeechToText();
  Future<bool>? _initializing;
  Future<void> _pendingCancel = Future.value();
  int _owner = 0, _generation = 0;
  DictationStatus _status = DictationStatus.idle;
  String _text = '';
  bool _allowEvents = false;
  Future<void> _cancelSafely() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  @override
  DictationStatus get status => _status;
  @override
  String get text => _text;
  void _set(DictationStatus value) {
    _status = value;
    notifyListeners();
  }

  @override
  int acquire() {
    ++_owner;
    ++_generation;
    _pendingCancel = _pendingCancel.then((_) => _cancelSafely());
    _text = '';
    _allowEvents = false;
    _status = DictationStatus.idle;
    return _owner;
  }

  bool _current(int lease, int generation) =>
      lease == _owner && generation == _generation;
  Future<bool> _initialize() async {
    final value = await (_initializing ??= _speech.initialize(
      onStatus: (_) {
        if (_status == DictationStatus.listening && !_speech.isListening) {
          _set(DictationStatus.idle);
        }
      },
      onError: (error) {
        if (!_allowEvents) return;
        if (_status != DictationStatus.listening &&
            _status != DictationStatus.starting) {
          return;
        }
        _set(
          error.errorMsg.contains('permission')
              ? DictationStatus.denied
              : error.errorMsg.contains('no_match') ||
                    error.errorMsg.contains('timeout')
              ? DictationStatus.noSpeech
              : DictationStatus.failed,
        );
      },
    ));
    if (!value) _initializing = null;
    return value;
  }

  @override
  Future<void> start(int lease, String language) async {
    if (lease != _owner ||
        _status == DictationStatus.starting ||
        _status == DictationStatus.listening) {
      return;
    }
    final generation = ++_generation;
    _allowEvents = false;
    _set(DictationStatus.starting);
    try {
      await _pendingCancel;
      if (!_current(lease, generation)) return;
      final available = await _initialize();
      if (!_current(lease, generation)) return;
      if (!available) {
        final allowed = await _speech.hasPermission;
        if (_current(lease, generation)) {
          _set(allowed ? DictationStatus.unavailable : DictationStatus.denied);
        }
        return;
      }
      final locales = await _speech.locales();
      if (!_current(lease, generation)) return;
      final supported = locales
          .where(
            (l) =>
                l.localeId
                    .toLowerCase()
                    .replaceAll('-', '_')
                    .startsWith('${language}_') ||
                l.localeId == language,
          )
          .toList();
      if (supported.isEmpty) {
        _set(DictationStatus.languageUnavailable);
        return;
      }
      final preferred = language == 'ar' ? 'ar_eg' : 'en_us';
      final locale =
          supported
              .where(
                (l) =>
                    l.localeId.toLowerCase().replaceAll('-', '_') == preferred,
              )
              .firstOrNull ??
          supported.first;
      _text = '';
      notifyListeners();
      _allowEvents = true;
      await _speech.listen(
        onResult: (result) {
          if (!_current(lease, generation)) return;
          _text = result.recognizedWords;
          if (result.finalResult) _status = DictationStatus.idle;
          notifyListeners();
        },
        listenOptions: SpeechListenOptions(
          localeId: locale.localeId,
          listenFor: const Duration(seconds: 35),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
      if (_current(lease, generation) && _status == DictationStatus.starting) {
        _set(
          _speech.isListening
              ? DictationStatus.listening
              : DictationStatus.noSpeech,
        );
      }
    } catch (_) {
      if (_current(lease, generation)) {
        _initializing = null;
        _set(DictationStatus.failed);
      }
    }
  }

  @override
  Future<void> stop(int lease) async {
    if (lease != _owner) return;
    if (_status == DictationStatus.starting) ++_generation;
    try {
      await _speech.stop();
    } catch (_) {}
    _allowEvents = false;
    if (lease == _owner) _set(DictationStatus.idle);
  }

  @override
  void release(int lease) {
    if (lease != _owner) return;
    ++_owner;
    ++_generation;
    _text = '';
    _allowEvents = false;
    _status = DictationStatus.idle;
    _pendingCancel = _pendingCancel.then((_) => _cancelSafely());
  }
}

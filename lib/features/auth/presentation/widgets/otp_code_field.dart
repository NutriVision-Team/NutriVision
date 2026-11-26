import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Separate boxes for a numeric code. The [controller] always holds the code
/// typed so far, so forms can validate it like a normal text field.
///
/// Typing a digit moves to the next box, backspace on an empty box clears and
/// moves to the previous one, and pasting a full code (into any box) fills the
/// boxes from that position. Digits are always left to right, also in Arabic.
/// Arabic-Indic digits are converted to ASCII digits.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.enabled = true,
    this.onCompleted,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final int length;
  final bool enabled;
  final ValueChanged<String>? onCompleted;
  final String? semanticLabel;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  late final List<TextEditingController> _boxes;
  late final List<FocusNode> _focus;
  bool _updating = false;

  static String digitsOnly(String input) {
    final out = StringBuffer();
    for (final unit in input.runes) {
      if (unit >= 0x30 && unit <= 0x39) {
        out.writeCharCode(unit);
      } else if (unit >= 0x660 && unit <= 0x669) {
        out.writeCharCode(0x30 + unit - 0x660);
      } else if (unit >= 0x6F0 && unit <= 0x6F9) {
        out.writeCharCode(0x30 + unit - 0x6F0);
      }
    }
    return out.toString();
  }

  @override
  void initState() {
    super.initState();
    _boxes = List.generate(widget.length, (_) => TextEditingController());
    _focus = List.generate(widget.length, (_) => FocusNode());
    widget.controller.addListener(_fromController);
    _fromController();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_fromController);
    for (final c in _boxes) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _fromController() {
    if (_updating) return;
    final code = digitsOnly(widget.controller.text);
    for (var i = 0; i < widget.length; i++) {
      final v = i < code.length ? code[i] : '';
      if (_boxes[i].text != v) _boxes[i].text = v;
    }
  }

  void _publish() {
    final code = _boxes.map((c) => c.text).join();
    _updating = true;
    widget.controller.text = code;
    _updating = false;
    if (code.length == widget.length && !_boxes.any((c) => c.text.isEmpty)) {
      widget.onCompleted?.call(code);
    }
  }

  void _changed(int i, String raw) {
    final digits = digitsOnly(raw);
    if (digits.isEmpty) {
      _boxes[i].text = '';
      _publish();
      return;
    }
    // One digit types; several digits are a paste that fills from this box.
    var last = i;
    for (var k = 0; k < digits.length && i + k < widget.length; k++) {
      _boxes[i + k].text = digits[k];
      last = i + k;
    }
    _publish();
    if (last + 1 < widget.length) {
      _focus[last + 1].requestFocus();
    } else {
      _focus[last].requestFocus();
    }
  }

  KeyEventResult _key(int i, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _boxes[i].text.isEmpty &&
        i > 0) {
      _boxes[i - 1].text = '';
      _publish();
      _focus[i - 1].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: widget.semanticLabel,
      container: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final w =
                ((constraints.maxWidth - gap * (widget.length - 1)) /
                        widget.length)
                    .clamp(36.0, 52.0);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  SizedBox(
                    width: w,
                    height: 58,
                    child: Focus(
                      onKeyEvent: (_, e) => _key(i, e),
                      child: TextField(
                        key: ValueKey('otp-box-$i'),
                        controller: _boxes[i],
                        focusNode: _focus[i],
                        enabled: widget.enabled,
                        autofocus: false,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        textInputAction: i == widget.length - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        autofillHints: i == 0
                            ? const [AutofillHints.oneTimeCode]
                            : null,
                        enableSuggestions: false,
                        autocorrect: false,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (v) => _changed(i, v),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

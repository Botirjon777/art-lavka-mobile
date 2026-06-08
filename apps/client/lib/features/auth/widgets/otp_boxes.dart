import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six single-digit OTP boxes with auto-advance, backspace-to-previous, paste of
/// the whole code, and auto-submit when full (SPEC §8).
class OtpBoxes extends StatefulWidget {
  const OtpBoxes({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.hasError = false,
  });

  /// Called with the full code once all [AppConstants.otpLength] digits are set.
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool hasError;

  @override
  State<OtpBoxes> createState() => OtpBoxesState();
}

class OtpBoxesState extends State<OtpBoxes> {
  static const int _len = AppConstants.otpLength;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_len, (_) => TextEditingController());
    _nodes = List.generate(_len, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  /// Clear all boxes and focus the first (used on a wrong-code error).
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (mounted) _nodes.first.requestFocus();
  }

  void _onChanged(int index, String value) {
    // Paste / autofill of the whole code into one box.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _len; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final filled = digits.length.clamp(0, _len);
      (filled >= _len ? _nodes.last : _nodes[filled]).requestFocus();
      _emit();
      return;
    }
    if (value.isNotEmpty && index < _len - 1) {
      _nodes[index + 1].requestFocus();
    }
    _emit();
  }

  void _emit() {
    final code = _code;
    widget.onChanged?.call(code);
    if (code.length == _len && !code.contains(' ')) {
      widget.onCompleted(code);
    }
  }

  KeyEventResult _onKey(int index, FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _nodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _emit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.hasError ? AppColors.error : AppColors.border;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_len, (i) {
        return SizedBox(
          width: 48,
          child: Focus(
            onKeyEvent: (node, event) => _onKey(i, node, event),
            child: TextField(
              controller: _controllers[i],
              focusNode: _nodes[i],
              enabled: widget.enabled,
              autofocus: i == 0,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: i == 0 ? AppConstants.otpLength : 1,
              style: Theme.of(context).textTheme.titleLarge,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
              ),
              onChanged: (v) => _onChanged(i, v),
            ),
          ),
        );
      }),
    );
  }
}

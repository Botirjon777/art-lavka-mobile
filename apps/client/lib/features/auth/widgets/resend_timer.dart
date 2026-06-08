import 'dart:async';

import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

/// Counts down [AppConstants.otpResendSeconds] then enables a "Resend code"
/// button (SPEC §8). Restarts the countdown each time [onResend] is invoked.
class ResendTimer extends StatefulWidget {
  const ResendTimer({super.key, required this.onResend, this.enabled = true});

  /// Called when the user taps resend. Return value ignored; the timer restarts.
  final Future<void> Function() onResend;
  final bool enabled;

  @override
  State<ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<ResendTimer> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _remaining = AppConstants.otpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  Future<void> _resend() async {
    await widget.onResend();
    if (mounted) _start();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (_remaining > 0) {
      return Text(
        t.otpResendIn(_remaining),
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return TextButton(
      onPressed: widget.enabled ? _resend : null,
      child: Text(t.otpResend),
    );
  }
}

import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../ui/loading_button.dart';
import 'auth_controller.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/otp_boxes.dart';
import 'widgets/resend_timer.dart';

/// OTP verification: 6 boxes, auto-submit, resend countdown (SPEC §8).
/// On success the router redirects (to home or profile completion) via the
/// session change — this screen doesn't navigate itself.
class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _boxesKey = GlobalKey<OtpBoxesState>();
  String _code = '';

  Future<void> _verify() async {
    if (_code.length != AppConstants.otpLength) return;
    await ref.read(authControllerProvider.notifier).verify(_code);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final state = ref.watch(authControllerProvider);

    // Clear the boxes whenever a new error arrives (e.g. wrong code).
    ref.listen(authControllerProvider, (prev, next) {
      if (next.errorCode != null && prev?.errorCode != next.errorCode) {
        _boxesKey.currentState?.clear();
        setState(() => _code = '');
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(t.otpTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space * 3),
          children: [
            Text(
              t.otpSentTo(state.phone),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.space * 3),
            OtpBoxes(
              key: _boxesKey,
              enabled: !state.submitting,
              hasError: state.errorCode != null,
              onChanged: (code) => setState(() => _code = code),
              onCompleted: (_) => _verify(),
            ),
            AuthErrorBanner(code: state.errorCode),
            const SizedBox(height: AppTheme.space * 2),
            LoadingButton(
              label: t.otpVerify,
              loading: state.submitting,
              onPressed: _code.length == AppConstants.otpLength
                  ? _verify
                  : null,
            ),
            const SizedBox(height: AppTheme.space * 2),
            Center(
              child: ResendTimer(
                enabled: !state.submitting,
                onResend: () =>
                    ref.read(authControllerProvider.notifier).resend(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

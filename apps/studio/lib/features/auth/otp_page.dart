import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import 'auth_controller.dart';

/// Studio OTP entry. On success the router redirects (onboarding/pending/dashboard).
class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != AppConstants.otpLength) return;
    await ref.read(authControllerProvider.notifier).verify(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final state = ref.watch(authControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.otpTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space * 3),
          children: [
            Text(t.otpSentTo(state.phone), style: text.bodyLarge),
            const SizedBox(height: AppTheme.space * 2),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: AppConstants.otpLength,
              textAlign: TextAlign.center,
              style: text.headlineMedium,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: ''),
              onChanged: (v) {
                if (v.length == AppConstants.otpLength) _verify();
              },
            ),
            if (state.errorCode != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.space),
                child: Text(
                  localizedFailure(t, state.errorCode),
                  style: text.bodyMedium?.copyWith(color: AppColors.error),
                ),
              ),
            const SizedBox(height: AppTheme.space * 2),
            FilledButton(
              onPressed: state.submitting ? null : _verify,
              child: state.submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.onAccent,
                      ),
                    )
                  : Text(t.otpVerify),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).resend(),
              child: Text(t.authSendCode),
            ),
          ],
        ),
      ),
    );
  }
}

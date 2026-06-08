import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import 'auth_controller.dart';

/// Studio login: phone → OTP (SPEC §8). Sellers log in, then onboard.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phone = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    if (Validators.phone(_phone.text) != null) {
      setState(() => _error = t.valInvalidPhone);
      return;
    }
    setState(() => _error = null);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .requestOtp(_phone.text);
    if (ok && mounted) context.push('/otp');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final state = ref.watch(authControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.appName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space * 3),
          children: [
            Text(t.tagline, style: text.headlineMedium),
            const SizedBox(height: AppTheme.space),
            Text(t.loginSubtitle, style: text.bodyLarge),
            const SizedBox(height: AppTheme.space * 2),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()-]')),
              ],
              decoration: InputDecoration(
                labelText: t.fieldPhone,
                prefixText: '+998 ',
                hintText: '90 123 45 67',
                errorText: _error,
                helperText: ' ',
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (state.errorCode != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space),
                child: Text(
                  localizedFailure(t, state.errorCode),
                  style: text.bodyMedium?.copyWith(color: AppColors.error),
                ),
              ),
            const SizedBox(height: AppTheme.space),
            FilledButton(
              onPressed: state.submitting ? null : _submit,
              child: state.submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.onAccent,
                      ),
                    )
                  : Text(t.authSendCode),
            ),
          ],
        ),
      ),
    );
  }
}

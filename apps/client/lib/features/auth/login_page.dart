import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../ui/loading_button.dart';
import 'auth_controller.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/phone_field.dart';

/// Login: phone only → request an OTP (SPEC §8).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phone = TextEditingController();
  String? _phoneError;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final invalid = Validators.phone(_phone.text) != null;
    setState(() => _phoneError = invalid ? t.valInvalidPhone : null);
    if (invalid) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .startLogin(phone: _phone.text);
    if (ok && mounted) context.push('/otp');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.loginTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space * 3),
          children: [
            Text(t.loginSubtitle, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppTheme.space * 2),
            PhoneField(
              controller: _phone,
              label: t.fieldPhone,
              errorText: _phoneError,
              onChanged: (_) {
                if (_phoneError != null) setState(() => _phoneError = null);
              },
            ),
            AuthErrorBanner(code: state.errorCode),
            const SizedBox(height: AppTheme.space * 2),
            LoadingButton(
              label: t.authSendCode,
              loading: state.submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bootstrap/core_providers.dart';
import '../../l10n/l10n.dart';
import '../../ui/language_switcher.dart';
import '../../ui/loading_button.dart';
import 'auth_controller.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/phone_field.dart';

/// Register: name + phone (+ optional email), then request an OTP (SPEC §8).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String? _nameError;
  String? _phoneError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final nameMissing = Validators.required(_name.text) != null;
    final phoneInvalid = Validators.phone(_phone.text) != null;
    setState(() {
      _nameError = nameMissing ? t.valRequired : null;
      _phoneError = phoneInvalid ? t.valInvalidPhone : null;
    });
    if (nameMissing || phoneInvalid) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .startRegister(
          fullName: _name.text,
          phone: _phone.text,
          email: _email.text,
          languageCode: ref.read(localeProvider).languageCode,
        );
    if (ok && mounted) context.push('/otp');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.registerTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space * 3),
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: LanguageSwitcher(),
            ),
            const SizedBox(height: AppTheme.space * 2),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: t.fieldFullName,
                errorText: _nameError,
                helperText: ' ',
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: AppTheme.space),
            PhoneField(
              controller: _phone,
              label: t.fieldPhone,
              errorText: _phoneError,
              onChanged: (_) {
                if (_phoneError != null) setState(() => _phoneError = null);
              },
            ),
            const SizedBox(height: AppTheme.space),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: t.fieldEmailOptional,
                helperText: ' ',
              ),
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

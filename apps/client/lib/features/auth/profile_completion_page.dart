import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../l10n/l10n.dart';
import '../../ui/language_switcher.dart';
import '../../ui/loading_button.dart';
import 'auth_controller.dart';
import 'widgets/auth_error_banner.dart';

/// First-login profile completion: name + preferred language (SPEC §8). Shown
/// only when a signed-in user has no display name yet; saving unlocks the app.
class ProfileCompletionPage extends ConsumerStatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  ConsumerState<ProfileCompletionPage> createState() =>
      _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends ConsumerState<ProfileCompletionPage> {
  final _name = TextEditingController();
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.l10n;
    final missing = Validators.required(_name.text) != null;
    setState(() => _nameError = missing ? t.valRequired : null);
    if (missing) return;

    // Saving sets the session user → the router redirects to home.
    await ref
        .read(authControllerProvider.notifier)
        .submitProfile(
          fullName: _name.text.trim(),
          languageCode: ref.read(localeProvider).languageCode,
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final state = ref.watch(authControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.profileTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space * 3),
          children: [
            Text(t.profileSubtitle, style: text.bodyLarge),
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
            Row(
              children: [
                Text(t.languageLabel, style: text.bodyMedium),
                const Spacer(),
                const LanguageSwitcher(),
              ],
            ),
            AuthErrorBanner(code: state.errorCode),
            const SizedBox(height: AppTheme.space * 2),
            LoadingButton(
              label: t.profileSave,
              loading: state.submitting,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

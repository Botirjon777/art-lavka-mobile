import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../l10n/l10n.dart';
import '../auth/auth_controller.dart';

/// Concise seller regulations (SPEC §9). Real legal text + localization later;
/// the hash of this exact text is stored with the acceptance for enforceability.
const _rulesText = '''
By selling on ART-LAVKA you agree that:

1. No 18+ or sexual content.
2. No religious content.
3. No content depicting war or violence.
4. No copyrighted or trademarked work you do not own.
5. You own all rights to the artwork you upload and grant ART-LAVKA the right to print and sell it.
6. You indemnify ART-LAVKA against claims arising from your content.
7. Royalties are paid per delivered item after the return window; payouts are processed on a schedule once your balance reaches the minimum threshold.
8. ART-LAVKA may reject or remove any design that violates these rules.

These terms may be updated; continued selling constitutes acceptance of the current version.
''';

/// Seller onboarding: KYC → read regulations (scroll to enable) → e-signature →
/// submit (status pending). The router gate keeps the dashboard locked (SPEC §9).
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _displayName = TextEditingController();
  final _legalName = TextEditingController();
  final _idNumber = TextEditingController();
  final _signature = TextEditingController();
  final _rulesScroll = ScrollController();

  PayoutMethod _payout = PayoutMethod.card;
  bool _scrolledToEnd = false;
  bool _agreed = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rulesScroll.addListener(() {
      if (_rulesScroll.position.pixels >=
          _rulesScroll.position.maxScrollExtent - 8) {
        if (!_scrolledToEnd) setState(() => _scrolledToEnd = true);
      }
    });
  }

  @override
  void dispose() {
    _displayName.dispose();
    _legalName.dispose();
    _idNumber.dispose();
    _signature.dispose();
    _rulesScroll.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _displayName.text.trim().isNotEmpty &&
      _legalName.text.trim().isNotEmpty &&
      _agreed &&
      _signature.text.trim().isNotEmpty &&
      !_submitting;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final result = await ref
        .read(designerRepositoryProvider)
        .onboard(
          displayName: _displayName.text.trim(),
          legalName: _legalName.text.trim(),
          idNumber: _idNumber.text.trim().isEmpty
              ? null
              : _idNumber.text.trim(),
          payoutMethod: _payout,
          contractVersion: AppConstants.contractVersion,
          // Stable identifier of the exact text accepted (sha256 ideally).
          regulationsHash: _rulesText.hashCode.toRadixString(16),
          signatureName: _signature.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      (profile) => ref.read(appSessionProvider).setProfile(profile),
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedFailure(context.l10n, failure.code))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.onboardTitle),
        actions: [
          IconButton(
            tooltip: t.actionSignOut,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space * 2),
          children: [
            Text(t.onboardKyc, style: text.titleLarge),
            const SizedBox(height: AppTheme.space),
            _field(_displayName, t.fieldDisplayName),
            _field(_legalName, t.fieldLegalName),
            _field(_idNumber, t.fieldIdNumber),
            const SizedBox(height: AppTheme.space),
            Text(t.fieldPayoutMethod, style: text.titleMedium),
            RadioGroup<PayoutMethod>(
              groupValue: _payout,
              onChanged: (v) => setState(() => _payout = v ?? _payout),
              child: Column(
                children: [
                  RadioListTile(
                    value: PayoutMethod.card,
                    title: Text(t.payoutCard),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile(
                    value: PayoutMethod.bank,
                    title: Text(t.payoutBank),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space),
            Text(t.onboardRules, style: text.titleLarge),
            const SizedBox(height: AppTheme.space),
            Container(
              height: 200,
              padding: const EdgeInsets.all(AppTheme.space),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: Scrollbar(
                controller: _rulesScroll,
                child: SingleChildScrollView(
                  controller: _rulesScroll,
                  child: Text(_rulesText, style: text.bodyMedium),
                ),
              ),
            ),
            if (!_scrolledToEnd)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  t.onboardRulesScrollHint,
                  style: text.bodySmall?.copyWith(color: AppColors.inkFaint),
                ),
              ),
            CheckboxListTile(
              value: _agreed,
              onChanged: _scrolledToEnd
                  ? (v) => setState(() => _agreed = v ?? false)
                  : null,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(t.onboardAgree),
            ),
            const SizedBox(height: AppTheme.space),
            Text(t.onboardSignature, style: text.titleLarge),
            const SizedBox(height: AppTheme.space),
            TextField(
              controller: _signature,
              decoration: InputDecoration(
                labelText: t.fieldSignatureName,
                helperText: ' ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppTheme.space),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.onAccent,
                      ),
                    )
                  : Text(t.onboardSubmit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: AppTheme.space),
    child: TextField(
      controller: c,
      decoration: InputDecoration(labelText: label, helperText: ' '),
      onChanged: (_) => setState(() {}),
    ),
  );
}

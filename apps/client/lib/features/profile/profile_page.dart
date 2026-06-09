import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bootstrap/core_providers.dart';
import '../../l10n/l10n.dart';
import '../../ui/language_switcher.dart';
import '../auth/auth_controller.dart';

/// Account tab: identity (+ edit name), language, shortcuts, about, sign out.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    final session = ref.watch(appSessionProvider);

    // Rebuild when the session user changes (e.g. after editing the name).
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final user = session.user;
        return Scaffold(
          appBar: AppBar(title: Text(t.profileTitle)),
          body: ListView(
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  (user?.fullName?.isNotEmpty ?? false) ? user!.fullName! : '—',
                  style: text.titleMedium,
                ),
                subtitle: Text(user?.phone ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: t.profileEditName,
                  onPressed: () => _editName(context, ref, user?.fullName),
                ),
              ),
              const Divider(),

              _sectionLabel(context, t.profileLanguage),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.space * 2,
                  0,
                  AppTheme.space * 2,
                  AppTheme.space,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: LanguageSwitcher(),
                ),
              ),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(t.profileMyOrders),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/orders'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(t.profileAddresses),
                trailing: Text(t.profileComingSoon, style: text.bodySmall),
                onTap: () => _snack(context, t.profileComingSoon),
              ),
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(t.profileBecomeSeller),
                subtitle: Text(t.profileBecomeSellerHint),
                onTap: () => _snack(context, t.profileBecomeSellerHint),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(t.profileAbout),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: t.appName,
                  applicationVersion: 'v1.0',
                  children: [Text(t.profileAboutBody)],
                ),
              ),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  t.actionSignOut,
                  style: text.bodyLarge?.copyWith(color: AppColors.error),
                ),
                onTap: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(BuildContext context, String label) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppTheme.space * 2,
      AppTheme.space,
      AppTheme.space * 2,
      0,
    ),
    child: Text(label, style: Theme.of(context).textTheme.titleMedium),
  );

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final t = context.l10n;
    final controller = TextEditingController(text: current ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.profileEditName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: t.fieldFullName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(t.profileSave),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    // submitProfile updates the backend (PATCH /auth/me) + the session user.
    await ref
        .read(authControllerProvider.notifier)
        .submitProfile(
          fullName: name,
          languageCode: ref.read(localeProvider).languageCode,
        );
  }
}

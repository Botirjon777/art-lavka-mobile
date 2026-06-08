import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../l10n/l10n.dart';
import '../../ui/language_switcher.dart';
import '../auth/auth_controller.dart';

/// Account tab: identity, language, become-a-seller pointer, sign out.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    final user = ref.watch(appSessionProvider).user;

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
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space * 2,
              AppTheme.space,
              AppTheme.space * 2,
              0,
            ),
            child: Text(t.profileLanguage, style: text.titleMedium),
          ),
          const Padding(
            padding: EdgeInsets.all(AppTheme.space * 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: LanguageSwitcher(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(t.profileBecomeSeller),
            subtitle: Text(t.profileBecomeSellerHint),
            onTap: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(t.profileBecomeSellerHint))),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              t.actionSignOut,
              style: text.bodyLarge?.copyWith(color: AppColors.error),
            ),
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}

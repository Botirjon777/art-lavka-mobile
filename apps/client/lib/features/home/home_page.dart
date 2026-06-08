import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../l10n/l10n.dart';
import '../auth/auth_controller.dart';

/// Authenticated landing. Placeholder until Step 4 builds the real home
/// (banners + feeds). Confirms the session works and offers sign-out.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    final user = ref.watch(appSessionProvider).user;
    final name = user?.fullName;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appName),
        actions: [
          IconButton(
            tooltip: t.actionSignOut,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space * 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                (name != null && name.isNotEmpty)
                    ? t.homeWelcome(name)
                    : t.homeWelcomeGeneric,
                style: text.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space),
              Text(
                t.homeFoundationNote,
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../auth/auth_controller.dart';

/// Shown while `kyc_status = pending` — dashboard stays locked (SPEC §9).
class PendingPage extends ConsumerWidget {
  const PendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.hourglass_top,
                size: 56,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppTheme.space * 2),
              Text(t.pendingTitle, style: text.headlineMedium),
              const SizedBox(height: AppTheme.space),
              Text(
                t.pendingBody,
                style: text.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

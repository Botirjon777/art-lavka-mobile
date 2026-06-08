import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../auth/auth_controller.dart';

/// Verified-seller dashboard (placeholder). Uploads/stats/earnings land next.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.dashboardTitle),
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
          child: Text(
            t.dashboardWelcome,
            style: text.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

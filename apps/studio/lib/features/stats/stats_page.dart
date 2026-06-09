import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../bootstrap/result_x.dart';
import '../../l10n/l10n.dart';
import '../../ui/async_views.dart';
import '../auth/auth_controller.dart';

final designerStatsProvider = FutureProvider.autoDispose<DesignerStats>(
  (ref) async => (await ref.watch(designerRepositoryProvider).stats()).unwrap(),
);

/// Seller stats: designs, listings, sales, balance.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final stats = ref.watch(designerStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.statsTitle),
        actions: [
          IconButton(
            tooltip: t.actionSignOut,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(designerStatsProvider),
        child: stats.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorRetryView(
            message: failureMessage(context, e),
            onRetry: () => ref.invalidate(designerStatsProvider),
          ),
          data: (s) => GridView.count(
            padding: const EdgeInsets.all(AppTheme.space * 2),
            crossAxisCount: 2,
            mainAxisSpacing: AppTheme.space * 2,
            crossAxisSpacing: AppTheme.space * 2,
            childAspectRatio: 1.4,
            children: [
              _StatCard(label: t.statDesigns, value: '${s.designs}'),
              _StatCard(label: t.statListings, value: '${s.listings}'),
              _StatCard(label: t.statSales, value: '${s.sales}'),
              _StatCard(
                label: t.statBalance,
                value: Money.format(s.balanceUzs),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space * 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: text.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: text.headlineMedium),
        ],
      ),
    );
  }
}

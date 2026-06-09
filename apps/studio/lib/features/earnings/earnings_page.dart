import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../bootstrap/result_x.dart';
import '../../l10n/l10n.dart';
import '../../ui/async_views.dart';
import '../auth/auth_controller.dart';
import 'earnings_controller.dart';

/// Earnings: available balance, withdraw, and the ledger history.
class EarningsPage extends ConsumerWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final balance = ref.watch(balanceProvider);
    final ledger = ref.watch(ledgerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.earningsTitle),
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
        onRefresh: () async {
          ref.invalidate(balanceProvider);
          ref.invalidate(ledgerProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space * 2),
          children: [
            _BalanceCard(
              balance: balance.valueOrNull ?? 0,
              onWithdraw: () => _withdraw(context, ref),
            ),
            const SizedBox(height: AppTheme.space * 2),
            Text(
              t.earningsHistory,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.space),
            ledger.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorRetryView(
                message: failureMessage(context, e),
                onRetry: () => ref.invalidate(ledgerProvider),
              ),
              data: (entries) => entries.isEmpty
                  ? EmptyView(
                      message: t.earningsEmpty,
                      icon: Icons.account_balance_wallet_outlined,
                    )
                  : Column(
                      children: [
                        for (final e in entries) _LedgerTile(entry: e),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.withdrawTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.withdrawAmount),
            ),
            const SizedBox(height: 8),
            Text(
              t.withdrawMin(AppConstants.minPayoutUzs),
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.actionCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: Text(t.withdrawSubmit),
          ),
        ],
      ),
    );
    if (amount == null || !context.mounted) return;

    final result = await ref
        .read(payoutRepositoryProvider)
        .requestPayout(amountUzs: amount);
    if (!context.mounted) return;
    result.fold(
      (_) {
        ref.invalidate(balanceProvider);
        ref.invalidate(ledgerProvider);
        ref.invalidate(payoutsProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.withdrawRequested)));
      },
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            f.code == FailureCode.belowPayoutThreshold
                ? t.withdrawMin(AppConstants.minPayoutUzs)
                : failureMessage(context, FailureException('', code: f.code)),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.onWithdraw});
  final int balance;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space * 2.5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.earningsBalance, style: text.bodyMedium),
          const SizedBox(height: 4),
          Text(Money.format(balance), style: text.displaySmall),
          const SizedBox(height: AppTheme.space),
          FilledButton.icon(
            onPressed: balance > 0 ? onWithdraw : null,
            icon: const Icon(Icons.payments_outlined),
            label: Text(t.earningsWithdraw),
          ),
        ],
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry});
  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final credit = entry.isCredit;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        credit ? Icons.arrow_downward : Icons.arrow_upward,
        color: credit ? AppColors.success : AppColors.inkMuted,
      ),
      title: Text(entry.memo ?? entry.type.name),
      subtitle: Text(
        entry.createdAt.toLocal().toString().split('.').first,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        Money.format(entry.amountUzs),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: credit ? AppColors.success : AppColors.ink,
        ),
      ),
    );
  }
}

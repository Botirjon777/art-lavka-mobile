import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bootstrap/result_x.dart';
import '../../l10n/l10n.dart';
import '../../ui/async_views.dart';
import 'orders_controller.dart';

/// The customer's orders, newest first, with loading/empty/error states (§7).
class OrdersListPage extends ConsumerWidget {
  const OrdersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final orders = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.ordersTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myOrdersProvider),
        child: orders.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorRetryView(
            message: failureMessage(context, e),
            onRetry: () => ref.invalidate(myOrdersProvider),
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    EmptyView(
                      message: t.ordersEmpty,
                      icon: Icons.receipt_long_outlined,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.space),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _OrderTile(order: list[i]),
                ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final shortId = order.id.split('-').first;
    return ListTile(
      title: Text('${t.ordersTitle} #$shortId'),
      subtitle: Text(orderStatusLabel(t, order.status)),
      trailing: Text(
        Money.format(order.totalUzs),
        style: Theme.of(context).textTheme.labelLarge,
      ),
      onTap: () => context.push('/orders/${order.id}'),
    );
  }
}

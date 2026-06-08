import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/result_x.dart';
import '../../l10n/l10n.dart';
import '../../ui/async_views.dart';
import 'orders_controller.dart';
import 'widgets/review_sheet.dart';

/// Order tracking: status timeline + items, with a rate action on delivered
/// items not yet reviewed (SPEC §6/§12).
class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  static const _steps = [
    OrderStatus.paid,
    OrderStatus.inProduction,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final order = ref.watch(orderProvider(orderId));
    final shortId = orderId.split('-').first;

    return Scaffold(
      appBar: AppBar(title: Text('${t.ordersTitle} #$shortId')),
      body: order.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorRetryView(
          message: failureMessage(context, e),
          onRetry: () => ref.invalidate(orderProvider(orderId)),
        ),
        data: (o) => ListView(
          padding: const EdgeInsets.all(AppTheme.space * 2),
          children: [
            _Timeline(status: o.status),
            const Divider(height: AppTheme.space * 4),
            for (final item in o.items)
              _ItemRow(
                item: item,
                canReview: o.status == OrderStatus.delivered && !item.reviewed,
                onReview: () async {
                  final done = await showReviewSheet(context, item.id);
                  if (done && context.mounted) {
                    ref.invalidate(orderProvider(orderId));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(t.reviewThanks)));
                  }
                },
              ),
            const Divider(height: AppTheme.space * 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.checkoutTotal,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  Money.format(o.totalUzs),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;

    if (status == OrderStatus.cancelled || status == OrderStatus.refunded) {
      return Row(
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.error),
          const SizedBox(width: AppTheme.space),
          Text(orderStatusLabel(t, status), style: text.titleMedium),
        ],
      );
    }

    final currentIndex = OrderDetailPage._steps.indexOf(status);
    return Column(
      children: [
        for (var i = 0; i < OrderDetailPage._steps.length; i++)
          _StepRow(
            label: orderStatusLabel(t, OrderDetailPage._steps[i]),
            done: currentIndex >= i,
            isLast: i == OrderDetailPage._steps.length - 1,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.isLast,
  });
  final String label;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.success : AppColors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: color,
                size: 22,
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: color)),
            ],
          ),
          const SizedBox(width: AppTheme.space * 1.5),
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space * 1.5),
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.canReview,
    required this.onReview,
  });
  final OrderItem item;
  final bool canReview;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titleSnapshot ?? '', style: text.titleMedium),
                Text('×${item.quantity}', style: text.bodySmall),
              ],
            ),
          ),
          Text(Money.format(item.lineTotalUzs), style: text.bodyMedium),
          if (canReview)
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.space),
              child: OutlinedButton(onPressed: onReview, child: Text(t.rate)),
            ),
        ],
      ),
    );
  }
}

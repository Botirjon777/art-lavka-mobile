import 'package:artlavka_core/artlavka_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../ui/async_views.dart';
import 'cart_controller.dart';

/// Cart: line items with qty steppers + remove, subtotal, checkout (SPEC §11).
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.cartTitle)),
      body: items.isEmpty
          ? EmptyView(message: t.cartEmpty, icon: Icons.shopping_bag_outlined)
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.space * 2),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppTheme.space * 2),
                    itemBuilder: (_, i) => _CartTile(item: items[i]),
                  ),
                ),
                _Footer(subtotal: subtotal),
              ],
            ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final cart = ref.read(cartProvider.notifier);
    final variant = [item.size, item.color].whereType<String>().join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 64,
            height: 64,
            child: (item.mockupUrl == null || item.mockupUrl!.isEmpty)
                ? Container(color: AppColors.surfaceMuted)
                : CachedNetworkImage(
                    imageUrl: item.mockupUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: AppColors.surfaceMuted),
                    errorWidget: (_, _, _) =>
                        Container(color: AppColors.surfaceMuted),
                  ),
          ),
        ),
        const SizedBox(width: AppTheme.space * 1.5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.titleSnapshot ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium,
              ),
              if (variant.isNotEmpty) Text(variant, style: text.bodySmall),
              const SizedBox(height: 4),
              Text(Money.format(item.lineTotalUzs), style: text.labelLarge),
            ],
          ),
        ),
        _QtyStepper(
          quantity: item.quantity,
          onChanged: (q) => cart.setQuantity(item.id, q),
          onRemove: () => cart.remove(item.id),
        ),
      ],
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.onChanged,
    required this.onRemove,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: quantity <= 1 ? onRemove : () => onChanged(quantity - 1),
          icon: Icon(quantity <= 1 ? Icons.delete_outline : Icons.remove),
        ),
        Text('$quantity'),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(quantity + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.subtotal});
  final int subtotal;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space * 2),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.cartSubtotal, style: text.titleMedium),
                Text(Money.format(subtotal), style: text.titleLarge),
              ],
            ),
            const SizedBox(height: AppTheme.space * 1.5),
            FilledButton(
              onPressed: () => context.push('/checkout'),
              child: Text(t.cartCheckout),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bootstrap/core_providers.dart';
import '../../l10n/l10n.dart';
import '../../ui/loading_button.dart';
import 'cart_controller.dart';

/// Checkout: address + payment method + summary → `POST /orders` (the server is
/// the price authority; the client total here is display-only). SPEC §5/§11.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _address = TextEditingController();
  PaymentProvider _provider = PaymentProvider.click;
  bool _submitting = false;
  String? _addressError;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final t = context.l10n;
    if (_address.text.trim().isEmpty) {
      setState(() => _addressError = t.valRequired);
      return;
    }
    setState(() {
      _addressError = null;
      _submitting = true;
    });
    final result = await ref
        .read(paymentServiceProvider)
        .createOrder(
          items: ref.read(cartProvider),
          provider: _provider,
          shippingAddress: _address.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      (intent) {
        ref.read(cartProvider.notifier).clear();
        context.go('/order-success/${intent.orderId}');
      },
      (failure) {
        final msg = failure.code == FailureCode.paymentFailed
            ? t.errPaymentFailed
            : t.errServer;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    final total = ref.watch(cartSubtotalProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.checkoutTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space * 2),
          children: [
            Text(t.checkoutAddress, style: text.titleMedium),
            const SizedBox(height: AppTheme.space),
            TextField(
              controller: _address,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: t.checkoutAddressHint,
                errorText: _addressError,
                helperText: ' ',
              ),
              onChanged: (_) {
                if (_addressError != null) {
                  setState(() => _addressError = null);
                }
              },
            ),
            const SizedBox(height: AppTheme.space * 2),
            Text(t.checkoutPayment, style: text.titleMedium),
            RadioGroup<PaymentProvider>(
              groupValue: _provider,
              onChanged: (v) => setState(() => _provider = v ?? _provider),
              child: Column(
                children: [
                  for (final p in PaymentProvider.values)
                    RadioListTile<PaymentProvider>(
                      value: p,
                      title: Text(_providerLabel(p)),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.checkoutTotal, style: text.titleMedium),
                  Text(Money.format(total), style: text.titleLarge),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space),
            LoadingButton(
              label: t.checkoutPlaceOrder,
              loading: _submitting,
              onPressed: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }

  String _providerLabel(PaymentProvider p) => switch (p) {
    PaymentProvider.click => 'Click',
    PaymentProvider.payme => 'Payme',
    PaymentProvider.uzum => 'Uzum',
  };
}
